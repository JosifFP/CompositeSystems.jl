"Extracts data from excel file"
function extract(ReliabilityDataDir::String, files::Vector{String}, asset::Type{<:AbstractAssets}, container_1::Vector{Vector}, container_2::Vector{Vector{Any}})

    if in(files).("$asset"*".xlsx") == true
        XLSX.openxlsx(ReliabilityDataDir*"/"*"$asset"*".xlsx", enable_cache=false) do io
            for i in 1:XLSX.sheetcount(io)
                if XLSX.sheetnames(io)[i] == "time series MW" 
                    container_1[2], container_1[1] = XLSX.readtable("$asset"*".xlsx", XLSX.sheetnames(io)[i])
                elseif XLSX.sheetnames(io)[i] == "core"
                    container_2[2], container_2[1] = XLSX.readtable("$asset"*".xlsx",XLSX.sheetnames(io)[i])
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
        Float16(comp["qmax"]), 
        Float16(comp["pmin"]), 
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
                setindex!(dict_timeseries, Float16.([container_data[:pg][i] for k in 1:N]), i)
            else
                dict_timeseries[i] = Float16.(dict_timeseries[i]/network.baseMVA)
            end
        end
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        @assert length(container_key) == length(container_data[:keys])
    end

    container_timeseries = [Float16.(dict_timeseries[i]) for i in key_order_series]

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
        reduce(vcat,transpose.(container_timeseries)),
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
                setindex!(dict_timeseries, Float16.([container_data[:pd][i] for k in 1:N]), i)
            else
                dict_timeseries[i] = Float16.(dict_timeseries[i]/network.baseMVA)
            end
            #get!(dict_timeseries_qd, i, Float16.(dict_timeseries_pd[i]*powerfactor))
        end
        container_key = [i for i in keys(dict_timeseries)]
        key_order_series = sortperm(container_key)
        @assert length(container_key) == length(container_data[:keys])
    end

    container_timeseries = [Float16.(dict_timeseries[i]) for i in key_order_series]

    return Loads{N,L,T,U}(
        container_data[:keys][key_order_core],
        container_data[:buses][key_order_core],    
        reduce(vcat,transpose.(container_timeseries)),
        container_data[:qd][key_order_core],
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