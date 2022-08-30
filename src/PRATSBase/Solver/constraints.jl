###############################################################################
# This file defines commonly used constraints for power flow models

###############################################################################

"Fix the voltage angle to zero at the reference bus"
function constraint_theta_ref_bus(ref::Dict{Symbol,Any}, model::Model)
    # Fix the voltage angle to zero at the reference bus
    for i in keys(ref[:ref_buses])
        JuMP.@constraint(model, model[:va][i] == 0)
    end
end

"Nodal power balance constraints"
function constraint_nodal_power_balance(ref::Dict{Symbol,Any}, method::Type{dc_opf}, model::Model)

    # Build JuMP expressions for the value of p[(l,i,j)] and p[(l,j,i)] on the branches
    p_expr = JuMP.@expression(model, Dict([((l,i,j), 1.0*model[:p][(l,i,j)]) for (l,i,j) in ref[:arcs_from]]))
    p_expr = JuMP.@expression(model, merge(p_expr, Dict([((l,j,i), -1.0*model[:p][(l,i,j)]) for (l,i,j) in ref[:arcs_from]])))
    
    for i in keys(ref[:bus])
        # Build a list of the loads and shunt elements connected to the bus i
        bus_loads = [ref[:load][l] for l in ref[:bus_loads][i]]
        bus_shunts = [ref[:shunt][s] for s in ref[:bus_shunts][i]]
        
        JuMP.@constraint(model,
            #sum(p[a] for a in ref[:bus_arcs][i]) +
            sum(p_expr[a] for a in ref[:bus_arcs][i]) +                  # sum of active power flow on lines from bus i +
            sum(model[:p_dc][a_dc] for a_dc in ref[:bus_arcs_dc][i]) ==     # sum of active power flow on HVDC lines from bus i =
            sum(model[:pg][g] for g in ref[:bus_gens][i]) -                 # sum of active power generation at bus i -
            sum(load["pd"] for load in bus_loads) -                 # sum of active load consumption at bus i -
            sum(shunt["gs"] for shunt in bus_shunts)*1.0^2          # sum of active shunt element injections at bus i
        )
    end
end

""
function constraint_nodal_power_balance(ref::Dict{Symbol,Any}, method::Type{dc_opf_lc}, model::Model)

    # Build JuMP expressions for the value of p[(l,i,j)] and p[(l,j,i)] on the branches
    p_expr = JuMP.@expression(model, merge(Dict([((l,i,j), 1.0*model[:p][(l,i,j)]) for (l,i,j) in ref[:arcs_from]]), 
    Dict([((l,j,i), -1.0*model[:p][(l,i,j)]) for (l,i,j) in ref[:arcs_from]])))
    
    # Nodal power balance constraints  
    #####################    PG + C = PL     ########################################################
    for i in keys(ref[:bus])
        # Build a list of the loads and shunt elements connected to the bus i
        bus_loads = [ref[:load][l] for l in ref[:bus_loads][i]]
        bus_shunts = [ref[:shunt][s] for s in ref[:bus_shunts][i]]

        # Active power balance at node i
        JuMP.@constraint(model,
            #sum(p[a] for a in ref[:bus_arcs][i]) +
            sum(p_expr[a] for a in ref[:bus_arcs][i]) +                  # sum of active power flow on lines from bus i +
            sum(model[:p_dc][a_dc] for a_dc in ref[:bus_arcs_dc][i]) ==     # sum of active power flow on HVDC lines from bus i =
            sum(model[:pg][g] for g in ref[:bus_gens][i]) +                 # sum of active power generation at bus i -
            sum(model[:plc][m] for m in ref[:bus_loads][i]) -
            sum(load["pd"] for load in bus_loads) -                 # sum of active load consumption at bus i -
            sum(shunt["gs"] for shunt in bus_shunts)*1.0^2          # sum of active shunt element injections at bus i
        )
    end
end

"For AC-OPF method"
function constraint_nodal_power_balance(ref::Dict{Symbol,Any}, method::Type{ac_opf}, model::Model)

    for i in keys(ref[:bus])
        # Build a list of the loads and shunt elements connected to the bus i
        bus_loads = [ref[:load][l] for l in ref[:bus_loads][i]]
        bus_shunts = [ref[:shunt][s] for s in ref[:bus_shunts][i]]
        
        # Active power balance at node i
        JuMP.@constraint(model,
            sum(model[:p][a] for a in ref[:bus_arcs][i]) +
            sum(model[:p_dc][a_dc] for a_dc in ref[:bus_arcs_dc][i]) ==     # sum of active power flow on HVDC lines from bus i =
            sum(model[:pg][g] for g in ref[:bus_gens][i]) -                 # sum of active power generation at bus i -
            sum(load["pd"] for load in bus_loads) -                 # sum of active load consumption at bus i -
            sum(shunt["gs"] for shunt in bus_shunts)*model[:vm][i]^2        # sum of active shunt element injections at bus i
        )

        # Reactive power balance at node i
        JuMP.@constraint(model,
            sum(model[:q][a] for a in ref[:bus_arcs][i]) +
            sum(model[:q_dc][a_dc] for a_dc in ref[:bus_arcs_dc][i]) ==     # sum of reactive power flow on HVDC lines from bus i =
            sum(model[:qg][g] for g in ref[:bus_gens][i]) -                 # sum of reactive power generation at bus i -
            sum(load["qd"] for load in bus_loads) +                 # sum of reactive load consumption at bus i -
            sum(shunt["bs"] for shunt in bus_shunts)*model[:vm][i]^2        # sum of reactive shunt element injections at bus i
        )
    end

