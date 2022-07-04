
"Parses a Matpower .m `file` or PTI (PSS(R)E-v33) .raw `file` into a
PowerModels data structure. All fields from PTI files will be imported if
`import_all` is true (Default: false)."

function parse_model(file::String)
    
    filetype = split(lowercase(file), '.')[end]
    if filetype == "m"
        pm_data = PowerModels.parse_matpower(file, validate=true)
    elseif filetype == "raw"
        pm_data = PowerModels.parse_psse(file; import_all=false, validate=true)
    else
        Memento.error(_LOGGER, "Unrecognized filetype: \".$file\", Supported extensions are \".raw\" and \".m\"")
    end
    
    #renumber_buses!(pm_data)
    calc_thermal_limits!(pm_data)
    s_cost_terms!(pm_data, order=2)

    return pm_data
end

""
function build_data(file::String)
    
    data = parse_model(file)
    simp_network!(data)
    return data
end

""
function build_data(file::String, t_contingency_info::Vector{Tuple{Int64, Int64}})
    
    data = parse_model(file)
    apply_contingencies!(data,t_contingency_info)
    simp_network!(data)
    return data
end

""
function build_data(file::String, t_contingency_info::Vector{})
    
    data = parse_model(file)
    simp_network!(data)
    return data
end


"""
attempts to deactive components that are not needed in the network by repeated
calls to `propagate_topology_status!` and `deactivate_isolated_components!`
"""
function simp_network!(data::Dict{String,<:Any})

    revised = true
    iteration = 0

    while revised
        iteration += 1
        revised = false
        revised |= propagate_topo_status!(data)
        revised |= deactivate_isol_components!(data)
    end

    Memento.info(_LOGGER, "network simplification fixpoint reached in $(iteration) rounds")
    return revised
end