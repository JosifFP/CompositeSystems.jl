""
function initialize_pm_containers!(pm::AbstractDCPowerModel, system::SystemModel; timeseries=false)

    @assert !timeseries "Timeseries containers not supported"
    #add_var_container!(pm.var, :pg, field(system, :generators, :keys), timesteps = 1:N)
    add_var_container!(pm.var, :pg, field(system, :generators, :keys))
    add_var_container!(pm.var, :va, field(system, :buses, :keys))
    add_var_container!(pm.var, :z_branch, field(system, :branches, :keys))
    add_var_container!(pm.var, :z_demand, field(system, :loads, :keys))
    add_var_container!(pm.var, :z_shunt, field(system, :shunts, :keys))
    add_var_container!(pm.var, :p, field(pm.topology, :arcs_available))

    add_con_container!(pm.con, :power_balance_p, field(system, :buses, :keys))
    add_con_container!(pm.con, :ohms_yt_from_lower_p, field(system, :branches, :keys))
    add_con_container!(pm.con, :ohms_yt_from_upper_p, field(system, :branches, :keys))
    add_con_container!(pm.con, :ohms_yt_to_lower_p, field(system, :branches, :keys))
    add_con_container!(pm.con, :ohms_yt_to_upper_p, field(system, :branches, :keys))
    add_con_container!(pm.con, :voltage_angle_diff_upper, field(system, :branches, :keys))
    add_con_container!(pm.con, :voltage_angle_diff_lower, field(system, :branches, :keys))
    add_con_container!(pm.con, :thermal_limit_from, field(system, :branches, :keys))
    add_con_container!(pm.con, :thermal_limit_to, field(system, :branches, :keys))

    add_var_container!(pm.var, :ps, field(system, :storages, :keys))
    add_var_container!(pm.var, :stored_energy, field(system, :storages, :keys))
    add_var_container!(pm.var, :sc, field(system, :storages, :keys))
    add_var_container!(pm.var, :sd, field(system, :storages, :keys))
    add_var_container!(pm.var, :sc_on, field(system, :storages, :keys))
    add_var_container!(pm.var, :sd_on, field(system, :storages, :keys))

    add_con_container!(pm.con, :storage_state, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_complementarity_mi_1, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_complementarity_mi_2, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_complementarity_mi_3, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_losses, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_thermal_lower_limit, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_thermal_upper_limit, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_losses, field(system, :storages, :keys))
    return
end

""
function initialize_pm_containers!(pm::AbstractLPACModel, system::SystemModel; timeseries=false)

    @assert !timeseries "Timeseries containers not supported"
    #add_var_container!(pm.var, :pg, field(system, :generators, :keys), timesteps = 1:N)
    add_var_container!(pm.var, :pg, field(system, :generators, :keys))
    add_var_container!(pm.var, :qg, field(system, :generators, :keys))
    add_var_container!(pm.var, :va, field(system, :buses, :keys))
    add_var_container!(pm.var, :phi, field(system, :buses, :keys))
    add_var_container!(pm.var, :z_branch, field(system, :branches, :keys))
    add_var_container!(pm.var, :phi_fr, field(system, :branches, :keys))
    add_var_container!(pm.var, :phi_to, field(system, :branches, :keys))
    add_var_container!(pm.var, :td, field(system, :branches, :keys))
    add_var_container!(pm.var, :cs, field(system, :branches, :keys))
    add_var_container!(pm.var, :z_demand, field(system, :loads, :keys))
    add_var_container!(pm.var, :z_shunt, field(system, :shunts, :keys))
    add_var_container!(pm.var, :p, field(pm.topology, :arcs_available))
    add_var_container!(pm.var, :q, field(pm.topology, :arcs_available))

    add_con_container!(pm.con, :power_balance_p, field(system, :buses, :keys))
    add_con_container!(pm.con, :power_balance_q, field(system, :buses, :keys))
    add_con_container!(pm.con, :ohms_yt_from_p, field(system, :branches, :keys))
    add_con_container!(pm.con, :ohms_yt_to_p, field(system, :branches, :keys))
    add_con_container!(pm.con, :ohms_yt_from_q, field(system, :branches, :keys))
    add_con_container!(pm.con, :ohms_yt_to_q, field(system, :branches, :keys))
    add_con_container!(pm.con, :voltage_angle_diff_upper, field(system, :branches, :keys))
    add_con_container!(pm.con, :voltage_angle_diff_lower, field(system, :branches, :keys))
    add_con_container!(pm.con, :model_voltage, keys(field(pm.topology, :buspairs_available)))
    add_con_container!(pm.con, :model_voltage_upper, field(system, :branches, :keys))
    add_con_container!(pm.con, :model_voltage_lower, field(system, :branches, :keys))
    add_con_container!(pm.con, :relaxation_cos_upper, field(system, :branches, :keys))
    add_con_container!(pm.con, :relaxation_cos_lower, field(system, :branches, :keys))
    add_con_container!(pm.con, :relaxation_cos, field(system, :branches, :keys))
    add_con_container!(pm.con, :thermal_limit_from, field(system, :branches, :keys))
    add_con_container!(pm.con, :thermal_limit_to, field(system, :branches, :keys))

    add_var_container!(pm.var, :ccms, field(system, :storages, :keys))
    add_var_container!(pm.var, :ps, field(system, :storages, :keys))
    add_var_container!(pm.var, :qs, field(system, :storages, :keys))
    add_var_container!(pm.var, :qsc, field(system, :storages, :keys))
    add_var_container!(pm.var, :stored_energy, field(system, :storages, :keys))
    add_var_container!(pm.var, :sc, field(system, :storages, :keys))
    add_var_container!(pm.var, :sd, field(system, :storages, :keys))
    add_var_container!(pm.var, :sc_on, field(system, :storages, :keys))
    add_var_container!(pm.var, :sd_on, field(system, :storages, :keys))

    add_con_container!(pm.con, :storage_state, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_complementarity_mi_1, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_complementarity_mi_2, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_complementarity_mi_3, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_losses, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_thermal_limit, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_losses_p, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_losses_q, field(system, :storages, :keys))
    add_con_container!(pm.con, :storage_losses, field(system, :storages, :keys))
    return
