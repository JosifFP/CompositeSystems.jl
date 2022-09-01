###############################################################################
# This file defines commonly used constraints for power flow models

###############################################################################

"Fix the voltage angle to zero at the reference bus"

function constraint_theta_ref_bus(pm::AbstractPowerModel)
    # Fix the voltage angle to zero at the reference bus
    for i in keys(pm.ref[:ref_buses])
        #JuMP.@constraint(pm.model, pm.model[:va][i] == 0)
        JuMP.fix(pm.model[:va][i], 0; force = true)
    end
end

"Nodal power balance constraints"
function constraint_nodal_power_balance(pm::DCPPowerModel)

    # Build JuMP expressions for the value of p[(l,i,j)] and p[(l,j,i)] on the branches
    p_expr = JuMP.@expression(pm.model, Dict([((l,i,j), 1.0*pm.model[:p][(l,i,j)]) for (l,i,j) in pm.ref[:arcs_from]]))
    p_expr = JuMP.@expression(pm.model, merge(p_expr, Dict([((l,j,i), -1.0*pm.model[:p][(l,i,j)]) for (l,i,j) in pm.ref[:arcs_from]])))
    
    for i in keys(pm.ref[:bus])
        # Build a list of the loads and shunt elements connected to the bus i
        bus_loads = [pm.ref[:load][l] for l in pm.ref[:bus_loads][i]]
        bus_shunts = [pm.ref[:shunt][s] for s in pm.ref[:bus_shunts][i]]
        
        JuMP.@constraint(pm.model,
            #sum(p[a] for a in pm.ref[:bus_arcs][i]) +
            sum(p_expr[a] for a in pm.ref[:bus_arcs][i]) +                  # sum of active power flow on lines from bus i +
            sum(pm.model[:p_dc][a_dc] for a_dc in pm.ref[:bus_arcs_dc][i]) ==     # sum of active power flow on HVDC lines from bus i =
            sum(pm.model[:pg][g] for g in pm.ref[:bus_gens][i]) -                 # sum of active power generation at bus i -
            sum(load["pd"] for load in bus_loads) -                 # sum of active load consumption at bus i -
            sum(shunt["gs"] for shunt in bus_shunts)*1.0^2          # sum of active shunt element injections at bus i
        )
    end
end

""
function constraint_nodal_power_balance(pm::DCMLPowerModel)

    # Build JuMP expressions for the value of p[(l,i,j)] and p[(l,j,i)] on the branches
    p_expr = JuMP.@expression(pm.model, merge(Dict([((l,i,j), 1.0*pm.model[:p][(l,i,j)]) for (l,i,j) in pm.ref[:arcs_from]]), 
    Dict([((l,j,i), -1.0*pm.model[:p][(l,i,j)]) for (l,i,j) in pm.ref[:arcs_from]])))
    
    # Nodal power balance constraints  
    #####################    PG + C = PL     ########################################################
    for i in keys(pm.ref[:bus])
        # Build a list of the loads and shunt elements connected to the bus i
        bus_loads = [pm.ref[:load][l] for l in pm.ref[:bus_loads][i]]
        bus_shunts = [pm.ref[:shunt][s] for s in pm.ref[:bus_shunts][i]]

        # Active power balance at node i
        JuMP.@constraint(pm.model,
            #sum(p[a] for a in pm.ref[:bus_arcs][i]) +
            sum(p_expr[a] for a in pm.ref[:bus_arcs][i]) +                  # sum of active power flow on lines from bus i +
            sum(pm.model[:p_dc][a_dc] for a_dc in pm.ref[:bus_arcs_dc][i]) ==     # sum of active power flow on HVDC lines from bus i =
            sum(pm.model[:pg][g] for g in pm.ref[:bus_gens][i]) +                 # sum of active power generation at bus i -
            sum(pm.model[:plc][m] for m in pm.ref[:bus_loads][i]) -
            sum(load["pd"] for load in bus_loads) -                 # sum of active load consumption at bus i -
            sum(shunt["gs"] for shunt in bus_shunts)*1.0^2          # sum of active shunt element injections at bus i
        )
    end
