"""
    ELCC{M} <: CapacityValuationMethod{M}

Define the Effective Load Carrying Capability (ELCC) model for capacity valuation.

# Fields
- `capacity_max::Float64`: The maximum capacity.
- `tolerance::Float64`: The acceptable tolerance for the valuation.
- `p_value::Float64`: The probability value used for statistical significance.
- `loads::Vector{Tuple{Int,Float64}}`: A vector containing pairs of time and load values.
- `verbose::Bool`: A flag indicating if verbose logging should be enabled.

# Description
The `ELCC` struct models the ability of a power system component (e.g., a generator or battery) to serve 
added demand without increasing the likelihood of a supply interruption. It's a measure used to determine 
the equivalent capacity of non-dispatchable resources like wind and solar. The higher the ELCC value, the more 
reliable the resource is considered in contributing to the overall system's reliability.

# Usage
`ELCC` is typically used in reliability studies to measure the capacity value of renewable resources. 
It accounts for the variable and uncertain nature of renewable generation by determining 
how much firm capacity (in MW) the renewable resource can replace while maintaining system reliability.

"""
struct ELCC{M} <: CapacityValuationMethod{M}
    
    capacity_max::Float64
    tolerance::Float64
    p_value::Float64
    loads::Vector{Tuple{Int,Float64}}
    verbose::Bool

    function ELCC{M}(
        capacity_max::Float64, 
        loads::Vector{Pair{Int,Float64}};
        tolerance::Float64=0.0, 
        p_value::Float64=0.05, 
        verbose::Bool=false) where M

        @assert capacity_max > 0
        @assert tolerance >= 0
        @assert 0 < p_value < 1
        @assert sum(x.second for x in loads) ≈ 1.0

        return new{M}(capacity_max, tolerance, p_value, Tuple.(loads), verbose)
    end
end


""
function ELCC{M}(capacity_max::Float64, loads::Float64; kwargs...) where M
    return ELCC{M}(capacity_max, [loads=>1.0]; kwargs...)
end