end

""
function constraint_nodal_power_balance(ref::Dict{Symbol,Any}, method::Type{ac_opf_lc}, model::Model)

    for (i,bus) in ref[:bus]
        # Build a list of the loads and shunt elements connected to the bus i
        bus_loads = [ref[:load][l] for l in ref[:bus_loads][i]]
        bus_shunts = [ref[:shunt][s] for s in ref[:bus_shunts][i]]
    
        # Active power balance at node i
        JuMP.@constraint(model,
            sum(model[:p][a] for a in ref[:bus_arcs][i]) +
            sum(model[:p_dc][a_dc] for a_dc in ref[:bus_arcs_dc][i]) ==     # sum of active power flow on HVDC lines from bus i =
            sum(model[:pg][g] for g in ref[:bus_gens][i]) +                 # sum of active power generation at bus i -
            sum(model[:plc][m] for m in ref[:bus_loads][i]) -
            sum(load["pd"] for load in bus_loads) -                 # sum of active load consumption at bus i -
            sum(shunt["gs"] for shunt in bus_shunts)*model[:vm][i]^2        # sum of active shunt element injections at bus i
        )

        # Reactive power balance at node i
        JuMP.@constraint(model,
            sum(model[:q][a] for a in ref[:bus_arcs][i]) +
            sum(model[:q_dc][a_dc] for a_dc in ref[:bus_arcs_dc][i]) ==     # sum of reactive power flow on HVDC lines from bus i =
            sum(model[:qg][g] for g in ref[:bus_gens][i]) +                 # sum of reactive power generation at bus i -
            sum(model[:qlc][m] for m in ref[:bus_loads][i]) -
            sum(load["qd"] for load in bus_loads) +                 # sum of reactive load consumption at bus i -
            sum(shunt["bs"] for shunt in bus_shunts)*model[:vm][i]^2        # sum of reactive shunt element injections at bus i
        )
    end

end

"Branch power flow physics and limit constraints"
function constraint_branch_pf_limits(ref::Dict{Symbol,Any},  method::Union{Type{dc_opf},Type{dc_opf_lc}}, model::Model)

    for (i,branch) in ref[:branch]
        # Build the from variable id of the i-th branch, which is a tuple given by (branch id, from bus, to bus)
        #f_idx = (i, branch["f_bus"], branch["t_bus"])
        p_fr = JuMP.@expression(model, model[:p][(i, branch["f_bus"], branch["t_bus"])])                    # p_fr is a reference to the optimization variable p[f_idx]
        va_fr_to = JuMP.@expression(model, model[:va][branch["f_bus"]]-model[:va][branch["t_bus"]])         # va_fr is a reference to the optimization variable va on the from side of the branch
    
        # Compute the branch parameters and transformer ratios from the data
        g, b = calc_branchs_y(branch)
    
        # DC Line Flow Constraints
        JuMP.@constraint(model, p_fr == -b*(va_fr_to))

        # Voltage angle difference limit
        JuMP.@constraint(model, va_fr_to <= branch["angmax"])
        JuMP.@constraint(model, va_fr_to >= branch["angmin"])
    end
end

