export Network, conversion_to_pm_data

struct Network

    bus::Dict{String,<:Any}
    dcline::Dict{String,<:Any}
    gen::Dict{String,<:Any}
    branch::Dict{String,<:Any}
    storage::Dict{String,<:Any}
    switch::Dict{String,<:Any}
    shunt::Dict{String,<:Any}
    load::Dict{String,<:Any}
    baseMVA::Float64
    per_unit::Bool

    function Network(data::Dict{String,<:Any})

        bus = data["bus"]::Dict{String,<:Any}
        dcline = data["dcline"]::Dict{String,<:Any}
        gen = data["gen"]::Dict{String,<:Any}
        branch = data["branch"]::Dict{String,<:Any}
        storage = data["storage"]::Dict{String,<:Any}
        switch = data["switch"]::Dict{String,<:Any}
        shunt = data["shunt"]::Dict{String,<:Any}
        load = data["load"]::Dict{String,<:Any}
        baseMVA = data["baseMVA"]::Float64
        per_unit = data["per_unit"]::Bool

        return new(bus, dcline, gen, branch, storage, switch, shunt, load, baseMVA, per_unit)

    end

end


function conversion_to_pm_data(network::Network)::Dict{String,<:Any}
    return Dict(
    [("bus",network.bus)
    ("dcline",network.dcline)
    ("gen",network. gen)
    ("branch",network. branch)
    ("storage",network.storage)
    ("switch",network.switch )
    ("shunt",network.shunt)
    ("load",network.load)
    ("baseMVA",network.baseMVA)
    ("per_unit", network.per_unit)])
end
