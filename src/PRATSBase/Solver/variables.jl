""
function var_bus_voltage(ref::Dict{Symbol,Any}, method::Union{Type{dc_opf}, Type{dc_opf_lc}}, model::Model)
    var_bus_voltage_angle(ref, model)
end

""
function var_bus_voltage(ref::Dict{Symbol,Any}, method::Union{Type{ac_opf}, Type{ac_opf_lc}}, model::Model)
    var_bus_voltage_angle(ref, model)
    var_bus_voltage_magnitude(ref, model)
end

""
function var_bus_voltage_magnitude_sqr(ref::Dict{Symbol,Any}, model::Model)
    
    JuMP.@variable(model, w[i in keys(ref[:bus])], start=1.001)

    for i in keys(ref[:bus])
        JuMP.set_lower_bound(w[i], ref[:bus][i]["vmin"]^2)
        JuMP.set_upper_bound(w[i], ref[:bus][i]["vmax"]^2)
    end
end

""
function var_buspair_voltage_product(ref::Dict{Symbol,Any}, model::Model)

    wr_min, wr_max, wi_min, wi_max = calc_voltage_product_bounds(ref[:buspairs])

    JuMP.@variable(model, wr_min[bp] <= wr[bp in keys(ref[:buspairs])] <= wr_max[bp], start=1.0)
    JuMP.@variable(model, wi_min[bp] <= wi[bp in keys(ref[:buspairs])] <= wi_max[bp])    
end



""
function var_bus_voltage_angle(ref::Dict{Symbol,Any}, model::Model)

    JuMP.@variable(model, va[i in keys(ref[:bus])])
end

""
function var_bus_voltage_magnitude(ref::Dict{Symbol,Any}, model::Model)

    JuMP.@variable(model, ref[:bus][i]["vmin"] <= vm[i in keys(ref[:bus])] <= ref[:bus][i]["vmax"], start=1.0)
end

""
function var_gen_power(ref::Dict{Symbol,Any}, method::Union{Type{dc_opf}, Type{dc_opf_lc}}, model::Model)
    var_gen_power_real(ref, model)
end

""
function var_gen_power(ref::Dict{Symbol,Any}, method::Union{Type{ac_opf}, Type{ac_opf_lc}}, model::Model)
    var_gen_power_real(ref, model)
    var_gen_power_imaginary(ref, model)
end

""
function var_gen_power_real(ref::Dict{Symbol,Any},  model::Model)

    JuMP.@variable(model, pg[i in keys(ref[:gen])])

    for (i, gen) in ref[:gen]
        if gen["pmin"]>=0.0
            JuMP.set_lower_bound(pg[i], gen["pmin"])
        else
            JuMP.set_lower_bound(pg[i], 0.0)
        end
        JuMP.set_upper_bound(pg[i], gen["pmax"])
    end
end

""
function var_gen_power_imaginary(ref::Dict{Symbol,Any},  model::Model)

    JuMP.@variable(model, qg[i in keys(ref[:gen])])

    for (i, gen) in ref[:gen]
        JuMP.set_lower_bound(qg[i], gen["qmin"])
        JuMP.set_upper_bound(qg[i], gen["qmax"])
    end
end


""
function var_dcline_power(ref::Dict{Symbol,Any}, method::Union{Type{ac_opf}, Type{ac_opf_lc}}, model::Model)

    JuMP.@variable(model, p_dc[a in ref[:arcs_dc]], start=0.0)
    JuMP.@variable(model, q_dc[a in ref[:arcs_dc]], start=0.0)

    for (l,dcline) in ref[:dcline]
        f_idx = (l, dcline["f_bus"], dcline["t_bus"])
        t_idx = (l, dcline["t_bus"], dcline["f_bus"])

        JuMP.set_lower_bound(p_dc[f_idx], dcline["pminf"])
        JuMP.set_upper_bound(p_dc[f_idx], dcline["pmaxf"])
        JuMP.set_lower_bound(q_dc[f_idx], dcline["qminf"])
        JuMP.set_upper_bound(q_dc[f_idx], dcline["qmaxf"])

        JuMP.set_lower_bound(p_dc[t_idx], dcline["pmint"])
        JuMP.set_upper_bound(p_dc[t_idx], dcline["pmaxt"])
        JuMP.set_lower_bound(q_dc[t_idx], dcline["qmint"])
        JuMP.set_upper_bound(q_dc[t_idx], dcline["qmaxt"])
    end 
