"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (+Min Load Curtailment) formulation of the given data and returns the JuMP model
"""

"Load Minimization version of OPF"
function build_method!(pm::AbstractPowerModel, system::SystemModel, t)

    # Add Optimization and State Variables
    var_bus_voltage(pm, system)
    var_gen_power(pm, system)
    var_branch_power(pm, system)
    var_load_power_factor(pm, system, t)
    var_shunt_admittance_factor(pm, system, t)
    var_storage_power_mi(pm, system)

    objective_min_stor_load_curtailment(pm, system, t)

    # Add Constraints
    # ---------------
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

    active_buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
    active_branches = assetgrouplist(topology(pm, :branches_idxs))

    for bp in active_buspairs
        con_model_voltage(pm, bp)
        con_voltage_angle_difference(pm, bp)
    end

    for i in active_branches
        con_ohms_yt(pm, system, i)
        con_thermal_limits(pm, system, i)
    end

    return

end

"Classic OPF from PowerModels.jl."
function solve_opf(system::SystemModel, powermodel::Type, optimizer::MOI.OptimizerWithAttributes)

    model = jump_model(JuMP.AUTOMATIC, optimizer, string_names = true)
    pm = abstract_model(powermodel, OPF.Topology(system), model)
    initialize_pm_containers!(pm, system; timeseries=false)
    build_opf!(pm, system)
    JuMP.optimize!(pm.model)
    return pm
    
end

"Internal function to build classic OPF from PowerModels.jl. 
It requires internal function 'con_power_balance_nolc' since it does not have power curtailment variables."
function build_opf!(pm::AbstractPowerModel, system::SystemModel)

    # Add Optimization and State Variables
    var_bus_voltage(pm, system)
    var_gen_power(pm, system, force_pmin=true)
    var_branch_power(pm, system)
    var_storage_power_mi(pm, system)

    objective_min_fuel_and_flow_cost(pm, system)

    # Add Constraints
    # ---------------
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

    active_buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
    active_branches = assetgrouplist(topology(pm, :branches_idxs))

    for bp in active_buspairs
        con_model_voltage(pm, bp)
        con_voltage_angle_difference(pm, bp)
    end

    for i in active_branches
        con_ohms_yt(pm, system, i)
        con_thermal_limits(pm, system, i)
    end

    return

end

""
function _update_opf!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    
    _update_topology!(pm, system, states, t)

    for i in field(system, :generators, :keys)
        update_var_gen_power_real(pm, system, states, i, t, force_pmin=true)
        update_var_gen_power_imaginary(pm, system, states, i, t)
    end

    for arc in field(system, :arcs)
        update_var_branch_power_real(pm, system, states, arc, t)
        update_var_branch_power_imaginary(pm, system, states, arc, t)
    end

    for i in field(system, :buses, :keys)
        update_var_bus_voltage_angle(pm, system, states, i, t)
        update_var_bus_voltage_magnitude(pm, system, states, i, t)
        update_con_power_balance_nolc(pm, system, states, i, t)
    end
    
    for i in field(system, :storages, :keys)
        update_con_storage(pm, system, states, i, t)
    end

    for i in field(system, :branches, :keys)
        update_con_thermal_limits(pm, system, states, i, t)
        update_con_ohms_yt(pm, system, states, i, t)
    end

    for (bp,_) in field(system, :buspairs)
        update_con_voltage_angle_difference(pm, bp)
    end

    active_buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
    reset_con_model_voltage(pm, active_buspairs)
    #reset_con_voltage_angle_difference(pm, active_buspairs)

    for (bp,buspair) in topology(pm, :buspairs)
        update_var_buspair_cosine(pm, bp)
        if !ismissing(buspair)
            con_model_voltage(pm, bp)
            #con_voltage_angle_difference(pm, bp)
        end
    end

    JuMP.optimize!(pm.model)
    return pm

end

"Updates OPF formulation with Load Curtailment variables and constraints"
function update_method!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    for i in field(system, :generators, :keys)
        update_var_gen_power_real(pm, system, states, i, t)
        update_var_gen_power_imaginary(pm, system, states, i, t)
    end

    for arc in field(system, :arcs)
        update_var_branch_power_real(pm, system, states, arc, t)
        update_var_branch_power_imaginary(pm, system, states, arc, t)
    end

    for i in field(system, :buses, :keys)
        update_var_load_power_factor(pm, system, states, i, t)
        update_var_bus_voltage_angle(pm, system, states, i, t)
        update_var_bus_voltage_magnitude(pm, system, states, i, t)
        update_con_power_balance(pm, system, states, i, t)
    end
    
    for i in field(system, :storages, :keys)
        update_con_storage(pm, system, states, i, t)
    end

    for i in field(system, :branches, :keys)
        update_con_thermal_limits(pm, system, states, i, t)
        #update_con_ohms_yt(pm, system, states, i, t)
    end

    for (bp,_) in field(system, :buspairs)
        update_con_voltage_angle_difference(pm, bp)
    end

    if all(states.branches[:,t]) ≠ true || all(states.branches[:,t-1]) ≠ true
        active_buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
        active_branches = assetgrouplist(topology(pm, :branches_idxs))
        reset_con_model_voltage(pm, active_buspairs)
        #reset_con_voltage_angle_difference(pm, active_buspairs)
        reset_con_ohms_yt(pm, active_branches)
        for (bp,buspair) in topology(pm, :buspairs)
            update_var_buspair_cosine(pm, bp)
            if !ismissing(buspair)
                con_model_voltage(pm, bp)
                #con_voltage_angle_difference(pm, bp)
            end
        end
        for i in active_branches
            con_ohms_yt(pm, system, i)
        end
    end
    return
end

""
function _update_method!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; force_pmin::Bool=false)

    for i in field(system, :generators, :keys)
        update_var_gen_power_real(pm, system, states, i, t, force_pmin=force_pmin)
        update_var_gen_power_imaginary(pm, system, states, i, t)
    end

    for arc in field(system, :arcs)
        update_var_branch_power_real(pm, system, states, arc, t)
        update_var_branch_power_imaginary(pm, system, states, arc, t)
    end

    for i in field(system, :buses, :keys)
        update_var_load_power_factor(pm, system, states, i, t)
        update_var_bus_voltage_angle(pm, system, states, i, t)
        update_var_bus_voltage_magnitude(pm, system, states, i, t)
        update_con_power_balance(pm, system, states, i, t)
    end
    
    for i in field(system, :storages, :keys)
        update_con_storage(pm, system, states, i, t)
    end

    for i in field(system, :branches, :keys)
        update_con_thermal_limits(pm, system, states, i, t)
        update_con_ohms_yt(pm, system, states, i, t)
    end

    for (bp,_) in field(system, :buspairs)
        update_con_voltage_angle_difference(pm, bp)
    end

    active_buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
    #active_branches = assetgrouplist(topology(pm, :branches_idxs))
    reset_con_model_voltage(pm, active_buspairs)
    #reset_con_ohms_yt(pm, active_branches)

    for (bp,buspair) in topology(pm, :buspairs)
        update_var_buspair_cosine(pm, bp)
        if !ismissing(buspair)
            con_model_voltage(pm, bp)
        end
    end
    #for i in active_branches
        #con_ohms_yt(pm, system, i)
    #end
    return

end

"Classic OPF objective function without nonlinear equations"
function objective_min_fuel_and_flow_cost(pm::AbstractPowerModel, system::SystemModel; nw::Int=1)

    gen_cost = Dict{Int, Any}()
    gen_idxs = assetgrouplist(topology(pm, :generators_idxs))

    for i in field(system, :generators, :keys)
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

    fg = @expression(pm.model, sum(gen_cost[i] for i in eachindex(gen_idxs)))

    return JuMP.@objective(pm.model, MIN_SENSE, fg)
    
end

""
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
    for i in field(system, :buses, :keys)
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
        fill!(states.plc, 0)
    
        for i in field(system, :buses, :keys)
            bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :init_loads_nodes)[i]; init=0)
            if field(states, :buses)[i,t] == 4
                states.plc[i] = bus_pd
            else
                !haskey(plc, i) && get!(plc, i, bus_pd)
                states.plc[i] = bus_pd*(1 - getindex(plc, i))
            end
        end

        for i in field(system, :storages, :keys)
            haskey(se, i) == false && get!(se, i, 0.0)
            states.se[i,t] = getindex(se, i)
        end
    else
        println("not solved, t=$(t), status=$(termination_status(pm.model)), branches = $(states.branches[:,t])")
        #@assert termination_status(pm.model) == OPTIMAL "A fatal error occurred"

        for i in field(system, :buses, :keys)
            bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :init_loads_nodes)[i]; init=0)
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
function build_result!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1)

    if termination_status(pm.model) == LOCALLY_SOLVED || termination_status(pm.model) == OPTIMAL

        plc = build_sol_values(var(pm, :z_demand, nw))
        se = build_sol_values(var(pm, :se, nw))
        fill!(states.plc, 0)
        fill!(states.qlc, 0)

        for i in field(system, :buses, :keys)
            bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :init_loads_nodes)[i]; init=0)
            bus_qd = sum(field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k] for k in topology(pm, :init_loads_nodes)[i]; init=0)
            if field(states, :buses)[i,t] == 4
                states.plc[i] = bus_pd
                states.qlc[i] = bus_qd
            else
                !haskey(plc, i) && get!(plc, i, bus_pd)
                states.plc[i] = bus_pd*(1 - getindex(plc, i))
                states.qlc[i] = bus_qd*(1 - getindex(plc, i))
            end
        end

        for i in field(system, :storages, :keys)
            haskey(se, i) == false && get!(se, i, 0.0)
            states.se[i,t] = getindex(se, i)
        end
    else
        println("not solved, t=$(t), status=$(termination_status(pm.model)), branches = $(states.branches[:,t]), buspairs = $(topology(pm, :buspairs))")
        #@assert termination_status(pm.model) == OPTIMAL "A fatal error occurred"
        for i in field(system, :buses, :keys)
            bus_pd = sum(field(system, :loads, :pd)[k,t] for k in topology(pm, :init_loads_nodes)[i]; init=0)
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

    sol = Dict{Int, Any}()

    for key in axes(var)[1]
        sol[key] = InfrastructureModels.build_solution_values(var[key])
    end

    return sol
end

"Build solution dictionary of active flows per branch"
function build_sol_branch_values(pm::AbstractDCPowerModel, branches::Branches)

    dict_p = sort(InfrastructureModels.build_solution_values(var(pm, :p, :)))
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

    dict_p = sort(InfrastructureModels.build_solution_values(var(pm, :p, :)))
    dict_q = sort(InfrastructureModels.build_solution_values(var(pm, :q, :)))
    dict_cs = sort(InfrastructureModels.build_solution_values(var(pm, :cs, :)))
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
    
            if haskey(dict_cs, string((i,j)))
                get!(sol[l], "cs", dict_cs[string((i,j))])
            elseif haskey(dict_cs, string((j,i)))
                get!(sol[l], "cs", dict_cs[string((j,i))])
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