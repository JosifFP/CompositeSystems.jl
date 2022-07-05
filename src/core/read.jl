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
            if XLSX.sheetnames(io)[i]=="buses" f[:buses] = string.(XLSX.gettable(io["buses"])[1][1])
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

    empty_buses = isempty(f[:buses][1][1])
    empty_generators =  isempty(f[:generators][1][1])
    empty_storages = isempty(f[:storages][1][1])
    empty_generatorstorages = isempty(f[:generatorstorages][1][1])
    empty_interfaces = isempty(f[:interfaces][1][1])
    empty_lines = isempty(f[:lines][1][1])

    if empty_buses error("Bus data must be provided") end
    if empty_generators && empty_generatorstorages error("Generator or generator storage data (or both) must be provided") end
    #if xor(has_interfaces, has_lines)==false error("Both (or neither) interface and line data must be provided") end

    #busnames = string.(f[:buses])
    buslookup = Dict(n=>i for (i, n) in enumerate(string.(f[:buses])))
    if size(string.(f[:buses])) == (1,)
        buses = Buses{N,P}(string.(f[:buses]), reshape(f[:total_load], 1, :))
    else
        buses = Buses{N,P}(string.(f[:buses]), copy(transpose(repeat(f[:total_load],1,2))))
    end
    
    if empty_generators
        generators = Generators{N,L,T,P}(String[], String[], zeros(Int, 0, N), zeros(Float64, 0), zeros(Float64, 0))
        bus_gen_idxs = fill(1:0, length(buses))       
    else
        gen_names =  string.(D_generators[:name])
        gen_categories = string.(D_generators[:category])
        gen_buses = getindex.(Ref(buslookup), string.(D_generators[:bus]))
        bus_order = sortperm(gen_buses)
        gen_capacity = repeat(round.(Int, D_generators[:Pmax]), 1, N)
        failureprobability = float.(D_generators[:failureprobability])/N
        repairprobability = float.(D_generators[:repairprobability])/N
        generators = Generators{N,L,T,P}(
            gen_names[bus_order], gen_categories[bus_order],
            gen_capacity[bus_order, :],
            failureprobability[bus_order],
            repairprobability[bus_order]
        )

        bus_gen_idxs = makeidxlist(gen_buses[bus_order], length(buses))
    end

    if empty_storages
        storages = Storages{N,L,T,P,E}(
            String[], String[], 
            zeros(Int, 0, N), zeros(Int, 0, N), zeros(Int, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N), zeros(Float64, 0, N),
            zeros(Float64, 0), zeros(Float64, 0))

        bus_stor_idxs = fill(1:0, length(buses))
    
    else
        stor_names =  string.(D_storages[:name])
        stor_categories = string.(D_storages[:category])
        stor_buses = getindex.(Ref(buslookup), string.(D_storages[:bus]))
        bus_order = sortperm(stor_buses)
        chargecapacity = repeat(round.(Int, D_storages[:chargecapacity]), 1, N)
        dischargecapacity = repeat(round.(Int, D_storages[:dischargecapacity]), 1, N)
        energycapacity = repeat(round.(Int, D_storages[:energycapacity]), 1, N)
        chargeefficiency = repeat(float.(D_storages[:chargeefficiency]), 1, N)
        dischargeefficiency = repeat(float.(D_storages[:dischargeefficiency]), 1, N)
        carryoverefficiency = repeat(float.(D_storages[:carryoverefficiency]), 1, N)
        dischargeefficiency = repeat(float.(D_storages[:dischargeefficiency]), 1, N)       
        failureprobability = float.(D_storages[:failureprobability])
        repairprobability = float.(D_storages[:repairprobability])

        storages = Storages{N,L,T,P,E}(
            stor_names[bus_order], stor_categories[bus_order],
            chargecapacity[bus_order, :],
            dischargecapacity[bus_order, :],
            energycapacity[bus_order, :],
            chargeefficiency[bus_order, :],
            dischargeefficiency[bus_order, :],
            carryoverefficiency[bus_order, :],
            failureprobability[bus_order],
            repairprobability[bus_order]
        )

        bus_stor_idxs = makeidxlist(stor_buses[bus_order], length(buses))
    end

    if empty_generatorstorages
        generatorstorages = GeneratorStorages{N,L,T,P,E}(
            String[], String[], 
            zeros(Int, 0, N), zeros(Int, 0, N), zeros(Int, 0, N),
            zeros(Float64, 0, N), zeros(Float64, 0, N), zeros(Float64, 0, N),
            zeros(Int, 0, N), zeros(Int, 0, N), zeros(Int, 0, N),
            zeros(Float64, 0), zeros(Float64, 0))

        bus_genstor_idxs = fill(1:0, length(buses))

    else
        genstor_names =  string.(D_generatorstorages[:name])
        genstor_categories = string.(D_generatorstorages[:category])
        genstor_buses = getindex.(Ref(buslookup), string.(D_generatorstorages[:bus]))
        bus_order = sortperm(genstor_buses)
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

        failureprobability = float.(D_generatorstorages[:failureprobability])
        repairprobability = float.(D_generatorstorages[:repairprobability])

        generatorstorages = GeneratorStorages{N,L,T,P,E}(
            genstor_names[bus_order], genstor_categories[bus_order],
            chargecapacity[bus_order, :],
            dischargecapacity[bus_order, :],
            energycapacity[bus_order, :],
            chargeefficiency[bus_order, :],
            dischargeefficiency[bus_order, :],
            carryoverefficiency[bus_order, :],
            gridinjectioncapacity[bus_order, :],
            gridwithdrawalcapacity[bus_order, :],
            inflow[bus_order, :],
            failureprobability[bus_order],
            repairprobability[bus_order]
        )

        bus_genstor_idxs = makeidxlist(genstor_buses[bus_order], length(buses))
    end

    if empty_interfaces
        interfaces = Interfaces{N,P}(
            Int[], Int[], zeros(Int, 0, N), zeros(Int, 0, N))

        lines = Lines{N,L,T,P}(
            String[], String[], zeros(Int, 0, N), zeros(Int, 0, N),
            zeros(Float64, 0), zeros(Float64, 0))

        interface_line_idxs = UnitRange{Int}[]
    
    else
        forwardcapacity = repeat(round.(Int, D_interfaces[:forwardcapacity]), 1, N)
        backwardcapacity = repeat(round.(Int, D_interfaces[:backwardcapacity]), 1, N)
        n_interfaces = length(string.(D_interfaces[:bus_from]))
        from_buses = getindex.(Ref(buslookup), string.(D_interfaces[:bus_from]))
        to_buses = getindex.(Ref(buslookup), string.(D_interfaces[:bus_to]))

        # Force interface definitions as smaller => larger bus numbers
        for i in 1:n_interfaces
            from_bus = from_buses[i]
            to_bus = to_buses[i]
            if from_bus > to_bus
                from_buses[i] = to_bus
                to_buses[i] = from_bus
                new_forwardcapacity = backwardcapacity[i, :]
                backwardcapacity[i, :] .= forwardcapacity[i, :]
                forwardcapacity[i, :] .= new_forwardcapacity
            elseif from_bus == to_bus
                error("Cannot have an interface to and from " *
                      "the same bus ($(from_bus))")
            end
        end
        interfaces = Interfaces{N,P}(from_buses, to_buses, forwardcapacity, backwardcapacity)
        interface_lookup = Dict((r1, r2) => i for (i, (r1, r2)) in enumerate(tuple.(from_buses, to_buses)))

        #lines

        line_names = string.(D_lines[:name])
        line_categories = string.(D_lines[:category])
        line_forwardcapacity = repeat(round.(Int, D_lines[:forwardcapacity]), 1, N)
        line_backwardcapacity = repeat(round.(Int, D_lines[:backwardcapacity]), 1, N)
        line_frombuses = getindex.(Ref(buslookup), string.(D_lines[:bus_from]))
        line_tobuses  = getindex.(Ref(buslookup), string.(D_lines[:bus_to]))

        failureprobability = float.(D_lines[:failureprobability])
        repairprobability = float.(D_lines[:repairprobability])

        # Force line definitions as smaller => larger bus numbers
        for i in 1:length(line_names)
            from_bus = line_frombuses[i]
            to_bus = line_tobuses[i]
            if from_bus > to_bus
                line_frombuses[i] = to_bus
                line_tobuses[i] = from_bus
                new_forwardcapacity = line_backwardcapacity[i, :]
                line_backwardcapacity[i, :] .= line_forwardcapacity[i, :]
                line_forwardcapacity[i, :] = new_forwardcapacity
            elseif from_bus == to_bus
                error("Cannot have a line ($(line_names[i])) to and from " *
                      "the same bus ($(from_bus))")
            end
        end

        line_interfaces = getindex.(Ref(interface_lookup), tuple.(line_frombuses, line_tobuses))
        interface_order = sortperm(line_interfaces)

        lines = Lines{N,L,T,P}(
            line_names[interface_order], line_categories[interface_order],
            line_forwardcapacity[interface_order, :],
            line_backwardcapacity[interface_order, :],
            failureprobability[interface_order],
            repairprobability[interface_order])

        interface_line_idxs = makeidxlist(line_interfaces[interface_order], n_interfaces)

    end

    return SystemModel(buses, interfaces,
        generators, bus_gen_idxs,
        storages, bus_stor_idxs,
        generatorstorages, bus_genstor_idxs,
        lines, interface_line_idxs,
        timestamps
    )
end