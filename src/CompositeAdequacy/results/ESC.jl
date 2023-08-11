struct ESC{M} <: CapacityValuationMethod{M}
    
    energy_capacity_range::Tuple{Float64,Float64}
    elcc_target::Float64
    tolerance::Float64
    loads::Vector{Tuple{Int,Float64}}
    p_value::Float64
    verbose::Bool

    function ESC{M}(
        energy_capacity_range::Tuple{Float64,Float64},
        elcc_target::Float64,
        tolerance::Float64,
        loads::Vector{Pair{Int,Float64}};
        p_value::Float64=0.05,
        verbose::Bool=false) where M

        @assert energy_capacity_range[1] >= 0.0
        @assert energy_capacity_range[2] > 0.0
        @assert elcc_target > 0.0
        @assert tolerance >= 0.0
        @assert energy_capacity_range[1] == energy_capacity_range[2]
        @assert sum(x.second for x in loads) ≈ 1.0
        @assert 0 < p_value < 1

        return new{M}(
            energy_capacity_range,
            elcc_target,
            tolerance,
            p_value,
            Tuple.(loads), 
            verbose)
    end
end

""
function assess(sys_baseline::S, sys_augmented::S, params::ESC{M}, settings::Settings, simulationspec::SimulationSpec
   ) where {N, L, T, S <: SystemModel{N,L,T}, M <: ReliabilityMetric}

   P = BaseModule.powerunits["MW"]
   sys_baseline.loads.keys ≠ sys_augmented.loads.keys && error("Systems provided do not have matching loads")

   elcc_loads, base_load, sys_variable = copy_load(sys_augmented, params.loads)
   update_load!(sys_baseline, elcc_loads, base_load, params.elcc_target)
   shortfall = first(assess(sys_baseline, simulationspec, settings, Shortfall()))
   target_metric = M(shortfall)
   si_metric = SI(shortfall)
   eens_metric = EENS(shortfall)
   edlc_metric = EDLC(shortfall)

   energy_capacities = Int[]
   target_metrics = typeof(target_metric)[]
   si_metrics = SI[]
   eens_metrics = EENS[]
   edlc_metrics = EDLC[]

   lower_bound = params.energy_capacity_range[1]
   sys_variable.storages.energy_rating[1] = lower_bound
   update_load!(sys_variable, elcc_loads, base_load, params.elcc_target)
   shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
   lower_bound_metric = M(shortfall)
   push!(energy_capacities, lower_bound)
   push!(target_metrics , lower_bound_metric)
   push!(si_metrics, SI(shortfall))
   push!(eens_metrics, EENS(shortfall))
   push!(edlc_metrics, EDLC(shortfall))

   upper_bound = params.energy_capacity_range[2]
   sys_variable.storages.energy_rating[1] = upper_bound
   shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
   upper_bound_metric = M(shortfall)
   push!(energy_capacities, upper_bound)
   push!(target_metrics , upper_bound_metric)
   push!(si_metrics, SI(shortfall))
   push!(eens_metrics, EENS(shortfall))
   push!(edlc_metrics, EDLC(shortfall))
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
        sys_variable.storages.energy_rating[1] = x_1
        shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
        f_1 = M(shortfall)
        push!(energy_capacities, x_1)
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
        Float64.(energy_capacities), 
        si_metrics, 
        eens_metrics, 
        edlc_metrics)
end