"""
    assess(sys_baseline::S, sys_augmented::S, params::ELCC{M}, settings::Settings, simulationspec::SimulationSpec)
        where {N, L, T, S <: SystemModel{N,L,T}, M <: ReliabilityMetric}

Assess the capacity credit of a system using the Newton-Raphson iterative method.

This function evaluates the capacity credit, which reflects the capacity contribution of a given system configuration 
towards ensuring system reliability. The assessment process relies on a Newton-Raphson iterative method to find the 
optimal capacity credit value within the defined bounds.

## Function Workflow:
1. Sets the filename based on the current timestamp to capture and save analysis results.
2. Logs essential system information, especially if storage elements are present.
3. Evaluates the target metric, SI (System Index), EENS (Expected Energy Not Supplied), and EDLC (Expected Duration of Load Curtailed).
4. Initiates the Newton-Raphson iteration to progressively narrow down the capacity credit bounds until it meets a specified 
   precision or encounters conditions to stop.
5. The function's stopping conditions include:
   - A statistically insignificant gap between upper and lower bound metrics.
   - Approximations becoming only marginally different, meaning the iterative process has converged.
6. Returns a structured `CapacityCreditResult` capturing the results of the capacity credit analysis, including the final 
   estimated value, metrics, and associated error tolerances.

The function is designed to provide a robust estimate of a system's capacity credit, essential for system planners and 
operators to ensure optimal reliability and performance.

## Parameters:
- `sys_baseline`: The baseline system configuration.
- `sys_augmented`: The system configuration with potential augmentations or changes.
- `params`: Parameters related to the ELCC (Effective Load Carrying Capability).
- `settings`: General settings for the assessment.
- `simulationspec`: Specifications related to the simulation process.

## Returns:
- `CapacityCreditResult`: A structured result capturing the assessed capacity credit, its associated metrics, and 
  error tolerances.
"""
function assess(
    sys_baseline::S, 
    sys_augmented::S, 
    params::ELCC{M}, 
    settings::Settings, 
    simulationspec::SimulationSpec
    ) where {N, L, T, S <: SystemModel{N,L,T}, M <: ReliabilityMetric}

    P = BaseModule.powerunits["MW"]
    sys_baseline.loads.keys ≠ sys_augmented.loads.keys && error(
        "Systems provided do not have matching loads")

    shortfall = first(assess(sys_baseline, simulationspec, settings, Shortfall()))
    target_metric = M(shortfall)
    si_metric = SI(shortfall)
    eens_metric = EENS(shortfall)
    edlc_metric = EDLC(shortfall)

    capacities = Int[]
    target_metrics = typeof(target_metric)[]
    si_metrics = SI[]
    eens_metrics = EENS[]
    edlc_metrics = EDLC[]

    elcc_loads, base_load, sys_variable = copy_load(sys_augmented, params.loads)

    lower_bound = 0
    shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
    lower_bound_metric = M(shortfall)
    push!(capacities, lower_bound)
    push!(target_metrics , lower_bound_metric)
    push!(si_metrics, SI(shortfall))
    push!(eens_metrics, EENS(shortfall))
    push!(edlc_metrics, EDLC(shortfall))

    # initial estimate of the root
    upper_bound = params.capacity_max
    update_load!(sys_variable, elcc_loads, base_load, upper_bound)
    shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
    upper_bound_metric = M(shortfall)
    push!(capacities, upper_bound)
    push!(target_metrics , upper_bound_metric)
    push!(si_metrics, SI(shortfall))
    push!(eens_metrics, EENS(shortfall))
    push!(edlc_metrics, EDLC(shortfall))

    @info(
        "target_metric=$(val(target_metric)), lower_bound_metric=$(val(lower_bound_metric)), "*
        "upper_bound_metric=$(val(upper_bound_metric))")
    
    x_1 = x_n_1 = tolerance = 0

    while true

        params.verbose && @info(
            "\n$(lower_bound) $P\t< ELCC <\t$(upper_bound) $P\n",
            "$(lower_bound_metric)\t< $(target_metric) <\t$(upper_bound_metric)")

        #the tangent of f(x) at x0 to improve on the estimate of the root (x1)
        #gradient
        gradient = (val(upper_bound_metric) - val(lower_bound_metric)) / (upper_bound - lower_bound)
        x_1 = div((val(target_metric) - val(lower_bound_metric)) + gradient*lower_bound, gradient)
        x_n = x_1
        tolerance = abs(x_n - x_n_1)
        @info("x_1=$(x_1), tolerance=$(tolerance)")

        # Stopping condition N1
        # If the null hypothesis upper_bound_metric !>= lower_bound_metric
        # cannot be rejected, terminate and return the loose bounds
        pval = pvalue(lower_bound_metric, upper_bound_metric)
        if pval >= params.p_value
            @warn "Gap between upper and lower bound risk metrics is not " *
                "statistically significant (p_value=$pval), stopping newton-raphson method. " *
                "The tolerance error is $(tolerance) $P, " * 
                "while the target stopping criteria was $(params.tolerance) $P."
            break
        end

        if tolerance > 0
            # Evaluate metric at midpoint
            update_load!(sys_variable, elcc_loads, base_load, x_1)
            shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
            f_1 = M(shortfall)
            push!(capacities, x_1)
            push!(target_metrics , f_1)
            push!(si_metrics, SI(shortfall))
            push!(eens_metrics, EENS(shortfall))
            push!(edlc_metrics, EDLC(shortfall))
        end

        if  tolerance <= params.tolerance
            # Stopping condition N2
            ## Return the bounds if they are within solution tolerance of each other
            params.verbose && @info "Successive approximations will become only marginally different. " *
            "The iterative process (newton-raphson method) is terminated."
            break
        end

        x_n_1 = x_1

        # Tighten capacity bounds
        if val(f_1) < val(target_metric)
            lower_bound = x_1
            lower_bound_metric = f_1
        else # midpoint_metric <= target_metric
            upper_bound = x_1
            upper_bound_metric = f_1
        end
    end

    return CapacityCreditResult{typeof(params), typeof(target_metric), P}(
        target_metric,
        si_metric,
        eens_metric,
        edlc_metric, 
        Int(x_1), 
        Float64(tolerance), 
        Int.(capacities), 
        si_metrics, 
        eens_metrics, 
        edlc_metrics)
end


