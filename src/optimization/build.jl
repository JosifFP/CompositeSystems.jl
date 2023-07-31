"Constructor for an AbstractPowerModel modeling object"
function abstract_model(system::SystemModel, settings::Settings, env::Union{Gurobi.Env, Nothing}=nothing)
    
    @assert settings.jump_modelmode == JuMP.AUTOMATIC "A fatal error occurred. 
        Please use JuMP.AUTOMATIC, mode $(settings.jump_modelmode) is not supported."

    if env !== nothing
        Gurobi.GRBsetintparam(env, "OutputFlag", 0)
        Gurobi.GRBsetintparam(env, "Presolve", 0)
        Gurobi.GRBsetintparam(env, "NonConvex", 2)
        jump_model = Model(optimizer_with_attributes(()-> Gurobi.Optimizer(env)))
        #Gurobi.GRBsetintparam(env, "Threads", nthreads)
    else
        jump_model = Model(settings.optimizer; add_bridges = false)
    end

    JuMP.set_string_names_on_creation(jump_model, settings.set_string_names_on_creation)

    JuMP.set_silent(jump_model)

    topology = Topology(system)
    
    return pm(jump_model, topology, settings.powermodel_formulation)
end

"Assign abstract type 'AbstractPowerModel'"
function pm(model::JuMP.Model, topology::Topology, ::Type{M}) where {M<:AbstractPowerModel}
    var = Dict{Symbol, AbstractArray}()
    con = Dict{Symbol, AbstractArray}()
    return M(model, topology, var, con)
end

"""
Given a JuMP model and a PowerModels network data structure, it builds an DC-OPF or AC-OPF 
(+Min Load Curtailment) formulation of the given data and returns the JuMP model. 
It constructs the power model with the given method by adding variables and constraints to the model. 
It adds optimization and state variables such as branch indicator, bus voltage, load power factor, 
shunt admittance factor, generator power, branch power, and storage power. It also adds objectives 
and constraints such as power balance, thermal limits, voltage angle difference, and storage state. 
It uses the topology() function to get the indices of the different assets in the system such as buses, 
storages, and branches, and then iterates over those indices to add the corresponding variables and 
constraints to the model.
"""
function build_problem!(pm::AbstractPowerModel, system::SystemModel; t::Int=1)

    initialize_pm_containers!(pm, system)

    # Add Optimization and State Variables
    var_branch_indicator(pm, system)
    var_bus_voltage_on_off(pm, system)
    var_load_power_factor(pm, system)
    var_shunt_admittance_factor(pm, system)
    var_gen_power(pm, system)
    var_branch_power(pm, system)
    var_storage_power_mi(pm, system)

    obj_min_stor_load_curtailment(pm, system, t)

    # Add Constraints
    # ---------------
    con_model_voltage_on_off(pm, system)

    for i in topology(pm, :ref_buses)
        con_theta_ref(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :buses_idxs))
        con_power_balance(pm, system, i, t)
    end
    
    for i in assetgrouplist(topology(pm, :storages_idxs))
        con_storage_state(pm, system, i)
        con_storage_complementarity_mi(pm, system, i)
        con_storage_losses(pm, system, i)
        con_storage_thermal_limit(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :branches_idxs))
        con_ohms_yt(pm, system, i)
        con_thermal_limits(pm, system, i)
        con_voltage_angle_difference(pm, system, i)
    end
    return
end

"""
This solve! function performs the optimization and state updating processes for a given power model and system model.
It first updates the system topology to reflect changes, such as outages. Depending on whether there are storage 
components in the system, it updates the power model accordingly and performs optimization. If the system has a 
failed state, it updates and solves the problem. Upon completion of optimization, the function checks if the 
solution is locally or globally optimal. It then records the system's branch flows, curtailed load, and stored energy 
for the current timestep based on the optimization solution's status.
"""
function solve!(
    pm::AbstractPowerModel, system::SystemModel, settings::Settings, t::Int; force::Bool=false)

    update_topology!(pm.topology, system, settings, t)
    update_problem!(pm, system, t)

    should_optimize = isempty(field(system, :storages, :keys)) ? (topology(pm, :failed_systemstate)[t] || force) : true
    
    should_optimize && JuMP.optimize!(pm.model)

    is_solved = (JuMP.termination_status(pm.model) == JuMP.LOCALLY_SOLVED) || 
                (JuMP.termination_status(pm.model) == JuMP.OPTIMAL)

    
    record_states!(pm.topology)
    record_flow_branch!(pm, system, t, is_solved=is_solved)
    record_curtailed_load!(pm, system, t, is_solved=is_solved)
    record_stored_energy!(pm, system, t, is_solved=is_solved)
    return
