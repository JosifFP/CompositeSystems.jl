"maps component types to status parameters"
const component_status = Dict(
    "bus" => "bus_type",
    "load" => "status",
    "shunt" => "status",
    "gen" => "gen_status",
    "storage" => "status",
    "switch" => "status",
    "branch" => "br_status",
    "dcline" => "br_status",
)

function conversion_to_pm_data(network::Network{N,L,T,U}) where {N,L,T,U}
    return Dict(
    [("bus",network.bus)
    #("source_type",network.source_type)
    #("name",network.name)
    #("source_version",network.source_version)
    ("dcline",network.dcline)
    ("gen",network. gen)
    ("branch",network. branch)
    ("storage",network.storage)
    ("switch",network.switch )
    ("shunt",network.shunt)
    ("load",network.load)
    ("baseMVA",network.baseMVA)
    ("per_unit", network.per_unit)])
end

""
function BuildNetwork(file::String)
    
    pm_data = parse_model(file)
    network = _BuildNetwork!(pm_data)

    return network

end

""
function BuildNetwork(file::String, N::Int, L::Int, T::Type{<:Period}, U::Type{<:PerUnit})
    
    pm_data = parse_model(file)
    network = _BuildNetwork!(pm_data,N,L,T,U)

    return network

end

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

    return pm_data
end

""
function _BuildNetwork!(pm_data::Dict{String,Any})
    
    #renumber_buses!(pm_data)
    delete!(pm_data, "source_type")
    delete!(pm_data, "source_version")
    delete!(pm_data,"name")
    calc_thermal_limits!(pm_data)
    SimplifyNetwork!(pm_data)
    s_cost_terms!(pm_data, order=2)
    __init__() = Memento.register(_LOGGER)

    return Network{1,1,Hour,pu}(pm_data)
end

""
function _BuildNetwork!(pm_data::Dict{String,Any}, N::Int, L::Int, T::Type{<:Period}, U::Type{<:PerUnit})
    
    #renumber_buses!(pm_data)
    PowerModels.correct_network_data!(pm_data)
    delete!(pm_data, "source_type")
    delete!(pm_data, "source_version")
    delete!(pm_data,"name")
    calc_thermal_limits!(pm_data)
    SimplifyNetwork!(pm_data)
    s_cost_terms!(pm_data, order=2)
    __init__() = Memento.register(_LOGGER)

    return Network{N,L,T,U}(pm_data)
end

"""
attempts to deactive components that are not needed in the network by repeated
calls to `propagate_topology_status!` and `deactivate_isolated_components!`
"""
function SimplifyNetwork!(pm_data::Dict{String,Any})

    revised = true
    iteration = 0

    while revised
        iteration += 1
        revised = false
        revised |= propagate_topo_status!(pm_data)
        revised |= deactivate_isol_components!(pm_data)
    end

    Memento.info(_LOGGER, "network simplification fixpoint reached in $(iteration) rounds")
    return iteration
end

"""
attempts to deactive components that are not needed in the network by repeated
calls to `propagate_topology_status!` and `deactivate_isolated_components!`
"""
function SimplifyNetwork!(network::Network{N,L,T,U}) where {N,L,T,U}

    revised = true
    iteration = 0

    while revised
        iteration += 1
        revised = false
        revised |= propagate_topo_status!(network)
        revised |= deactivate_isol_components!(network)
    end

    Memento.info(_LOGGER, "network simplification fixpoint reached in $(iteration) rounds")
    return revised
end

"ensures all polynomial costs functions have the same number of terms"
function s_cost_terms!(pm_data::Dict{String,<:Any}; order=-1)

    comp_max_order = 1
    if haskey(pm_data, "gen")
        for (i, gen) in pm_data["gen"]
            if haskey(gen, "model") && gen["model"] == 2
                max_nonzero_index = 1
                for i in 1:length(gen["cost"])
                    max_nonzero_index = i
                    if gen["cost"][i] != 0.0
                        break
                    end
                end
                max_oder = length(gen["cost"]) - max_nonzero_index + 1
                comp_max_order = max(comp_max_order, max_oder)
            end
        end
    end

    if haskey(pm_data, "dcline")
        for (i, dcline) in pm_data["dcline"]
            if haskey(dcline, "model") && dcline["model"] == 2
                max_nonzero_index = 1
                for i in 1:length(dcline["cost"])
                    max_nonzero_index = i
                    if dcline["cost"][i] != 0.0
                        break
                    end
                end
                max_oder = length(dcline["cost"]) - max_nonzero_index + 1
                comp_max_order = max(comp_max_order, max_oder)
            end
        end
    end

    if comp_max_order <= order+1
        comp_max_order = order+1
    else
        if order != -1 # if not the default
            Memento.warn(_LOGGER, "a standard cost order of $(order) was requested but the given data requires an order of at least $(comp_max_order-1)")
        end
    end

    if haskey(pm_data, "gen")
        _s_cost_terms!(pm_data["gen"], comp_max_order, "generator")
    end
    if haskey(pm_data, "dcline")
        _s_cost_terms!(pm_data["dcline"], comp_max_order, "dcline")
    end
