export NetworkData

struct NetworkData

    bus::Dict{String,<:Any}
    dcline::Dict{String,<:Any}
    gen::Dict{String,<:Any}
    branch::Dict{String,<:Any}
    storage::Dict{String,<:Any}
    switch::Dict{String,<:Any}
    shunt::Dict{String,<:Any}
    load::Dict{String,<:Any}
    baseMVA::Float16
    per_unit::Bool

    function NetworkData(data::Dict{String,<:Any})

        bus = data["bus"]
        dcline = data["dcline"]
        gen = data["gen"]
        branch = data["branch"]
        storage = data["storage"]
        switch = data["switch"]
        shunt = data["shunt"]
        load = data["load"]
        baseMVA = data["baseMVA"]
        per_unit = data["per_unit"]

        @assert isempty(bus) == false
        @assert isempty(gen) == false
        @assert isempty(branch) == false
        @assert isempty(load) == false
        @assert isempty(baseMVA) == false
        @assert isempty(per_unit) == false

        return new(bus, dcline, gen, branch, storage, switch, shunt, load, baseMVA, per_unit)

    end

end