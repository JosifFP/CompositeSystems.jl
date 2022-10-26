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
        if asset == Loads || asset == Generators || asset == Branches
            error("file $asset.xlsx not found in $ReliabilityDataDir/ directory")
        end
    end

    return Dict(parse(Int, String(container_1[1][i])) => Float16.(container_1[2][i]) for i in 2:length(container_1[1])), 
    Dict(container_2[1][i] => container_2[2][i] for i in 1:length(container_2[1]))

end

"Creates AbstractAsset - Buses"
function container(network::Dict{Symbol, <:Any}, asset::Type{Buses}, B::Int, N::Int, L::Int, T::Type{<:Period})

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

    return asset{N,L,T,B}(
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
function container(network::Dict{Symbol, <:Any}, asset::Type{Generators}, B::Int, N::Int, L::Int, T::Type{<:Period})

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
    D = length(container_data[:keys])

    return asset{N,L,T,B}(
        container_data[:keys][key_order_core],
        container_data[:buses][key_order_core],
        container_data[:pg][key_order_core],
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
        zeros(Float64, D), zeros(Float64, D))
end

"Creates AbstractAsset - Generators with time-series data"
function container(dict_core::Dict{<:Any}, dict_timeseries::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Generators}, B::Int, N::Int, L::Int, T::Type{<:Period})

    container_key = [i for i in keys(dict_timeseries)]
    key_order_series = sortperm(container_key)

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
                setindex!(dict_timeseries, [container_data[:pg][i] for k in 1:N]*B, i)
            end
        end
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        @assert length(container_key) == length(container_data[:keys])
    end

    container_timeseries = [Float16.(dict_timeseries[i]/B) for i in keys(dict_timeseries)]

    container_λ = Float64.(values(dict_core[Symbol("failurerate[f/year]")]))
    container_μ = Vector{Float64}(undef, length(values(dict_core[Symbol("repairtime[hrs]")])))

    for i in 1:length(values(dict_core[Symbol("repairtime[hrs]")]))
        if values(dict_core[Symbol("repairtime[hrs]")])[i]≠0.0
            container_μ[i] = Float64.(8736/values(dict_core[Symbol("repairtime[hrs]")])[i])
        else
            container_μ[i] = 0.0
        end
    end

    return asset{N,L,T,B}(
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
function container(network::Dict{Symbol, <:Any}, asset::Type{Loads}, B::Int, N::Int, L::Int, T::Type{<:Period})

    for (i,load) in network[:load]
        get!(load, "cost", Float16(0.0))
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

    return asset{N,L,T,B}(
        container_data[:keys][key_order_core],
        container_data[:buses][key_order_core],    
        container_data[:pd][key_order_core],
        container_data[:qd][key_order_core],
        container_data[:source_id][key_order_core],
        container_data[:status][key_order_core],
        container_data[:cost][key_order_core])

end

"Creates AbstractAsset - Loads with time-series data"
function container(dict_core::Dict{<:Any}, dict_timeseries::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Loads}, B::Int, N::Int, L::Int, T::Type{<:Period})

    container_key = [i for i in keys(dict_timeseries)]
    key_order_series = sortperm(container_key)

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

    if length(container_key) ≠ length(container_data[:keys])
        for i in container_data[:keys]
            if in(container_key).(i) == false
                setindex!(dict_timeseries, [container_data[:pd][i] for k in 1:N]*B, i)
            end
            #get!(dict_timeseries_qd, i, Float16.(dict_timeseries_pd[i]*powerfactor))
        end
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        @assert length(container_key) == length(container_data[:keys])
    end

    container_timeseries = [Float16.(dict_timeseries[i]/B) for i in keys(dict_timeseries)]

    return asset{N,L,T,B}(
        container_data[:keys][key_order_core],
        container_data[:buses][key_order_core],    
        reduce(vcat,transpose.(container_timeseries[key_order_series])),
        container_data[:qd][key_order_core],
        container_data[:source_id][key_order_core],
        container_data[:status][key_order_core],
        container_data[:cost][key_order_core])

end

