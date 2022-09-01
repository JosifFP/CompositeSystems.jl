""
function var_bus_voltage(pm::AbstractDCPModel; kwargs...)
    var_bus_voltage_angle(pm.ref, pm.model; kwargs...)
end

""
function var_bus_voltage(pm::AbstractACPModel; kwargs...)
    var_bus_voltage_angle(pm.ref, pm.model; kwargs...)
    var_bus_voltage_magnitude(pm.ref, pm.model; kwargs...)
end

""
function var_bus_voltage_angle(ref::Dict{Symbol,Any}, model::Model; bounded::Bool=true)

    JuMP.@variable(model, va[i in keys(ref[:bus])])
end

""
function var_bus_voltage_magnitude(ref::Dict{Symbol,Any}, model::Model; bounded::Bool=true)

    JuMP.@variable(model, vm[i in keys(ref[:bus])], start=1.0)

    if bounded
        for (i, bus) in keys(ref[:bus])
            JuMP.set_lower_bound(vm[i], bus["vmin"])
            JuMP.set_upper_bound(vm[i], bus["vmax"])
        end
    end

end

""
function var_bus_voltage_magnitude_sqr(pm::AbstractPowerModel; bounded::Bool=true)
    
    JuMP.@variable(pm.model, w[i in keys(pm.ref[:bus])], start=1.001)

    if bounded
        for i in keys(pm.ref[:bus])
            JuMP.set_lower_bound(w[i], pm.ref[:bus][i]["vmin"]^2)
            JuMP.set_upper_bound(w[i], pm.ref[:bus][i]["vmax"]^2)
        end
    end
end

""
function var_buspair_voltage_product(pm::AbstractPowerModel)

    wr_min, wr_max, wi_min, wi_max = calc_voltage_product_bounds(pm.ref[:buspairs])

    JuMP.@variable(pm.model, wr_min[bp] <= wr[bp in keys(pm.ref[:buspairs])] <= wr_max[bp], start=1.0)
    JuMP.@variable(pm.model, wi_min[bp] <= wi[bp in keys(pm.ref[:buspairs])] <= wi_max[bp])    
end

""
function var_gen_power(pm::AbstractDCPModel; kwargs...)
    var_gen_power_real(pm.ref, pm.model; kwargs...)
end

""
function var_gen_power(pm::AbstractACPModel; kwargs...)
    var_gen_power_real(pm.ref, pm.model; kwargs...)
    var_gen_power_imaginary(pm.ref, pm.model; kwargs...)
end

""
function var_gen_power_real(ref::Dict{Symbol,Any}, model::Model; bounded::Bool=true)

    JuMP.@variable(model, pg[i in keys(ref[:gen])])

    if bounded
        for (i, gen) in ref[:gen]
            JuMP.set_upper_bound(pg[i], gen["pmax"])
            JuMP.set_lower_bound(pg[i], gen["pmin"])
        end
    end

end

""
function var_gen_power_imaginary(ref::Dict{Symbol,Any}, model::Model; bounded::Bool=true)

    JuMP.@variable(model, qg[i in keys(ref[:gen])])
    
    if bounded
        for (i, gen) in ref[:gen]
            JuMP.set_lower_bound(qg[i], gen["qmin"])
            JuMP.set_upper_bound(qg[i], gen["qmax"])
        end
    end
end

"""
Defines DC power flow variables p to represent the active power flow for each branch
"""
function var_branch_power(pm::AbstractDCPModel; kwargs...)
    var_branch_power_real(pm.ref, pm.model; kwargs...)
end

"""
Defines AC power flow variables p to represent the active power flow for each branch
"""
function var_branch_power(pm::AbstractACPModel; kwargs...)
    var_branch_power_real(pm.ref, pm.model; kwargs...)
    var_branch_power_imaginary(pm.ref, pm.model; kwargs...)
end

""
function var_branch_power_real(ref::Dict{Symbol,Any}, model::Model; bounded::Bool=true)

    JuMP.@variable(model, p[(l,i,j) in ref[:arcs]])

    if bounded
        for arc in ref[:arcs]
            branch = ref[:branch][arc[1]]
            if haskey(branch, "rate_a")
                JuMP.set_lower_bound(p[arc], -branch["rate_a"])
                JuMP.set_upper_bound(p[arc],  branch["rate_a"])
            end
        end
    end

    for (l,branch) in ref[:branch]
        if haskey(branch, "pf_start")
            f_idx = (l, branch["f_bus"], branch["t_bus"])
            JuMP.set_start_value(p[f_idx], branch["pf_start"])
        end
        if haskey(branch, "pt_start")
            t_idx = (l, branch["t_bus"], branch["f_bus"])
            JuMP.set_start_value(p[t_idx], branch["pt_start"])
        end
    end

end

""
function var_branch_power_imaginary(ref::Dict{Symbol,Any}, model::Model; bounded::Bool=true)
    
    @variable(model, q[(l,i,j) in ref[:arcs]])

    if bounded
        for arc in ref[:arcs]
            branch = ref[:branch][arc[1]]
            if haskey(branch, "rate_a")
                JuMP.set_lower_bound(q[arc], -branch["rate_a"])
                JuMP.set_upper_bound(q[arc],  branch["rate_a"])
            end
        end
    end

    for (l,branch) in ref[:branch]
        if haskey(branch, "qf_start")
            f_idx = (l, branch["f_bus"], branch["t_bus"])
            JuMP.set_start_value(q[f_idx], branch["qf_start"])
        end
        if haskey(branch, "qt_start")
            t_idx = (l, branch["t_bus"], branch["f_bus"])
            JuMP.set_start_value(q[t_idx], branch["qt_start"])
        end
    end