end

"ensures all polynomial costs functions have at exactly comp_order terms"
function _s_cost_terms!(components::Dict{String,<:Any}, comp_order::Int, cost_comp_name::String)
    modified = Set{Int}()
    for (i, comp) in components
        if haskey(comp, "model") && comp["model"] == 2 && length(comp["cost"]) != comp_order
            std_cost = [0.0 for i in 1:comp_order]
            current_cost = reverse(comp["cost"])

            for i in 1:min(comp_order, length(current_cost))
                std_cost[i] = current_cost[i]
            end
            comp["cost"] = reverse(std_cost)
            comp["ncost"] = comp_order

            Memento.info(_LOGGER, "updated $(cost_comp_name) $(comp["index"]) cost function with order $(length(current_cost)) to a function of order $(comp_order): $(comp["cost"])")
            push!(modified, comp["index"])
        end
    end
    return modified
end

"""
propagates inactive active network buses status to attached components so that
the system status values are consistent.

returns true if any component was modified.
"""
function propagate_topo_status!(network::Network{N,L,T,U}) where {N,L,T,U}
    
    revised = false
    buses = Dict(bus["bus_i"] => bus for (i,bus) in network.bus)

    # compute what active components are incident to each bus
    incident_load = bus_load_lookup(network.load, network.bus)
    incident_active_load = Dict()
    for (i, load_list) in incident_load
        incident_active_load[i] = [load for load in load_list if load["status"] != 0]
    end

    incident_shunt = bus_shunt_lookup(network.shunt, network.bus)
    incident_active_shunt = Dict()
    for (i, shunt_list) in incident_shunt
        incident_active_shunt[i] = [shunt for shunt in shunt_list if shunt["status"] != 0]
    end

    incident_gen = bus_gen_lookup(network.gen, network.bus)
    incident_active_gen = Dict()
    for (i, gen_list) in incident_gen
        incident_active_gen[i] = [gen for gen in gen_list if gen["gen_status"] != 0]
    end

    incident_strg = bus_storage_lookup(network.storage, network.bus)
    incident_active_strg = Dict()
    for (i, strg_list) in incident_strg
        incident_active_strg[i] = [strg for strg in strg_list if strg["status"] != 0]
    end

    incident_branch = Dict(bus["bus_i"] => [] for (i,bus) in network.bus)
    for (i,branch) in network.branch
        push!(incident_branch[branch["f_bus"]], branch)
        push!(incident_branch[branch["t_bus"]], branch)
    end

    incident_dcline = Dict(bus["bus_i"] => [] for (i,bus) in network.bus)
    for (i,dcline) in network.dcline
        push!(incident_dcline[dcline["f_bus"]], dcline)
        push!(incident_dcline[dcline["t_bus"]], dcline)
    end

    incident_switch = Dict(bus["bus_i"] => [] for (i,bus) in network.bus)
    for (i,switch) in network.switch
        push!(incident_switch[switch["f_bus"]], switch)
        push!(incident_switch[switch["t_bus"]], switch)
    end

    revised = false

    for (i,branch) in network.branch
        if branch["br_status"] != 0
            #f_bus = buses[branch["f_bus"]]
            #t_bus = buses[branch["t_bus"]]

            if buses[branch["f_bus"]]["bus_type"] == 4 || buses[branch["t_bus"]]["bus_type"] == 4
                Memento.info(_LOGGER, "deactivating branch $(i):($(branch["f_bus"]),$(branch["t_bus"])) due to connecting bus status")
                branch["br_status"] = 0
                revised = true
            end
        end
    end

    for (i,dcline) in network.dcline
        if dcline["br_status"] != 0
            #f_bus = buses[dcline["f_bus"]]
            #t_bus = buses[dcline["t_bus"]]

            if buses[dcline["f_bus"]]["bus_type"] == 4 || buses[dcline["t_bus"]]["bus_type"] == 4
                Memento.info(_LOGGER, "deactivating dcline $(i):($(dcline["f_bus"]),$(dcline["t_bus"])) due to connecting bus status")
                dcline["br_status"] = 0
                revised = true
            end
        end
    end

    for (i,switch) in network.switch
        if switch["status"] != 0
            #f_bus = buses[switch["f_bus"]]
            #t_bus = buses[switch["t_bus"]]

            if buses[switch["f_bus"]]["bus_type"] == 4 || buses[switch["t_bus"]]["bus_type"] == 4
                Memento.info(_LOGGER, "deactivating switch $(i):($(switch["f_bus"]),$(switch["t_bus"])) due to connecting bus status")
                switch["status"] = 0
                revised = true
            end
        end
    end

    for (i,bus) in buses
        if bus["bus_type"] == 4
            for load in incident_active_load[i]
                if load["status"] != 0
                    Memento.info(_LOGGER, "deactivating load $(load["index"]) due to inactive bus $(i)")
                    load["status"] = 0
                    revised = true
                end
            end

            for shunt in incident_active_shunt[i]
                if shunt["status"] != 0
                    Memento.info(_LOGGER, "deactivating shunt $(shunt["index"]) due to inactive bus $(i)")
                    shunt["status"] = 0
                    revised = true
                end
            end

            for gen in incident_active_gen[i]
                if gen["gen_status"] != 0
                    Memento.info(_LOGGER, "deactivating generator $(gen["index"]) due to inactive bus $(i)")
                    gen["gen_status"] = 0
                    revised = true
                end
            end

            for strg in incident_active_strg[i]
                if strg["status"] != 0
                    Memento.info(_LOGGER, "deactivating storage $(strg["index"]) due to inactive bus $(i)")
                    strg["status"] = 0
                    revised = true
                end
            end
        end
    end

    return revised
