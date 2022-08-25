export TimeSeriesPowerFlow!
import LinearAlgebra: pinv

# function TimeSeriesPowerFlow!(network_data::Dict{String,Any}, system::SystemModel{N}, overloadings::Vector{Int64}) where {N}

#     for j in eachindex(1:N)
#         update_data_from_system!(network_data, system, j)
#         update_data!(network_data, PowerModels.compute_dc_pf(network_data)["solution"])
#         flow = calc_branch_flow_dc(network_data)
#         update_systemmodel_branches!(network_data, system, flow, overloadings, j)
#         update_data!(network_data, flow)
#         update_systemmodel_generators!(network_data, system, j)
#     end
    
#     return overloadings

# end


# function TimeSeriesPowerFlow!(network_data::Dict{String,Any}, system::SystemModel{N}, overloadings::Vector{Int64}, optimizer, info::String) where {N}

#     resize!(overloadings,0)

#     for j in eachindex(1:N)
#         update_data_from_system!(network_data, system, j)
#         PowerModels.update_data!(network_data, PowerModels.solve_dc_opf(network_data, optimizer)["solution"])
#         flow = calc_branch_flow_dc(network_data)
#         update_systemmodel_branches!(network_data, system, flow, overloadings, j, info)
#         update_data!(network_data, flow)
#         update_systemmodel_generators!(network_data, system, j)
#     end
    
#     return overloadings

# end

function update_data_from_system!(network_data::Dict{String,Any}, system::SystemModel, j::Int)

    for i in eachindex(system.generators.keys)
        network_data["gen"][string(i)]["pg"] = system.generators.pg[i,j]
        @assert network_data["gen"][string(i)]["pg"] <= network_data["gen"][string(i)]["pmax"] "Generator Pmax violated"
    end

    for i in eachindex(system.loads.keys)
        network_data["load"][string(i)]["qd"] = Float16.(system.loads.pd[i,j]*
            Float32.(network_data["load"][string(i)]["qd"] / network_data["load"][string(i)]["pd"]))
        network_data["load"][string(i)]["pd"] = system.loads.pd[i,j]
    end
    
end

function update_systemmodel_branches!(network_data::Dict{String,Any}, system::SystemModel, flow::Dict{String, Any}, overloadings::Vector{Int64}, j::Int)
    for i in eachindex(system.branches.keys)
        if abs(flow["branch"][string(i)]["pf"]) > network_data["branch"][string(i)]["rate_a"]
            push!(overloadings, j)
        end
        system.branches.pf[i,j] = Float16.(flow["branch"][string(i)]["pf"])
        system.branches.pt[i,j] = Float16.(flow["branch"][string(i)]["pt"])
    end

    for i in eachindex(system.generators.keys)
        system.generators.pg[i,j] = network_data["gen"][string(i)]["pg"]
    end

end

function update_systemmodel_branches!(system::SystemModel, flow::Dict{String, Any}, j::Int)
    for i in eachindex(system.branches.keys)
        system.branches.pf[i,j] = Float16.(flow["branch"][string(i)]["pf"])
        system.branches.pt[i,j] = Float16.(flow["branch"][string(i)]["pt"])
    end
end

function update_systemmodel_branches!(network_data::Dict{String,Any}, system::SystemModel, flow::Dict{String, Any}, overloadings::Vector{Int64}, j::Int, ::String)
    for i in eachindex(system.branches.keys)
        if abs(flow["branch"][string(i)]["pf"]) > network_data["branch"][string(i)]["rate_a"]
            push!(overloadings, j)
            Memento.info(_LOGGER, "Branch (f_bus,t_bus)=($(network_data["branch"][string(i)]["f_bus"]),$(network_data["branch"][string(i)]["t_bus"])) is overloaded by %$(
            Float16(abs(flow["branch"][string(i)]["pf"])*100/network_data["branch"][string(i)]["rate_a"])), MW=$(
            Float16(flow["branch"][string(i)]["pf"])), rate_a = $(network_data["branch"][string(i)]["rate_a"]), key=$(
            i), index=$(network_data["branch"][string(i)]["index"]), Hour=$(j).")
        end
        system.branches.pf[i,j] = Float16.(flow["branch"][string(i)]["pf"])
        system.branches.pt[i,j] = Float16.(flow["branch"][string(i)]["pt"])
    end

    for i in eachindex(system.generators.keys)
        system.generators.pg[i,j] = network_data["gen"][string(i)]["pg"]
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