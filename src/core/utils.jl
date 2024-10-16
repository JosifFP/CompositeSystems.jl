"maps component types to status parameters"
const pm_component_status = Dict{String, String}(
    "bus" => "bus_type",
    "load" => "status",
    "shunt" => "status",
    "gen" => "gen_status",
    "storage" => "status",
    "switch" => "status",
    "branch" => "br_status",
    "dcline" => "br_status",
)

"maps component types to inactive status values"
const pm_component_status_inactive = Dict{String, Int}(
    "bus" => 4,
    "load" => 0,
    "shunt" => 0,
    "gen" => 0,
    "storage" => 0,
    "switch" => 0,
    "branch" => 0,
    "dcline" => 0,
)


"""
    build_network(rawfile::String; replace::Bool=false, export_file::Bool=false, 
                  export_filetype::String="", symbol::Bool=true)

Builds and processes a power network based on the provided raw file.

- `rawfile`: A file path to the raw network data.
- `replace`: If `true`, the original file will be replaced with the processed data.
- `export_file`: If `true`, exports the processed data to a new file.
- `export_filetype`: Specifies the file type for exporting; defaults to the type of the raw file.
- `symbol`: If `true`, returns the network data with Symbol keys; otherwise, uses String keys.

Returns the processed network data as a dictionary.

## Notes
The function internally uses `DataSanityCheck` to validate and possibly modify the network data. 
Users are warned about the potential changes made during the sanity check process. 
"""

function build_network(rawfile::String; replace::Bool=false, export_file::Bool=false, export_filetype::String="", symbol::Bool=true)

    Memento.warn(_LOGGER, """
        DataSanityCheck process changes/updates the network topology and input data
        (for more details, please read InfrastructureModels and PowerModels printed messages). 
        To create/export a new file, set export_file=true and specify export_filetype if needed. 
        To replace the file, set replace=true.""")

    network = open(rawfile) do io
        _, ext = splitext(rawfile)
        pm_data = parse_model(io, lowercase(ext[2:end]))
        data = DataSanityCheck(pm_data)

        if export_file || replace
            
            target_file = replace ? rawfile : rawfile[1:findlast(==('.'), rawfile)-1]*"_CompositeSystems_"*format(
                now(),"HHMMSS")*"."*(isempty(export_filetype) ? ext[2:end] : export_filetype)
            
            @info("File: $(target_file) has been created/updated.")
            _PM.export_file(target_file, data)
        end

        symbol ? Dict{Symbol, Any}(convert_keys(data)) : Dict{String, Any}(data)
    end

    return network

end

"Parses a Matpower .m `file` or PTI (PSS(R)E-v33) .raw `file` into a
PowerModels data structure. All fields from PTI files will be imported if
`import_all` is true (Default: false)."
function parse_model(io::IO, filetype::String)
    
    if filetype == "m"
        pm_data = _PM.parse_matpower(io, validate=true)
    elseif filetype == "raw"
        pm_data = _PM.parse_psse(io; import_all=false, validate=true)
    else
        error("Unrecognized filetype: \".$filetype\", Supported extensions are \".raw\" and \".m\"")
    end
    return pm_data
end


"""
given a powermodels data dict produces a new data dict that conforms to the
following basic network model requirements.
- no dclines
- no switches
- no inactive components
- all components are numbered from 1-to-n
- the network forms a single connected component
- there exactly one phase angle reference bus
- generation cost functions are polynomial
- all branches have explicit thermal limits
- Network in per-unit.
"""
function DataSanityCheck(pm_data::Dict{String, <:Any})

    if _IM.ismultiinfrastructure(pm_data)
        @error("build_network function does not support multiinfrastructure data")
    end

    if _IM.ismultinetwork(pm_data)
        @error("build_network function does not support multinetwork data")
    end

    # make a copy of data so that modifications do not change the input data
    data = deepcopy(pm_data)

    _PM.make_per_unit!(data)

    # ensure that branch components always have a rate_a value
    _PM.calc_thermal_limits!(data)

    #checks that each branch has non-negative thermal ratings and removes zero thermal ratings.
    _PM.correct_thermal_limits!(data)

    #checks that all buses are unique and other components link to valid buses.
    _PM.check_connectivity(data)

    #checks that each branch has a reasonable transformer parameters.
    _PM.correct_transformer_parameters!(data)

    # TODO transform PWL costs into linear costs
    for (i,gen) in data["gen"]
        if get(gen, "cost_model", 2) ≠ 2
            @error("make_basic_network only supports network data with polynomial cost functions, generator $(i) has a piecewise linear cost function")
        end
    end

    "throws warnings if cost functions are malformed"
    _PM.correct_cost_functions!(data)

    _PM.standardize_cost_terms!(data, order=1)

    _PM.simplify_cost_terms!(data)

    _PM.simplify_network!(data)

    # ensure single connected component.
    #_PM.select_largest_component!(data)

    # ensure there is exactly one reference bus
    ref_buses = Set{Int}()
    for (i,bus) in data["bus"]
        if bus["bus_type"] == 3
            push!(ref_buses, bus["index"])
        end
    end
    if length(ref_buses) > 1
        @warn("network data specifies $(length(ref_buses)) reference buses")
        for ref_bus_id in ref_buses
            data["bus"]["$(ref_bus_id)"]["bus_type"] = 2
        end
        ref_buses = Set{Int}()
    end
    if length(ref_buses) == 0
        gen = _biggest_generator(data["gen"])
        @assert length(gen) > 0
        gen_bus = gen["gen_bus"]
        ref_bus = data["bus"]["$(gen_bus)"]
        ref_bus["bus_type"] = 3
        @warn("setting bus $(gen_bus) as reference based on generator $(gen["index"])")
    end

    # remove switches by merging buses
    _PM.resolve_swithces!(data)

    # switch resolution can result in new parallel branches
    _PM.correct_branch_directions!(data)

    # set remaining unsupported components as inactive
    dcline_status_key = pm_component_status["dcline"]
    dcline_inactive_status = pm_component_status_inactive["dcline"]
    for (i,dcline) in data["dcline"]
        dcline[dcline_status_key] = dcline_inactive_status
    end

    # remove inactive components
    for (comp_key, status_key) in pm_component_status
        comp_count = length(data[comp_key])
        status_inactive = pm_component_status_inactive[comp_key]
        data[comp_key] = _filter_inactive_components(data[comp_key], status_key=status_key, status_inactive_value=status_inactive)
        if length(data[comp_key]) < comp_count
        @info("removed $(comp_count - length(data[comp_key])) inactive $(comp_key) components")
        end
    end

    # re-number non-bus component ids
    for comp_key in keys(pm_component_status)
        if comp_key ≠ "bus"
            data[comp_key] = _renumber_components(data[comp_key])
        end
    end

    # renumber bus ids
    bus_ordered = sort([bus for (i,bus) in data["bus"]], by=(x) -> x["index"])

    bus_id_map = Dict{Int,Int}()
    for (i,bus) in enumerate(bus_ordered)
        bus_id_map[bus["index"]] = i
    end

    _PM.update_bus_ids!(data, bus_id_map)

    #add load power factors
    for (i,load) in data["load"]
        if load["pd"] > 0.0 || load["qd"] ≠ 0.0
            get!(load, "pf", load["qd"]/load["pd"])
        end
    end

    data["interface"] = Dict{Int, Any}()
    get!(data, "Sanity_check", true)

    return data