end

function propagate_topo_status!(data::Dict{String,<:Any})
    
    revised = false
    #data = get_pm_data(data)
    buses = Dict(bus["bus_i"] => bus for (i,bus) in data["bus"])

    # compute what active components are incident to each bus
    incident_load = bus_load_lookup(data["load"], data["bus"])
    incident_active_load = Dict()
    for (i, load_list) in incident_load
        incident_active_load[i] = [load for load in load_list if load["status"] != 0]
    end

    incident_shunt = bus_shunt_lookup(data["shunt"], data["bus"])
    incident_active_shunt = Dict()
    for (i, shunt_list) in incident_shunt
        incident_active_shunt[i] = [shunt for shunt in shunt_list if shunt["status"] != 0]
    end

    incident_gen = bus_gen_lookup(data["gen"], data["bus"])
    incident_active_gen = Dict()
    for (i, gen_list) in incident_gen
        incident_active_gen[i] = [gen for gen in gen_list if gen["gen_status"] != 0]
    end

    incident_strg = bus_storage_lookup(data["storage"], data["bus"])
    incident_active_strg = Dict()
    for (i, strg_list) in incident_strg
        incident_active_strg[i] = [strg for strg in strg_list if strg["status"] != 0]
    end

    incident_branch = Dict(bus["bus_i"] => [] for (i,bus) in data["bus"])
    for (i,branch) in data["branch"]
        push!(incident_branch[branch["f_bus"]], branch)
        push!(incident_branch[branch["t_bus"]], branch)
    end

    incident_dcline = Dict(bus["bus_i"] => [] for (i,bus) in data["bus"])
    for (i,dcline) in data["dcline"]
        push!(incident_dcline[dcline["f_bus"]], dcline)
        push!(incident_dcline[dcline["t_bus"]], dcline)
    end

    incident_switch = Dict(bus["bus_i"] => [] for (i,bus) in data["bus"])
    for (i,switch) in data["switch"]
        push!(incident_switch[switch["f_bus"]], switch)
        push!(incident_switch[switch["t_bus"]], switch)
    end

    revised = false

    for (i,branch) in data["branch"]
        if branch["br_status"] != 0
            #f_bus = buses[branch["f_bus"]]
            #t_bus = buses[branch["t_bus"]]

            if buses[branch["f_bus"]]["bus_type"] == 4 || buses[branch["t_bus"]]["bus_type"] == 4
                Memento.info(_LOGGER, "deactivating branch $(i):($(branch["f_bus"]),$(branch["t_bus"])) due to connecting bus status")
                branch["br_status"] = 0
                revised = true
            end
        end
    end

    for (i,dcline) in data["dcline"]
        if dcline["br_status"] != 0
            #f_bus = buses[dcline["f_bus"]]
            #t_bus = buses[dcline["t_bus"]]

            if buses[dcline["f_bus"]]["bus_type"] == 4 || buses[dcline["t_bus"]]["bus_type"] == 4
                Memento.info(_LOGGER, "deactivating dcline $(i):($(dcline["f_bus"]),$(dcline["t_bus"])) due to connecting bus status")
                dcline["br_status"] = 0
                revised = true
            end
        end
    end

    for (i,switch) in data["switch"]
        if switch["status"] != 0
            #f_bus = buses[switch["f_bus"]]
            #t_bus = buses[switch["t_bus"]]

            if buses[switch["f_bus"]]["bus_type"] == 4 || buses[switch["t_bus"]]["bus_type"] == 4
                Memento.info(_LOGGER, "deactivating switch $(i):($(switch["f_bus"]),$(switch["t_bus"])) due to connecting bus status")
                switch["status"] = 0
                revised = true
            end
        end
    end

    for (i,bus) in buses
        if bus["bus_type"] == 4
            for load in incident_active_load[i]
                if load["status"] != 0
                    Memento.info(_LOGGER, "deactivating load $(load["index"]) due to inactive bus $(i)")
                    load["status"] = 0
                    revised = true
                end
            end

            for shunt in incident_active_shunt[i]
                if shunt["status"] != 0
                    Memento.info(_LOGGER, "deactivating shunt $(shunt["index"]) due to inactive bus $(i)")
                    shunt["status"] = 0
                    revised = true
                end
            end

            for gen in incident_active_gen[i]
                if gen["gen_status"] != 0
                    Memento.info(_LOGGER, "deactivating generator $(gen["index"]) due to inactive bus $(i)")
                    gen["gen_status"] = 0
                    revised = true
                end
            end

            for strg in incident_active_strg[i]
                if strg["status"] != 0
                    Memento.info(_LOGGER, "deactivating storage $(strg["index"]) due to inactive bus $(i)")
                    strg["status"] = 0
                    revised = true
                end
            end
        end
    end

    return revised
