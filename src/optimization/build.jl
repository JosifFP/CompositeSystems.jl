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
    var_load_curtailment(pm, system, t)
    var_storage_power_mi(pm, system)

    objective_min_stor_load_curtailment(pm, system)

    # Add Constraints
    # ---------------
    for i in field(system, :ref_buses)
        con_theta_ref(pm, system, i)
    end

    for i in assetgrouplist(topology(pm, :loads_idxs))
        con_power_factor(pm, system, i)
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

    model = jump_model(JuMP.AUTOMATIC, optimizer)
    pm = abstract_model(powermodel, OPF.Topology(system), model)
    initialize_pm_containers!(pm, system; timeseries=false)
    build_opf!(pm, system)
    optimize_method!(pm)
    return pm
    
end

"Internal function to build classic OPF from PowerModels.jl. 
It requires internal function 'con_power_balance_nolc' since it does not have power curtailment variables."
function build_opf!(pm::AbstractPowerModel, system::SystemModel)

    # Add Optimization and State Variables
    var_bus_voltage(pm, system)
    var_gen_power(pm, system)
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
function update_opf!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
    
    _update_topology!(pm, system, states, t)

    for i in field(system, :generators, :keys)
        update_var_gen_power_real(pm, system, states, i, t)
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
    end

    active_buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
    active_branches = assetgrouplist(topology(pm, :branches_idxs))

    reset_con_model_voltage(pm, active_buspairs)
    reset_con_ohms_yt(pm, active_branches)
    #reset_con_voltage_angle_difference(pm, active_buspairs)

    for (bp,buspair) in topology(pm, :buspairs)
        update_var_buspair_cosine(pm, bp)
        update_con_voltage_angle_difference(pm, bp)
        if !ismissing(buspair)
            con_model_voltage(pm, bp)
        end
    end

    for i in active_branches
        con_ohms_yt(pm, system, i)
    end

    optimize_method!(pm)
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

    for i in field(system, :loads, :keys)
        update_var_load_curtailment_real(pm, system, states, i, t)
        update_var_load_curtailment_imaginary(pm, system, states, i, t)
    end

    for i in field(system, :buses, :keys)
        update_var_bus_voltage_angle(pm, system, states, i, t)
        update_var_bus_voltage_magnitude(pm, system, states, i, t)
        update_con_power_balance(pm, system, states, i, t)
    end
    
    for i in field(system, :storages, :keys)
        update_con_storage(pm, system, states, i, t)
    end

    for i in field(system, :branches, :keys)
        update_con_thermal_limits(pm, system, states, i, t)
    end

    if all(states.branches[:,t]) ≠ true || all(states.branches[:,t-1]) ≠ true
        
        active_buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
        active_branches = assetgrouplist(topology(pm, :branches_idxs))
    
        reset_con_model_voltage(pm, active_buspairs)
        reset_con_ohms_yt(pm, active_branches)
        #reset_con_voltage_angle_difference(pm, active_buspairs)
    
        for (bp,buspair) in topology(pm, :buspairs)
            update_var_buspair_cosine(pm, bp)
            #update_con_voltage_angle_difference(pm, bp)
            if !ismissing(buspair)
                con_model_voltage(pm, bp)
            end
        end
        
        for i in active_branches
            con_ohms_yt(pm, system, i)
        end
    end

    return

end

function _update_method!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    for i in field(system, :generators, :keys)
        update_var_gen_power_real(pm, system, states, i, t)
        update_var_gen_power_imaginary(pm, system, states, i, t)
    end

    for arc in field(system, :arcs)
        update_var_branch_power_real(pm, system, states, arc, t)
        update_var_branch_power_imaginary(pm, system, states, arc, t)
    end

    for i in field(system, :loads, :keys)
        update_var_load_curtailment_real(pm, system, states, i, t)
        update_var_load_curtailment_imaginary(pm, system, states, i, t)
    end

    for i in field(system, :buses, :keys)
        update_var_bus_voltage_angle(pm, system, states, i, t)
        update_var_bus_voltage_magnitude(pm, system, states, i, t)
        update_con_power_balance(pm, system, states, i, t)
    end
    
    for i in field(system, :storages, :keys)
        update_con_storage(pm, system, states, i, t)
    end

    for i in field(system, :branches, :keys)
        update_con_thermal_limits(pm, system, states, i, t)
    end

    if  all(view(states.branches,:,t)) ≠ true
        
        active_buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
        active_branches = assetgrouplist(topology(pm, :branches_idxs))
    
        reset_con_model_voltage(pm, active_buspairs)
        reset_con_ohms_yt(pm, active_branches)
        #reset_con_voltage_angle_difference(pm, active_buspairs)
    
        for (bp,buspair) in topology(pm, :buspairs)
            update_var_buspair_cosine(pm, bp)
            #update_con_voltage_angle_difference(pm, bp)
            if !ismissing(buspair)
                con_model_voltage(pm, bp)
            end
        end
    
        for i in active_branches
            con_ohms_yt(pm, system, i)
        end
    end

    return

end

