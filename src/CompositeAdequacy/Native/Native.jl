"""
computes a linear DC power flow based on the susceptance matrix of the network
data using Julia's native linear equation solvers.

returns a solution data structure in Dict format
"""
function compute_dc_pf(data::Dict{String,<:Any})
    #time_start = time()
    #TODO check single connected component and ref bus

    ref_bus = PRATSBase.reference_bus(data)

    bi = PRATSBase.calculate_bus_injection_active(data)

    # accounts for vm = 1.0 assumption
    for (i,shunt) in data["shunt"]
        if shunt["status"] ≠ 0 && !isapprox(shunt["gs"], 0.0)
            bi[shunt["shunt_bus"]] += shunt["gs"]
        end
    end

    sm = PRATSBase.calculate_susceptance_matrix(data)

    bi_idx = [bi[bus_id] for bus_id in sm.idx_to_bus]

    ref_idx = sm.bus_to_idx[ref_bus["index"]]

    theta_idx = solve_theta(sm, ref_idx, bi_idx)

    bus_assignment= Dict{String,Any}()
    for (i,bus) in data["bus"]
        va = NaN
        if haskey(sm.bus_to_idx, bus["index"])
            va = theta_idx[sm.bus_to_idx[bus["index"]]]
        end
        bus_assignment[i] = Dict("va" => va)
    end

    PRATSBase.update_data!(data["bus"], bus_assignment)

    #vm = Dict(bus["index"] => bus["vm"] for (i,bus) in data["bus"])
    va = Dict(bus["index"] => bus["va"] for (i,bus) in data["bus"])

    flows = Dict{String,Any}()
    for (i,branch) in data["branch"]
        if branch["br_status"] ≠ 0
            f_bus = branch["f_bus"]
            t_bus = branch["t_bus"]

            g, b = PRATSBase.calc_branch_y(branch)

            p_fr = -b*(va[f_bus] - va[t_bus])
        else
            p_fr = NaN
        end

        flows[i] = Dict(
            "pf" =>  p_fr,
            "qf" =>  NaN,
            "pt" => -p_fr,
            "qt" =>  NaN,
            "rate_a" => branch["rate_a"]
        )
    end

    solution = Dict(
        "per_unit" => data["per_unit"], 
        "bus" => data["bus"],
        "branch" => flows
    )

    # result = Dict(
    #     "optimizer" => string(\),
    #     "termination_status" => true,
    #     "objective" => 0.0,
    #     "solution" => solution,
    #     #"solve_time" => time() - time_start
    # )

    #PRATSBase.update_data!(data, solution)

    return solution
end


"""
solves a DC power flow, assumes a single slack power variable at the given reference bus
"""
function solve_theta(am::PRATSBase.AdmittanceMatrix, ref_idx::Int, bus_injection::Vector{Float64})
    # TODO can copy be avoided?  @view?
    m = deepcopy(am.matrix)
    bi = deepcopy(bus_injection)

    for i in 1:length(am.idx_to_bus)
        if i == ref_idx
            # TODO improve scaling of this value
            m[i,i] = 1.0
        else
            if !iszero(m[ref_idx,i])
                m[ref_idx,i] = 0.0
            end
        end
    end
    bi[ref_idx] = 0.0

    theta = qr(-m) \ bi

    return theta
end
