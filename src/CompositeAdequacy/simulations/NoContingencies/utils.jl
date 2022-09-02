""
function create_dict_from_system!(system::SystemModel, t::Int)

    network_data = Dict(
        [("bus",system.network.bus)
        #("source_type",network.source_type)
        #("name",network.name)
        #("source_version",network.source_version)
        ("dcline",system.network.dcline)
        ("gen",system.network. gen)
        ("branch",system.network. branch)
        ("storage",system.network.storage)
        ("switch",system.network.switch )
        ("shunt",system.network.shunt)
        ("load",system.network.load)
        ("baseMVA",system.network.baseMVA)
        ("per_unit", system.network.per_unit)]
    )

    for i in eachindex(system.generators.keys)
        network_data["gen"][string(i)]["pg"] = system.generators.pg[i,t]
    end

    for i in eachindex(system.loads.keys)
        network_data["load"][string(i)]["qd"] = Float16.(system.loads.pd[i,t]*
            Float32.(network_data["load"][string(i)]["qd"] / network_data["load"][string(i)]["pd"]))
        network_data["load"][string(i)]["pd"] = system.loads.pd[i,t]
    end

    return network_data
    
end

function update_systemmodel_branches!(system::SystemModel, flow::Dict{String, Any}, j::Int)
    for i in eachindex(system.branches.keys)
        # if abs(flow["branch"][string(i)]["pf"]) > network_data["branch"][string(i)]["rate_a"]
        #     Memento.info(_LOGGER, "Branch (f_bus,t_bus)=($(network_data["branch"][string(i)]["f_bus"]),$(network_data["branch"][string(i)]["t_bus"])) is overloaded by %$(
        #     Float16(abs(flow["branch"][string(i)]["pf"])*100/network_data["branch"][string(i)]["rate_a"])), MW=$(
        #     Float16(flow["branch"][string(i)]["pf"])), rate_a = $(network_data["branch"][string(i)]["rate_a"]), key=$(
        #     i), index=$(network_data["branch"][string(i)]["index"]), Hour=$(j).")
        # end
        system.branches.pf[i,j] = Float16.(flow["branch"][string(i)]["pf"])
        system.branches.pt[i,j] = Float16.(flow["branch"][string(i)]["pt"])
    end
end

function update_systemmodel_generators!(network_data::Dict{String,Any}, system::SystemModel, j::Int)
    for i in eachindex(system.generators.keys)
        system.generators.pg[i,j] = network_data["gen"][string(i)]["pg"]
    end
end

"recursively applies new_data to data, overwriting information"
function update_data!(data::Dict{String,<:Any}, new_data::Dict{String,<:Any})
    for (key, new_v) in new_data
        if haskey(data, key)
            v = data[key]
            if isa(v, Dict) && isa(new_v, Dict)
                update_data!(v, new_v)
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