"This function finds a capacity value range based on the newton-raphson algorithm"
function assess(
    sys_baseline::S, 
    sys_augmented::S, 
    params::ELCC{M}, 
    settings::Settings, 
    simulationspec::SimulationSpec,
    shortfall::ShortfallResult
    ) where {N, L, T, S <: SystemModel{N,L,T}, M <: ReliabilityMetric}

    P = BaseModule.powerunits["MW"]
    sys_baseline.loads.keys ≠ sys_augmented.loads.keys && error("Systems provided do not have matching loads")

    target_metric = M(shortfall)
    si_metric = SI(shortfall)
    eens_metric = EENS(shortfall)
    edlc_metric = EDLC(shortfall)

    capacities = Int[]
    target_metrics = typeof(target_metric)[]
    si_metrics = SI[]
    eens_metrics = EENS[]
    edlc_metrics = EDLC[]

    elcc_loads, base_load, sys_variable = copy_load(sys_augmented, params.loads)

    lower_bound = 0
    shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
    lower_bound_metric = M(shortfall)
    push!(capacities, lower_bound)
    push!(target_metrics , lower_bound_metric)
    push!(si_metrics, SI(shortfall))
    push!(eens_metrics, EENS(shortfall))
    push!(edlc_metrics, EDLC(shortfall))

    # initial estimate of the root
    upper_bound = params.capacity_max
    update_load!(sys_variable, elcc_loads, base_load, upper_bound)
    shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
    upper_bound_metric = M(shortfall)
    push!(capacities, upper_bound)
    push!(target_metrics , upper_bound_metric)
    push!(si_metrics, SI(shortfall))
    push!(eens_metrics, EENS(shortfall))
    push!(edlc_metrics, EDLC(shortfall))
    params.verbose && @info("target_metric=$(target_metric), lower_bound_metric=$(lower_bound_metric), upper_bound_metric=$(upper_bound_metric)")
    x_n_1 = 0
    x_1 = 0
    tolerance = 0

    while true

        params.verbose && @info(
            "\n$(lower_bound) $P\t< ELCC <\t$(upper_bound) $P\n",
            "$(lower_bound_metric)\t< $(target_metric) <\t$(upper_bound_metric)")

        #the tangent of f(x) at x0 to improve on the estimate of the root (x1)
        #gradient
        gradient = (val(upper_bound_metric) - val(lower_bound_metric)) / (upper_bound - lower_bound)
        x_1 = div((val(target_metric) - val(lower_bound_metric)) + gradient*lower_bound, gradient)
        x_n = x_1
        tolerance = abs(x_n - x_n_1)

        # Stopping condition N1
        # If the null hypothesis upper_bound_metric !>= lower_bound_metric
        # cannot be rejected, terminate and return the loose bounds
        pval = pvalue(lower_bound_metric, upper_bound_metric)
        if pval >= params.p_value
            @warn "Gap between upper and lower bound risk metrics is not " *
                "statistically significant (p_value=$pval), stopping newton-raphson method. " *
                "The tolerance error is $(tolerance) $P, " * 
                "while the target stopping criteria was $(params.tolerance) $P."
            break
        end

        # Evaluate metric at midpoint
        update_load!(sys_variable, elcc_loads, base_load, x_1)
        shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
        f_1 = M(shortfall)
        push!(capacities, x_1)
        push!(target_metrics , f_1)
        push!(si_metrics, SI(shortfall))
        push!(eens_metrics, EENS(shortfall))
        push!(edlc_metrics, EDLC(shortfall))

        # Stopping condition N2
        ## Return the bounds if they are within solution tolerance of each other
        if tolerance <= params.tolerance
            params.verbose && @info "Successive approximations will become only marginally different. " *
            "The iterative process (newton-raphson method) is terminated."
            break
        end

        x_n_1 = x_1

        # Tighten capacity bounds
        if val(f_1) < val(target_metric)
            lower_bound = x_1
            lower_bound_metric = f_1
        else # midpoint_metric <= target_metric
            upper_bound = x_1
            upper_bound_metric = f_1
        end
    end

    return CapacityCreditResult{typeof(params), typeof(target_metric), P}(
        target_metric,
        si_metric,
        eens_metric,
        edlc_metric, 
        Int(x_1), 
        Float64(tolerance), 
        Int.(capacities), 
        si_metrics, 
        eens_metrics, 
        edlc_metrics)
end


"The function copy_load is used to create a new instance of the SystemModel 
with the same structure as sys but with an updated Loads component"
function copy_load(sys::SystemModel{N,L,T}, load_shares::Vector{Tuple{Int,Float64}}) where {N,L,T}

    load_allocations = allocate_loads(sys.loads.keys, load_shares)

    new_loads = Loads{N,L,T}(
        sys.loads.keys, sys.loads.buses, copy(sys.loads.pd), sys.loads.qd, 
        sys.loads.pf, sys.loads.cost, sys.loads.status)

    return load_allocations, sys.loads.pd, SystemModel(
        new_loads, sys.generators, sys.storages, sys.buses, sys.branches, 
        sys.commonbranches, sys.shunts, sys.baseMVA, sys.timestamps)
end

""
function update_load!(
    sys::SystemModel, load_shares::Vector{Tuple{Int,Float64}}, 
    load_base::Matrix{Float32}, load_increase::Float64)

    load_increase_normalized = Float32(load_increase/sys.baseMVA)

    for (r, share) in load_shares
        sys.loads.pd[r, :] .= load_base[r, :] .+ share*load_increase_normalized
    end
end

""
function allocate_loads(load_keys::Vector{Int}, load_shares::Vector{Tuple{Int,Float64}})

    load_allocations = similar(load_shares, Tuple{Int,Float64})

    for (i, (name, share)) in enumerate(load_shares)
        r = findfirst(isequal(name), load_keys)
        isnothing(r) && error("$name is not a region name in the provided systems")
        load_allocations[i] = (r, share)
    end
    return sort!(load_allocations)
end

""
function pvalue(lower::T, upper::T) where {T<:ReliabilityMetric}

    vl = val(lower)
    sl = stderror(lower)

    vu = val(upper)
    su = stderror(upper)

    if iszero(sl) && iszero(su)
        result = Float64(vl ≈ vu)
    else
        # single-sided z-test with null hypothesis that (vu - vl) not > 0
        z = (vu - vl) / sqrt(su^2 + sl^2)
        result = ccdf(Normal(), z)
    end
    return result
end