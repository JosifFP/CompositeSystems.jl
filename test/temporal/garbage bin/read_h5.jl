function systemmodel_0_5(f::File)

    metadata = attributes(f)

    start_timestamp = ZonedDateTime(read(metadata["start_timestamp"]),
                                    dateformat"yyyy-mm-ddTHH:MM:SSz")

    N = read(metadata["timestep_count"])
    L = read(metadata["timestep_length"])
    T = timeunits[read(metadata["timestep_unit"])]
    P = powerunits[read(metadata["power_unit"])]
    E = energyunits[read(metadata["energy_unit"])]

    timestamps = range(start_timestamp, length=N, step=T(L))

    has_buses = haskey(f, "buses")
    has_generators = haskey(f, "generators")
    has_storages = haskey(f, "storages")
    has_generatorstorages = haskey(f, "generatorstorages")
    has_interfaces = haskey(f, "interfaces")
    has_branches = haskey(f, "branches")

    has_buses ||
        error("Bus data must be provided")

    has_generators || has_generatorstorages ||
        error("Generator or generator storage data (or both) must be provided")

    xor(has_interfaces, has_branches) &&
        error("Both (or neither) interface and line data must be provided")

    regionnames = readvector(f["buses/_core"], :name)
    buses = Buses{N,P}(
        regionnames,
        Int.(read(f["buses/load"]))
    )
    regionlookup = Dict(n=>i for (i, n) in enumerate(regionnames))
    n_buses = length(buses)

    if has_generators

        gen_core = read(f["generators/_core"])
        gen_names, gen_categories, gen_regionnames = readvector.(
            Ref(gen_core), [:name, :category, :bus])

        gen_buses = getindex.(Ref(regionlookup), gen_regionnames)
        region_order = sortperm(gen_buses)

        generators = Generators{N,L,T,P}(
            gen_names[region_order], gen_categories[region_order],
            Int.(read(f["generators/capacity"]))[region_order, :],
            read(f["generators/failureprobability"])[region_order, :],
            read(f["generators/repairprobability"])[region_order, :]
        )

        region_gen_idxs = makeidxlist(gen_buses[region_order], n_buses)

    else

        generators = Generators{N,L,T,P}(
            String[], String[], zeros(Int, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N))

        region_gen_idxs = fill(1:0, n_buses)

    end

    if has_storages

        stor_core = read(f["storages/_core"])
        stor_names, stor_categories, stor_regionnames = readvector.(
            Ref(stor_core), [:name, :category, :bus])

        stor_buses = getindex.(Ref(regionlookup), stor_regionnames)
        region_order = sortperm(stor_buses)

        storages = Storages{N,L,T,P,E}(
            stor_names[region_order], stor_categories[region_order],
            Int.(read(f["storages/chargecapacity"]))[region_order, :],
            Int.(read(f["storages/dischargecapacity"]))[region_order, :],
            Int.(read(f["storages/energycapacity"]))[region_order, :],
            read(f["storages/chargeefficiency"])[region_order, :],
            read(f["storages/dischargeefficiency"])[region_order, :],
            read(f["storages/carryoverefficiency"])[region_order, :],
            read(f["storages/failureprobability"])[region_order, :],
            read(f["storages/repairprobability"])[region_order, :]
        )

        region_stor_idxs = makeidxlist(stor_buses[region_order], n_buses)

    else

        storages = Storages{N,L,T,P,E}(
            String[], String[], 
            zeros(Int, 0, N), zeros(Int, 0, N), zeros(Int, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N), zeros(Float64, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N))

        region_stor_idxs = fill(1:0, n_buses)

    end


    if has_generatorstorages

        genstor_core = read(f["generatorstorages/_core"])
        genstor_names, genstor_categories, genstor_regionnames = readvector.(
            Ref(genstor_core), [:name, :category, :bus])

        genstor_buses = getindex.(Ref(regionlookup), genstor_regionnames)
        region_order = sortperm(genstor_buses)

        generatorstorages = GeneratorStorages{N,L,T,P,E}(
            genstor_names[region_order], genstor_categories[region_order],
            Int.(read(f["generatorstorages/chargecapacity"]))[region_order, :],
            Int.(read(f["generatorstorages/dischargecapacity"]))[region_order, :],
            Int.(read(f["generatorstorages/energycapacity"]))[region_order, :],
            read(f["generatorstorages/chargeefficiency"])[region_order, :],
            read(f["generatorstorages/dischargeefficiency"])[region_order, :],
            read(f["generatorstorages/carryoverefficiency"])[region_order, :],
            Int.(read(f["generatorstorages/inflow"]))[region_order, :],
            Int.(read(f["generatorstorages/gridwithdrawalcapacity"]))[region_order, :],
            Int.(read(f["generatorstorages/gridinjectioncapacity"]))[region_order, :],
            read(f["generatorstorages/failureprobability"])[region_order, :],
            read(f["generatorstorages/repairprobability"])[region_order, :])

        region_genstor_idxs = makeidxlist(genstor_buses[region_order], n_buses)

    else

        generatorstorages = GeneratorStorages{N,L,T,P,E}(
            String[], String[], 
            zeros(Int, 0, N), zeros(Int, 0, N), zeros(Int, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N), zeros(Float64, 0, N),
            zeros(Int, 0, N), zeros(Int, 0, N), zeros(Int, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N))

        region_genstor_idxs = fill(1:0, n_buses)

    end

    if has_interfaces

        interfaces_core = read(f["interfaces/_core"])
        from_regionnames, to_regionnames =
            readvector.(Ref(interfaces_core), [:region_from, :region_to])
        forwardcapacity = Int.(read(f["interfaces/forwardcapacity"]))
        backwardcapacity = Int.(read(f["interfaces/backwardcapacity"]))

        n_interfaces = length(from_regionnames)
        from_buses = getindex.(Ref(regionlookup), from_regionnames)
        to_buses = getindex.(Ref(regionlookup), to_regionnames)

        # Force interface definitions as smaller => larger bus numbers
        for i in 1:n_interfaces
            from_region = from_buses[i]
            to_region = to_buses[i]
            if from_region > to_region
                from_buses[i] = to_region
                to_buses[i] = from_region
                new_forwardcapacity = backwardcapacity[i, :]
                backwardcapacity[i, :] .= forwardcapacity[i, :]
                forwardcapacity[i, :] .= new_forwardcapacity
            elseif from_region == to_region
                error("Cannot have an interface to and from " *
                      "the same bus ($(from_region))")
            end
        end

        interfaces = Interfaces{N,P}(
            from_buses, to_buses, forwardcapacity, backwardcapacity)

        interface_lookup = Dict((r1, r2) => i for (i, (r1, r2))
                                in enumerate(tuple.(from_buses, to_buses)))

        branches_core = read(f["branches/_core"])
        line_names, line_categories, line_fromregionnames, line_toregionnames =
            readvector.(Ref(branches_core), [:name, :category, :region_from, :region_to])
        line_forwardcapacity = Int.(read(f["branches/forwardcapacity"]))
        line_backwardcapacity = Int.(read(f["branches/backwardcapacity"]))

        n_branches = length(line_names)
        line_frombuses = getindex.(Ref(regionlookup), line_fromregionnames)
        line_tobuses  = getindex.(Ref(regionlookup), line_toregionnames)

        # Force line definitions as smaller => larger bus numbers
        for i in 1:n_branches
            from_region = line_frombuses[i]
            to_region = line_tobuses[i]
            if from_region > to_region
                line_frombuses[i] = to_region
                line_tobuses[i] = from_region
                new_forwardcapacity = line_backwardcapacity[i, :]
                line_backwardcapacity[i, :] .= line_forwardcapacity[i, :]
                line_forwardcapacity[i, :] = new_forwardcapacity
            elseif from_region == to_region
                error("Cannot have a line ($(line_names[i])) to and from " *
                      "the same bus ($(from_region))")
            end
        end

        line_interfaces = getindex.(Ref(interface_lookup),
                                    tuple.(line_frombuses, line_tobuses))
        interface_order = sortperm(line_interfaces)

        branches = Branches{N,L,T,P}(
            line_names[interface_order], line_categories[interface_order],
            line_forwardcapacity[interface_order, :],
            line_backwardcapacity[interface_order, :],
            read(f["branches/failureprobability"])[interface_order, :],
            read(f["branches/repairprobability"])[interface_order, :])

        interface_line_idxs = makeidxlist(line_interfaces[interface_order], n_interfaces)

    else

        interfaces = Interfaces{N,P}(
            Int[], Int[], zeros(Int, 0, N), zeros(Int, 0, N))

        branches = Branches{N,L,T,P}(
            String[], String[], zeros(Int, 0, N), zeros(Int, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N))

        interface_line_idxs = UnitRange{Int}[]

    end

    return SystemModel(
        buses, interfaces,
        generators, region_gen_idxs,
        storages, region_stor_idxs,
        generatorstorages, region_genstor_idxs,
        branches, interface_line_idxs,
        timestamps)

end

"""
Attempts to parse the file's "vX.Y.Z" version label into (x::Int, y::Int, z::Int).
Errors if the label cannot be found or parsed as expected.
"""
function readversion(f::File)

    haskey(attributes(f), "pras_dataversion") || error(
          "File format version indicator could not be found - the file may " *
          "not be a PRAS SystemModel representation.")

    versionstring = read(attributes(f)["pras_dataversion"])

    version = match(r"^v(\d+)\.(\d+)\.(\d+)$", versionstring)
    isnothing(version) && error("File format version $versionstring not recognized")

    major, minor, patch = parse.(Int, version.captures)

    return (major, minor, patch), versionstring

end

"""
Attempts to extract a vector of elements from an HDF5 compound datatype,
corresponding to `field`.
"""
readvector(d::Dataset, field::Union{Symbol,Int}) = readvector(read(d), field)
readvector(d::Vector{<:NamedTuple}, field::Union{Symbol,Int}) = getindex.(d, field)