end

"find the largest active generator in a collection of generators"
function _biggest_generator(gens::Dict)::Dict
    if length(gens) == 0
        @error("generator list passed to _biggest_generator was empty.  please report this bug.")
    end

    biggest_gen = Dict{String,Any}()
    biggest_value = -Inf

    for (k,gen) in gens
        if gen["gen_status"] ≠ 0
            pmax = maximum(gen["pmax"])
            if pmax > biggest_value
                biggest_gen = gen
                biggest_value = pmax
            end
        end
    end

    return biggest_gen
end


"""
given a component dict returns a new dict where inactive components have been
removed.
"""
function _filter_inactive_components(comp_dict::Dict{String,<:Any}; status_key="status", status_inactive_value=0)
    filtered_dict = Dict{String,Any}()

    for (i,comp) in comp_dict
        if comp[status_key] ≠ status_inactive_value
            filtered_dict[i] = comp
        end
    end

    return filtered_dict
end


"""
given a component dict returns a new dict where components have been renumbered
from 1-to-n ordered by the increasing values of the orginal component id.
"""
function _renumber_components(comp_dict::Dict{String,<:Any})
    renumbered_dict = Dict{String,Any}()

    comp_ordered = sort([comp for (i,comp) in comp_dict], by=(x) -> x["index"])

    for (i,comp) in enumerate(comp_ordered)
        comp = deepcopy(comp)
        comp["index"] = i
        renumbered_dict["$i"] = comp
    end

    return renumbered_dict
end

"Converts keys from string type to symbol type"
function convert_keys(data::Dict{String, <:Any}; type::String="Symbol")
    # Initialize the refs dictionary.

    if type=="Int"
        refs = Dict{Int, Any}()
        for (key,item) in data
            if isa(item, Dict{String, Any})
                refs[Int(key)] = Dict{Int, Any}([(parse(Int, k), v) for (k, v) in item])
            else
                refs[Int(key)] = item
            end        
        end
    else
        refs = Dict{Symbol, Any}()
        for (key,item) in data
            if isa(item, Dict{String, Any})
                refs[Symbol(key)] = Dict{Int, Any}([(parse(Int, k), v) for (k, v) in item])
            else
                refs[Symbol(key)] = item
            end        
        end
    end
    # Return the final refs object.
    return refs
end

""
function assetgrouplist(idxss::Vector{UnitRange{Int}})
    
    if isempty(idxss)
        results = Int[]
    else
        results = Vector{Int}(undef, last(idxss[end]))
        for (g, idxs) in enumerate(idxss)
            results[idxs] .= g
        end
    end
    return results

end

"The makeidxlist function takes in a collection of indices and the number of collections. 
It outputs a list of index ranges. The function essentially groups consecutive indices in the 
collectionidxs vector into ranges and assigns them to collections in the idxlist."
function makeidxlist(collectionidxs::Vector{Int}, n_collections::Int)::Vector{UnitRange{Int}}

    if isempty(collectionidxs)
        idxlist = fill(1:0, n_collections)
    else
        n_assets = length(collectionidxs)
        idxlist = Vector{UnitRange{Int}}(undef, n_collections)
        active_collection = 1
        start_idx = 1
        a = 1

        while a <= n_assets
        if collectionidxs[a] > active_collection
                idxlist[active_collection] = start_idx:(a-1)       
                active_collection += 1
                start_idx = a
        else
            a += 1
        end
        end

        idxlist[active_collection] = start_idx:n_assets       
        active_collection += 1

        while active_collection <= n_collections
            idxlist[active_collection] = (n_assets+1):n_assets
            active_collection += 1
        end
    end

    return idxlist

end

"Extract a field from a composite value by name or position."
field(system::SystemModel, field::Symbol) = getfield(system, field)
field(system::SystemModel, field::Symbol, subfield::Symbol) = getfield(getfield(system, field), subfield)
field(abstractassets::AbstractAssets, subfield::Symbol) = getfield(abstractassets, subfield)
field(abstractassets::TimeSeriesAssets, subfield::Symbol) = getfield(abstractassets, subfield)