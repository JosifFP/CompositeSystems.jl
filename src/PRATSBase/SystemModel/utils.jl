export extract, container

function extract(ReliabilityDataDir::String, files::Vector{String}, asset::Type{<:AbstractAssets}, container_1::Vector{Vector}, container_2::Vector{Vector{Any}})

    if in(files).("$asset"*".xlsx") == true
        XLSX.openxlsx(ReliabilityDataDir*"/"*"$asset"*".xlsx", enable_cache=false) do io
            for i in 1:XLSX.sheetcount(io)
                if XLSX.sheetnames(io)[i] == "time series capacity" 
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

function container(container_key::Vector{<:Any}, key_order::Vector{<:Any}, ::Dict{<:Any}, 
    dictionary_timeseries::Dict{<:Any}, network::Network{N,L,T,P,E,V}, ::Type{Loads}) where {N,L,T,P,E,V}

    if isempty(dictionary_timeseries) error("Load data must be provided") end

    ref = Dict(i => network.load[string(i)] for i in 1:length(keys(network.load)))
    @assert length(dictionary_timeseries) == length(ref)

    container_bus = [Int64.(ref[i]["load_bus"]) for i in keys(dictionary_timeseries)]
    container_data = [Float16.(dictionary_timeseries[i]) for i in keys(dictionary_timeseries)]

    return Loads{N,L,T,P}(container_key[key_order], container_bus[key_order], reduce(vcat,transpose.(container_data[key_order])))

end

function container(container_key::Vector{<:Any}, key_order::Vector{<:Any}, dictionary_core::Dict{<:Any}, 
    dictionary_timeseries::Dict{<:Any}, network::Network{N,L,T,P,E,V}, ::Type{Generators}) where {N,L,T,P,E,V}

    ref = Dict(i => network.gen[string(i)] for i in 1:length(keys(network.gen)))
    tmp = sort([[i, gen["gen_bus"]] for (i,gen) in ref], by = x->x[1])
    container_key_core = Int64.(reduce(vcat, tmp')[:,1])
    key_order_core = sortperm(container_key_core)

    if length(container_key) != length(container_key_core)
        for i in container_key_core
            if in(container_key).(i) == false
                setindex!(dictionary_timeseries, Float16.([ref[i]["pmax"]*network.baseMVA for k in 1:N]), i)
            end
        end
        container_key = [i for i in keys(dictionary_timeseries)]
        key_order = sortperm(container_key)
        @assert length(container_key) == length(container_key_core)
    end

    container_data = [Float16.(dictionary_timeseries[i]) for i in keys(dictionary_timeseries)]
    container_bus = Int64.(reduce(vcat, tmp')[:,2])
    container_category = String.(values(dictionary_core[:category]))
    container_λ = Float32.(values(dictionary_core[Symbol("failurerate[f/year]")]))
    container_μ = Float32.(values(dictionary_core[Symbol("repairrate[h/year]")])) 

    return Generators{N,L,T,P}(container_key_core[key_order_core], container_bus[key_order_core], container_category[key_order_core], 
        reduce(vcat,transpose.(container_data[key_order])), container_λ[key_order_core], container_μ[key_order_core])

end

function container(container_key::Vector{<:Any}, key_order::Vector{<:Any}, dictionary_core::Dict{<:Any}, 
    ::Dict{<:Any}, network::Network{N,L,T,P,E,V}, ::Type{Branches}) where {N,L,T,P,E,V}

    ref = Dict(i => network.branch[string(i)] for i in 1:length(keys(network.branch)))

    container_longterm_capacity = Dict{Int64, Any}()
    container_shortterm_capacity = Dict{Int64, Any}()
    #container_data_longterm = Vector{Vector{Float16}}()
    #container_data_shortterm = Vector{Vector{Float16}}()
    #container_f_bus = Vector{Int64}()
    #container_t_bus = Vector{Int64}()

    tmp = sort([[i, Int64.(branch["f_bus"]), Int64.(branch["t_bus"]), Float16.(branch["rate_a"]*network.baseMVA),
                Float16.(branch["rate_b"]*network.baseMVA)] for (i,branch) in ref], by = x->x[1])

    container_key_core = Int64.(reduce(vcat, tmp')[:,1])
    key_order_core = sortperm(container_key_core)

    if length(container_key) != length(container_key_core)
        for i in container_key_core
            if in(container_key).(i) == false
                setindex!(container_longterm_capacity, Float16.([ref[i]["rate_a"]*network.baseMVA for k in 1:N]), i)
                setindex!(container_shortterm_capacity, Float16.([ref[i]["rate_b"]*network.baseMVA for k in 1:N]), i)
            end
        end
        container_key = [i for i in keys(container_longterm_capacity)]
        key_order = sortperm(container_key)
        @assert length(container_key) == length(container_key_core)
        @assert [i for i in keys(container_longterm_capacity)] == [i for i in keys(container_shortterm_capacity)]
    end

    container_f_bus = Int64.(reduce(vcat, tmp')[:,2])
    container_t_bus = Int64.(reduce(vcat, tmp')[:,3])
    container_category = String.(values(dictionary_core[:category]))
    container_λ = Float32.(values(dictionary_core[Symbol("failurerate[f/year]")]))
    container_μ = Float32.(values(dictionary_core[Symbol("repairrate[h/year]")]))
    
    container_data_longterm = [Float16.(container_longterm_capacity[i]) for i in keys(container_longterm_capacity)]
    container_data_shortterm = [Float16.(container_shortterm_capacity[i]) for i in keys(container_shortterm_capacity)]
    
    return Branches{N,L,T,P}(container_key_core[key_order_core],
                        container_f_bus[key_order_core], container_t_bus[key_order_core],
                        container_category[key_order_core],
                        reduce(vcat,transpose.(container_data_longterm[key_order])),
                        reduce(vcat,transpose.(container_data_shortterm[key_order])),
                        container_λ[key_order_core], container_μ[key_order_core])

end