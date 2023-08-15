"""
    EESC{M} <: CapacityValuationMethod{M}

Represents the Energy Storage Capacity valuation method parameters.

This structure captures essential parameters for assessing energy storage capacity credit.
It details the energy capacity range, the power capacity of the storage, and the specific energy storage device key.
Furthermore, it also includes the target for Effective Load Carrying Capability (ELCC), the desired solution tolerance,
the significance level for statistical tests, and the load scaling information for different scenarios.

## Fields:
- `energy_capacity_range`: The minimum and maximum energy capacity values for consideration.
- `power_capacity`: The power capacity of the storage.
- `storage_key`: The specific key identifier for the energy storage device.
- `elcc_target`: The target value for Effective Load Carrying Capability (ELCC).
- `tolerance`: The desired solution tolerance for the iterative process.
- `p_value`: The significance level for statistical tests.
- `loads`: A vector detailing the load scaling information for various scenarios.
- `verbose`: A flag indicating if detailed log outputs should be displayed.

## Constructor:
The EESC constructor asserts the validity of its input parameters and provides default values for the tolerance,
significance level, and verbosity.
"""
struct EESC{M} <: CapacityValuationMethod{M}
    
    energy_capacity_range::Tuple{Float64,Float64}
    power_capacity::Float64
    storage_key::Int
    elcc_target::Int
    tolerance::Float64
    p_value::Float64
    loads::Vector{Tuple{Int,Float64}}
    verbose::Bool

    function EESC{M}(
        energy_capacity_range::Tuple{Float64,Float64},
        power_capacity::Float64,
        storage_key::Int,
        elcc_target::Int,
        loads::Vector{Pair{Int,Float64}};
        tolerance::Float64=1e-3,
        p_value::Float64=0.05,
        verbose::Bool=false) where M

        @assert energy_capacity_range[1] >= 0.0
        @assert energy_capacity_range[2] > 0.0
        @assert power_capacity > 0.0
        @assert storage_key > 0
        @assert elcc_target > 0
        @assert tolerance >= 0.0
        @assert energy_capacity_range[1] != energy_capacity_range[2]
        @assert sum(x.second for x in loads) ≈ 1.0
        @assert 0 < p_value < 1

        return new{M}(
            energy_capacity_range,
            power_capacity,
            storage_key,
            elcc_target,
            tolerance,
            p_value,
            Tuple.(loads), 
            verbose)
    end
end


