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
function build_method!(pm::AbstractPowerModel, system::SystemModel, t)

    # Add Optimization and State Variables
    var_branch_indicator(pm, system)
    var_bus_voltage_on_off(pm, system)
    var_load_power_factor(pm, system, t)
    var_shunt_admittance_factor(pm, system, t)
    var_gen_power(pm, system)
    var_branch_power(pm, system)
    var_storage_power_mi(pm, system)

    objective_min_stor_load_curtailment(pm, system, t)

    # Add Constraints
    # ---------------
    con_model_voltage_on_off(pm, system)

    @inbounds for i in field(system, :ref_buses)
        con_theta_ref(pm, system, i)
    end

    @inbounds for i in assetgrouplist(topology(pm, :buses_idxs))
        con_power_balance(pm, system, i, t)
    end
    
    @inbounds for i in assetgrouplist(topology(pm, :storages_idxs))
        con_storage_state(pm, system, i)
        con_storage_complementarity_mi(pm, system, i)
        con_storage_losses(pm, system, i)
        con_storage_thermal_limit(pm, system, i)
    end

    @inbounds for i in assetgrouplist(topology(pm, :branches_idxs))
        con_ohms_yt(pm, system, i)
        con_thermal_limits(pm, system, i)
        con_voltage_angle_difference(pm, system, i)
    end
    return
end

""
function update_method!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    update_generators!(pm, system, states, t)
    update_branches!(pm, system, states, t)
    update_storages!(pm, system, states, t)
    update_buses!(pm, system, states, t)
    return pm
end

""
function update_generators!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; force_pmin::Bool=false)
    if !check_availability(field(system, :generators), field(states, :generators), t, t-1)
        @inbounds for i in field(system, :generators, :keys)
            update_var_gen_power_real(pm, system, states, i, t, force_pmin=force_pmin)
            update_var_gen_power_imaginary(pm, system, states, i, t)
        end
    end
end

""
function update_branches!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    if !check_availability(field(states, :branches), t, t-1)
        @inbounds for l in field(system, :branches, :keys)
            update_var_branch_indicator(pm, system, states, l, t)
            update_con_ohms_yt(pm, system, states, l, t)
            update_con_thermal_limits(pm, system, states, l, t)
            update_con_voltage_angle_difference(pm, system, states, l, t)
            #update_branch_voltage_magnitude_fr_on_off(pm, system, states, l, t)
            #update_branch_voltage_magnitude_to_on_off(pm, system, states, l, t)
            #update_var_branch_voltage_product_angle_on_off(pm, system, states, l, t)
        end
    end
end

""
function update_storages!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    if !check_availability(field(states, :storages), t, t-1)
        @inbounds for i in field(system, :storages, :keys)
            update_con_storage(pm, system, states, i, t)
        end
    end
end

""
function update_buses!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    @inbounds for i in field(system, :buses, :keys)
        update_var_load_power_factor(pm, system, states, i, t)
        update_var_bus_voltage_angle(pm, system, states, i, t)
        update_con_power_balance(pm, system, states, i, t)
    end
end

""
function _update_method!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; force_pmin::Bool=false)
    update_generators!(pm, system, states, t, force_pmin=force_pmin)
    update_branches!(pm, system, states, t)
    update_storages!(pm, system, states, t)
    update_buses!(pm, system, states, t)
    JuMP.optimize!(pm.model)
    return pm
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
function _update_opf!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    
    _update_topology!(pm, system, states, t)
    update_generators!(pm, system, states, t)
    update_branches!(pm, system, states, t)
    update_storages!(pm, system, states, t)
    
    for i in field(system, :buses, :keys)
        update_var_bus_voltage_angle(pm, system, states, i, t)
        update_con_power_balance_nolc(pm, system, states, i, t)
    end

    JuMP.optimize!(pm.model)
    return pm

end

"""
Optimizes the power model and update the system states based on the results of the optimization. 
The function first checks if there are any changes in the branch, storage, or generator states at time step t 
compared to the previous time step. If there are any changes, the function calls JuMP.optimize!(pm.model) 
to optimize the power model and then calls build_result!(pm, system, states, t) to update the system states. 
If there are no changes, it fills the states.plc variable with zeros.
"""
function optimize_method!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    if all(@view states.branches[:,t]) ≠ true  || all(@view states.storages[:,t]) ≠ true || sum(@view field(states, :generators)[:, t]) < length(system.generators) - 1
        JuMP.optimize!(pm.model)
        build_result!(pm, system, states, t)
    else
        fill!(states.plc, 0.0)
    end
    return
end



"Classic OPF objective function without nonlinear equations"
function objective_min_fuel_and_flow_cost(pm::AbstractPowerModel, system::SystemModel; nw::Int=1)

    gen_cost = Dict{Int, Any}()
    gen_idxs = assetgrouplist(topology(pm, :generators_idxs))

    @views for i in field(system, :generators, :keys)
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

    load_cost = Dict{Int, Any}()
    bus_load = Dict{Int, Any}()
    for i in assetgrouplist(topology(pm, :buses_idxs))
        bus_load[i] = sum((field(system, :loads, :cost)[k]*field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads)[i]); init=0)
        load_cost[i] = @expression(pm.model, bus_load[i]*(1 - var(pm, :z_demand, nw)[i]))
    end
    fd = @expression(pm.model, sum(load_cost[i] for i in assetgrouplist(topology(pm, :buses_idxs))))
    fe = @expression(pm.model, 1000*sum(field(system, :storages, :energy_rating)[i] - var(pm, :se, nw)[i] for i in field(system, :storages, :keys)))
    return @objective(pm.model, MIN_SENSE, fd + fe)
end