end

"""
removes buses with single branch connections and without any other attached
components.  Also removes connected components without suffuceint generation
or loads.

also deactivates 0 valued loads and shunts.
"""
function deactivate_isol_components!(network::Network{N,L,T,U}) where {N,L,T,U}

    buses = Dict(bus["bus_i"] => bus for (i,bus) in network.bus)
    revised = false

    for (i,load) in network.load
        if load["status"] != 0 && all(load["pd"] .== 0.0) && all(load["qd"] .== 0.0)
            Memento.info(_LOGGER, "deactivating load $(load["index"]) due to zero pd and qd")
            load["status"] = 0
            revised = true
        end
    end

    for (i,shunt) in network.shunt
        if shunt["status"] != 0 && all(shunt["gs"] .== 0.0) && all(shunt["bs"] .== 0.0)
            Memento.info(_LOGGER, "deactivating shunt $(shunt["index"]) due to zero gs and bs")
            shunt["status"] = 0
            revised = true
        end
    end

    # compute what active components are incident to each bus
    incident_load = bus_load_lookup(network.load, network.bus)
    incident_active_load = Dict()
    for (i, load_list) in incident_load
        incident_active_load[i] = [load for load in load_list if load["status"] != 0]
    end

    incident_shunt = bus_shunt_lookup(network.shunt, network.bus)
    incident_active_shunt = Dict()
    for (i, shunt_list) in incident_shunt
        incident_active_shunt[i] = [shunt for shunt in shunt_list if shunt["status"] != 0]
    end

    incident_gen = bus_gen_lookup(network.gen, network.bus)
    incident_active_gen = Dict()
    for (i, gen_list) in incident_gen
        incident_active_gen[i] = [gen for gen in gen_list if gen["gen_status"] != 0]
    end

    incident_strg = bus_storage_lookup(network.storage, network.bus)
    incident_active_strg = Dict()
    for (i, strg_list) in incident_strg
        incident_active_strg[i] = [strg for strg in strg_list if strg["status"] != 0]
    end

    incident_branch = Dict(bus["bus_i"] => [] for (i,bus) in network.bus)
    for (i,branch) in network.branch
        push!(incident_branch[branch["f_bus"]], branch)
        push!(incident_branch[branch["t_bus"]], branch)
    end

    incident_dcline = Dict(bus["bus_i"] => [] for (i,bus) in network.bus)
    for (i,dcline) in network.dcline
        push!(incident_dcline[dcline["f_bus"]], dcline)
        push!(incident_dcline[dcline["t_bus"]], dcline)
    end

    incident_switch = Dict(bus["bus_i"] => [] for (i,bus) in network.bus)
    for (i,switch) in network.switch
        push!(incident_switch[switch["f_bus"]], switch)
        push!(incident_switch[switch["t_bus"]], switch)
    end

    changed = true
    while changed
        changed = false
        for (i,bus) in buses
            if bus["bus_type"] != 4
                incident_active_edge = 0
                if length(incident_branch[i]) + length(incident_dcline[i]) + length(incident_switch[i]) > 0
                    incident_branch_count = sum([0; [branch["br_status"] for branch in incident_branch[i]]])
                    incident_dcline_count = sum([0; [dcline["br_status"] for dcline in incident_dcline[i]]])
                    incident_switch_count = sum([0; [switch["status"] for switch in incident_switch[i]]])
                    incident_active_edge = incident_branch_count + incident_dcline_count + incident_switch_count
                end

                if incident_active_edge == 1 && length(incident_active_gen[i]) == 0 && length(incident_active_load[i]) == 0 && 
                    length(incident_active_shunt[i]) == 0 && length(incident_active_strg[i]) == 0
                    Memento.info(_LOGGER, "deactivating bus $(i) due to dangling bus without generation, load or storage")
                    bus["bus_type"] = 4
                    revised = true
                    changed = true
                end
            end
        end

        if changed
            for (i,branch) in network.branch
                if branch["br_status"] != 0
                    #f_bus = buses[branch["f_bus"]]
                    #t_bus = buses[branch["t_bus"]]

                    if buses[branch["f_bus"]]["bus_type"] == 4 || buses[branch["t_bus"]]["bus_type"] == 4
                        Memento.info(_LOGGER, "deactivating branch $(i):($(branch["f_bus"]),$(branch["t_bus"])) due to connecting bus status")
                        branch["br_status"] = 0
                    end
                end
            end

            for (i,dcline) in network.dcline
                if dcline["br_status"] != 0
                    #f_bus = buses[dcline["f_bus"]]
                    #t_bus = buses[dcline["t_bus"]]

                    if buses[dcline["f_bus"]]["bus_type"] == 4 || buses[dcline["t_bus"]]["bus_type"] == 4
                        Memento.info(_LOGGER, "deactivating dcline $(i):($(dcline["f_bus"]),$(dcline["t_bus"])) due to connecting bus status")
                        dcline["br_status"] = 0
                    end
                end
            end

            for (i,switch) in network.switch
                if switch["status"] != 0
                    #f_bus = buses[switch["f_bus"]]
                    #t_bus = buses[switch["t_bus"]]

                    if buses[switch["f_bus"]]["bus_type"] == 4 || buses[switch["t_bus"]]["bus_type"] == 4
                        Memento.info(_LOGGER, "deactivating switch $(i):($(switch["f_bus"]),$(switch["t_bus"])) due to connecting bus status")
                        switch["status"] = 0
                    end
                end
            end
        end

    end

    ccs = calc_connected_components!(network)

    for cc in ccs
        cc_active_loads = [0]
        cc_active_shunts = [0]
        cc_active_gens = [0]
        cc_active_strg = [0]

        for i in cc
            cc_active_loads = push!(cc_active_loads, length(incident_active_load[i]))
            cc_active_shunts = push!(cc_active_shunts, length(incident_active_shunt[i]))
            cc_active_gens = push!(cc_active_gens, length(incident_active_gen[i]))
            cc_active_strg = push!(cc_active_strg, length(incident_active_strg[i]))
        end

        active_load_count = sum(cc_active_loads)
        active_shunt_count = sum(cc_active_shunts)
        active_gen_count = sum(cc_active_gens)
        active_strg_count = sum(cc_active_strg)

        if (active_load_count == 0 && active_shunt_count == 0 && active_strg_count == 0) || active_gen_count == 0
            Memento.info(_LOGGER, "deactivating connected component $(cc) due to isolation without generation, load or storage")
            for i in cc
                buses[i]["bus_type"] = 4
            end
            revised = true
        end
    end

    return revised
