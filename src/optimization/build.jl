"Constructor for an AbstractPowerModel modeling object"
function abstract_model(system::SystemModel, settings::Settings)
    
    @assert settings.jump_modelmode == JuMP.AUTOMATIC "A fatal error occurred. 
        Please use JuMP.AUTOMATIC, mode $(settings.jump_modelmode) is not supported."

    jump_model = Model(settings.optimizer; add_bridges = false)
    JuMP.set_string_names_on_creation(jump_model, settings.set_string_names_on_creation)
    JuMP.set_silent(jump_model)
    topology = Topology(system)
    powermodel_formulation = pm(jump_model, topology, settings.powermodel_formulation)
    initialize_pm_containers!(powermodel_formulation, system)
    return powermodel_formulation
end

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
function build_problem!(pm::AbstractPowerModel, system::SystemModel, t)

    # Add Optimization and State Variables
    var_branch_indicator(pm, system)
    var_bus_voltage_on_off(pm, system)
    var_load_power_factor(pm, system)
    var_shunt_admittance_factor(pm, system)
    var_gen_power(pm, system)
    var_branch_power(pm, system)
    var_storage_power_mi(pm, system)

    objective_min_stor_load_curtailment(pm, system, t)

    # Add Constraints
    # ---------------
    con_model_voltage_on_off(pm, system)

    for i in field(system, :ref_buses)
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

""
function update_problem!(
    pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int; force_pmin::Bool=false)

    update_generators!(pm, system, states, t, force_pmin=force_pmin)
    update_branches!(pm, system, states, t)
    update_shunts!(pm, system, states, t)
    update_storages!(pm, system, states, t)
    update_buses!(pm, system, states, t)
    objective_min_stor_load_curtailment(pm, system, t)
    return pm
end

""
function update_generators!(
    pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int; force_pmin::Bool=false)

    if !check_availability(states.generators, t, t-1)
        for i in field(system, :generators, :keys)
            update_var_gen_power_real(pm, system, states, i, t, force_pmin=force_pmin)
            update_var_gen_power_imaginary(pm, system, states, i, t)
        end
    end

end

""
function update_branches!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int)
    if !check_availability(states.branches, t, t-1)
        for i in field(system, :branches, :keys)
            update_var_branch_indicator(pm, system, states, i, t)
            update_con_ohms_yt(pm, system, states, i, t)
            update_con_thermal_limits(pm, system, states, i, t)
            update_con_voltage_angle_difference(pm, system, states, i, t)
        end
    end
end

""
function update_shunts!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int)
    if !check_availability(states.shunts, t, t-1) || !check_availability(states.branches, t, t-1)
        for i in field(system, :shunts, :keys)
            update_var_shunt_admittance_factor(pm, system, states, i, t)
        end
    end
end

""
function update_storages!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int)
    for i in field(system, :storages, :keys)
        update_con_storage_state(pm, system, states, i, t)
        if !check_availability(states.storages, t, t-1)
            update_var_storage_charge(pm, system, states, i, t)
            update_var_storage_discharge(pm, system, states, i, t)
        end
    end
end

""
function update_buses!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int)  
    for i in field(system, :buses, :keys)
        update_con_power_balance(pm, system, states, i, t)
        if !check_availability(states.buses, t, t-1)
            update_var_load_power_factor(pm, system, states, i, t)
            update_var_bus_voltage_angle(pm, system, states, i, t)
        end
    end
end

"Classic OPF from _PM.jl."
function solve_opf(system::SystemModel, settings::Settings)

    pm = abstract_model(system, settings)
    build_opf!(pm, system)
    JuMP.optimize!(pm.model)
    return pm
end

"Internal function to build classic OPF from _PM.jl. It requires internal function 
'con_power_balance_nolc' since it does not have power curtailment variables."
function build_opf!(pm::AbstractPowerModel, system::SystemModel)

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

    for i in field(system, :ref_buses)
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

""
function _update_opf!(
    pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, settings::Settings, t::Int)
    
    update_topology!(pm, system, states, settings, t)

    for i in field(system, :generators, :keys)
        update_var_gen_power_real(pm, system, states, i, t, force_pmin=true)
        update_var_gen_power_imaginary(pm, system, states, i, t)
    end
    for l in field(system, :branches, :keys)
        update_var_branch_indicator(pm, system, states, l, t)
        update_con_ohms_yt(pm, system, states, l, t)
        update_con_thermal_limits(pm, system, states, l, t)
        update_con_voltage_angle_difference(pm, system, states, l, t)
    end
    for i in field(system, :storages, :keys)
        update_con_storage_state(pm, system, states, i, t)
    end

    for i in field(system, :buses, :keys)
        update_var_bus_voltage_angle(pm, system, states, i, t)
        update_con_power_balance_nolc(pm, system, states, i, t)
    end

    JuMP.optimize!(pm.model)
    return pm
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
function objective_min_stor_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1)

    exp_load_stor = Dict{Int, Any}()
    z_demand   = var(pm, :z_demand, nw)
    z_stor   = var(pm, :stored_energy, nw)

    for i in assetgrouplist(topology(pm, :buses_idxs))

        bus_load = topology(pm, :bus_loads)[i]
        bus_storage = topology(pm, :bus_storages)[i]

        bus_load_cost = Dict{Int, Any}(k => field(system, :loads, :cost)[k]*field(system, :loads, :pd)[k,t] for k in bus_load)
        bus_stor_rating = Dict{Int, Any}(k => field(system, :storages, :energy_rating)[k] for k in bus_storage)

        exp_load_stor[i] = @expression(pm.model, 
        sum(bus_load_cost[a] for a in bus_load)*(1 - z_demand[i]) +
        sum(bus_stor_rating[a]-z_stor[a] for a in bus_storage)
        )
    end

    return @objective(pm.model, MIN_SENSE, 
        sum(exp_load_stor[i] for i in assetgrouplist(topology(pm, :buses_idxs))))

end

""
function objective_min_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1)

    load_cost = Dict{Int, Any}()
    bus_load = Dict{Int, Any}()
    for i in field(system, :buses, :keys)
        bus_load[i] = sum((field(system, :loads, :cost)[k] for k in topology(pm, :bus_loads)[i]); init=0)
        load_cost[i] = @expression(pm.model, bus_load[i]*(1 - var(pm, :z_demand, nw)[i]))
    end
    return @objective(pm.model, MIN_SENSE, sum(load_cost[i] for i in field(system, :buses, :keys)))
end

"This function is used to build the results of the optimization problem for the DC Power Model. 
It first checks if the optimization problem has been solved optimally or locally, and if so, 
it retrieves the values of the variables z_demand and stored_energy from the solution and updates 
the corresponding fields in the states struct."
function build_result!(
    pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, settings::Settings, 
    t::Int; nw::Int=1, changes::Bool=true)

    is_solved = any([
        JuMP.termination_status(pm.model) == JuMP.LOCALLY_SOLVED, 
        JuMP.termination_status(pm.model) == JuMP.OPTIMAL]) # Check if the problem was solved optimally or locally

    all([changes, !is_solved]) && println(
        "not solved, t=$(t), status=$(termination_status(pm.model)), changes = $(changes)")

    settings.record_branch_flow == true && fill_flow_branch!(pm, system, states, t, is_solved=is_solved)
    fill_curtailed_load!(pm, system, states, t, is_solved=is_solved)
    fill_stored_energy!(pm, system, states, t, is_solved=is_solved)
    return
end