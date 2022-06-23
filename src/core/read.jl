include("read_h5.jl")

"""
    SystemModel(filename::String)

Load a `SystemModel` from an appropriately-formatted XLSX or HDF5 file on disk.
"""
function SystemModel(inputfile::String)

    if contains(inputfile, "pras") || contains(inputfile, "hdf5")
        system = h5open(inputfile, "r") do f::File
            version, versionstring = readversion(f)
            # Determine the appropriate version of the importer to use
            return if (0,5,0) <= version < (0,7,0)
                systemmodel_0_5(f)
            else
                error("PRAS file format $versionstring not supported by this version of PRASBase.")
            end
        end
    else
        SystemModel_XLSX(inputfile)
    end
end

function SystemModel_XLSX(inputfile::String)

    f = Dict{Symbol,Any}()
    XLSX.openxlsx(inputfile, enable_cache=false) do io
        for i in 1:XLSX.sheetcount(io)
            if XLSX.sheetnames(io)[i]=="regions" f[:regions] = string.(XLSX.gettable(io["regions"])[1][1])
            else f[Symbol(XLSX.sheetnames(io)[i])] = XLSX.gettable(io[XLSX.sheetnames(io)[i]]) end
        end
        f[:total_load] = zeros(Int64,length(f[:loads][1][1]))
    end;

    D_generators = Dict(f[:generators][2][i] => f[:generators][1][i] for i in 1:length(f[:generators][2]))
    D_storages = Dict(f[:storages][2][i] => f[:storages][1][i] for i in 1:length(f[:storages][2]))
    D_generatorstorages = Dict(f[:generatorstorages][2][i] => filter(!ismissing, f[:generatorstorages][1][i]) for i in 1:length(f[:generatorstorages][2]))
    D_lines = Dict(f[:lines][2][i] => f[:lines][1][i] for i in 1:length(f[:lines][2]))
    D_interfaces = Dict(f[:interfaces][2][i] => f[:interfaces][1][i] for i in 1:length(f[:interfaces][2]))
    D_loads = Dict(f[:loads][2][i] => Vector{Any}() for i in 1:length(f[:loads][2]))

    for i in 1:length(f[:loads][2])
        if f[:loads][2][i] == :time
            for n in 1:length(f[:loads][1][1])
                if typeof(f[:loads][1][1][n]) == Date
                    push!(D_loads[f[:loads][2][i]], DateTime(f[:loads][1][1][n]))
                else
                    push!(D_loads[f[:loads][2][i]],f[:loads][1][1][n])
                end
            end
        else
            D_loads[f[:loads][2][i]] = round.(Int64,f[:loads][1][i])
            if occursin("MW",string(f[:loads][2][i])) == true
                D_loads[f[:loads][2][i]] = round.(Int64,f[:loads][1][i])
                f[:total_load]+= round.(Int64,f[:loads][1][i])
            end
        end
    end

    #T = timeunits["h"]
    start_timestamp = DateTime(D_loads[:time][1])
    N = length(D_loads[:time])
    L = hour(D_loads[:time][2])-hour(D_loads[:time][1])
    T = typeof(Hour(D_loads[:time][2]-D_loads[:time][1]))
    P = powerunits["MW"]
    E = energyunits[string(P)*"h"]
    timestamps = range(start_timestamp, length=N, step=T(L))

    empty_regions = isempty(f[:regions][1][1])
    empty_generators =  isempty(f[:generators][1][1])
    empty_storages = isempty(f[:storages][1][1])
    empty_generatorstorages = isempty(f[:generatorstorages][1][1])
    empty_interfaces = isempty(f[:interfaces][1][1])
    empty_lines = isempty(f[:lines][1][1])

    if empty_regions error("Region data must be provided") end
    if empty_generators && empty_generatorstorages error("Generator or generator storage data (or both) must be provided") end
    #if xor(has_interfaces, has_lines)==false error("Both (or neither) interface and line data must be provided") end

    #regionnames = string.(f[:regions])
    regionlookup = Dict(n=>i for (i, n) in enumerate(string.(f[:regions])))
    if size(string.(f[:regions])) == (1,)
        regions = Regions{N,P}(string.(f[:regions]), reshape(f[:total_load], 1, :))
    else
        regions = Regions{N,P}(string.(f[:regions]), copy(transpose(repeat(f[:total_load],1,2))))
    end
    
    if empty_generators
        generators = Generators{N,L,T,P}(String[], String[], zeros(Int, 0, N), zeros(Float64, 0, N), zeros(Float64, 0, N))
        region_gen_idxs = fill(1:0, length(regions))       
    else
        gen_names =  string.(D_generators[:name])
        gen_categories = string.(D_generators[:category])
        gen_regions = getindex.(Ref(regionlookup), string.(D_generators[:region]))
        region_order = sortperm(gen_regions)
        gen_capacity = repeat(round.(Int, D_generators[:Pmax]), 1, N)
        failureprobability = repeat(float.(D_generators[:failureprobability])/N, 1, N)
        repairprobability = repeat(float.(D_generators[:repairprobability])/N, 1, N)
        #failureprobability = repeat(float.(D_generators[:failureprobability]), 1, N)
        #repairprobability = repeat(float.(D_generators[:repairprobability]), 1, N)

        generators = Generators{N,L,T,P}(
            gen_names[region_order], gen_categories[region_order],
            gen_capacity[region_order, :],
            failureprobability[region_order, :],
            repairprobability[region_order, :]
        )

        region_gen_idxs = makeidxlist(gen_regions[region_order], length(regions))
    end

    if empty_storages
        storages = Storages{N,L,T,P,E}(
            String[], String[], 
            zeros(Int, 0, N), zeros(Int, 0, N), zeros(Int, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N), zeros(Float64, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N))

        region_stor_idxs = fill(1:0, length(regions))
    
    else
        stor_names =  string.(D_storages[:name])
        stor_categories = string.(D_storages[:category])
        stor_regions = getindex.(Ref(regionlookup), string.(D_storages[:region]))
        region_order = sortperm(stor_regions)
        chargecapacity = repeat(round.(Int, D_storages[:chargecapacity]), 1, N)
        dischargecapacity = repeat(round.(Int, D_storages[:dischargecapacity]), 1, N)
        energycapacity = repeat(round.(Int, D_storages[:energycapacity]), 1, N)
        chargeefficiency = repeat(float.(D_storages[:chargeefficiency]), 1, N)
        dischargeefficiency = repeat(float.(D_storages[:dischargeefficiency]), 1, N)
        carryoverefficiency = repeat(float.(D_storages[:carryoverefficiency]), 1, N)
        dischargeefficiency = repeat(float.(D_storages[:dischargeefficiency]), 1, N)       
        failureprobability = repeat(float.(D_storages[:failureprobability]), 1, N)
        repairprobability = repeat(float.(D_storages[:repairprobability]), 1, N)

        storages = Storages{N,L,T,P,E}(
            stor_names[region_order], stor_categories[region_order],
            chargecapacity[region_order, :],
            dischargecapacity[region_order, :],
            energycapacity[region_order, :],
            chargeefficiency[region_order, :],
            dischargeefficiency[region_order, :],
            carryoverefficiency[region_order, :],
            failureprobability[region_order, :],
            repairprobability[region_order, :]
        )

        region_stor_idxs = makeidxlist(stor_regions[region_order], length(regions))
    end

    if empty_generatorstorages
        generatorstorages = GeneratorStorages{N,L,T,P,E}(
            String[], String[], 
            zeros(Int, 0, N), zeros(Int, 0, N), zeros(Int, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N), zeros(Float64, 0, N),
            zeros(Int, 0, N), zeros(Int, 0, N), zeros(Int, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N))

        region_genstor_idxs = fill(1:0, length(regions))

    else
        genstor_names =  string.(D_generatorstorages[:name])
        genstor_categories = string.(D_generatorstorages[:category])
        genstor_regions = getindex.(Ref(regionlookup), string.(D_generatorstorages[:region]))
        region_order = sortperm(genstor_regions)
        chargecapacity = repeat(round.(Int, D_generatorstorages[:chargecapacity]), 1, N)
        dischargecapacity = repeat(round.(Int, D_generatorstorages[:dischargecapacity]), 1, N)
        energycapacity = repeat(round.(Int, D_generatorstorages[:energycapacity]), 1, N)
        chargeefficiency = repeat(float.(D_generatorstorages[:chargeefficiency]), 1, N)
        dischargeefficiency = repeat(float.(D_generatorstorages[:dischargeefficiency]), 1, N)
        carryoverefficiency = repeat(float.(D_generatorstorages[:carryoverefficiency]), 1, N)
        dischargeefficiency = repeat(float.(D_generatorstorages[:dischargeefficiency]), 1, N)       

        gridinjectioncapacity = repeat(round.(Int, D_generatorstorages[:gridinjectioncapacity]), 1, N)
        gridwithdrawalcapacity = repeat(round.(Int, D_generatorstorages[:gridwithdrawalcapacity]), 1, N)
        inflow = reshape(round.(Int, D_generatorstorages[:inflow]), 1, :)

        failureprobability = repeat(float.(D_generatorstorages[:failureprobability]), 1, N)
        repairprobability = repeat(float.(D_generatorstorages[:repairprobability]), 1, N)

        generatorstorages = GeneratorStorages{N,L,T,P,E}(
            genstor_names[region_order], genstor_categories[region_order],
            chargecapacity[region_order, :],
            dischargecapacity[region_order, :],
            energycapacity[region_order, :],
            chargeefficiency[region_order, :],
            dischargeefficiency[region_order, :],
            carryoverefficiency[region_order, :],
            gridinjectioncapacity[region_order, :],
            gridwithdrawalcapacity[region_order, :],
            inflow[region_order, :],
            failureprobability[region_order, :],
            repairprobability[region_order, :]
        )

        region_genstor_idxs = makeidxlist(genstor_regions[region_order], length(regions))
    end

    if empty_interfaces
        interfaces = Interfaces{N,P}(
            Int[], Int[], zeros(Int, 0, N), zeros(Int, 0, N))

        lines = Lines{N,L,T,P}(
            String[], String[], zeros(Int, 0, N), zeros(Int, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N))

        interface_line_idxs = UnitRange{Int}[]
    
    else
        forwardcapacity = repeat(round.(Int, D_interfaces[:forwardcapacity]), 1, N)
        backwardcapacity = repeat(round.(Int, D_interfaces[:backwardcapacity]), 1, N)
        n_interfaces = length(string.(D_interfaces[:region_from]))
        from_regions = getindex.(Ref(regionlookup), string.(D_interfaces[:region_from]))
        to_regions = getindex.(Ref(regionlookup), string.(D_interfaces[:region_to]))

        # Force interface definitions as smaller => larger region numbers
        for i in 1:n_interfaces
            from_region = from_regions[i]
            to_region = to_regions[i]
            if from_region > to_region
                from_regions[i] = to_region
                to_regions[i] = from_region
                new_forwardcapacity = backwardcapacity[i, :]
                backwardcapacity[i, :] .= forwardcapacity[i, :]
                forwardcapacity[i, :] .= new_forwardcapacity
            elseif from_region == to_region
                error("Cannot have an interface to and from " *
                      "the same region ($(from_region))")
            end
        end
        interfaces = Interfaces{N,P}(from_regions, to_regions, forwardcapacity, backwardcapacity)
        interface_lookup = Dict((r1, r2) => i for (i, (r1, r2)) in enumerate(tuple.(from_regions, to_regions)))

        #lines

        line_names = string.(D_lines[:name])
        line_categories = string.(D_lines[:category])
        line_forwardcapacity = repeat(round.(Int, D_lines[:forwardcapacity]), 1, N)
        line_backwardcapacity = repeat(round.(Int, D_lines[:backwardcapacity]), 1, N)
        line_fromregions = getindex.(Ref(regionlookup), string.(D_lines[:region_from]))
        line_toregions  = getindex.(Ref(regionlookup), string.(D_lines[:region_to]))

        failureprobability = repeat(float.(D_lines[:failureprobability]), 1, N)
        repairprobability = repeat(float.(D_lines[:repairprobability]), 1, N)

        # Force line definitions as smaller => larger region numbers
        for i in 1:length(line_names)
            from_region = line_fromregions[i]
            to_region = line_toregions[i]
            if from_region > to_region
                line_fromregions[i] = to_region
                line_toregions[i] = from_region
                new_forwardcapacity = line_backwardcapacity[i, :]
                line_backwardcapacity[i, :] .= line_forwardcapacity[i, :]
                line_forwardcapacity[i, :] = new_forwardcapacity
            elseif from_region == to_region
                error("Cannot have a line ($(line_names[i])) to and from " *
                      "the same region ($(from_region))")
            end
        end

        line_interfaces = getindex.(Ref(interface_lookup), tuple.(line_fromregions, line_toregions))
        interface_order = sortperm(line_interfaces)

        lines = Lines{N,L,T,P}(
            line_names[interface_order], line_categories[interface_order],
            line_forwardcapacity[interface_order, :],
            line_backwardcapacity[interface_order, :],
            failureprobability[interface_order, :],
            repairprobability[interface_order, :])

        interface_line_idxs = makeidxlist(line_interfaces[interface_order], n_interfaces)

    end

    return SystemModel(regions, interfaces,
        generators, region_gen_idxs,
        storages, region_stor_idxs,
        generatorstorages, region_genstor_idxs,
        lines, interface_line_idxs,
        timestamps
    )
end