"Extracts data from excel file"
function extract(ReliabilityDataDir::String, files::Vector{String}, asset::Type{<:AbstractAssets}, container_1::Vector{Vector}, container_2::Vector{Vector{Any}})

    if in(files).("$asset"*".xlsx") == true
        XLSX.openxlsx(ReliabilityDataDir*"/"*"$asset"*".xlsx", enable_cache=false) do io
            for i in 1:XLSX.sheetcount(io)
                if XLSX.sheetnames(io)[i] == "time series MW" 
                    dtable =  XLSX.readtable("$asset"*".xlsx", XLSX.sheetnames(io)[i])
                    container_1[2], container_1[1] = dtable.data, dtable.column_labels
                elseif XLSX.sheetnames(io)[i] == "core"
                    dtable =  XLSX.readtable("$asset"*".xlsx",XLSX.sheetnames(io)[i])
                    container_2[2], container_2[1] = dtable.data, dtable.column_labels
                end
            end
        end
    else
        if asset == Loads || asset == Generators
            error("file $asset.xlsx not found in $ReliabilityDataDir/ directory")
        end
    end

    return Dict(parse(Int, String(container_1[1][i])) => Float16.(container_1[2][i]) for i in 2:length(container_1[1])), 
    Dict(container_2[1][i] => container_2[2][i] for i in 1:length(container_2[1]))

end

