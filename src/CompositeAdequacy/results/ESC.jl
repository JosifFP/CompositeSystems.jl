struct ESC{M} <: CapacityValuationMethod{M}
    
    energy_capacity_range::Tuple{Float64,Float64}
    elcc_target::Tuple{Float64,Float64}
    energy_capacity_gap::Float64
    loads::Vector{Tuple{Int,Float64}}
    p_value::Float64
    verbose::Bool

    function ESC{M}(
        energy_capacity_range::Tuple{Float64,Float64},
        elcc_target::Tuple{Float64,Float64},
        energy_capacity_gap::Float64,
        loads::Vector{Pair{Int,Float64}};
        p_value::Float64=0.05,
        verbose::Bool=false) where M

        @assert energy_capacity_range[1] >= 0.0
        @assert energy_capacity_range[2] > 0.0
        @assert elcc_target[1] > 0.0
        @assert elcc_target[2] > 0.0
        @assert energy_capacity_gap >= 0.0

        @assert energy_capacity_gap == 0.0
        @assert energy_capacity_range[1] == energy_capacity_range[2]

        @assert sum(x.second for x in loads) ≈ 1.0

        @assert 0 < p_value < 1

        return new{M}(
            energy_capacity_range,
            elcc_target,
            energy_capacity_gap,
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
   update_load!(sys_baseline, elcc_loads, base_load, params.elcc_target[1])
   shortfall = first(assess(sys_baseline, simulationspec, settings, Shortfall()))
   target_metric = M(shortfall)
   si_metric = SI(shortfall)
   eens_metric = EENS(shortfall)
   edlc_metric = EDLC(shortfall)

   energy_capacities = Int[]
   si_metrics = SI[]
   eens_metrics = EENS[]
   edlc_metrics = EDLC[]

   lower_bound = params.energy_capacity_range[1]
   sys_variable.storages.energy_rating[1] = lower_bound
   update_load!(sys_variable, elcc_loads, base_load, params.elcc_target[1])
   shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
   lower_bound_metric = M(shortfall)
   push!(energy_capacities, lower_bound)
   push!(si_metrics, SI(shortfall))
   push!(eens_metrics, EENS(shortfall))
   push!(edlc_metrics, EDLC(shortfall))

   upper_bound = params.energy_capacity_range[2]
   sys_variable.storages.energy_rating[1] = upper_bound
   shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
   upper_bound_metric = M(shortfall)
   push!(energy_capacities, upper_bound)
   push!(si_metrics, SI(shortfall))
   push!(eens_metrics, EENS(shortfall))
   push!(edlc_metrics, EDLC(shortfall))

   while true

        midpoint = div(lower_bound + upper_bound, 2)
        capacity_gap = upper_bound - lower_bound

       # Stopping conditions
       ## Return the bounds if they are within solution tolerance of each other
       if capacity_gap <= params.energy_capacity_gap
           params.verbose && @info "Capacity bound gap within tolerance, stopping bisection."
           break
       end
   
       # If the null hypothesis upper_bound_metric !>= lower_bound_metric
       # cannot be rejected, terminate and return the loose bounds
       pval = pvalue(lower_bound_metric, upper_bound_metric)
       if pval >= params.p_value
           @warn "Gap between upper and lower bound risk metrics is not " *
               "statistically significant (p_value=$pval), stopping bisection. " *
               "The gap between capacity bounds is $(capacity_gap) $P, " *
               "while the target stopping gap was $(params.energy_capacity_gap) $P."
           break
       end

       # Evaluate metric at midpoint
       sys_variable.storages.energy_rating[1] = midpoint
       shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
       midpoint_metric = M(shortfall)
       push!(energy_capacities, midpoint)
       push!(si_metrics, SI(shortfall))
       push!(eens_metrics, EENS(shortfall))
       push!(edlc_metrics, EDLC(shortfall))

       # Tighten capacity bounds
       if val(midpoint_metric) < val(target_metric)
           lower_bound = midpoint
           lower_bound_metric = midpoint_metric
       else # midpoint_metric <= target_metric
           upper_bound = midpoint
           upper_bound_metric = midpoint_metric
       end
   end
   
    return CapacityCreditResult{typeof(params), typeof(target_metric), P}(
        target_metric,
        si_metric,
        eens_metric,
        edlc_metric, 
        Float64(lower_bound), 
        Float64(upper_bound), 
        Float64.(energy_capacities), 
        si_metrics, 
        eens_metrics, 
        edlc_metrics)    
end