end

"For AC-OPF type"
function constraint_nodal_power_balance(pm::ACPPowerModel)

    for i in keys(pm.ref[:bus])
        # Build a list of the loads and shunt elements connected to the bus i
        bus_loads = [pm.ref[:load][l] for l in pm.ref[:bus_loads][i]]
        bus_shunts = [pm.ref[:shunt][s] for s in pm.ref[:bus_shunts][i]]
        
        # Active power balance at node i
        JuMP.@constraint(pm.model,
            sum(pm.model[:p][a] for a in pm.ref[:bus_arcs][i]) +
            sum(pm.model[:p_dc][a_dc] for a_dc in pm.ref[:bus_arcs_dc][i]) ==     # sum of active power flow on HVDC lines from bus i =
            sum(pm.model[:pg][g] for g in pm.ref[:bus_gens][i]) -                 # sum of active power generation at bus i -
            sum(load["pd"] for load in bus_loads) -                 # sum of active load consumption at bus i -
            sum(shunt["gs"] for shunt in bus_shunts)*pm.model[:vm][i]^2        # sum of active shunt element injections at bus i
        )

        # Reactive power balance at node i
        JuMP.@constraint(pm.model,
            sum(pm.model[:q][a] for a in pm.ref[:bus_arcs][i]) +
            sum(pm.model[:q_dc][a_dc] for a_dc in pm.ref[:bus_arcs_dc][i]) ==     # sum of reactive power flow on HVDC lines from bus i =
            sum(pm.model[:qg][g] for g in pm.ref[:bus_gens][i]) -                 # sum of reactive power generation at bus i -
            sum(load["qd"] for load in bus_loads) +                 # sum of reactive load consumption at bus i -
            sum(shunt["bs"] for shunt in bus_shunts)*pm.model[:vm][i]^2        # sum of reactive shunt element injections at bus i
        )
    end

end

""
function constraint_nodal_power_balance(pm::ACMLPowerModel)

    for (i,bus) in pm.ref[:bus]
        # Build a list of the loads and shunt elements connected to the bus i
        bus_loads = [pm.ref[:load][l] for l in pm.ref[:bus_loads][i]]
        bus_shunts = [pm.ref[:shunt][s] for s in pm.ref[:bus_shunts][i]]
    
        # Active power balance at node i
        JuMP.@constraint(pm.model,
            sum(pm.model[:p][a] for a in pm.ref[:bus_arcs][i]) +
            sum(pm.model[:p_dc][a_dc] for a_dc in pm.ref[:bus_arcs_dc][i]) ==     # sum of active power flow on HVDC lines from bus i =
            sum(pm.model[:pg][g] for g in pm.ref[:bus_gens][i]) +                 # sum of active power generation at bus i -
            sum(pm.model[:plc][m] for m in pm.ref[:bus_loads][i]) -
            sum(load["pd"] for load in bus_loads) -                 # sum of active load consumption at bus i -
            sum(shunt["gs"] for shunt in bus_shunts)*pm.model[:vm][i]^2        # sum of active shunt element injections at bus i
        )

        # Reactive power balance at node i
        JuMP.@constraint(pm.model,
            sum(pm.model[:q][a] for a in pm.ref[:bus_arcs][i]) +
            sum(pm.model[:q_dc][a_dc] for a_dc in pm.ref[:bus_arcs_dc][i]) ==     # sum of reactive power flow on HVDC lines from bus i =
            sum(pm.model[:qg][g] for g in pm.ref[:bus_gens][i]) +                 # sum of reactive power generation at bus i -
            sum(pm.model[:qlc][m] for m in pm.ref[:bus_loads][i]) -
            sum(load["qd"] for load in bus_loads) +                 # sum of reactive load consumption at bus i -
            sum(shunt["bs"] for shunt in bus_shunts)*pm.model[:vm][i]^2        # sum of reactive shunt element injections at bus i
        )
    end

end