"Creates AbstractAsset - Buses"
function container(network::Dict{Symbol, <:Any}, asset::Type{Buses}, N::Int, L::Int, T::Type{<:Period}, U::Type{<:PerUnit})

    tmp = [[i, 
        Int(comp["zone"]),
        Int(comp["bus_type"]),
        Int(comp["area"]),
        Int(comp["index"]),
        Float16(comp["vmax"]),
        Float16(comp["vmin"]),
        Float16(comp["base_kv"]),
        Float32(comp["va"]),
        Float32(comp["vm"])] for (i,comp) in sort(network[:bus])]

    tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:bus])]]

    container_data = Dict{Symbol, Any}(
        :keys => Int.(reduce(vcat, tmp')[:,1]),
        :zone => Int.(reduce(vcat, tmp')[:,2]),
        :bus_type => Int.(reduce(vcat, tmp')[:,3]),
        :area => Int.(reduce(vcat, tmp')[:,4]),
        :index => Int.(reduce(vcat, tmp')[:,5]),
        :source_id => String.(reduce(vcat, tmp_string)),
        :vmax => Float16.(reduce(vcat, tmp')[:,6]),
        :vmin => Float16.(reduce(vcat, tmp')[:,7]),
        :base_kv => Float16.(reduce(vcat, tmp')[:,8]),
        :va => Float32.(reduce(vcat, tmp')[:,9]),
        :vm => Float32.(reduce(vcat, tmp')[:,10])
    )

    key_order_core = sortperm(container_data[:keys])

    return asset{N,L,T,U}(
        container_data[:keys][key_order_core],
        container_data[:zone][key_order_core],
        container_data[:bus_type][key_order_core],
        container_data[:area][key_order_core],
        container_data[:index][key_order_core],
        container_data[:source_id][key_order_core],
        container_data[:vmax][key_order_core],
        container_data[:vmin][key_order_core],
        container_data[:base_kv][key_order_core],
        container_data[:va][key_order_core],
        container_data[:vm][key_order_core])

end

"Creates AbstractAsset - Generators"
function container(container_key::Vector{<:Any}, key_order_series::Vector{<:Any}, dict_core::Dict{<:Any}, 
    dict_timeseries::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Generators}, N::Int, L::Int, T::Type{<:Period}, U::Type{<:PerUnit})

    tmp = [[i, 
        Int(comp["gen_bus"]),
        Float16(comp["pg"]),
        Float16(comp["qg"]),
        Float32(comp["vg"]),
        Float16(comp["pmax"]),
        Float16(comp["pmin"]),
        Float16(comp["qmax"]),
        Float16(comp["qmin"]),
        Int(comp["mbase"]),
        Bool(comp["gen_status"]),
        Float16.(comp["cost"])] for (i,comp) in sort(network[:gen])]

    tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:gen])]]

    container_data = Dict{Symbol, Any}(
        :keys => Int.(reduce(vcat, tmp')[:,1]),
        :buses => Int.(reduce(vcat, tmp')[:,2]),
        :pg => Float16.(reduce(vcat, tmp')[:,3]),
        :qg => Float16.(reduce(vcat, tmp')[:,4]),
        :vg => Float32.(reduce(vcat, tmp')[:,5]),
        :pmax => Float16.(reduce(vcat, tmp')[:,6]),
        :pmin => Float16.(reduce(vcat, tmp')[:,7]),
        :qmax => Float16.(reduce(vcat, tmp')[:,8]),
        :qmin => Float16.(reduce(vcat, tmp')[:,9]),
        :source_id => String.(reduce(vcat, tmp_string)),
        :mbase => Int.(reduce(vcat, tmp')[:,10]),
        :status => Bool.(reduce(vcat, tmp')[:,11]),
        :cost => (reduce(vcat, tmp')[:,12])
    )

    key_order_core = sortperm(container_data[:keys])

    if length(container_key) ≠ length(container_data[:keys])
        for i in container_data[:keys]
            if in(container_key).(i) == false
                setindex!(dict_timeseries, [container_data[:pg][i] for k in 1:N]*network[:baseMVA], i)
            end
        end
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        @assert length(container_key) == length(container_data[:keys])
    end

    container_timeseries = [Float16.(dict_timeseries[i]/network[:baseMVA]) for i in keys(dict_timeseries)]

    container_λ = Float64.(values(dict_core[Symbol("failurerate[f/year]")]))
    container_μ = Vector{Float64}(undef, length(values(dict_core[Symbol("repairtime[hrs]")])))

    for i in 1:length(values(dict_core[Symbol("repairtime[hrs]")]))
        if values(dict_core[Symbol("repairtime[hrs]")])[i]≠0.0
            container_μ[i] = Float64.(N/values(dict_core[Symbol("repairtime[hrs]")])[i])
        else
            container_μ[i] = 0.0
        end
    end

    return asset{N,L,T,U}(
        container_data[:keys][key_order_core],
        container_data[:buses][key_order_core],
        reduce(vcat,transpose.(container_timeseries[key_order_series])),
        container_data[:qg][key_order_core],
        container_data[:vg][key_order_core],
        container_data[:pmax][key_order_core],
        container_data[:pmin][key_order_core],
        container_data[:qmax][key_order_core],
        container_data[:qmin][key_order_core],
        container_data[:source_id][key_order_core],
        container_data[:mbase][key_order_core],
        container_data[:status][key_order_core],
        container_data[:cost][key_order_core],
        container_λ[key_order_core], 
        container_μ[key_order_core])
end

"Creates AbstractAsset - Loads"
function container(container_key::Vector{<:Any}, key_order_series::Vector{<:Any}, dict_core::Dict{<:Any}, 
    dict_timeseries::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Loads}, N::Int, L::Int, T::Type{<:Period}, U::Type{<:PerUnit})

    tmp_cost = Dict(Int(dict_core[:key][i]) => Float16(dict_core[Symbol("customerloss[USD/MWh]")][i]) for i in eachindex(dict_core[:key]))
    for (i,load) in network[:load]
        get!(load, "cost", tmp_cost[i])
    end

    tmp = [[i, 
        Int(comp["load_bus"]),
        Float16(comp["pd"]),
        Float16(comp["qd"]),
        Bool(comp["status"]),
        Float16(comp["cost"])] for (i,comp) in sort(network[:load])]

    tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:load])]]

    container_data = Dict{Symbol, Any}(
        :keys => Int.(reduce(vcat, tmp')[:,1]),
        :buses => Int.(reduce(vcat, tmp')[:,2]),
        :pd => Float16.(reduce(vcat, tmp')[:,3]),
        :qd => Float16.(reduce(vcat, tmp')[:,4]),
        :source_id => String.(reduce(vcat, tmp_string)),
        :status => Bool.(reduce(vcat, tmp')[:,5]),
        :cost => Float16.(reduce(vcat, tmp')[:,6])
    )

    key_order_core = sortperm(container_data[:keys])
    if isempty(dict_timeseries) error("Load data must be provided") end
    #dict_timeseries_qd = Dict{Int, Any}()
    #powerfactor = Float32.(container_data[:pd]/container_data[:qd])

    if length(container_key) ≠ length(container_data[:keys])
        for i in container_data[:keys]
            if in(container_key).(i) == false
                setindex!(dict_timeseries, [container_data[:pd][i] for k in 1:N]*network[:baseMVA], i)
            end
            #get!(dict_timeseries_qd, i, Float16.(dict_timeseries_pd[i]*powerfactor))
        end
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        @assert length(container_key) == length(container_data[:keys])
    end

    container_timeseries = [Float16.(dict_timeseries[i]/network[:baseMVA]) for i in keys(dict_timeseries)]
    nloads = length(container_data[:keys])

    return asset{N,L,T,U}(
        container_data[:keys][key_order_core],
        container_data[:buses][key_order_core],    
        reduce(vcat,transpose.(container_timeseries[key_order_series])),
        container_data[:qd][key_order_core],
        zeros(Float16, nloads),
        zeros(Float16, nloads),
        container_data[:source_id][key_order_core],
        container_data[:status][key_order_core],
        container_data[:cost][key_order_core])

end

"Creates AbstractAsset - Branches"
function container(dict_core::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Branches}, N::Int, L::Int, T::Type{<:Period}, U::Type{<:PerUnit})

    tmp = [[i, 
        Int(comp["f_bus"]),
        Int(comp["t_bus"]),
        Float16(comp["rate_a"]),
        Float16(comp["rate_b"]),
        Float16(comp["rate_c"]),
        Float16(comp["br_r"]),
        Float16(comp["br_x"]),
        Float16(comp["b_fr"]),
        Float16(comp["b_to"]),
        Float16(comp["g_fr"]),
        Float16(comp["g_to"]),
        Float16(comp["shift"]),
        Float16(comp["angmin"]),
        Float16(comp["angmax"]),
        Bool(comp["transformer"]),
        Float16(comp["tap"]),
        Bool(comp["br_status"])] for (i,comp) in sort(network[:branch])]

    tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:branch])]]

    container_data = Dict{Symbol, Any}(
        :keys => Int.(reduce(vcat, tmp')[:,1]),
        :f_bus => Int.(reduce(vcat, tmp')[:,2]),
        :t_bus => Int.(reduce(vcat, tmp')[:,3]),
        :rate_a => Float16.(reduce(vcat, tmp')[:,4]),
        :rate_b => Float16.(reduce(vcat, tmp')[:,5]),
        :rate_c => Float16.(reduce(vcat, tmp')[:,6]),
        :r => Float16.(reduce(vcat, tmp')[:,7]),
        :x => Float16.(reduce(vcat, tmp')[:,8]),
        :b_fr => Float16.(reduce(vcat, tmp')[:,9]),
        :b_to => Float16.(reduce(vcat, tmp')[:,10]),
        :g_fr => Float16.(reduce(vcat, tmp')[:,11]),
        :g_to => Float16.(reduce(vcat, tmp')[:,12]),
        :shift => Float16.(reduce(vcat, tmp')[:,13]),
        :angmin => Float16.(reduce(vcat, tmp')[:,14]),
        :angmax => Float16.(reduce(vcat, tmp')[:,15]),
        :transformer => Bool.(reduce(vcat, tmp')[:,16]),
        :tap => Float16.(reduce(vcat, tmp')[:,17]),
        :source_id => String.(reduce(vcat, tmp_string)),
        :status => Bool.(reduce(vcat, tmp')[:,18])
    )

    key_order_core = sortperm(container_data[:keys])

    container_λ = Float64.(values(dict_core[Symbol("failurerate[f/year]")]))
    container_μ = Vector{Float64}(undef, length(values(dict_core[Symbol("repairtime[hrs]")])))

    for i in 1:length(values(dict_core[Symbol("repairtime[hrs]")]))
        if values(dict_core[Symbol("repairtime[hrs]")])[i]≠0.0
            container_μ[i] = Float64.(N/values(dict_core[Symbol("repairtime[hrs]")])[i])
        else
            container_μ[i] = 0.0
        end
    end

    return asset{N,L,T,U}(
        container_data[:keys][key_order_core],
        container_data[:f_bus][key_order_core],
        container_data[:t_bus][key_order_core],
        container_data[:rate_a][key_order_core],
        container_data[:rate_b][key_order_core],
        container_data[:rate_c][key_order_core],
        container_data[:r][key_order_core],
        container_data[:x][key_order_core],
        container_data[:b_fr][key_order_core],
        container_data[:b_to][key_order_core],
        container_data[:g_fr][key_order_core],
        container_data[:g_to][key_order_core],
        container_data[:shift][key_order_core],
        container_data[:angmin][key_order_core],
        container_data[:angmax][key_order_core],
        container_data[:transformer][key_order_core],
        container_data[:tap][key_order_core],
        container_data[:source_id][key_order_core],
        container_data[:status][key_order_core],
        container_λ[key_order_core], 
        container_μ[key_order_core])
end

"Creates AbstractAsset - Shunts"
function container(network::Dict{Symbol, <:Any}, asset::Type{Shunts}, N::Int, L::Int, T::Type{<:Period}, U::Type{<:PerUnit})

    tmp = [
        [i, 
        Int(comp["shunt_bus"]),
        Float16(comp["bs"]),
        Float16(comp["gs"]),
        Bool(comp["status"])] for (i,comp) in sort(network[:shunt])]

    tmp_string = [[join(comp["source_id"]) for (i,comp) in sort(network[:shunt])]]

    container_data = Dict{Symbol, Any}(
        :keys => Int.(reduce(vcat, tmp')[:,1]),
        :buses => Int.(reduce(vcat, tmp')[:,2]),
        :bs => Float16.(reduce(vcat, tmp')[:,3]),
        :gs => Float16.(reduce(vcat, tmp')[:,4]),
        :source_id => String.(reduce(vcat, tmp_string)),
        :status => Bool.(reduce(vcat, tmp')[:,5])
    )

    key_order_core = sortperm(container_data[:keys])

    return asset{N,L,T,U}(
        container_data[:keys][key_order_core],
        container_data[:buses][key_order_core],
        container_data[:bs][key_order_core],
        container_data[:gs][key_order_core],
        container_data[:source_id][key_order_core],
        container_data[:status][key_order_core])

end

"Creates AbstractAsset - Topology"
function container(ref::Dict{Symbol,<:Any}, asset::Type{Topology}, buses::Buses, loads::Loads, branches::Branches, shunts::Shunts, generators::Generators, storages::Storages, N, U)

    arcs_from = [(i, branches.f_bus[i], branches.t_bus[i]) for i in branches.keys]
    arcs_to = [(i, branches.t_bus[i], branches.f_bus[i]) for i in branches.keys]
    arcs = [arcs_from; arcs_to]

    (bus_arcs, bus_loads, bus_shunts, bus_gens, bus_storage) = bus_components(arcs, buses, loads, shunts, generators, storages)

    ref_buses = Int[]
    for i in buses.keys
        if buses.bus_type[i] == 3
            push!(ref_buses, i)
        end
    end

    if length(ref_buses) > 1
        Memento.error(_LOGGER, "multiple reference buses found, $(keys(ref_buses)), this can cause infeasibility if they are in the same connected component")
    end

    buspairs = calculate_buspair_parameters(buses, branches)

    baseMVA = Int.(ref[:baseMVA])
    per_unit = ref[:per_unit]

    return asset{N,U}(baseMVA, per_unit, arcs_from, arcs_to, arcs, bus_gens, bus_loads, bus_shunts, bus_storage, bus_arcs, buspairs, ref_buses)

end

function bus_components(arcs::Vector{Tuple{Int, Int, Int}}, buses::Buses, loads::Loads, shunts::Shunts, generators::Generators, storages::Storages)

    tmp = Dict((i, Tuple{Int,Int,Int}[]) for i in buses.keys)
    for (l,i,j) in arcs
        push!(tmp[i], (l,i,j))
    end
    bus_arcs = tmp

    tmp = Dict((i, Int[]) for i in buses.keys)
    for k in loads.keys
        if loads.status[k] ≠ 0 push!(tmp[loads.buses[k]], k) end
    end
    bus_loads = tmp

    tmp = Dict((i, Int[]) for i in buses.keys)
    for k in shunts.keys
        if shunts.status[k] ≠ 0 push!(tmp[shunts.buses[k]], k) end
    end
    bus_shunts = tmp

    tmp = Dict((i, Int[]) for i in buses.keys)
    for k in generators.keys
        if generators.status[k] ≠ 0 push!(tmp[generators.buses[k]], k) end
    end
    bus_gens = tmp

    tmp = Dict((i, Int[]) for i in buses.keys)
    for k in storages.keys
        if storages.status[k] ≠ 0 push!(tmp[storages.buses[k]], k) end
    end
    bus_storage = tmp

    return (bus_arcs, bus_loads, bus_shunts, bus_gens, bus_storage)

end

"compute bus pair level data, can be run on data or ref data structures"
function calculate_buspair_parameters(buses::Buses, branches::Branches)

    bus_lookup = [i for i in buses.keys if buses.bus_type[i] ≠ 4]
    branch_lookup = [i for i in branches.keys if branches.status[i] == 1 && branches.f_bus[i] in bus_lookup && branches.t_bus[i] in bus_lookup]
    
    
    buspair_indexes = Set((branches.f_bus[i], branches.t_bus[i]) for i in branch_lookup)
    bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf) for bp in buspair_indexes)
    
    for l in branch_lookup
        i = branches.f_bus[l]
        j = branches.t_bus[l]
        bp_angmin[(i,j)] = max(bp_angmin[(i,j)], branches.angmin[l])
        bp_angmax[(i,j)] = min(bp_angmax[(i,j)], branches.angmax[l])
        bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end
    
    buspairs = Dict((i,j) => Dict(
        "branch"=>Int(bp_branch[(i,j)]),
        "angmin"=>Float16(bp_angmin[(i,j)]),
        "angmax"=>Float16(bp_angmax[(i,j)]),
        "tap"=>Float16(branches.tap[bp_branch[(i,j)]]),
        "vm_fr_min"=>Float16(buses.vmin[i]),
        "vm_fr_max"=>Float16(buses.vmax[i]),
        "vm_to_min"=>Float16(buses.vmin[j]),
        "vm_to_max"=>Float16(buses.vmax[j]),
        ) for (i,j) in buspair_indexes
    )
    
    # add optional parameters
    for bp in buspair_indexes
        buspairs[bp]["rate_a"] = branches.rate_a[bp_branch[bp]]
    end
    
    return buspairs

end