end

function deactivate_isol_components!(data::Dict{String,<:Any})

    buses = Dict(bus["bus_i"] => bus for (i,bus) in data["bus"])
    revised = false

    for (i,load) in data["load"]
        if load["status"] != 0 && all(load["pd"] .== 0.0) && all(load["qd"] .== 0.0)
            Memento.info(_LOGGER, "deactivating load $(load["index"]) due to zero pd and qd")
            load["status"] = 0
            revised = true
        end
    end

    for (i,shunt) in data["shunt"]
        if shunt["status"] != 0 && all(shunt["gs"] .== 0.0) && all(shunt["bs"] .== 0.0)
            Memento.info(_LOGGER, "deactivating shunt $(shunt["index"]) due to zero gs and bs")
            shunt["status"] = 0
            revised = true
        end
    end

    # compute what active components are incident to each bus
    incident_load = bus_load_lookup(data["load"], data["bus"])
    incident_active_load = Dict()
    for (i, load_list) in incident_load
        incident_active_load[i] = [load for load in load_list if load["status"] != 0]
    end

    incident_shunt = bus_shunt_lookup(data["shunt"], data["bus"])
    incident_active_shunt = Dict()
    for (i, shunt_list) in incident_shunt
        incident_active_shunt[i] = [shunt for shunt in shunt_list if shunt["status"] != 0]
    end

    incident_gen = bus_gen_lookup(data["gen"], data["bus"])
    incident_active_gen = Dict()
    for (i, gen_list) in incident_gen
        incident_active_gen[i] = [gen for gen in gen_list if gen["gen_status"] != 0]
    end

    incident_strg = bus_storage_lookup(data["storage"], data["bus"])
    incident_active_strg = Dict()
    for (i, strg_list) in incident_strg
        incident_active_strg[i] = [strg for strg in strg_list if strg["status"] != 0]
    end

    incident_branch = Dict(bus["bus_i"] => [] for (i,bus) in data["bus"])
    for (i,branch) in data["branch"]
        push!(incident_branch[branch["f_bus"]], branch)
        push!(incident_branch[branch["t_bus"]], branch)
    end

    incident_dcline = Dict(bus["bus_i"] => [] for (i,bus) in data["bus"])
    for (i,dcline) in data["dcline"]
        push!(incident_dcline[dcline["f_bus"]], dcline)
        push!(incident_dcline[dcline["t_bus"]], dcline)
    end

    incident_switch = Dict(bus["bus_i"] => [] for (i,bus) in data["bus"])
    for (i,switch) in data["switch"]
        push!(incident_switch[switch["f_bus"]], switch)
        push!(incident_switch[switch["t_bus"]], switch)
    end

    changed = true
    while changed
        changed = false
        for (i,bus) in buses
            if bus["bus_type"] != 4
                incident_active_edge = 0
                if length(incident_branch[i]) + length(incident_dcline[i]) + length(incident_switch[i]) > 0
                    incident_branch_count = sum([0; [branch["br_status"] for branch in incident_branch[i]]])
                    incident_dcline_count = sum([0; [dcline["br_status"] for dcline in incident_dcline[i]]])
                    incident_switch_count = sum([0; [switch["status"] for switch in incident_switch[i]]])
                    incident_active_edge = incident_branch_count + incident_dcline_count + incident_switch_count
                end

                if incident_active_edge == 1 && length(incident_active_gen[i]) == 0 && length(incident_active_load[i]) == 0 && 
                    length(incident_active_shunt[i]) == 0 && length(incident_active_strg[i]) == 0
                    Memento.info(_LOGGER, "deactivating bus $(i) due to dangling bus without generation, load or storage")
                    bus["bus_type"] = 4
                    revised = true
                    changed = true
                end
            end
        end

        if changed
            for (i,branch) in data["branch"]
                if branch["br_status"] != 0
                    #f_bus = buses[branch["f_bus"]]
                    #t_bus = buses[branch["t_bus"]]

                    if buses[branch["f_bus"]]["bus_type"] == 4 || buses[branch["t_bus"]]["bus_type"] == 4
                        Memento.info(_LOGGER, "deactivating branch $(i):($(branch["f_bus"]),$(branch["t_bus"])) due to connecting bus status")
                        branch["br_status"] = 0
                    end
                end
            end

            for (i,dcline) in data["dcline"]
                if dcline["br_status"] != 0
                    #f_bus = buses[dcline["f_bus"]]
                    #t_bus = buses[dcline["t_bus"]]

                    if buses[dcline["f_bus"]]["bus_type"] == 4 || buses[dcline["t_bus"]]["bus_type"] == 4
                        Memento.info(_LOGGER, "deactivating dcline $(i):($(dcline["f_bus"]),$(dcline["t_bus"])) due to connecting bus status")
                        dcline["br_status"] = 0
                    end
                end
            end

            for (i,switch) in data["switch"]
                if switch["status"] != 0
                    #f_bus = buses[switch["f_bus"]]
                    #t_bus = buses[switch["t_bus"]]

                    if buses[switch["f_bus"]]["bus_type"] == 4 || buses[switch["t_bus"]]["bus_type"] == 4
                        Memento.info(_LOGGER, "deactivating switch $(i):($(switch["f_bus"]),$(switch["t_bus"])) due to connecting bus status")
                        switch["status"] = 0
                    end
                end
            end
        end

    end

    ccs = calc_connected_components!(data)

    for cc in ccs
        cc_active_loads = [0]
        cc_active_shunts = [0]
        cc_active_gens = [0]
        cc_active_strg = [0]

        for i in cc
            cc_active_loads = push!(cc_active_loads, length(incident_active_load[i]))
            cc_active_shunts = push!(cc_active_shunts, length(incident_active_shunt[i]))
            cc_active_gens = push!(cc_active_gens, length(incident_active_gen[i]))
            cc_active_strg = push!(cc_active_strg, length(incident_active_strg[i]))
        end

        active_load_count = sum(cc_active_loads)
        active_shunt_count = sum(cc_active_shunts)
        active_gen_count = sum(cc_active_gens)
        active_strg_count = sum(cc_active_strg)

        if (active_load_count == 0 && active_shunt_count == 0 && active_strg_count == 0) || active_gen_count == 0
            Memento.info(_LOGGER, "deactivating connected component $(cc) due to isolation without generation, load or storage")
            for i in cc
                buses[i]["bus_type"] = 4
            end
            revised = true
        end
    end

    return revised
