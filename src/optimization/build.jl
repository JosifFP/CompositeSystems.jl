"""
    abstract_model(system::SystemModel, settings::Settings, env::Union{Gurobi.Env, Nothing}=nothing)

Constructs an `AbstractPowerModel` modeling object. The function checks settings, initializes a `JuMP` model, 
and returns a power model.

# Arguments
- `system::SystemModel`: A data structure containing power system data.
- `settings::Settings`: Modeling settings and configuration parameters.
- `env::Union{Gurobi.Env, Nothing}=nothing`: Optional environment for the Gurobi optimizer.

# Returns
- An instance of an `AbstractPowerModel`.
"""

function abstract_model(system::SystemModel, settings::Settings, env::Union{Gurobi.Env, Nothing}=nothing)
    
    @assert settings.jump_modelmode === JuMP.AUTOMATIC "A fatal error occurred. 
        Please use JuMP.AUTOMATIC, mode $(settings.jump_modelmode) is not supported."

    if env !== nothing
        jump_model = Model(optimizer_with_attributes(()-> Gurobi.Optimizer(env)))
    else
        jump_model = Model(settings.optimizer; add_bridges = false)
    end

    JuMP.set_string_names_on_creation(jump_model, settings.set_string_names_on_creation)
    JuMP.set_silent(jump_model)
    topology = Topology(system)
    
    return pm(jump_model, topology, settings.powermodel_formulation)
end



"""
    pm(model::JuMP.Model, topology::Topology, ::Type{M}) where {M<:AbstractPowerModel}

Assigns the abstract type `AbstractPowerModel`. It serves as a helper to create the `AbstractPowerModel` struct 
with the necessary components.

# Arguments
- `model::JuMP.Model`: A JuMP optimization model.
- `topology::Topology`: Topological information of the power system.
- `::Type{M} where {M<:AbstractPowerModel}`: Specific type of power model to be constructed.

# Returns
- An instance of the specified type of `AbstractPowerModel`.
"""
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



"""
    update_problem!(pm::AbstractPowerModel, system::SystemModel, t::Int; force_pmin::Bool=false)

Updates components of the `AbstractPowerModel` problem based on the current system state.

This function takes the current system state and time `t` to update various components of the
power model, such as generators, branches, shunts, storages, and loads. Additionally, it can enforce
a minimum power constraint (`force_pmin`) if required.

# Arguments
- `pm::AbstractPowerModel`: The power model to be updated.
- `system::SystemModel`: The current system state.
- `t::Int`: The current time step.
- `force_pmin::Bool=false`: Optional parameter to enforce minimum power constraint.

# Usage
```julia
update_problem!(my_power_model, current_system, 5)
"""
function update_problem!(pm::AbstractPowerModel, system::SystemModel, t::Int; force_pmin::Bool=false)

    failed_now = topology(pm, :failed_systemstate)[t]
    failed_prev = t > 1 ? topology(pm, :failed_systemstate)[t-1] : false
    systemstate = failed_now || failed_prev
    
    update_generators!(pm, system, force_pmin=force_pmin)
    update_branches!(pm, system)
    update_shunts!(pm, system)
    update_storages!(pm, system)
    update_buses!(pm, system, t, loads=systemstate)
    update_loads!(pm, system)
    update_obj_min_stor_load_curtailment!(pm, system, t, loads=systemstate)
end

""
function update_generators!(pm::AbstractPowerModel, system::SystemModel; force_pmin::Bool=false)

    gen_keys = field(system, :generators, :keys)

    for i in gen_keys
        if !topology(pm, :generators_available)[i] || !topology(pm, :generators_pasttransition)[i]
            update_var_gen_power_real(pm, system, i, force_pmin=force_pmin)
            update_var_gen_power_imaginary(pm, system, i)
        end
    end
end

""
function update_branches!(pm::AbstractPowerModel, system::SystemModel)

    branch_keys = field(system, :branches, :keys)

    for l in branch_keys
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

    shunt_keys = field(system, :shunts, :keys)

    if any([topology(pm, :branches_available); topology(pm, :branches_pasttransition)].== 0)
        for i in shunt_keys
            if !topology(pm, :shunts_available)[i] || !topology(pm, :shunts_pasttransition)[i]         
                update_var_shunt_admittance_factor(pm, system, i)
            end
        end
    end
end

""
function update_storages!(pm::AbstractPowerModel, system::SystemModel)

    storage_keys = field(system, :storages, :keys)

    for i in storage_keys
        update_con_storage_state(pm, system, i)

        if !topology(pm, :storages_available)[i] || !topology(pm, :storages_pasttransition)[i]
            update_var_storage_charge(pm, system, i)
            update_var_storage_discharge(pm, system, i)
        end
    end
end

""
function update_buses!(pm::AbstractPowerModel, system::SystemModel, t::Int; loads::Bool=true)

    bus_keys = field(system, :buses, :keys)

    for i in bus_keys
        loads && update_con_power_balance(pm, system, i, t)
        
        if !topology(pm, :buses_available)[i] || !topology(pm, :buses_pasttransition)[i]
            update_var_bus_voltage_angle(pm, system, i)
        end
    end
end

""
function update_loads!(pm::AbstractPowerModel, system::SystemModel)

    load_keys = field(system, :loads, :keys)

    for i in load_keys
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
    obj_min_stor_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1)

Creates an objective function to minimize load curtailment and energy storage usage.

The function computes load curtailment and energy storage costs. It returns an objective 
function aiming at minimizing the combined costs of load curtailment and energy storage usage.

# Arguments
- `pm::AbstractPowerModel`: The power model to be updated.
- `system::SystemModel`: The current system state.
- `t::Int`: The current time step.
- `nw::Int=1`: The network number (optional).

# Usage
```julia
objective = obj_min_stor_load_curtailment(my_power_model, current_system, 5)
"""
function obj_min_stor_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1)

    z_demand   = var(pm, :z_demand, nw)
    z_stor   = var(pm, :stored_energy, nw)
    
    load_cost = Float32[
        field(system, :loads, :cost)[i]*field(system, :loads, :pd)[i,t] for i in field(system, :loads, :keys)]

    load_var_cost = @expression(pm.model, sum(
        load_cost[w] * (1 - z_demand[w]) for w in field(system, :loads, :keys)))
        
    load_stor_cost = @expression(pm.model, sum(
        field(system, :storages, :energy_rating)[s] - z_stor[s] for s in field(system, :storages, :keys)))
    
    return @objective(pm.model, MIN_SENSE, load_var_cost + load_stor_cost)
end



"""
    update_obj_min_stor_load_curtailment!(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1, loads::Bool=true)

Update the objective function coefficients for dynamic changes in loads.

# Parameters
- `pm`: The power model.
- `system`: The system model.
- `t`: Current timestep.
- `nw`: The network number (default is 1).
- `loads`: Whether to update the load coefficients (default is true).
"""
function update_obj_min_stor_load_curtailment!(
    pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1, loads::Bool=true)

    if loads
        z_demand   = var(pm, :z_demand, nw)
        for i in field(system, :loads, :keys)
            coeff_value = -field(system, :loads, :cost)[i] * field(system, :loads, :pd)[i, t]
            JuMP.set_objective_coefficient(pm.model, z_demand[i], coeff_value)
        end

        constant_shift = sum(field(system, :loads, :cost) .* field(system, :loads, :pd)[:, t])
        MOI.modify(JuMP.backend(pm.model), MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarConstantChange(constant_shift))
    end
end