""
function constraint_branch_pf_limits(ref::Dict{Symbol,Any}, method::Union{Type{ac_opf},Type{ac_opf_lc}}, model::Model)

    for (i,branch) in ref[:branch]

        #f_idx = (i, branch["f_bus"], branch["t_bus"])
        #t_idx = (i, branch["t_bus"], branch["f_bus"])

        p_fr = model[:p][(i, branch["f_bus"], branch["t_bus"])]                     # p_fr is a reference to the optimization variable p[f_idx]
        q_fr = model[:q][(i, branch["f_bus"], branch["t_bus"])]                     # q_fr is a reference to the optimization variable q[f_idx]
        p_to = model[:p][(i, branch["t_bus"], branch["f_bus"])]                     # p_to is a reference to the optimization variable p[t_idx]
        q_to = model[:q][(i, branch["t_bus"], branch["f_bus"])]                     # q_to is a reference to the optimization variable q[t_idx]
        vm_fr = model[:vm][branch["f_bus"]]         # vm_fr is a reference to the optimization variable vm on the from side of the branch
        vm_to = model[:vm][branch["t_bus"]]         # vm_to is a reference to the optimization variable vm on the to side of the branch
        va_fr = model[:va][branch["f_bus"]]         # va_fr is a reference to the optimization variable va on the from side of the branch
        va_to = model[:va][branch["t_bus"]]         # va_fr is a reference to the optimization variable va on the to side of the branch

        # Compute the branch parameters and transformer ratios from the data
        g, b = calc_branchs_y(branch)
        tr, ti = calc_branchs_t(branch)
        g_fr = branch["g_fr"]
        b_fr = branch["b_fr"]
        g_to = branch["g_to"]
        b_to = branch["b_to"]
        tm = branch["tap"]^2

        # AC Power Flow Constraints
        # From side of the branch flow
        JuMP.@NLconstraint(model, p_fr ==  (g+g_fr)/tm*vm_fr^2 + (-g*tr+b*ti)/tm*(vm_fr*vm_to*cos(va_fr-va_to)) + (-b*tr-g*ti)/tm*(vm_fr*vm_to*sin(va_fr-va_to)) )
        JuMP.@NLconstraint(model, q_fr == -(b+b_fr)/tm*vm_fr^2 - (-b*tr-g*ti)/tm*(vm_fr*vm_to*cos(va_fr-va_to)) + (-g*tr+b*ti)/tm*(vm_fr*vm_to*sin(va_fr-va_to)) )

        # To side of the branch flow
        JuMP.@NLconstraint(model, p_to ==  (g+g_to)*vm_to^2 + (-g*tr-b*ti)/tm*(vm_to*vm_fr*cos(va_to-va_fr)) + (-b*tr+g*ti)/tm*(vm_to*vm_fr*sin(va_to-va_fr)) )
        JuMP.@NLconstraint(model, q_to == -(b+b_to)*vm_to^2 - (-b*tr+g*ti)/tm*(vm_to*vm_fr*cos(va_fr-va_to)) + (-g*tr-b*ti)/tm*(vm_to*vm_fr*sin(va_to-va_fr)) )

        # Voltage angle difference limit
        JuMP.@constraint(model, va_fr - va_to <= branch["angmax"])
        JuMP.@constraint(model, va_fr - va_to >= branch["angmin"])

        # Apparent Power Limit, From and To
        if haskey(branch, "rate_a")
            JuMP.@constraint(model, model[:p][(i, branch["f_bus"], branch["t_bus"])]^2 + model[:q][(i, branch["f_bus"], branch["t_bus"])]^2 <= branch["rate_a"]^2)
            JuMP.@constraint(model, model[:p][(i, branch["t_bus"], branch["f_bus"])]^2 + model[:q][(i, branch["t_bus"], branch["f_bus"])]^2 <= branch["rate_a"]^2)
        end
    end
end

"HVDC line constraints"
function constraint_hvdc_line(ref::Dict{Symbol,Any}, model::Model)

    for (i,dcline) in ref[:dcline]
        #f_idx = (i, dcline["f_bus"], dcline["t_bus"])
        #t_idx = (i, dcline["t_bus"], dcline["f_bus"])
    
        # Constraint defining the power flow and losses over the HVDC line
        JuMP.@constraint(model, (1-dcline["loss1"])*model[:p_dc][(i, dcline["f_bus"], dcline["t_bus"])] + 
        (model[:p_dc][(i, dcline["t_bus"], dcline["f_bus"])] - dcline["loss0"]) == 0)
    end
end

"Fixed Power Factor"
function constraint_power_factor(ref::Dict{Symbol,Any}, model::Model)
    for i in keys(ref[:load])
        JuMP.@constraint(model, model[:z_demand][i]*model[:plc][i] - model[:qlc][i] == 0.0)      
    end
end

function constraint_voltage_magnitude_diff(ref::Dict{Symbol,Any}, model::Model)

    for (i,branch) in ref[:branch]
        #f_idx = (i, branch["f_bus"], branch["t_bus"])
        #g_fr = branch["g_fr"]
        #b_fr = branch["b_fr"]
        p_fr = model[:p][(i, branch["f_bus"], branch["t_bus"])]
        q_fr = model[:q][(i, branch["f_bus"], branch["t_bus"])]
        r = branch["br_r"]
        x = branch["br_x"]
        w_fr = model[:w][branch["f_bus"]]
        w_to = model[:w][branch["t_bus"]]
        ccm = model[:ccm][i]
        ym_sh_sqr = branch["g_fr"]^2 + branch["b_fr"]^2

        JuMP.@constraint(model, 
        (1+2*(r*branch["g_fr"] - x*branch["b_fr"]))*(w_fr/branch["tap"]^2) - w_to ==  2*(r*p_fr + x*q_fr) - 
        (r^2 + x^2)*(ccm + ym_sh_sqr*(w_fr/branch["tap"]^2) - 2*(branch["g_fr"]*p_fr - branch["b_fr"]*q_fr))
        )
    end
end