end


function var_dcline_power(pm::AbstractDCPModel; kwargs...)
    var_dcline_power_real(pm.ref, pm.model; kwargs...)
end

function var_dcline_power(pm::AbstractACPModel; kwargs...)
    var_dcline_power_real(pm.ref, pm.model; kwargs...)
    var_dcline_power_imaginary(pm.ref, pm.model; kwargs...)
end

""
function var_dcline_power_real(ref::Dict{Symbol,Any}, model::Model, bounded::Bool=true)

    JuMP.@variable(model, p_dc[a in ref[:arcs_dc]])

    if bounded
        for (l,dcline) in ref[:dcline]
            f_idx = (l, dcline["f_bus"], dcline["t_bus"])
            t_idx = (l, dcline["t_bus"], dcline["f_bus"])

            JuMP.set_lower_bound(p_dc[f_idx], dcline["pminf"])
            JuMP.set_upper_bound(p_dc[f_idx], dcline["pmaxf"])

            JuMP.set_lower_bound(p_dc[t_idx], dcline["pmint"])
            JuMP.set_upper_bound(p_dc[t_idx], dcline["pmaxt"])
        end
    end

    for (l,dcline) in ref[:dcline]
        if haskey(dcline, "pf")
            f_idx = (l, dcline["f_bus"], dcline["t_bus"])
            JuMP.set_start_value(p_dc[f_idx], dcline["pf"])
        end

        if haskey(dcline, "pt")
            t_idx = (l, dcline["t_bus"], dcline["f_bus"])
            JuMP.set_start_value(p_dc[t_idx], dcline["pt"])
        end
    end

end

""
function var_dcline_power_imaginary(ref::Dict{Symbol,Any}, model::Model, bounded::Bool=true)

    JuMP.@variable(model, q_dc[a in ref[:arcs_dc]])

    if bounded
        for (l,dcline) in ref[:dcline]
            f_idx = (l, dcline["f_bus"], dcline["t_bus"])
            t_idx = (l, dcline["t_bus"], dcline["f_bus"])

            JuMP.set_lower_bound(q_dc[f_idx], dcline["qminf"])
            JuMP.set_upper_bound(q_dc[f_idx], dcline["qmaxf"])

            JuMP.set_lower_bound(q_dc[t_idx], dcline["qmint"])
            JuMP.set_upper_bound(q_dc[t_idx], dcline["qmaxt"])
        end
    end

    for (l,dcline) in ref[:dcline]
        if haskey(dcline, "qf")
            f_idx = (l, dcline["f_bus"], dcline["t_bus"])
            JuMP.set_start_value(q_dc[f_idx], dcline["qf"])
        end

        if haskey(dcline, "qt")
            t_idx = (l, dcline["t_bus"], dcline["f_bus"])
            JuMP.set_start_value(q_dc[t_idx], dcline["qt"])
        end
    end

end



"""
Defines load curtailment variables p to represent the active power flow for each branch
"""
function var_load_curtailment(pm::AbstractDCPModel)

    JuMP.@variable(pm.model, plc[i in keys(pm.ref[:load])])

    for (i, load) in pm.ref[:load]
        JuMP.set_upper_bound(plc[i],load["pd"])
        JuMP.set_lower_bound(plc[i],0.0)
    end
end

"""
Defines load curtailment variables q to represent the active power flow for each branch
"""
function var_load_curtailment(pm::AbstractACPModel)
    
    @variable(pm.model, plc[i in keys(pm.ref[:load])])
    @variable(pm.model, qlc[i in keys(pm.ref[:load])])

    for (i, load) in pm.ref[:load]
        JuMP.set_upper_bound(plc[i],load["pd"])
        JuMP.set_upper_bound(qlc[i],load["qd"])
        JuMP.set_lower_bound(plc[i],0.0)
        JuMP.set_lower_bound(qlc[i],0.0)
    end
end

""
function var_load_power_factor_range(pm::Type)

    JuMP.@variable(pm.model, z_demand[i in keys(pm.ref[:load])])

    for (i, load) in pm.ref[:load]
        JuMP.set_lower_bound(z_demand[i], -Float32(load["qd"]/load["pd"]))
        JuMP.set_upper_bound(z_demand[i], Float32(load["qd"]/load["pd"]))
    end
end

function var_buspair_current_magnitude_sqr(pm::AbstractPowerModel)
    
    JuMP.@variable(pm.model, ccm[i in keys(pm.ref[:branch])])

    for (i, b) in pm.ref[:branch]
        rate_a = Inf
        if haskey(b, "rate_a")
            rate_a = b["rate_a"]
        end
        ub = ((rate_a*b["tap"])/(pm.ref[:bus][b["f_bus"]]["vmin"]))^2
        JuMP.set_lower_bound(ccm[i], 0.0)
        if !isinf(ub)
            JuMP.set_upper_bound(ccm[i], ub)
        end
    end

end