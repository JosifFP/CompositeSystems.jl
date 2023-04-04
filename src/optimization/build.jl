"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (+Min Load Curtailment) formulation of the given data and returns the JuMP model
It constructs the power model with the given method by adding variables and constraints to the model. 
It adds optimization and state variables such as branch indicator, bus voltage, load power factor, 
shunt admittance factor, generator power, branch power, and storage power.
It also adds objectives and constraints such as power balance, thermal limits, voltage angle difference, and storage state. 
It uses the topology() function to get the indices of the different assets in the system such as buses, storages, and branches, 
and then iterates over those indices to add the corresponding variables and constraints to the model.
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
function update_problem!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int; force_pmin::Bool=false)
    update_generators!(pm, system, states, t, force_pmin=force_pmin)
    update_branches!(pm, system, states, t)
    update_shunts!(pm, system, states, t)
    update_storages!(pm, system, states, t)
    update_buses!(pm, system, states, t)
    return pm
end

function _update_problem!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int; force_pmin::Bool=false)

    for i in field(system, :generators, :keys)
        update_var_gen_power_real(pm, system, states, i, t, force_pmin=force_pmin)
        update_var_gen_power_imaginary(pm, system, states, i, t)
    end
    for i in field(system, :branches, :keys)
        update_var_branch_indicator(pm, system, states, i, t)
        update_con_ohms_yt(pm, system, states, i, t)
        update_con_thermal_limits(pm, system, states, i, t)
        update_con_voltage_angle_difference(pm, system, states, i, t)
    end
    for i in field(system, :storages, :keys)
        update_con_storage_state(pm, system, states, i, t)
    end
    for i in field(system, :buses, :keys)
        update_var_load_power_factor(pm, system, states, i, t)
        update_var_bus_voltage_angle(pm, system, states, i, t)
        update_con_power_balance(pm, system, states, i, t)
    end
    return pm
end

""
function update_generators!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int; force_pmin::Bool=false)
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
        #if !check_availability(states.storages, t, t-1)
            #update_var_storage_charge(pm, system, states, i, t)
            #update_var_storage_discharge(pm, system, states, i, t)
        #end
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

