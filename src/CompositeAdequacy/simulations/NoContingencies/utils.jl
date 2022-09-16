""
function create_dict_from_system(system::SystemModel)

    network_data = Dict{String,Dict{String,<:Any}}()

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