"""
    assess(sys_transmission_solved::S, sys_storage_augmented::S, params::EESC{M}, settings::Settings, simulationspec::SimulationSpec)
        where {N, L, T, S <: SystemModel{N,L,T}, M <: ReliabilityMetric}

Assess the capacity credit of a system using the Newton-Raphson iterative method.

This function evaluates the capacity credit, a measure of the capacity contribution of a system configuration to 
maintain reliability. The assessment process utilizes a Newton-Raphson iterative method to find the optimal 
energy capacity that achieves a target metric value.

## Parameters:
- `sys_transmission_solved`: The transmission system configuration.
- `sys_storage_augmented`: The system configuration with energy storage devices.
- `params`: Parameters for the capacity valuation method (EESC).
- `settings`: General settings for the assessment.
- `simulationspec`: Specifications for the simulation process.

## Returns:
- `CapacityCreditResult`: A structured result capturing the assessed capacity credit, its associated metrics, 
  and error tolerances.
"""
function assess(
    sys_transmission_solved::S, 
    sys_storage_augmented::S, 
    params::EESC{M}, 
    settings::Settings, 
    simulationspec::SimulationSpec
    ) where {N, L, T, S <: SystemModel{N,L,T}, M <: ReliabilityMetric}

    P = BaseModule.powerunits["MW"]
    E = BaseModule.energyunits["MWh"]
    sys_transmission_solved.loads.keys ≠ sys_storage_augmented.loads.keys && error(
        "Systems provided do not have matching loads")

    length(sys_storage_augmented.storages) == 0 && error(
        "Systems provided do not have energy storage devices")
    
    # Calculate target metrics for the base system
    sys = deepcopy(sys_transmission_solved)
    elcc_loads, base_load, sys_variable = copy_load(sys_storage_augmented, params.loads)
    update_load!(sys_variable, elcc_loads, base_load, Float64(params.elcc_target))
    
    #TARGET INDEX
    update_load!(sys, elcc_loads, base_load, Float64(params.elcc_target))
    shortfall = first(assess(sys, simulationspec, settings, Shortfall()))
    target_metric = M(shortfall)
    si_metric = SI(shortfall)
    eens_metric = EENS(shortfall)
    edlc_metric = EDLC(shortfall)
    @info("si_metric=$(CompositeAdequacy.val(CompositeAdequacy.SI(shortfall)))")

    energy_capacities = Int[]
    target_metrics = typeof(target_metric)[]
    si_metrics = SI[]
    eens_metrics = EENS[]
    edlc_metrics = EDLC[]

    # Calculate target metrics for the lower bound energy capacity
    lower_bound = params.energy_capacity_range[2]
    sys_variable.storages.energy_rating[params.storage_key] = lower_bound/100
    shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
    lower_bound_metric = M(shortfall)
    push!(energy_capacities, lower_bound)
    push!(target_metrics , lower_bound_metric)
    push!(si_metrics, SI(shortfall))
    push!(eens_metrics, EENS(shortfall))
    push!(edlc_metrics, EDLC(shortfall))
    params.verbose && @info("lower_bound_metric=$(CompositeAdequacy.val(CompositeAdequacy.SI(shortfall)))")

    # Calculate target metrics for the upper bound energy capacity
    upper_bound = params.energy_capacity_range[1]
    sys_variable.storages.energy_rating[params.storage_key] = upper_bound/100
    shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
    upper_bound_metric = M(shortfall)
    push!(energy_capacities, upper_bound)
    push!(target_metrics , upper_bound_metric)
    push!(si_metrics, SI(shortfall))
    push!(eens_metrics, EENS(shortfall))
    push!(edlc_metrics, EDLC(shortfall))
    params.verbose && @info("upper_bound_metric=$(CompositeAdequacy.val(CompositeAdequacy.SI(shortfall)))")

    # Check if the target metric falls within the bounds
    if val(target_metric) >= val(lower_bound_metric) && val(target_metric) <= val(upper_bound_metric)
        params.verbose && @info(
            "target_metric=$(val(target_metric)), lower_bound_metric=$(val(lower_bound_metric)), "*
            "upper_bound_metric=$(val(upper_bound_metric))")
    else
        error("Choose a different energy_capacity_range! "*
            "target_metric=$(val(target_metric)), lower_bound_metric=$(val(lower_bound_metric)), "*
            "upper_bound_metric=$(val(upper_bound_metric))")
    end
    
    x_1 = x_n_1 = f_1 = tolerance = 0

    while true
    
        params.verbose && @info(
            "\n$(lower_bound) $P\t< Energy Capacity $(E) <\t$(upper_bound) $P\n",
            "$(lower_bound_metric)\t< $(target_metric) <\t$(upper_bound_metric)")

        #the tangent of f(x) at x0 to improve on the estimate of the root (x1)
        #gradient
        gradient = (val(upper_bound_metric) - val(lower_bound_metric)) / (upper_bound - lower_bound)
        x_1 = div((val(target_metric) - val(lower_bound_metric)) + gradient*lower_bound, gradient)
        x_n = x_1
        tolerance = abs(val(target_metric) - val(f_1))

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

        if abs(x_n - x_n_1) > 0
            # Evaluate metric at midpoint
            sys_variable.storages.energy_rating[1] = x_1/100
            shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
            f_1 = M(shortfall)
            push!(energy_capacities, x_1)
            push!(target_metrics , f_1)
            push!(si_metrics, SI(shortfall))
            push!(eens_metrics, EENS(shortfall))
            push!(edlc_metrics, EDLC(shortfall))
        end

        # Stopping condition N2
        ## Return the bounds if they are within solution tolerance of each other
        if tolerance <= params.tolerance || abs(x_n - x_n_1) == 0
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

    # Construct and return the CapacityCreditResult
    return CapacityCreditResult{typeof(params), typeof(target_metric), P}(
        target_metric,
        si_metric,
        eens_metric,
        edlc_metric, 
        Int(x_1), 
        Float64(tolerance), 
        Int.(energy_capacities), 
        si_metrics, 
        eens_metrics, 
        edlc_metrics)
end