"Branch power flow physics and limit constraints"
function constraint_branch_pf_limits(pm::AbstractDCPModel)

    for (i,branch) in pm.ref[:branch]
        # Build the from variable id of the i-th branch, which is a tuple given by (branch id, from bus, to bus)
        #f_idx = (i, branch["f_bus"], branch["t_bus"])
        p_fr = JuMP.@expression(pm.model, pm.model[:p][(i, branch["f_bus"], branch["t_bus"])])                    # p_fr is a reference to the optimization variable p[f_idx]
        va_fr_to = JuMP.@expression(pm.model, pm.model[:va][branch["f_bus"]]-pm.model[:va][branch["t_bus"]])         # va_fr is a reference to the optimization variable va on the from side of the branch
    
        # Compute the branch parameters and transformer ratios from the data
        g, b = calc_branchs_y(branch)
    
        # DC Line Flow Constraints
        JuMP.@constraint(pm.model, p_fr == -b*(va_fr_to))

        # Voltage angle difference limit
        JuMP.@constraint(pm.model, va_fr_to <= branch["angmax"])
        JuMP.@constraint(pm.model, va_fr_to >= branch["angmin"])
    end
end

""
function constraint_branch_pf_limits(pm::AbstractACPModel)

    for (i,branch) in pm.ref[:branch]

        #f_idx = (i, branch["f_bus"], branch["t_bus"])
        #t_idx = (i, branch["t_bus"], branch["f_bus"])

        p_fr = pm.model[:p][(i, branch["f_bus"], branch["t_bus"])]                     # p_fr is a reference to the optimization variable p[f_idx]
        q_fr = pm.model[:q][(i, branch["f_bus"], branch["t_bus"])]                     # q_fr is a reference to the optimization variable q[f_idx]
        p_to = pm.model[:p][(i, branch["t_bus"], branch["f_bus"])]                     # p_to is a reference to the optimization variable p[t_idx]
        q_to = pm.model[:q][(i, branch["t_bus"], branch["f_bus"])]                     # q_to is a reference to the optimization variable q[t_idx]
        vm_fr = pm.model[:vm][branch["f_bus"]]         # vm_fr is a reference to the optimization variable vm on the from side of the branch
        vm_to = pm.model[:vm][branch["t_bus"]]         # vm_to is a reference to the optimization variable vm on the to side of the branch
        va_fr = pm.model[:va][branch["f_bus"]]         # va_fr is a reference to the optimization variable va on the from side of the branch
        va_to = pm.model[:va][branch["t_bus"]]         # va_fr is a reference to the optimization variable va on the to side of the branch

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
        JuMP.@constraint(pm.model, p_fr ==  (g+g_fr)/tm*vm_fr^2 + (-g*tr+b*ti)/tm*(vm_fr*vm_to*cos(va_fr-va_to)) + (-b*tr-g*ti)/tm*(vm_fr*vm_to*sin(va_fr-va_to)) )
        JuMP.@constraint(pm.model, q_fr == -(b+b_fr)/tm*vm_fr^2 - (-b*tr-g*ti)/tm*(vm_fr*vm_to*cos(va_fr-va_to)) + (-g*tr+b*ti)/tm*(vm_fr*vm_to*sin(va_fr-va_to)) )

        # To side of the branch flow
        JuMP.@constraint(pm.model, p_to ==  (g+g_to)*vm_to^2 + (-g*tr-b*ti)/tm*(vm_to*vm_fr*cos(va_to-va_fr)) + (-b*tr+g*ti)/tm*(vm_to*vm_fr*sin(va_to-va_fr)) )
        JuMP.@constraint(pm.model, q_to == -(b+b_to)*vm_to^2 - (-b*tr+g*ti)/tm*(vm_to*vm_fr*cos(va_fr-va_to)) + (-g*tr-b*ti)/tm*(vm_to*vm_fr*sin(va_to-va_fr)) )

        # Voltage angle difference limit
        JuMP.@constraint(pm.model, va_fr - va_to <= branch["angmax"])
        JuMP.@constraint(pm.model, va_fr - va_to >= branch["angmin"])

        # Apparent Power Limit, From and To
        if haskey(branch, "rate_a")
            JuMP.@constraint(pm.model, pm.model[:p][(i, branch["f_bus"], branch["t_bus"])]^2 + pm.model[:q][(i, branch["f_bus"], branch["t_bus"])]^2 <= branch["rate_a"]^2)
            JuMP.@constraint(pm.model, pm.model[:p][(i, branch["t_bus"], branch["f_bus"])]^2 + pm.model[:q][(i, branch["t_bus"], branch["f_bus"])]^2 <= branch["rate_a"]^2)
        end
    end