end

"builds a lookup list of what generators are connected to a given bus"
function bus_gen_lookup(gen_data::Dict{String,<:Any}, bus_data::Dict{String,<:Any})
    bus_gen = Dict(bus["bus_i"] => [] for (i,bus) in bus_data)
    for (i,gen) in gen_data
        push!(bus_gen[gen["gen_bus"]], gen)
    end
    return bus_gen
end

"builds a lookup list of what loads are connected to a given bus"
function bus_load_lookup(load_data::Dict{String,<:Any}, bus_data::Dict{String,<:Any})
    bus_load = Dict(bus["bus_i"] => [] for (i,bus) in bus_data)
    for (i,load) in load_data
        push!(bus_load[load["load_bus"]], load)
    end
    return bus_load
end

"builds a lookup list of what shunts are connected to a given bus"
function bus_shunt_lookup(shunt_data::Dict{String,<:Any}, bus_data::Dict{String,<:Any})
    bus_shunt = Dict(bus["bus_i"] => [] for (i,bus) in bus_data)
    for (i,shunt) in shunt_data
        push!(bus_shunt[shunt["shunt_bus"]], shunt)
    end
    return bus_shunt
end

"builds a lookup list of what storage is connected to a given bus"
function bus_storage_lookup(storage_data::Dict{String,<:Any}, bus_data::Dict{String,<:Any})
    bus_storage = Dict(bus["bus_i"] => [] for (i,bus) in bus_data)
    for (i,storage) in storage_data
        push!(bus_storage[storage["storage_bus"]], storage)
    end
    return bus_storage
end