"Internal function to build classic OPF from _PM.jl. 
It requires internal function 'con_power_balance_nolc' since it does not have power curtailment variables."
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
function _update_opf!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, settings::Settings, t::Int)
    
    _update_topology!(pm, system, states, settings, t)

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
It starts by creating two dictionaries: load_cost and bus_load. The bus_load dictionary stores the total load cost for each bus, 
calculated as the sum of the product of the load cost and active power for each load connected to the bus. The load_cost dictionary 
stores an expression for the load cost for each bus, calculated as the product of the total load cost for the bus and the complement 
of the load curtailment variable for the bus. Then, it creates an expression fd for the total load cost, which is the sum of the load 
cost for each bus. Additionally, it creates an expression fe for the total energy storage usage, which is the sum of the difference 
between the energy rating and the state of charge for each energy storage unit in the system. 
Finally, it returns an objective function to minimize the sum of fd and fe.
"""
function objective_min_stor_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1)

    bus_loads = Dict{Int, Any}()
    load_cost = Dict{Int, Any}()
    se_left = Dict{Int, Any}()
    rescale = 1.0

    if log10(maximum(system.loads.cost)) > 3
        rescale = 10^(-modf(log10(maximum(system.loads.cost)))[2]+2)
    end

    for i in assetgrouplist(topology(pm, :buses_idxs))
        bus_loads[i] = sum((field(system, :loads, :cost)[k]*field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads)[i]); init=0)
        load_cost[i] = rescale*JuMP.@expression(pm.model, bus_loads[i]*(1 - var(pm, :z_demand, nw)[i]))
        se_left[i] = sum((field(system, :storages, :energy_rating)[k] - var(pm, :stored_energy, nw)[k] for k in topology(pm, :bus_storages)[i]); init=0)
    end

    fd = @expression(pm.model, sum(load_cost[i] for i in assetgrouplist(topology(pm, :buses_idxs))))
    fe = @expression(pm.model, sum(se_left[i] for i in assetgrouplist(topology(pm, :buses_idxs))))
    return @objective(pm.model, MIN_SENSE, fd + fe)
end

""
function objective_min_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1)

    load_cost = Dict{Int, Any}()
    bus_load = Dict{Int, Any}()
    for i in field(system, :buses, :keys)
        bus_load[i] = sum((field(system, :loads, :cost)[k]*field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads)[i]); init=0)
        load_cost[i] = @expression(pm.model, bus_load[i]*(1 - var(pm, :z_demand, nw)[i]))
    end
    return @objective(pm.model, MIN_SENSE, sum(load_cost[i] for i in field(system, :buses, :keys)))
end

"This function is used to build the results of the optimization problem for the DC Power Model. 
# It first checks if the optimization problem has been solved optimally or locally, and if so, it retrieves the values 
# of the variables z_demand and stored_energy from the solution and updates the corresponding fields in the states struct."
function build_result!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, settings::Settings, t::Int; nw::Int=1, changes::Bool=true)

    is_solved = any([
        JuMP.termination_status(pm.model) == JuMP.LOCALLY_SOLVED, 
        JuMP.termination_status(pm.model) == JuMP.OPTIMAL]) # Check if the problem was solved optimally or locally

    all([changes, !is_solved]) && println("not solved, t=$(t), status=$(termination_status(pm.model)), changes = $(changes)")

    settings.record_branch_flow == true && fill_flow_branch!(pm, system, states, t, is_solved=is_solved)
    fill_curtailed_load!(pm, system, states, t, is_solved=is_solved)
    fill_stored_energy!(pm, system, states, t, is_solved=is_solved)
    return

end

""
function fill_curtailed_load!(pm::AbstractDCPowerModel, system::SystemModel, states::ComponentStates, t::Int; nw::Int=1, is_solved::Bool=true)

    if is_solved
        var = OPF.var(pm, :z_demand, nw)
        for i in field(system, :buses, :keys)
            bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads_init)[i]; init=0.0)
            if states.buses[i,t] != 4
                p_curtailed_factor = _IM.build_solution_values(var[i])
                states.p_curtailed[i] = bus_pd*(1.0 - p_curtailed_factor)
            else
                states.p_curtailed[i] = bus_pd
            end
        end
    else
        fill!(states.p_curtailed, 0.0)
    end
end

""
function fill_curtailed_load!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int; nw::Int=1, is_solved::Bool=true)

    if is_solved
        var = OPF.var(pm, :z_demand, nw)
        for i in field(system, :buses, :keys)
            bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads_init)[i]; init=0.0)
            bus_qd = sum(field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in topology(pm, :bus_loads_init)[i]; init=0)
            if states.buses[i,t] != 4
                p_curtailed_factor = _IM.build_solution_values(var[i])
                states.p_curtailed[i] = bus_pd*(1.0 - p_curtailed_factor)
                states.q_curtailed[i] = bus_qd*(1.0 - p_curtailed_factor)
            else
                states.p_curtailed[i] = bus_pd
                states.q_curtailed[i] = bus_qd
            end
        end
    else
        fill!(states.p_curtailed, 0.0)
        fill!(states.q_curtailed, 0.0)
    end
end

"Build solution dictionary of the argunment of type DenseAxisArray"
function build_sol_values(var::DenseAxisArray)

    axs =  axes(var)[1]

    if typeof(axs) == Vector{Tuple{Int, Int}}
        sol = Dict{Tuple{Int, Int}, Any}()
    elseif typeof(axs) == Vector{Int}
        sol = Dict{Int, Any}()
    else
        typeof(axs) == Union{Vector{Tuple{Int, Int}}, Vector{Int}}
    end

    for key in axs
        sol[key] = _IM.build_solution_values(var[key])
    end

    return sol
end

""
build_sol_values(var::Dict{Tuple{Int, Int, Int}, Any}) = _IM.build_solution_values(var)

"Build solution dictionary of active flows per branch"
function build_sol_values(var::Dict{Tuple{Int, Int, Int}, Any}, branches::Branches)

    dict_p = sort(_IM.build_solution_values(var))
    tuples = keys(sort(var))
    sol = Dict{Int, Any}()

    for (l,i,j) in tuples
        k = string((l,i,j))
        if !haskey(sol, l)
            if branches.f_bus[l] == i && branches.t_bus[l] == j
                get!(sol, l, Dict{String, Any}("from"=>dict_p[k])) # Active power withdrawn at the from bus
            elseif branches.f_bus[l] == j && branches.t_bus[l] == i
                get!(sol, l, Dict{String, Any}("to"=>dict_p[k])) # Active power withdrawn at the to bus
            end
        elseif haskey(sol, l)
            if branches.f_bus[l] == i && branches.t_bus[l] == j
                get!(sol[l], "from", dict_p[k])
            elseif branches.f_bus[l] == j && branches.t_bus[l] == i
                get!(sol[l], "to", dict_p[k])
            end
        end
    end
    return sol
end



""
function fill_stored_energy!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int; nw::Int=1, is_solved::Bool=true)

    for i in field(system, :storages, :keys)
        if is_solved
            var = OPF.var(pm, :stored_energy, nw)
            axs =  axes(var)[1]
            if i in axs
                states.stored_energy[i,t] = _IM.build_solution_values(var[i])
            else
                states.stored_energy[i,t] = states.stored_energy[i,t-1]
            end
        else
            states.stored_energy[i,t] = states.stored_energy[i,t-1]
        end
    end
end

""
function fill_flow_branch!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, t::Int; nw::Int=1, is_solved::Bool=true)

    if is_solved
        var = OPF.var(pm, :p, nw)
        tuples = keys(var)
        for (l,i,j) in tuples
            if states.branches[l,t] == 0
                states.flow_from[l] = 0.0
                states.flow_to[l] = 0.0
            else
                f_bus = system.branches.f_bus[l]
                t_bus = system.branches.t_bus[l]
                #k = string((l,i,j))
                if f_bus == i && t_bus == j
                    states.flow_from[l] = _IM.build_solution_values(var[(l,i,j)]) # Active power withdrawn at the from bus
                elseif f_bus == j && t_bus == i
                    states.flow_to[l] = _IM.build_solution_values(var[(l,i,j)]) # Active power withdrawn at the to bus
                end
            end
        end
    else
        fill!(states.flow_from, 0.0)
        fill!(states.flow_to, 0.0)
    end
end

""
function fill_curtailed_load!(pm::AbstractDCPowerModel, system::SystemModel, states::ComponentStates, p_curtailed_factor::Dict{Int, Any}, t::Int)
    for i in field(system, :buses, :keys)
        bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads_init)[i]; init=0.0)
        if states.buses[i,t] == 4
            states.p_curtailed[i] = bus_pd
        else
            states.p_curtailed[i] = bus_pd*(1 - get(p_curtailed_factor, i, 1.0))
        end
    end
end

""
function fill_curtailed_load!(pm::AbstractPowerModel, system::SystemModel, states::ComponentStates, p_curtailed_factor::Dict{Int, Any}, t::Int)
    for i in field(system, :buses, :keys)
        bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads_init)[i]; init=0)
        bus_qd = sum(field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in topology(pm, :bus_loads_init)[i]; init=0)
        if states.buses[i,t] == 4
            states.p_curtailed[i] = bus_pd
            states.q_curtailed[i] = bus_qd
        else
            states.p_curtailed[i] = bus_pd*(1 - get(p_curtailed_factor, i, 1.0))
            states.q_curtailed[i] = bus_qd*(1 - get(p_curtailed_factor, i, 1.0))
        end
    end
end

""
function fill_flow_branch!(system::SystemModel, states::ComponentStates, flow_branch::Dict{Int, Any}, t::Int)

    for l in field(system, :branches, :keys)
        if states.branches[l,t] == 0
            states.flow_from[l] = 0.0
            states.flow_to[l] = 0.0
        else
            flow_branch_dict = get(flow_branch, l, Dict{String, Any}("from"=>0.0, "to"=>0.0))
            states.flow_from[l] = flow_branch_dict["from"]
            states.flow_to[l] = flow_branch_dict["to"]
        end
    end
end

""
function fill_stored_energy!(storages::Storages, states::ComponentStates, stored_energy::Dict, t::Int; is_solved::Bool=true)
    for i in field(storages, :keys)
        if is_solved
            states.stored_energy[i,t] = get(stored_energy, i, 0.0)
        else
            states.stored_energy[i,t] = states.stored_energy[i,t-1]
        end
    end
end
