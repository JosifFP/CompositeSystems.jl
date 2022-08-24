export TimeSeriesPowerFlow!
import LinearAlgebra: pinv

function TimeSeriesPowerFlow!(network_data::Dict{String,Any}, system::SystemModel{N}) where {N}

    for j in eachindex(1:N)

        for i in eachindex(system.generators.keys)
            network_data["gen"][string(i)]["pg"] = system.generators.pg[i,j]
            @assert network_data["gen"][string(i)]["pg"] <= network_data["gen"][string(i)]["pmax"]
        end

        for i in eachindex(system.loads.keys)
            pf = Float32.(network_data["load"][string(i)]["qd"] / network_data["load"][string(i)]["pd"])
            network_data["load"][string(i)]["pd"] = system.loads.pd[i,j]
            network_data["load"][string(i)]["qd"] = Float16.(system.loads.pd[i,j]*pf)
        end

        pf_result = PowerModels.compute_dc_pf(network_data)
        update_data!(network_data, pf_result["solution"])
        flow = calc_branch_flow_dc(network_data)

        for i in eachindex(system.branches.keys)
            system.branches.pf[i,j] = Float16.(flow["branch"][string(i)]["pf"])
            system.branches.pt[i,j] = Float16.(flow["branch"][string(i)]["pt"])
        end

        update_data!(network_data, flow)

        for i in eachindex(system.generators.keys)
            system.generators.pg[i,j] = network_data["gen"][string(i)]["pg"]
        end
    end
end

"recursively applies new_data to data, overwriting information"
function update_data!(data::Dict{String,<:Any}, new_data::Dict{String,<:Any})
    if haskey(data, "per_unit") && haskey(new_data, "per_unit")
        if data["per_unit"] != new_data["per_unit"]
            Memento.error(_LOGGER, "update_data requires datasets in the same units, try make_per_unit and make_mixed_units")
        end
    else
        Memento.warn(_LOGGER, "running update_data with data that does not include per_unit field, units may be incorrect")
    end

    _update_data!(data, new_data)
end

"recursive call of _update_data"
function _update_data!(data::Dict{String,<:Any}, new_data::Dict{String,<:Any})
    for (key, new_v) in new_data
        if haskey(data, key)
            v = data[key]
            if isa(v, Dict) && isa(new_v, Dict)
                _update_data!(v, new_v)
            else
                data[key] = new_v
            end
        else
            data[key] = new_v
        end
    end
end

"assumes a vaild dc solution is included in the data and computes the branch flow values"
function calc_branch_flow_dc(data::Dict{String,<:Any})

    @assert("per_unit" in keys(data) && data["per_unit"])
    flows = _calc_branch_flow_dc(data)
    flows["per_unit"] = data["per_unit"]
    flows["baseMVA"] = data["baseMVA"]
    return flows

end

"helper function for calc_branch_flow_dc"
function _calc_branch_flow_dc(data::Dict{String,<:Any})

    vm = Dict(bus["index"] => bus["vm"] for (i,bus) in data["bus"])
    va = Dict(bus["index"] => bus["va"] for (i,bus) in data["bus"])

    flows = Dict{String,Any}()
    for (i,branch) in data["branch"]
        if branch["br_status"] != 0
            f_bus = branch["f_bus"]
            t_bus = branch["t_bus"]

            g, b = calc_branch_y(branch)

            p_fr = -b*(va[f_bus] - va[t_bus])
        else
            p_fr = NaN
        end

        flows[i] = Dict(
            "pf" =>  p_fr,
            "qf" =>  NaN,
            "pt" => -p_fr,
            "qt" =>  NaN
        )
    end

    return Dict{String,Any}("branch" => flows)
end

""
function calc_branch_y(branch::Dict{String,<:Any})
    y = pinv(branch["br_r"] + im * branch["br_x"])
    g, b = real(y), imag(y)
    return g, b
end

""
function check_violations(network_data, flow)

    container_rate_a = [network_data["branch"][i]["rate_a"] for i in eachindex(network_data["branch"])]
    key_order_rate_a = sortperm([network_data["branch"][i]["index"] for i in eachindex(network_data["branch"])])
    container_pf = [abs(flow["branch"][i]["pf"]) for i in eachindex(flow["branch"])]
    key_order = sortperm([parse(Int,i) for i in eachindex(flow["branch"])])
    
    [@assert container_pf[key_order][i] <= container_rate_a[key_order_rate_a][i] "Tests didn't pass" for i in eachindex(container_rate_a)]

end