"""
computes the connected components of the network graph
returns a set of sets of bus ids, each set is a connected component
"""
function calc_connected_components!(network::Network{N,L,T,U}; edges=["branch", "dcline", "switch"]) where {N,L,T,U}
    
    active_bus = Dict(x for x in network.bus if x.second["bus_type"] != 4)
    active_bus_ids = Set{Int}([bus["bus_i"] for (i,bus) in active_bus])

    neighbors = Dict(i => Int[] for i in active_bus_ids)
    for comp_type in edges
        status_key = get(component_status, comp_type, "status")
        status_inactive = get(component_status_inactive, comp_type, 0)
        for edge in values(getfield(network, Symbol(comp_type)))
            if get(edge, status_key, 1) != status_inactive && edge["f_bus"] in active_bus_ids && edge["t_bus"] in active_bus_ids
                push!(neighbors[edge["f_bus"]], edge["t_bus"])
                push!(neighbors[edge["t_bus"]], edge["f_bus"])
            end
        end
    end

    component_lookup = Dict(i => Set{Int}([i]) for i in active_bus_ids)
    touched = Set{Int}()

    for i in active_bus_ids
        if !(i in touched)
            cc_dfs!(i, neighbors, component_lookup, touched)
        end
    end
    ccs = (Set(values(component_lookup)))
    return ccs
end

function calc_connected_components!(data::Dict{String,<:Any}; edges=["branch", "dcline", "switch"])
    
    active_bus = Dict(x for x in data["bus"] if x.second["bus_type"] != 4)
    active_bus_ids = Set{Int}([bus["bus_i"] for (i,bus) in active_bus])

    neighbors = Dict(i => Int[] for i in active_bus_ids)
    for comp_type in edges
        status_key = get(component_status, comp_type, "status")
        status_inactive = get(component_status_inactive, comp_type, 0)
        for edge in values(get(data, comp_type, Dict()))
            if get(edge, status_key, 1) != status_inactive && edge["f_bus"] in active_bus_ids && edge["t_bus"] in active_bus_ids
                push!(neighbors[edge["f_bus"]], edge["t_bus"])
                push!(neighbors[edge["t_bus"]], edge["f_bus"])
            end
        end
    end

    component_lookup = Dict(i => Set{Int}([i]) for i in active_bus_ids)
    touched = Set{Int}()

    for i in active_bus_ids
        if !(i in touched)
            cc_dfs!(i, neighbors, component_lookup, touched)
        end
    end
    ccs = (Set(values(component_lookup)))
    return ccs
end

"""
DFS on a graph
"""
function cc_dfs!(i, neighbors, component_lookup, touched)
    push!(touched, i)
    for j in neighbors[i]
        if !(j in touched)
            for k in  component_lookup[j]
                push!(component_lookup[i], k)
            end
            for k in component_lookup[j]
                component_lookup[k] = component_lookup[i]
            end
            cc_dfs!(j, neighbors, component_lookup, touched)
        end
    end
end

""
function calc_branchs_y(branch::Dict{String,<:Any})

    g=(branch["br_r"] + im * branch["br_x"])
    #y = pinv(branch["br_r"] + im * branch["br_x"])
    g, b = real(pinv(branch["br_r"] + im * branch["br_x"])), imag(pinv(branch["br_r"] + im * branch["br_x"]))
    return g, b
end


""
function calc_branchs_t(branch::Dict{String,<:Any})
    #tap_ratio = branch["tap"]
    #angle_shift = branch["shift"]

    tr = branch["tap"] .* cos.(branch["shift"])
    ti = branch["tap"] .* sin.(branch["shift"])

    return tr, ti
end

""
function calc_thermal_limits!(network::Network{N,L,T,U}) where {N,L,T,U}
    
    mva_base = network.baseMVA
    branches = [branch for branch in values(network.branch)]

    for branch in branches
        if !haskey(branch, "rate_a")
            branch["rate_a"] = 0.0
        end

        if branch["rate_a"] <= 0.0
            theta_max = max(abs(branch["angmin"]), abs(branch["angmax"]))

            z = branch["br_r"] + im * branch["br_x"]
            y = pinv(z)

            fr_vmax = network.bus[string(branch["f_bus"])]["vmax"]
            to_vmax = network.bus[string(branch["t_bus"])]["vmax"]
            #m_vmax = max(fr_vmax, to_vmax)

            c_max = sqrt(fr_vmax^2 + to_vmax^2 - 2*fr_vmax*to_vmax*cos(theta_max))

            new_rate = abs.(y[1,1])*max(fr_vmax, to_vmax)*c_max

            if haskey(branch, "c_rating_a") && branch["c_rating_a"] > 0.0
                new_rate = min(new_rate, branch["c_rating_a"]*max(fr_vmax, to_vmax))
            end

            Memento.warn(_LOGGER, "this code only supports positive rate_a values, changing the value on branch $(branch["index"]) to $(round(mva_base*new_rate, digits=4))")
            branch["rate_a"] = new_rate
        end
    end
end