end

"""
Returns the container specification for the selected type of JuMP Model
"""
function _container_spec(::Type{T}, axs...) where {T <: Any}
    return DenseAxisArray{T}(undef, axs...)
end

""
function _container_spec(::Type{Float64}, axs...)
    cont = DenseAxisArray{Float64}(undef, axs...)
    #cont.data .= fill(NaN, size(cont.data))
    fill!(cont.data, 0.0)
    return cont
end

""
function container_spec(array::T, timesteps::UnitRange{Int}) where T <: AbstractArray
    tmp = DenseAxisArray{T}(undef, [i for i in timesteps])
    cont = fill!(tmp, array)
    return cont
end

""
function container_spec(dictionary::Dict{Tuple{Int, Int}, Any}, timesteps::UnitRange{Int})
    tmp = DenseAxisArray{Dict}(undef, [i for i in timesteps])
    cont = fill!(tmp, dictionary)
    return cont
end

""
function container_spec(
    dictionary::Dict{Tuple{Int, Int, Int}, Any}, timesteps::UnitRange{Int})
    tmp = DenseAxisArray{Dict}(undef, [i for i in timesteps])
    cont = fill!(tmp, dictionary)
    return cont
end

""
function add_sol_container!(
    container::Dict{Symbol, T}, var_key::Symbol, keys::Vector{Int}; 
    timesteps::UnitRange{Int}=1:1) where {T <: Matrix{Float64}}

    var_container = _container_spec(Float64, keys, timesteps)
    _assign_container!(container, var_key, var_container)
    return
end

""
function add_con_container!(
    container::Dict{Symbol, T}, con_key::Symbol, keys::Vector{Int}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.ConstraintRef, keys)
    con_container = container_spec(value, timesteps)
    _assign_container!(container, con_key, con_container)
    return
end

""
function add_con_container!(
    container::Dict{Symbol, T}, con_key::Symbol, keys::Base.KeySet{Tuple{Int, Int}}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.ConstraintRef, keys)
    con_container = container_spec(value, timesteps)
    _assign_container!(container, con_key, con_container)
    return
end

""
function add_con_container!(
    container::Dict{Symbol, T}, con_key::Symbol, keys::Vector{Tuple{Int, Int}}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.ConstraintRef, keys)
    con_container = container_spec(value, timesteps)
    _assign_container!(container, con_key, con_container)
    return
end

""
function add_var_container!(
    container::Dict{Symbol, T}, var_key::Symbol, keys::Vector{Int}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.VariableRef, keys)
    var_container = container_spec(value, timesteps)
    _assign_container!(container, var_key, var_container)
    return
end


""
function add_var_container!(
    container::Dict{Symbol, T}, con_key::Symbol, keys::Base.KeySet{Tuple{Int, Int}}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.VariableRef, keys)
    con_container = container_spec(value, timesteps)
    _assign_container!(container, con_key, con_container)
    return
end