end

""
function update_problem_fast!(pm::AbstractPowerModel, system::SystemModel, t::Int)

    failed_now = topology(pm, :failed_systemstate)[t]
    failed_prev = t > 1 ? topology(pm, :failed_systemstate)[t-1] : false
    failed_prev2 = t > 2 ? topology(pm, :failed_systemstate)[t-2] : false

    if failed_now || failed_prev
        update_problem!(pm, system, t)
    elseif !failed_prev && failed_prev2
        update_problem_nochanges!(pm, system, t)
    end
end

""
function update_problem!(pm::AbstractPowerModel, system::SystemModel, t::Int; force_pmin::Bool=false)
    update_generators!(pm, system, force_pmin=force_pmin)
    update_branches!(pm, system)
    update_shunts!(pm, system)
    update_storages!(pm, system)
    update_buses!(pm, system, t)
    update_loads!(pm, system)
    update_obj_min_stor_load_curtailment!(pm, system, t)
end

""
function update_problem_nochanges!(pm::AbstractPowerModel, system::SystemModel, t::Int)
    for i in field(system, :storages, :keys)
        update_con_storage_state(pm, system, i)
    end
    for i in field(system, :buses, :keys)
        update_con_power_balance(pm, system, i, t)
    end
    update_obj_min_stor_load_curtailment!(pm, system, t)
end

""
function update_generators!(pm::AbstractPowerModel, system::SystemModel; force_pmin::Bool=false)

    for i in field(system, :generators, :keys)
        if !topology(pm, :generators_available)[i] || !topology(pm, :generators_pasttransition)[i]
            update_var_gen_power_real(pm, system, i, force_pmin=force_pmin)
            update_var_gen_power_imaginary(pm, system, i)
        end
    end
end

""
function update_branches!(pm::AbstractPowerModel, system::SystemModel)

    for l in field(system, :branches, :keys)
        if !topology(pm, :branches_available)[l] || !topology(pm, :branches_pasttransition)[l]
            update_var_branch_indicator(pm, system, l)
            update_con_ohms_yt(pm, system, l)
            update_con_thermal_limits(pm, system, l)
            update_con_voltage_angle_difference(pm, system, l)
        end
    end
end

""
function update_shunts!(pm::AbstractPowerModel, system::SystemModel)

    if any([topology(pm, :branches_available); topology(pm, :branches_pasttransition)].== 0)
        for i in field(system, :shunts, :keys)
            if !topology(pm, :shunts_available)[i] || !topology(pm, :shunts_pasttransition)[i]         
                update_var_shunt_admittance_factor(pm, system, i)
            end
        end
    end
end

""
function update_storages!(pm::AbstractPowerModel, system::SystemModel)

    for i in field(system, :storages, :keys)
        update_con_storage_state(pm, system, i)

        if !topology(pm, :storages_available)[i] || !topology(pm, :storages_pasttransition)[i]
            update_var_storage_charge(pm, system, i)
            update_var_storage_discharge(pm, system, i)
        end
    end
end

""
function update_buses!(pm::AbstractPowerModel, system::SystemModel, t::Int)

    for i in field(system, :buses, :keys)
        update_con_power_balance(pm, system, i, t)
        
        if !topology(pm, :buses_available)[i] || !topology(pm, :buses_pasttransition)[i]
            update_var_bus_voltage_angle(pm, system, i)
        end
    end
end

""
function update_loads!(pm::AbstractPowerModel, system::SystemModel)
    for i in field(system, :loads, :keys)
        if !topology(pm, :loads_available)[i] || !topology(pm, :loads_pasttransition)[i]
            update_var_load_power_factor(pm, system, i)
        end
    end
end

"Classic OPF from _PM.jl."
function solve_opf!(system::SystemModel, settings::Settings)

    pm = abstract_model(system, settings)
    build_opf!(pm, system)
    JuMP.optimize!(pm.model)
    return pm