""
function objective_min_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1)

    load_cost = Dict{Int, Any}()
    bus_load = Dict{Int, Any}()
    @views for i in field(system, :buses, :keys)
        bus_load[i] = sum((field(system, :loads, :cost)[k]*field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads)[i]); init=0)
        load_cost[i] = @expression(pm.model, bus_load[i]*(1 - var(pm, :z_demand, nw)[i]))
    end
    return @objective(pm.model, MIN_SENSE, sum(load_cost[i] for i in field(system, :buses, :keys)))
end

""
function build_result!(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1)

    if termination_status(pm.model) == LOCALLY_SOLVED || termination_status(pm.model) == OPTIMAL
        
        plc = build_sol_values(var(pm, :z_demand, nw))
        se = build_sol_values(var(pm, :se, nw))
    
        @views for i in field(system, :buses, :keys)
            bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads_init)[i]; init=0)
            if field(states, :buses)[i,t] == 4
                states.plc[i] = bus_pd
            else
                !haskey(plc, i) && get!(plc, i, bus_pd)
                states.plc[i] = bus_pd*(1 - getindex(plc, i))
            end
        end

        @views for i in field(system, :storages, :keys)
            haskey(se, i) == false && get!(se, i, 0.0)
            states.se[i,t] = getindex(se, i)
        end
    else
        println("not solved, t=$(t), status=$(termination_status(pm.model)), branches = $(states.branches[:,t])")
        #@assert termination_status(pm.model) == OPTIMAL "A fatal error occurred"
        @views for i in field(system, :buses, :keys)
            bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads_init)[i]; init=0)
            if field(states, :buses)[i,t] == 4
                states.plc[i] = bus_pd
            else
                states.plc[i] = 0
            end
        end
    end
    return
end


"This function is used to build the results of the optimization problem for the DC Power Model. 
It first checks if the optimization problem has been solved optimally or locally, and if so, it retrieves the values 
of the variables z_demand and se from the solution and updates the corresponding fields in the states struct."
function build_result!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1)

    if termination_status(pm.model) == LOCALLY_SOLVED || termination_status(pm.model) == OPTIMAL
        
        plc = build_sol_values(var(pm, :z_demand, nw))
        se = build_sol_values(var(pm, :se, nw))
    
        @views for i in field(system, :buses, :keys)
            bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads_init)[i]; init=0)
            bus_qd = sum(field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in topology(pm, :bus_loads_init)[i]; init=0)
            if field(states, :buses)[i,t] == 4
                states.plc[i] = bus_pd
                states.qlc[i] = bus_qd
            else
                !haskey(plc, i) && get!(plc, i, bus_pd)
                states.plc[i] = bus_pd*(1 - getindex(plc, i))
                states.qlc[i] = bus_qd*(1 - getindex(plc, i))
            end
        end

        @views for i in field(system, :storages, :keys)
            haskey(se, i) == false && get!(se, i, 0.0)
            states.se[i,t] = getindex(se, i)
        end
    else
        println("not solved, t=$(t), status=$(termination_status(pm.model)), branches = $(states.branches[:,t])")
        #@assert termination_status(pm.model) == OPTIMAL "A fatal error occurred"
        @views for i in field(system, :buses, :keys)
            bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :bus_loads_init)[i]; init=0)
            if field(states, :buses)[i,t] == 4
                states.plc[i] = bus_pd
            else
                states.plc[i] = 0
            end
        end
    end
    return
end

""
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

"Build solution dictionary of active flows per branch"
function build_sol_branch_values(pm::AbstractDCPowerModel, branches::Branches)

    dict_p = sort(_IM.build_solution_values(var(pm, :p, :)))
    tuples = keys(sort(OPF.var(pm, :p, :)))
    sol = Dict{Int, Any}()

    for (l,i,j) in tuples
        k = string((l,i,j))
        if !haskey(sol, l)
            if branches.f_bus[l] == i && branches.t_bus[l] == j
                get!(sol, l, Dict{String, Any}("pf"=>dict_p[k]))
            elseif branches.f_bus[l] == j && branches.t_bus[l] == i
                get!(sol, l, Dict{String, Any}("pt"=>dict_p[k]))
            end
        elseif haskey(sol, l)
            if branches.f_bus[l] == i && branches.t_bus[l] == j
                get!(sol[l], "pf", dict_p[k])
            elseif branches.f_bus[l] == j && branches.t_bus[l] == i
                get!(sol[l], "pt", dict_p[k])
            end
        end
    end
    return sol
end

"Build solution dictionary of active flows per branch"
function build_sol_branch_values(pm::AbstractLPACModel, branches::Branches)

    dict_p = sort(_IM.build_solution_values(var(pm, :p, :)))
    dict_q = sort(_IM.build_solution_values(var(pm, :q, :)))
    sol = Dict{Int, Any}()
    tuples = keys(sort(OPF.var(pm, :p, :)))
    
    for (l,i,j) in tuples
    
        k = string((l,i,j))
        if !haskey(sol, l)
            if (branches.f_bus[l],branches.t_bus[l]) == (i,j)
                get!(sol, l, Dict{String, Any}("pf"=>dict_p[k], "qf"=>dict_q[k]))
            elseif (branches.f_bus[l],branches.t_bus[l]) == (j,i)
                get!(sol, l, Dict{String, Any}("pt"=>dict_p[k], "qt"=>dict_q[k]))
            end
    
        elseif haskey(sol, l)
            if (branches.f_bus[l],branches.t_bus[l]) == (i,j)
                get!(sol[l], "pf", dict_p[k])
                get!(sol[l], "qf", dict_q[k])
            elseif (branches.f_bus[l],branches.t_bus[l]) == (j,i)
                get!(sol[l], "pt", dict_p[k])
                get!(sol[l], "qt", dict_q[k])
            end
        end
        
    end

    return sol
end