""
function add_var_container!(
    container::Dict{Symbol, T}, var_key::Symbol, dict_keys::Dict{Tuple{Int, Int}, Union{Missing, Vector{Any}}}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = Dict{Tuple{Int, Int}, Any}(((i,j), undef) for (i,j) in keys(dict_keys))
    var_container = container_spec(value, timesteps)
    _assign_container!(container, var_key, var_container)
    return var_container
end

""
function add_var_container!(
    container::Dict{Symbol, T}, var_key::Symbol, keys::Vector{Union{Missing, Tuple{Int, Int, Int}}}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in keys)
    var_container = container_spec(value, timesteps)
    _assign_container!(container, var_key, var_container)
    return var_container
end

""
function _assign_container!(container::Dict, key::Symbol, value)
    #if haskey(container, key)
        #@error "$(key) is already stored"
    #end
    container[key] = value
    return
end

""
function reset_var_container!(container::DenseAxisArray{T}, keys::Vector{Union{Missing, Tuple{Int, Int, Int}}}; 
    timesteps::UnitRange{Int}=1:1) where {T <: Dict}

    value = Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), undef) for (l,i,j) in keys)
    for i in timesteps
        container[i] = value
    end
    return
end

""
function reset_var_container!(container::DenseAxisArray{T}, keys::Vector{Int}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.VariableRef, keys)
    for i in timesteps
        container[i] = value
    end
    return
end

""
function reset_con_container!(container::DenseAxisArray{T}, keys::Vector{Int}; 
    timesteps::UnitRange{Int}=1:1) where {T <: AbstractArray}

    value = _container_spec(JuMP.ConstraintRef, keys)
    for i in timesteps
        container[i] = value
    end
    return
end

""
function calc_branch_y(branches::Branches, i::Int)
    y = pinv(field(branches, :r)[i] + im * field(branches, :x)[i])
    g, b = real(y), imag(y)
    return g, b
end

""
function calc_branch_t(branches::Branches, i::Int)
    tr = field(branches, :tap)[i] .* cos.(field(branches, :shift)[i])
    ti = field(branches, :tap)[i] .* sin.(field(branches, :shift)[i])
    return tr, ti
end

""
function _phi_to_vm(solution::Dict)
    vm = Dict{Int, Float32}()
    for (i, phi) in solution
        get!(vm, i, 1.0 + phi)
    end
    return vm
end

""
function objective_value(opf_model::Model)
    obj_val = NaN
    try
        obj_val = JuMP.objective_value(opf_model)
    catch
    end
    return obj_val
end

""
function record_curtailed_load!(pm::AbstractDCPowerModel, system::SystemModel, t::Int; nw::Int=1, is_solved::Bool=true)

    if is_solved
        var = OPF.var(pm, :z_demand, nw)

        for i in field(system, :loads, :buses)
            
            topology(pm, :buses_curtailed_pd)[i] = sum(
                field(system, :loads, :pd)[k,t]*(
                    1.0 - _IM.build_solution_values(var[k])) for k in topology(pm, :buses_loads_base)[i])

        end
    else
        fill!(topology(pm, :buses_curtailed_pd), 0.0)
    end
end

""
function record_curtailed_load!(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1, is_solved::Bool=true)

    if is_solved
        var = OPF.var(pm, :z_demand, nw)

        for i in field(system, :loads, :buses)
            
            topology(pm, :buses_curtailed_pd)[i] = sum(
                field(system, :loads, :pd)[k,t]*(
                    1.0 - _IM.build_solution_values(var[k])) for k in topology(pm, :buses_loads_base)[i]; init=0.0)

            topology(pm, :buses_curtailed_qd)[i] = sum(
                field(system, :loads, :pd)[k,t]*field(system, :loads, :pf)[k]*(
                    1.0 - _IM.build_solution_values(var[k])) for k in topology(pm, :buses_loads_base)[i]; init=0.0)

        end
    else
        fill!(topology(pm, :buses_curtailed_pd), 0.0)
        fill!(topology(pm, :buses_curtailed_qd), 0.0)
    end
end



""
function record_stored_energy!(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1, is_solved::Bool=true)
    
    if is_solved
        var = OPF.var(pm, :stored_energy, nw)

        for i in field(system, :storages, :keys)
            if topology(pm, :storages_available)[i]
                axs =  axes(var)[1]
                if i in axs
                    topology(pm, :stored_energy)[i] = _IM.build_solution_values(var[i])
                end
            else
                topology(pm, :stored_energy)[i] = 0.0
            end
        end
    else
        fill!(topology(pm, :stored_energy), 0.0)
    end
end

