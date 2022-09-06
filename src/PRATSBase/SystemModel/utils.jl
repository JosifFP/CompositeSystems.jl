export extract, container

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

function container(container_key::Vector{<:Any}, key_order::Vector{<:Any}, dictionary_core::Dict{<:Any}, 
    dictionary_timeseries::Dict{<:Any}, network::Network{N,L,T,U}, ::Type{Loads}) where {N,L,T,U}
    
    tmp = Dict(string(dictionary_core[:key][i]) => Float16(dictionary_core[Symbol("customerloss[USD/MWh]")][i]) for i in eachindex(dictionary_core[:key]))
    for (i,load) in network.load
        get!(load, "cost", tmp[i])
    end

    if isempty(dictionary_timeseries) error("Load data must be provided") end
    ref = Dict(i => network.load[string(i)] for i in 1:length(keys(network.load)))
    @assert length(dictionary_timeseries) == length(ref)
    container_bus = [Int64.(ref[i]["load_bus"]) for i in keys(dictionary_timeseries)]
    container_data = [Float16.(dictionary_timeseries[i]/network.baseMVA) for i in keys(dictionary_timeseries)]

    return Loads{N,L,T,U}(container_key[key_order], container_bus[key_order], reduce(vcat,transpose.(container_data[key_order])))

end

function container(container_key::Vector{<:Any}, key_order::Vector{<:Any}, dictionary_core::Dict{<:Any}, 
    dictionary_timeseries::Dict{<:Any}, network::Network{N,L,T,U}, ::Type{Generators}) where {N,L,T,U}

    ref = Dict(i => network.gen[string(i)] for i in 1:length(keys(network.gen)))
    tmp = sort([[i, gen["gen_bus"]] for (i,gen) in ref], by = x->x[1])
    container_key_core = Int64.(reduce(vcat, tmp')[:,1])
    key_order_core = sortperm(container_key_core)

    if length(container_key) ≠ length(container_key_core)
        for i in container_key_core
            if in(container_key).(i) == false
                setindex!(dictionary_timeseries, Float16.([ref[i]["pg"]*network.baseMVA for k in 1:N]), i)
            end
        end
        container_key = [i for i in keys(dictionary_timeseries)]
        key_order = sortperm(container_key)
        @assert length(container_key) == length(container_key_core)
    end

    container_data = [Float16.(dictionary_timeseries[i]/network.baseMVA) for i in keys(dictionary_timeseries)]
    container_bus = Int64.(reduce(vcat, tmp')[:,2])
    container_λ = Float32.(values(dictionary_core[Symbol("failurerate[f/year]")]))
    container_μ = Vector{Float32}(undef, length(values(dictionary_core[Symbol("repairtime[hrs]")])))
    for i in 1:length(values(dictionary_core[Symbol("repairtime[hrs]")]))
        if values(dictionary_core[Symbol("repairtime[hrs]")])[i]≠0.0
            container_μ[i] = Float32.(8760/values(dictionary_core[Symbol("repairtime[hrs]")])[i])
        else
            container_μ[i] = 0.0
        end
    end

    return Generators{N,L,T,U}(container_key_core[key_order_core], container_bus[key_order_core], 
        reduce(vcat,transpose.(container_data[key_order])), container_λ[key_order_core], container_μ[key_order_core])

end

function container(container_key::Vector{<:Any}, key_order::Vector{<:Any}, dictionary_core::Dict{<:Any}, 
    ::Dict{<:Any}, network::Network{N,L,T,U}, ::Type{Branches}) where {N,L,T,U}

    ref = Dict(i => network.branch[string(i)] for i in 1:length(keys(network.branch)))

    container_longterm_capacity = Dict{Int64, Any}()
    container_shortterm_capacity = Dict{Int64, Any}()

    tmp = sort([[i, Int64.(branch["f_bus"]), Int64.(branch["t_bus"]), Float16.(branch["rate_a"]),
                Float16.(branch["rate_b"])] for (i,branch) in ref], by = x->x[1])

    container_key_core = Int64.(reduce(vcat, tmp')[:,1])
    key_order_core = sortperm(container_key_core)

    if length(container_key) ≠ length(container_key_core)
        for i in container_key_core
            if in(container_key).(i) == false
                setindex!(container_longterm_capacity, Float16.([ref[i]["rate_a"] for k in 1:N]), i)
                setindex!(container_shortterm_capacity, Float16.([ref[i]["rate_b"] for k in 1:N]), i)
            end
        end
        container_key = [i for i in keys(container_longterm_capacity)]
        key_order = sortperm(container_key)
        @assert length(container_key) == length(container_key_core)
        @assert [i for i in keys(container_longterm_capacity)] == [i for i in keys(container_shortterm_capacity)]
    end

    container_f_bus = Int64.(reduce(vcat, tmp')[:,2])
    container_t_bus = Int64.(reduce(vcat, tmp')[:,3])
    container_λ = Float32.(values(dictionary_core[Symbol("failurerate[f/year]")]))
    container_μ = Vector{Float32}(undef, length(values(dictionary_core[Symbol("repairtime[hrs]")])))

    for i in 1:length(values(dictionary_core[Symbol("repairtime[hrs]")]))
        if values(dictionary_core[Symbol("repairtime[hrs]")])[i]≠0.0
            container_μ[i] = Float32.(8760/values(dictionary_core[Symbol("repairtime[hrs]")])[i])
        else
            container_μ[i] = 0.0
        end
    end
    
    container_data_longterm = [Float16.(container_longterm_capacity[i]) for i in keys(container_longterm_capacity)]
    container_data_shortterm = [Float16.(container_shortterm_capacity[i]) for i in keys(container_shortterm_capacity)]
    
    return Branches{N,L,T,U}(container_key_core[key_order_core],
                        container_f_bus[key_order_core], container_t_bus[key_order_core],
                        reduce(vcat,transpose.(container_data_longterm[key_order])),
                        reduce(vcat,transpose.(container_data_shortterm[key_order])),
                        container_λ[key_order_core], container_μ[key_order_core])
end