"Creates AbstractAsset - Branches"
function container(network::Dict{Symbol, <:Any}, asset::Type{Branches}, B::Int, N::Int, L::Int, T::Type{<:Period})

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
    D = length(container_data[:keys])

    return asset{N,L,T,B}(
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
        zeros(Float64, D), zeros(Float64, D))
end

"Creates AbstractAsset - Branches with time-series data"
function container(dict_core::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Branches}, B::Int, N::Int, L::Int, T::Type{<:Period})

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

    return asset{N,L,T,B}(
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
function container(network::Dict{Symbol, <:Any}, asset::Type{Shunts}, B::Int, N::Int, L::Int, T::Type{<:Period})

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

    return asset{N,L,T,B}(
        container_data[:keys][key_order_core],
        container_data[:buses][key_order_core],
        container_data[:bs][key_order_core],
        container_data[:gs][key_order_core],
        container_data[:source_id][key_order_core],
        container_data[:status][key_order_core])

end

"Checks for inconsistencies between AbstractAsset and Power Model Network"
function _check_consistency(ref::Dict{Symbol,<:Any}, buses::Buses, loads::Loads, branches::Branches, shunts::Shunts, generators::Generators, storages::Storages)

    for k in buses.keys
        @assert haskey(ref[:bus],k) == true
        @assert Int.(ref[:bus][k]["index"]) == buses.keys[k]
        @assert Int.(ref[:bus][k]["index"]) == buses.index[k]
        @assert Int.(ref[:bus][k]["area"]) == buses.area[k]
        @assert Int.(ref[:bus][k]["bus_type"]) == buses.bus_type[k]
        @assert Float16.(ref[:bus][k]["vmax"]) == buses.vmax[k]
        @assert Float16.(ref[:bus][k]["vmin"]) == buses.vmin[k]
        @assert Float16.(ref[:bus][k]["base_kv"]) == buses.base_kv[k]
        @assert Float32.(ref[:bus][k]["va"]) == buses.va[k]
        @assert Float32.(ref[:bus][k]["vm"]) == buses.vm[k]
    end
    
    for k in generators.keys
        @assert haskey(ref[:gen],k) == true
        @assert Int.(ref[:gen][k]["index"]) == generators.keys[k]
        @assert Int.(ref[:gen][k]["gen_bus"]) == generators.buses[k]
        @assert Float16.(ref[:gen][k]["qg"]) == generators.qg[k]
        @assert Float32.(ref[:gen][k]["vg"]) == generators.vg[k]
        @assert Float16.(ref[:gen][k]["pmax"]) == generators.pmax[k]
        @assert Float16.(ref[:gen][k]["pmin"]) == generators.pmin[k]
        @assert Float16.(ref[:gen][k]["qmax"]) == generators.qmax[k]
        @assert Float16.(ref[:gen][k]["qmin"]) == generators.qmin[k]
        @assert Int.(ref[:gen][k]["mbase"]) == generators.mbase[k]
        @assert Bool.(ref[:gen][k]["gen_status"]) == generators.status[k]
        #@assert (ref[:gen][k]["cost"]) == generators.cost[k]
    end
    
    for k in loads.keys
        @assert haskey(ref[:load],k) == true
        @assert Int.(ref[:load][k]["index"]) == loads.keys[k]
        @assert Int.(ref[:load][k]["load_bus"]) == loads.buses[k]
        @assert Float16.(ref[:load][k]["qd"]) == loads.qd[k]
        @assert Bool.(ref[:load][k]["status"]) == loads.status[k]
    end
    
    for k in branches.keys
        @assert haskey(ref[:branch],k) == true
        @assert Int.(ref[:branch][k]["index"]) == branches.keys[k]
        @assert Int.(ref[:branch][k]["f_bus"]) == branches.f_bus[k]
        @assert Int.(ref[:branch][k]["t_bus"]) == branches.t_bus[k]
        @assert Float16.(ref[:branch][k]["rate_a"]) == branches.rate_a[k]
        @assert Float16.(ref[:branch][k]["rate_b"]) == branches.rate_b[k]
        @assert Float16.(ref[:branch][k]["rate_c"]) == branches.rate_c[k]
        @assert Float16.(ref[:branch][k]["br_r"]) == branches.r[k]
        @assert Float16.(ref[:branch][k]["br_x"]) == branches.x[k]
        @assert Float16.(ref[:branch][k]["b_fr"]) == branches.b_fr[k]
        @assert Float16.(ref[:branch][k]["b_to"]) == branches.b_to[k]
        @assert Float16.(ref[:branch][k]["g_fr"]) == branches.g_fr[k]
        @assert Float16.(ref[:branch][k]["g_to"]) == branches.g_to[k]
        @assert Float16.(ref[:branch][k]["shift"]) == branches.shift[k]
        @assert Float16.(ref[:branch][k]["angmin"]) == branches.angmin[k]
        @assert Float16.(ref[:branch][k]["angmax"]) == branches.angmax[k]
        @assert Bool.(ref[:branch][k]["transformer"]) == branches.transformer[k]
        @assert Float16.(ref[:branch][k]["tap"]) == branches.tap[k]
        @assert Bool.(ref[:branch][k]["br_status"]) == branches.status[k]
    end
    
    for k in shunts.keys
        @assert haskey(ref[:shunt],k) == true
        @assert Int.(ref[:shunt][k]["index"]) == shunts.keys[k]
        @assert Int.(ref[:shunt][k]["shunt_bus"]) == shunts.buses[k]
        @assert Float16.(ref[:shunt][k]["bs"]) == shunts.bs[k]
        @assert Float16.(ref[:shunt][k]["gs"]) == shunts.gs[k]
        @assert Bool.(ref[:shunt][k]["status"]) == shunts.status[k]
    end
    
end

"Checks connectivity issues and status"
function _check_connectivity(ref::Dict{Symbol,<:Any}, buses::Buses, loads::Loads, branches::Branches, shunts::Shunts, generators::Generators, storages::Storages)

    @assert(length(buses.keys) == length(ref[:bus])) # if this is not true something very bad is going on
    active_bus_ids = Set(bus["index"] for (i,bus) in ref[:bus] if bus["bus_type"] != 4)

    for (i, gen) in ref[:gen]
        if !(gen["gen_bus"] in buses.keys) || !(generators.buses[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(gen["gen_bus"]) in shunt $(i) is not defined")
        end
        if gen["gen_status"] != 0 && !(gen["gen_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active generator $(i) is connected to inactive bus $(gen["gen_bus"])")
        end
    end

    for (i, load) in ref[:load]
        if !(load["load_bus"] in buses.keys) || !(loads.buses[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(load["load_bus"]) in load $(i) is not defined")
        end

        if load["status"] != 0 && !(load["load_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active load $(i) is connected to inactive bus $(load["load_bus"])")
        end       
    end

    for (i, shunt) in ref[:shunt]
        if !(shunt["shunt_bus"] in buses.keys) || !(shunts.buses[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(shunt["shunt_bus"]) in shunt $(i) is not defined")
        end
        if shunt["status"] != 0 && !(shunt["shunt_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active shunt $(i) is connected to inactive bus $(shunt["shunt_bus"])")
        end
    end

    for (i, strg) in ref[:storage]
        if !(strg["storage_bus"] in buses.keys) || !(storages.buses[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(strg["storage_bus"]) in shunt $(i) is not defined")
        end
        if strg["status"] != 0 && !(strg["storage_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active storage unit $(i) is connected to inactive bus $(strg["storage_bus"])")
        end
    end
    
    for (i, branch) in ref[:branch]
        if !(branch["f_bus"] in buses.keys) || !(branches.f_bus[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(branch["f_bus"]) in shunt $(i) is not defined")
        end
        if !(branch["t_bus"] in buses.keys) || !(branches.t_bus[i] in buses.keys)
            Memento.error(_LOGGER, "bus $(branch["t_bus"]) in shunt $(i) is not defined")
        end
        if branch["br_status"] != 0 && !(branch["f_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active branch $(i) is connected to inactive bus $(branch["f_bus"])")
        end

        if branch["br_status"] != 0 && !(branch["t_bus"] in active_bus_ids)
            Memento.warn(_LOGGER, "active branch $(i) is connected to inactive bus $(branch["t_bus"])")
        end

        # if dcline["br_status"] != 0 && !(dcline["f_bus"] in active_bus_ids)
        #     Memento.warn(_LOGGER, "active dcline $(i) is connected to inactive bus $(dcline["f_bus"])")
        # end

        # if dcline["br_status"] != 0 && !(dcline["t_bus"] in active_bus_ids)
        #     Memento.warn(_LOGGER, "active dcline $(i) is connected to inactive bus $(dcline["t_bus"])")
        # end
    end

end

""
function calc_buspair_parameters(branches::Branches, branch_lookup::Vector{Int})
 
    buspair_indexes = Set((branches.f_bus[i], branches.t_bus[i]) for i in branch_lookup)
    bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf) for bp in buspair_indexes)
    
    for l in branch_lookup
        i = branches.f_bus[l]
        j = branches.t_bus[l]
        bp_angmin[(i,j)] = Float16(max(bp_angmin[(i,j)], branches.angmin[l]))
        bp_angmax[(i,j)] = Float16(min(bp_angmax[(i,j)], branches.angmax[l]))
        bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end
    
    buspairs = Dict((i,j) => [bp_branch[(i,j)],bp_angmin[(i,j)],bp_angmax[(i,j)]] for (i,j) in buspair_indexes)
        #"tap"=>Float16(branches.tap[bp_branch[(i,j)]]),
        #"vm_fr_min"=>Float16(field(buses, :vmin)[i]),
        #"vm_fr_max"=>Float16(field(buses, :vmax)[i]),
        #"vm_to_min"=>Float16(field(buses, :vmin)[j]),
        #"vm_to_max"=>Float16(field(buses, :vmax)[j]),
    
    # add optional parameters
    #for bp in buspair_indexes
    #    buspairs[bp]["rate_a"] = branches.rate_a[bp_branch[bp]]
    #end
    
    return buspairs

end

"compute bus pair level data, can be run on data or ref data structures"
function calc_buspair_parameters(buses, branches)

    bus_lookup = Dict(bus["index"] => bus for (i,bus) in buses if bus["bus_type"] ≠ 4)
    branch_lookup = Dict(branch["index"] => branch for (i,branch) in branches if branch["br_status"] == 1 && 
        haskey(bus_lookup, branch["f_bus"]) && haskey(bus_lookup, branch["t_bus"]))
    buspair_indexes = Set((branch["f_bus"], branch["t_bus"]) for (i,branch) in branch_lookup)
    bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)
    bp_angmin = Dict((bp, -Inf) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf) for bp in buspair_indexes)

    for (l,branch) in branch_lookup
        i = branch["f_bus"]
        j = branch["t_bus"]
        bp_angmin[(i,j)] = max(bp_angmin[(i,j)], branch["angmin"])
        bp_angmax[(i,j)] = min(bp_angmax[(i,j)], branch["angmax"])
        bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end

    buspairs = Dict((i,j) => Dict(
        "branch"=>bp_branch[(i,j)],
        "angmin"=>bp_angmin[(i,j)],
        "angmax"=>bp_angmax[(i,j)],
        "tap"=>branch_lookup[bp_branch[(i,j)]]["tap"],
        #"vm_fr_min"=>bus_lookup[i]["vmin"],
        #"vm_fr_max"=>bus_lookup[i]["vmax"],
        #"vm_to_min"=>bus_lookup[j]["vmin"],
        #"vm_to_max"=>bus_lookup[j]["vmax"]
        ) for (i,j) in buspair_indexes
    )

    # add optional parameters
    for bp in buspair_indexes
        branch = branch_lookup[bp_branch[bp]]
        if haskey(branch, "rate_a")
            buspairs[bp]["rate_a"] = branch["rate_a"]
        end
        if haskey(branch, "c_rating_a")
            buspairs[bp]["c_rating_a"] = branch["c_rating_a"]
        end
    end

    return buspairs
end