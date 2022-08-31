include("utils.jl")


struct NoContingencies <: SimulationSpec
    
    opf::Bool
    verbose::Bool
    threaded::Bool

    function NoContingencies(;opf::Bool=false, verbose::Bool=false, threaded::Bool=true)
        new(opf, verbose, threaded)
    end
end

function assess(
    system::SystemModel{N},
    method::NoContingencies,
    resultspecs::ResultSpec...
) where {N}

    nstors = length(system.storages)
    ngenstors = length(system.generatorstorages)

    if nstors + ngenstors > 0
        method.threaded = false
    end

    #overloadings = Vector{Int64}()
    info = Vector{Vector{Any}}()
    threads = nthreads()
    periods = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)

    @spawn makeperiods(periods, N)

    if method.threaded
        for _ in 1:threads
            @spawn assess(system, method, periods, results, resultspecs...)
        end
    else
        assess(system, method, periods, results, resultspecs...)
    end

    return finalize(results, system, method.threaded ? threads : 1)
end

function makeperiods(periods::Channel{Int}, N::Int)
    for t in 1:N
        put!(periods, t)
    end
    close(periods)
end

function assess(
    system::SystemModel{N,L,T,U}, method::NoContingencies, periods::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{NoContingencies}}}},
    resultspecs::ResultSpec...
    ) where {N,L,T<:Period,U<:PerUnit}
    
    recorders = accumulator.(system, method, resultspecs)
    network_data = PRATSBase.conversion_to_pm_data(system.network)
    optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)
    
    if method.opf == false
        for t in periods
            system = TimeSeriesPowerFlow!(network_data, system, t)
            foreach(recorder -> record!(recorder, system, 1, t), recorders)
        end

    else
        for t in periods
            system = TimeSeriesPowerFlow!(network_data, system, optimizer, t)
            foreach(recorder -> record!(recorder, system, 1, t), recorders)
        end
    end

    put!(results, recorders)

end

function TimeSeriesPowerFlow!(network_data::Dict{String,Any}, system::SystemModel{N}, t::Int) where {N}

    update_data_from_system!(network_data, system, t)
    update_data!(network_data, PowerModels.compute_dc_pf(network_data)["solution"])
    flow = calc_branch_flow_dc(network_data)
    update_data!(network_data, flow)
    update_systemmodel_branches!(system, flow, t)

    for i in eachindex(system.generators.keys)
        system.generators.pg[i,t] = network_data["gen"][string(i)]["pg"]
    end
    
    return system
end

function TimeSeriesPowerFlow!(network_data::Dict{String,Any}, system::SystemModel{N}, optimizer, t::Int) where {N}

    update_data_from_system!(network_data, system, t)
    update_data!(network_data, PowerModels.compute_dc_pf(network_data)["solution"])
    flow = calc_branch_flow_dc(network_data)
    update_data!(network_data, flow)
    update_systemmodel_branches!(system, flow, t)

    if any(abs.(system.branches.pf[:,t]).> system.branches.longterm_rating[:,t])
        results = PowerModels.solve_dc_opf(network_data, optimizer)
        update_systemmodel_branches!(system, results["solution"], t)

        for i in eachindex(system.generators.keys)
            system.generators.pg[i,t] = results["solution"]["gen"][string(i)]["pg"]
        end
    else

        for i in eachindex(system.generators.keys)
            system.generators.pg[i,t] = network_data["gen"][string(i)]["pg"]
        end

    end


    return system

end

include("result_flow.jl")

    # for j in eachindex(1:N)
    #     if any(abs.(system.branches.pf[:,j]).> system.branches.longterm_rating[:,j])
    #         for i in eachindex(system.branches.keys)
    #             if abs(system.branches.pf[i,j]) > system.branches.longterm_rating[i,j]
    #                 #push!(overloadings, j)
    #                 push!(info, ["Branch $(system.branches.keys[i]) overloaded by %$(Float16(abs(system.branches.pf[i,j])*100/system.branches.longterm_rating[i,j])),MW = $(abs(system.branches.pf[i,j])), Hour=$(j)"])
    #             end
    #         end
    #     end
    # end
    #overloadings = [j for j in eachindex(1:N) if any(abs.(system.branches.pf[:,j]).>system.branches.longterm_rating[:,j])]
    #return overloadings, info