end

"Internal function to build classic OPF from _PM.jl. It requires internal function 
'con_power_balance_nolc' since it does not have power curtailment variables."
function build_opf!(pm::AbstractPowerModel, system::SystemModel)

    initialize_pm_containers!(pm, system)
    
    # Add Optimization and State Variables
    JuMP.set_string_names_on_creation(pm.model, true)
    var_branch_indicator(pm, system)
    var_bus_voltage_on_off(pm, system)
    var_gen_power(pm, system, force_pmin=true)
    var_branch_power(pm, system)
    var_storage_power_mi(pm, system)

    objective_min_fuel_and_flow_cost(pm, system)

    # Add Constraints
    # ---------------
    con_model_voltage_on_off(pm, system)

    for i in topology(pm, :ref_buses)
        con_theta_ref(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :buses_idxs))
        con_power_balance_nolc(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :storages_idxs))
        con_storage_state(pm, system, i) # Model only considers initial stored energy (1 period).
        con_storage_complementarity_mi(pm, system, i)
        con_storage_losses(pm, system, i)
        con_storage_thermal_limit(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :branches_idxs))
        con_ohms_yt(pm, system, i)
        con_thermal_limits(pm, system, i)
        con_voltage_angle_difference(pm, system, i)
    end
    return
end

"Classic OPF objective function without nonlinear equations"
function objective_min_fuel_and_flow_cost(pm::AbstractPowerModel, system::SystemModel; nw::Int=1)

    gen_cost = Dict{Int, Any}()
    gen_idxs = assetgrouplist(topology(pm, :generators_idxs))

    for i in gen_idxs
        cost = reverse(field(system, :generators, :cost)[i])
        pg = var(pm, :pg, nw)[i]
        if length(cost) == 1
            gen_cost[i] = @expression(pm.model, cost[1])
        elseif length(cost) == 2
            gen_cost[i] = @expression(pm.model, cost[1] + cost[2]*pg)
        elseif length(cost) == 3
            @error("Nonlinear problems are not supported")
        else
            gen_cost[i] = @expression(pm.model, 0.0)
        end
    end
    return JuMP.@objective(pm.model, MIN_SENSE, sum(gen_cost[i] for i in eachindex(gen_idxs)))
end

"""
Creates an objective function to minimize the load curtailment and energy storage usage in a power system. 
It starts by creating two dictionaries: load_cost and bus_load. The bus_load dictionary stores the total 
load cost for each bus, calculated as the sum of the product of the load cost and active power for each 
load connected to the bus. The load_cost dictionary stores an expression for the load cost for each bus, 
calculated as the product of the total load cost for the bus and the complement of the load curtailment 
variable for the bus. Then, it creates an expression fd for the total load cost, which is the sum of the 
load cost for each bus. Additionally, it creates an expression fe for the total energy storage usage, 
which is the sum of the difference between the energy rating and the state of charge for each energy 
storage unit in the system. Finally, it returns an objective function to minimize the sum of fd and fe.
"""
function obj_min_stor_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1)

    z_demand   = var(pm, :z_demand, nw)
    z_stor   = var(pm, :stored_energy, nw)
    key_loads =  field(system, :loads, :keys)
    key_stors =  field(system, :storages, :keys)
    
    load_cost = Float32[field(system, :loads, :cost)[i]*field(system, :loads, :pd)[i,t] for i in key_loads]

    load_var_cost = @expression(
        pm.model, sum(load_cost[w]*(1 - z_demand[w]) for w in key_loads; init=0))

    load_stor_cost = @expression(
        pm.model, sum(field(system, :storages, :energy_rating)[s]-z_stor[s] for s in key_stors; init=0))

    return @objective(pm.model, MIN_SENSE, load_var_cost + load_stor_cost)
end

""
function update_obj_min_stor_load_curtailment!(
    pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1)

    z_demand   = var(pm, :z_demand, nw)

    for i in field(system, :loads, :keys)

        JuMP.set_objective_coefficient(
            pm.model, 
            z_demand[i], 
            -field(system, :loads, :cost)[i]*field(system, :loads, :pd)[i,t])
    end

    MOI.modify(
        JuMP.backend(pm.model),
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarConstantChange(sum(field(system, :loads, :cost).*field(system, :loads, :pd)[:,t])))

end