""
function calc_thermal_limits!(data::Dict{String,<:Any})
    
    mva_base = data["baseMVA"]
    branches = [branch for branch in values(data["branch"])]

    for branch in branches
        if !haskey(branch, "rate_a")
            branch["rate_a"] = 0.0
        end

        if branch["rate_a"] <= 0.0
            theta_max = max(abs(branch["angmin"]), abs(branch["angmax"]))

            z = branch["br_r"] + im * branch["br_x"]
            y = pinv(z)

            fr_vmax = data["bus"][string(branch["f_bus"])]["vmax"]
            to_vmax = data["bus"][string(branch["t_bus"])]["vmax"]
            #m_vmax = max(fr_vmax, to_vmax)

            c_max = sqrt(fr_vmax^2 + to_vmax^2 - 2*fr_vmax*to_vmax*cos(theta_max))

            new_rate = abs.(y[1,1])*max(fr_vmax, to_vmax)*c_max

            if haskey(branch, "c_rating_a") && branch["c_rating_a"] > 0.0
                new_rate = min(new_rate, branch["c_rating_a"]*max(fr_vmax, to_vmax))
            end

            Memento.warn(_LOGGER, "this code only supports positive rate_a values, changing the value on branch $(branch["index"]) to $(round(mva_base*new_rate, digits=4))")
            branch["rate_a"] = new_rate
        end
    end
end


""
function pinv(x::Number)
    xi = inv(x)
    return ifelse(isfinite(xi), xi, zero(xi))
end


# "set remaining unsupported components as inactive"
# function unsupported_components!(data::Dict{String,Any})

#     dcline_status_key = component_status.dcline
#     dcline_inactive_status = component_status_inactive.dcline
#     for (i,dcline) in data.dcline
#         dcline[dcline_status_key] = dcline_inactive_status
#     end    
# end


# "renumber bus ids"
# function renumber_buses!(data::Dict{String,Any})

#         bus_ordered = sort([bus for (i,bus) in network.bus], by=(x) -> x["index"])
#         bus_id_map = Dict{Int,Int}()

#         for (i,bus) in enumerate(bus_ordered)
#             bus_id_map[bus["index"]] = i
#         end
#         update_bus_ids!(data, bus_id_map)
# end

# """
# given a network data dict and a mapping of current-bus-ids to new-bus-ids
# modifies the data dict to reflect the proposed new bus ids.
# """
# function update_bus_ids!(data::Dict{String,<:Any}, bus_id_map::Dict{Int,Int}; injective=true)
    
#     # verify bus id map is injective
#     if injective
#         new_bus_ids = Set{Int}()
#         for (i,bus) in data.bus
#             new_id = get(bus_id_map, bus["index"], bus["index"])
#             if !(new_id in new_bus_ids)
#                 push!(new_bus_ids, new_id)
#             else
#                 Memento.error(_LOGGER, "bus id mapping given to update_bus_ids has an id clash on new bus id $(new_id)")
#             end
#         end
#     end


#     # start renumbering process
#     renumbered_bus_dict = Dict{String,Any}()

#     for (i,bus) in data.bus
#         new_id = get(bus_id_map, bus["index"], bus["index"])
#         bus["index"] = new_id
#         bus["bus_i"] = new_id
#         renumbered_bus_dict["$new_id"] = bus
#     end

#     data.bus = renumbered_bus_dict


#     # update bus numbering in dependent components
#     for (i, load) in data.load
#         load["load_bus"] = get(bus_id_map, load["load_bus"], load["load_bus"])
#     end

#     for (i, shunt) in data.shunt
#         shunt["shunt_bus"] = get(bus_id_map, shunt["shunt_bus"], shunt["shunt_bus"])
#     end

#     for (i, gen) in data.gen
#         gen["gen_bus"] = get(bus_id_map, gen["gen_bus"], gen["gen_bus"])
#     end

#     for (i, strg) in data.storage
#         strg["storage_bus"] = get(bus_id_map, strg["storage_bus"], strg["storage_bus"])
#     end


#     for (i, switch) in data.switch
#         switch["f_bus"] = get(bus_id_map, switch["f_bus"], switch["f_bus"])
#         switch["t_bus"] = get(bus_id_map, switch["t_bus"], switch["t_bus"])
#     end

#     branches = []
#     if haskey(data, "branch")
#         append!(branches, values(data.branch))
#     end

#     if haskey(data, "ne_branch")
#         append!(branches, values(data["ne_branch"]))
#     end

#     for branch in branches
#         branch["f_bus"] = get(bus_id_map, branch["f_bus"], branch["f_bus"])
#         branch["t_bus"] = get(bus_id_map, branch["t_bus"], branch["t_bus"])
#     end

#     for (i, dcline) in data.dcline
#         dcline["f_bus"] = get(bus_id_map, dcline["f_bus"], dcline["f_bus"])
#         dcline["t_bus"] = get(bus_id_map, dcline["t_bus"], dcline["t_bus"])
#     end
# end

"get the reference bus in a network dataset"
function reference_bus(data::Dict{String,<:Any})
    time_start = time()
    ref_bus = [bus for (i,bus) in data["bus"] if bus["bus_type"] == 3]
    if length(ref_bus) != 1
        Memento.error(_LOGGER, "exactly one refrence bus in data is required when calling reference_bus, given $(length(ref_bus))")
    end
    ref_bus = ref_bus[1]
    return ref_bus
end