end

""
function var_dcline_power(ref::Dict{Symbol,Any}, method::Union{Type{dc_opf}, Type{dc_opf_lc}}, model::Model)

    JuMP.@variable(model, p_dc[a in ref[:arcs_dc]])

    for (l,dcline) in ref[:dcline]
        f_idx = (l, dcline["f_bus"], dcline["t_bus"])
        t_idx = (l, dcline["t_bus"], dcline["f_bus"])

        JuMP.set_lower_bound(p_dc[f_idx], dcline["pminf"])
        JuMP.set_upper_bound(p_dc[f_idx], dcline["pmaxf"])

        JuMP.set_lower_bound(p_dc[t_idx], dcline["pmint"])
        JuMP.set_upper_bound(p_dc[t_idx], dcline["pmaxt"])
    end
end

"""
Defines DC power flow variables p to represent the active power flow for each branch
"""
function var_branch_power(ref::Dict{Symbol,Any}, method::Union{Type{dc_opf}, Type{dc_opf_lc}}, model::Model)

    JuMP.@variable(model, -Inf <= p[(l,i,j) in ref[:arcs]] <= Inf)

    for arc in ref[:arcs]
        branch = ref[:branch][arc[1]]
        if haskey(branch, "rate_a")
            JuMP.set_lower_bound(p[arc], -branch["rate_a"])
            JuMP.set_upper_bound(p[arc],  branch["rate_a"])
        end
    end
end


"""
Defines AC power flow variables p to represent the active power flow for each branch
"""
function var_branch_power(ref::Dict{Symbol,Any}, method::Union{Type{ac_opf}, Type{ac_opf_lc}}, model::Model)
    
    @variable(model, -Inf <= p[(l,i,j) in ref[:arcs]] <= Inf)
    @variable(model, -Inf <= q[(l,i,j) in ref[:arcs]] <= Inf)

    for arc in ref[:arcs]
        branch = ref[:branch][arc[1]]
        if haskey(branch, "rate_a")
            JuMP.set_lower_bound(p[arc], -branch["rate_a"])
            JuMP.set_upper_bound(p[arc],  branch["rate_a"])
            JuMP.set_lower_bound(q[arc], -branch["rate_a"])
            JuMP.set_upper_bound(q[arc],  branch["rate_a"])
        end
    end
end

"""
Defines load curtailment variables p to represent the active power flow for each branch
"""
function var_load_curtailment(ref::Dict{Symbol,Any}, method::Union{Type{dc_opf}, Type{dc_opf_lc}}, model::Model)

    @variable(model, plc[i in keys(ref[:load])])

    for (i, load) in ref[:load]
        JuMP.set_upper_bound(plc[i],load["pd"])
        JuMP.set_lower_bound(plc[i],0.0)
    end
end

"""
Defines load curtailment variables q to represent the active power flow for each branch
"""
function var_load_curtailment(ref::Dict{Symbol,Any}, method::Union{Type{ac_opf}, Type{ac_opf_lc}}, model::Model)
    
    @variable(model, plc[i in keys(ref[:load])])
    @variable(model, qlc[i in keys(ref[:load])])

    for (i, load) in ref[:load]
        JuMP.set_upper_bound(plc[i],load["pd"])
        JuMP.set_upper_bound(qlc[i],load["qd"])
        JuMP.set_lower_bound(plc[i],0.0)
        JuMP.set_lower_bound(qlc[i],0.0)
    end
end

""
function var_load_power_factor_range(ref::Dict{Symbol,Any}, model::Model)

    @variable(model, z_demand[i in keys(ref[:load])])

    for (i, load) in ref[:load]
        JuMP.set_lower_bound(z_demand[i], -(load["qd"]/load["pd"]))
        JuMP.set_upper_bound(z_demand[i], (load["qd"]/load["pd"]))
    end
end

function var_buspair_current_magnitude_sqr(ref::Dict{Symbol,Any}, model::Model)
    
    @variable(model, ccm[i in keys(ref[:branch])])
    for (i, b) in ref[:branch]
        rate_a = Inf
        if haskey(b, "rate_a")
                rate_a = b["rate_a"]
        end
        ub = ((rate_a*b["tap"])/(ref[:bus][b["f_bus"]]["vmin"]))^2
        JuMP.set_lower_bound(ccm[i], 0.0)
        if !isinf(ub)
            JuMP.set_upper_bound(ccm[i], ub)
        end
    end
end