"Classic OPF objective function without nonlinear equations"
function objective_min_fuel_and_flow_cost(pm::AbstractPowerModel, system::SystemModel; nw::Int=1)

    gen_cost = Dict{Int, Any}()
    gen_idxs = assetgrouplist(topology(pm, :generators_idxs))

    for i in system.generators.keys
        cost = reverse(system.generators.cost[i])
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
function objective_min_gen_stor_load_curtailment(pm::AbstractPowerModel, system::SystemModel; nw::Int=1)

    gen_cost = Dict{Int, Any}()
    gen_idxs = assetgrouplist(topology(pm, :generators_idxs))

    for i in system.generators.keys
        cost = field(system, :generators, :cost)[i]
        pg = var(pm, :pg, nw)[i]
        if length(cost) == 1
            gen_cost[i] = @expression(pm.model, cost[1])
        elseif length(cost) == 2
            gen_cost[i] = @expression(pm.model, cost[1]*pg + cost[2])
        elseif length(cost) == 3

            gen_cost[i] = @expression(pm.model, cost[1]*0.0 + cost[2]*pg + cost[3])

            # This linearization is not supported by Gurobi, due to RotatedSecondOrderCone.
            # pmin = field(system, :generators, :pmin)[i]
            # pmax = field(system, :generators, :pmax)[i]
            # pg_sqr_ub = max(pmin^2, pmax^2)
            # pg_sqr_lb = 0.0
            # if pmin > 0.0
            #     pg_sqr_lb = pmin^2
            # end
            # if pmax < 0.0
            #     pg_sqr_lb = pmax^2
            # end
            #pg_sqr = @variable(pm.model, lower_bound = pg_sqr_lb, upper_bound = pg_sqr_ub, start = 0.0)
            #@constraint(pm.model, [0.5, pg_sqr, pg] in JuMP.RotatedSecondOrderCone())
            #gen_cost[i] = @expression(pm.model,cost[1]*pg_sqr + cost[2]*pg + cost[3])

        else
            #@error("Nonlinear problems not supported. Length=$(length(cost)), $(cost)")
            gen_cost[i] = 0.0
        end
    end

    stor_cost = minimum(system.loads.cost)*0.5
    fg = @expression(pm.model, sum(gen_cost[i] for i in eachindex(gen_idxs)))
    fe = @expression(pm.model, stor_cost*sum(field(system, :storages, :energy_rating)[i] - var(pm, :se, nw)[i] for i in field(system, :storages, :keys)))
    fd = @expression(pm.model, sum(field(system, :loads, :cost)[i]*var(pm, :plc, nw)[i] for i in field(system, :loads, :keys)))
    
    @objective(pm.model, MIN_SENSE, fg+fd+fe)
    
end

""
function objective_min_stor_load_curtailment(pm::AbstractPowerModel, system::SystemModel; nw::Int=1)

    fe = @expression(pm.model, 1000*sum(field(system, :storages, :energy_rating)[i] - var(pm, :se, nw)[i] for i in field(system, :storages, :keys)))
    fd = @expression(pm.model, sum(field(system, :loads, :cost)[i]*var(pm, :plc, nw)[i] for i in field(system, :loads, :keys)))
    return @objective(pm.model, MIN_SENSE, fd+fe)
    
end

""
function objective_min_load_curtailment(pm::AbstractPowerModel, system::SystemModel; nw::Int=1)

    fd = @expression(pm.model, sum(field(system, :loads, :cost)[i]*var(pm, :plc, nw)[i] for i in field(system, :loads, :keys)))
    return @objective(pm.model, MIN_SENSE, fd)
    
end

function optimize_method!(pm::AbstractPowerModel)

    #optimize!(model; ignore_optimize_hook = true)
    _ = JuMP.optimize!(pm.model)
    #_ = optimize!(pm.model; ignore_optimize_hook = true)
    return
end

""
function build_result!(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1)

    plc = build_sol_values(var(pm, :plc, nw))
    se = build_sol_values(var(pm, :se, nw))

    if termination_status(pm.model) == LOCALLY_SOLVED || termination_status(pm.model) == OPTIMAL
        for i in field(system, :loads, :keys)
            if haskey(plc, i) == false
                println("hello")
                get!(plc, i, field(system, :loads, :pd)[i,t])
            end
            states.plc[i,t] = abs.(getindex(plc, i))
        end
        for i in field(system, :storages, :keys)
            if haskey(se, i) == false
                get!(se, i, 0.0)
            end
            states.se[i,t] = getindex(se, i)
        end
        #if sum(states.plc[:,t]) > 0
        #    println("t=$(t), plc = $(states.plc[:,t])")
        #end
        #if sum(states.plc[:,t]) > 0
        #    active_buspairs = [k for (k,v) in topology(pm, :buspairs) if ismissing(v) == false]
        #    arcs = filter(!ismissing, skipmissing(topology(pm, :arcs)))
        #    pg = sum(values(build_sol_values(var(pm, :pg, nw))))
        #    println("t=$(t), plc = $(states.plc[:,t]), branches = $(states.branches[:,t]), pg = $(pg)")  
        #end
    else
        println("not solved, t=$(t), status=$(termination_status(pm.model))")        
    end
    return

end

""
function build_result!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1)

    plc = build_sol_values(var(pm, :plc, nw))
    qlc = build_sol_values(var(pm, :qlc, nw))
    se = build_sol_values(var(pm, :se, nw))

    if termination_status(pm.model) == LOCALLY_SOLVED || termination_status(pm.model) == OPTIMAL
        for i in field(system, :loads, :keys)
            if haskey(plc, i) == false
                get!(plc, i, field(system, :loads, :pd)[i,t])
            end
            if haskey(qlc, i) == false
                get!(qlc, i, field(system, :loads, :pd)[i,t]*field(system, :loads, :pf)[i])
            end
            states.plc[i,t] = abs.(getindex(plc, i))
            states.qlc[i,t] = abs.(getindex(qlc, i))
        end
        for i in field(system, :storages, :keys)
            if haskey(se, i) == false
                get!(se, i, 0.0)
            end
            states.se[i,t] = getindex(se, i)
        end
        #if sum(states.plc[:,t]) > 0  println("t=$(t), PLC = $(sum(states.plc[:,t]))")  end
    else
        println("not solved, t=$(t), status=$(termination_status(pm.model))")        
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