""
function record_flow_branch!(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1, is_solved::Bool=true)

    if is_solved
        var = OPF.var(pm, :p, nw)
        f_bus = field(system, :branches, :f_bus)
        t_bus = field(system, :branches, :t_bus)

        for (l,i,j) in keys(var)
            if topology(pm, :branches_available)[l]
                if f_bus[l] == i && t_bus[l] == j
                    topology(pm, :branches_flow_from)[l] = _IM.build_solution_values(var[(l,i,j)]) # Active power withdrawn at the from bus
                elseif f_bus[l] == j && t_bus[l] == i
                    topology(pm, :branches_flow_to)[l] = _IM.build_solution_values(var[(l,i,j)]) # Active power withdrawn at the to bus
                end
            else
                topology(pm, :branches_flow_from)[l] = 0.0
                topology(pm, :branches_flow_to)[l] =  0.0
            end
        end
    else
        fill!(topology(pm, :branches_flow_from), 0.0)
        fill!(topology(pm, :branches_flow_to), 0.0)
    end
end

"Build solution dictionary of the argunment of type DenseAxisArray"
function build_sol_values(var::DenseAxisArray)

    axs =  axes(var)[1]

    if typeof(axs) == Vector{Tuple{Int, Int}}
        sol = Dict{Tuple{Int, Int}, Any}()
    elseif typeof(axs) == Vector{Int}
        sol = Dict{Int, Any}()
    else
        typeof(axs) == Union{Vector{Tuple{Int, Int}}, Vector{Int}}
    end

    for key in axs
        sol[key] = _IM.build_solution_values(var[key])
    end

    return sol
end

""
build_sol_values(var::Dict{Tuple{Int, Int, Int}, Any}) = _IM.build_solution_values(var)

"Build solution dictionary of active flows per branch"
function build_sol_values(var::Dict{Tuple{Int, Int, Int}, JuMP.VariableRef}, branches::Branches)

    dict_p = sort(_IM.build_solution_values(var))
    tuples = keys(sort(var))
    sol = Dict{Int, Any}()

    for (l,i,j) in tuples
        k = string((l,i,j))
        if !haskey(sol, l)
            if branches.f_bus[l] == i && branches.t_bus[l] == j
                get!(sol, l, Dict{String, Any}("from"=>dict_p[k])) # Active power withdrawn at the from bus
            elseif branches.f_bus[l] == j && branches.t_bus[l] == i
                get!(sol, l, Dict{String, Any}("to"=>dict_p[k])) # Active power withdrawn at the to bus
            end
        elseif haskey(sol, l)
            if branches.f_bus[l] == i && branches.t_bus[l] == j
                get!(sol[l], "from", dict_p[k])
            elseif branches.f_bus[l] == j && branches.t_bus[l] == i
                get!(sol[l], "to", dict_p[k])
            end
        end
    end
    return sol
end

"Build solution dictionary of active flows per branch"
function build_sol_values(var::Dict{Tuple{Int, Int, Int}, Any}, branches::Branches)

    dict_p = sort(_IM.build_solution_values(var))
    tuples = keys(sort(var))
    sol = Dict{Int, Any}()

    for (l,i,j) in tuples
        k = string((l,i,j))
        if !haskey(sol, l)
            if branches.f_bus[l] == i && branches.t_bus[l] == j
                get!(sol, l, Dict{String, Any}("from"=>dict_p[k])) # Active power withdrawn at the from bus
            elseif branches.f_bus[l] == j && branches.t_bus[l] == i
                get!(sol, l, Dict{String, Any}("to"=>dict_p[k])) # Active power withdrawn at the to bus
            end
        elseif haskey(sol, l)
            if branches.f_bus[l] == i && branches.t_bus[l] == j
                get!(sol[l], "from", dict_p[k])
            elseif branches.f_bus[l] == j && branches.t_bus[l] == i
                get!(sol[l], "to", dict_p[k])
            end
        end
    end
    return sol
end

""
function peakload(loads::Loads{N}, buses::Buses) where {N}
    
    key_buses = field(buses, :keys)
    buses_loads_base = Dict{Int, Vector{Float64}}((i, Float64[]) for i in key_buses)
    
    for k in field(loads, :keys)
        push!(buses_loads_base[field(loads, :buses)[k]], maximum(loads.pd[k,:]))
    end

    bus_peakload = Array{Float64}(undef, length(buses))

    for (k,v) in buses_loads_base
        if !isempty(v)
            bus_peakload[k] = sum(v)
        else
            bus_peakload[k] = 0.0
        end
    end

    system_peakload = Float64(maximum(sum(loads.pd, dims=1)))
    return system_peakload, bus_peakload
end

""
function finalize_model!(pm::AbstractPowerModel, settings::Settings)

    Base.finalize(JuMP.backend(pm.model).optimizer)
    Base.finalize(settings.env)
    return
end