end

"HVDC line constraints"
function constraint_hvdc_line(pm::AbstractPowerModel)

    for (i,dcline) in pm.ref[:dcline]
        #f_idx = (i, dcline["f_bus"], dcline["t_bus"])
        #t_idx = (i, dcline["t_bus"], dcline["f_bus"])
    
        # Constraint defining the power flow and losses over the HVDC line
        JuMP.@constraint(pm.model, (1-dcline["loss1"])*pm.model[:p_dc][(i, dcline["f_bus"], dcline["t_bus"])] + 
        (pm.model[:p_dc][(i, dcline["t_bus"], dcline["f_bus"])] - dcline["loss0"]) == 0)
    end
end

"Fixed Power Factor"
function constraint_power_factor(pm::AbstractPowerModel)
    for i in keys(pm.ref[:load])
        JuMP.@constraint(pm.model, pm.model[:z_demand][i]*pm.model[:plc][i] - pm.model[:qlc][i] == 0.0)      
    end
end

""
function constraint_voltage_magnitude_diff(pm::AbstractDCPModel)

    for (i,branch) in pm.ref[:branch]
        #f_idx = (i, branch["f_bus"], branch["t_bus"])
        #g_fr = branch["g_fr"]
        #b_fr = branch["b_fr"]
        p_fr = pm.model[:p][(i, branch["f_bus"], branch["t_bus"])]
        #q_fr = pm.model[:q][(i, branch["f_bus"], branch["t_bus"])]
        q_fr = 0
        r = branch["br_r"]
        x = branch["br_x"]
        w_fr = pm.model[:w][branch["f_bus"]]
        w_to = pm.model[:w][branch["t_bus"]]
        ccm = pm.model[:ccm][i]
        ym_sh_sqr = branch["g_fr"]^2 + branch["b_fr"]^2

        JuMP.@constraint(pm.model, 
        (1+2*(r*branch["g_fr"] - x*branch["b_fr"]))*(w_fr/branch["tap"]^2) - w_to ==  2*(r*p_fr + x*q_fr) - 
        (r^2 + x^2)*(ccm + ym_sh_sqr*(w_fr/branch["tap"]^2) - 2*(branch["g_fr"]*p_fr - branch["b_fr"]*q_fr))
        )
    end
end

""
function constraint_voltage_magnitude_diff(pm::AbstractACPModel)

    for (i,branch) in pm.ref[:branch]
        #f_idx = (i, branch["f_bus"], branch["t_bus"])
        #g_fr = branch["g_fr"]
        #b_fr = branch["b_fr"]
        p_fr = pm.model[:p][(i, branch["f_bus"], branch["t_bus"])]
        q_fr = pm.model[:q][(i, branch["f_bus"], branch["t_bus"])]
        r = branch["br_r"]
        x = branch["br_x"]
        w_fr = pm.model[:w][branch["f_bus"]]
        w_to = pm.model[:w][branch["t_bus"]]
        ccm = pm.model[:ccm][i]
        ym_sh_sqr = branch["g_fr"]^2 + branch["b_fr"]^2

        JuMP.@constraint(pm.model, 
        (1+2*(r*branch["g_fr"] - x*branch["b_fr"]))*(w_fr/branch["tap"]^2) - w_to ==  2*(r*p_fr + x*q_fr) - 
        (r^2 + x^2)*(ccm + ym_sh_sqr*(w_fr/branch["tap"]^2) - 2*(branch["g_fr"]*p_fr - branch["b_fr"]*q_fr))
        )
    end
end