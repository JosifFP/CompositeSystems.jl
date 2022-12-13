"SequentialMCS"
#update_idxs!(
    #    filter(i->states.buses[i]≠ 4,field(system, :buses, :keys)), topology(pm, :buses_idxs))

#update_idxs!(
    #    filter(i->field(states, :loads, i, t), field(system, :loads, :keys)), 
    #    topology(pm, :loads_idxs), topology(pm, :loads_nodes), field(system, :loads, :buses))

# update_idxs!(
    #     filter(i->BaseModule.field(states, :shunts, i, t), field(system, :shunts, :keys)), 
    #     topology.shunts_idxs, topology.shunts_nodes, field(system, :shunts, :buses))    

 #update_idxs!(
    #    filter(i->BaseModule.field(states, :generators, i, t), field(system, :generators, :keys)), 
    #    topology.generators_idxs, field(topology, :generators_nodes), field(system, :generators, :buses))

# update_branch_idxs!(
    #     field(system, :branches), topology.branches_idxs, topology.arcs, field(system, :arcs), field(states, :branches), t)    

#update_idxs!(
    #    filter(i->field(states, :storages, i, t), field(system, :storages, :keys)),
    #    topology(pm, :storages_idxs), topology(pm, :storages_nodes), field(system, :storages, :buses))

#update_idxs!(
    #    filter(i->field(states, :generatorstorages, i, t), field(system, :generatorstorages, :keys)), 
    #    topology(pm, :generatorstorages_idxs), topology(pm, :generatorstorages_nodes), field(system, :generatorstorages, :buses)) 
#

"OPF"
    #for i in field(system, :buses, :keys)
    #    update_con_power_balance(pm, system, states, i, t)
    #end
    
    # JuMP.delete(pm.model, con(pm, :ohms_yt_from, 1).data)
    # JuMP.delete(pm.model, con(pm, :voltage_angle_diff_upper, 1).data)
    # JuMP.delete(pm.model, con(pm, :voltage_angle_diff_lower, 1).data)

    # for i in field(system, :branches, :keys)
    #     if field(states, :branches)[i,t] ≠ 0
    #         con_ohms_yt(pm, system, i)
    #         con_voltage_angle_difference(pm, system, i)
    #     end
    # end   

    # if t > 1
    #     for i in field(system, :branches, :keys)
    #         if field(states, :branches)[i,t] ≠ 0 && field(states, :branches)[i,t-1] == 0
    #             con_ohms_yt(pm, system, i)
    #             con_voltage_angle_difference(pm, system, i)
    #         elseif field(states, :branches)[i,t] == 0 && field(states, :branches)[i,t-1] ≠ 0
    #             JuMP.delete(pm.model, con(pm, :ohms_yt_from, 1)[i])
    #             JuMP.delete(pm.model, con(pm, :voltage_angle_diff_upper, 1)[i])
    #             JuMP.delete(pm.model, con(pm, :voltage_angle_diff_lower, 1)[i])
    #         end
    #     end
    # else

    #     JuMP.delete(pm.model, con(pm, :ohms_yt_from, 1).data)
    #     JuMP.delete(pm.model, con(pm, :voltage_angle_diff_upper, 1).data)
    #     JuMP.delete(pm.model, con(pm, :voltage_angle_diff_lower, 1).data)

    #     for i in field(system, :branches, :keys)
    #         if field(states, :branches)[i,t] ≠ 0
    #             con_ohms_yt(pm, system, i)
    #             con_voltage_angle_difference(pm, system, i)
    #         end
    #     end     
    # end   

#end

#""
#function update_branch_idxs!(branches::Branches, assets_idxs::Vector{UnitRange{Int}}, topology_arcs::Arcs, initial_arcs::Arcs, asset_states::Matrix{Bool}, t::Int)
#    assets_idxs .= makeidxlist(filter(i->asset_states[i,t]==1, field(branches, :keys)), length(assets_idxs))
#    #update_arcs!(branches, topology_arcs, initial_arcs, asset_states, t)
#end

#""
# function update_arcs!(branches::Branches, topology_arcs::Arcs, initial_arcs::Arcs, asset_states::Matrix{Bool}, t::Int)
    
#     state = view(asset_states, :, t)
#     @inbounds for i in eachindex(state)

#         f_bus = field(branches, :f_bus)[i]
#         t_bus = field(branches, :t_bus)[i]

#         if state[i] == false
#             field(topology_arcs, :busarcs)[:,i] = Array{Missing}(undef, size(field(topology_arcs, :busarcs),1))
#             field(topology_arcs, :arcs_from)[i] = missing
#             field(topology_arcs, :arcs_to)[i] = missing
#             field(topology_arcs, :buspairs)[(f_bus, t_bus)] = missing
#         else
#             field(topology_arcs, :busarcs)[:,i] = field(initial_arcs, :busarcs)[:,i]
#             field(topology_arcs, :arcs_from)[i] = field(initial_arcs, :arcs_from)[i]
#             field(topology_arcs, :arcs_to)[i] = field(initial_arcs, :arcs_to)[i]
#             field(topology_arcs, :buspairs)[(f_bus, t_bus)] = field(initial_arcs, :buspairs)[(f_bus, t_bus)]
#         end
#     end
    
#     field(topology_arcs, :arcs)[:] = [field(topology_arcs, :arcs_from); field(topology_arcs, :arcs_to)]

# end

#"garbage-----------------------------------------------------------------------------------------------------------------"
# "computes flow bounds on branches from ref data"
# function ref_calc_branch_flow_bounds(branches::Branches)
#     flow_lb = Dict() 
#     flow_ub = Dict()

#     for i in field(branches, :keys)
#         flow_lb[i] = -Inf
#         flow_ub[i] = Inf

#         if hasfield(Branches, :rate_a)
#             flow_lb[i] = max(flow_lb[i], -field(branches, :rate_a)[i])
#             flow_ub[i] = min(flow_ub[i],  field(branches, :rate_a)[i])
#         end
#     end

#     return flow_lb, flow_ub
# end




# "a macro for adding the standard AbstractPowerModel fields to a type definition"
# CompositeAdequacy.@def ca_fields begin
    
#     model::AbstractModel
#     topology::Topology
#     var::Variables
#     sol::Matrix{Float32}

# end


#struct DCPPowerModel <: AbstractDCPModel @ca_fields end
#struct DCMPPowerModel <: AbstractDCMPPModel @ca_fields end
#struct NFAPowerModel <: AbstractNFAModel @ca_fields end
#struct PM_DCPPowerModel <: PM_AbstractDCPModel @ca_fields end

# """
# Cache: a OptimizationContainer structure that stores variables and results in mutable containers.
# """
# struct Cache <: OptimizationContainer

#     var::Variables

#     function Cache(system::SystemModel{N}; multiperiod::Bool=false) where {N}

#         var = Variables(system, multiperiod=multiperiod)
#         return new(var)

#     end
# end

# """
# The `def` macro is used to build other macros that can insert the same block of
# julia code into different parts of a program.
# """
# macro def(name, definition)
#     return quote
#         macro $(esc(name))()
#             esc($(Expr(:quote, definition)))
#         end
#     end
# end

# struct DCPPowerModel <: AbstractDCPModel

#     model::AbstractModel
#     topology::Topology
#     var::Dict{Symbol, AbstractArray}
#     con::Dict{Symbol, AbstractArray}
#     sol::Dict{Symbol, Matrix{Float64}}

#     function DCPPowerModel(
#         model::AbstractModel,
#         topology::Topology,
#         var::Dict{Symbol, AbstractArray},
#         con::Dict{Symbol, AbstractArray},
#         sol::Dict{Symbol, Matrix{Float64}}
#     )
#         return new(model, topology, var, con, sol)
#     end
# end

# ""
# struct DCMPPowerModel <: AbstractDCMPPModel

#     model::AbstractModel
#     topology::Topology
#     var::Dict{Symbol, AbstractArray}
#     con::Dict{Symbol, AbstractArray}
#     sol::Dict{Symbol, Matrix{Float64}}

#     function DCMPPowerModel(
#         model::AbstractModel,
#         topology::Topology,
#         var::Dict{Symbol, AbstractArray},
#         con::Dict{Symbol, AbstractArray},
#         sol::Dict{Symbol, Matrix{Float64}}
#     )
#     return new(model, topology, var, con, sol)
#     end
# end

# ""
# struct NFAPowerModel <: AbstractNFAModel

#     model::AbstractModel
#     topology::Topology
#     var::Dict{Symbol, AbstractArray}
#     con::Dict{Symbol, AbstractArray}
#     sol::Dict{Symbol, Matrix{Float64}}

#     function NFAPowerModel(
#         model::AbstractModel,
#         topology::Topology,
#         var::Dict{Symbol, AbstractArray},
#         con::Dict{Symbol, AbstractArray},
#         sol::Dict{Symbol, Matrix{Float64}}
#     )
#     return new(model, topology, var, con, sol)
#     end
# end

# ""
# struct PM_DCPPowerModel <: PM_AbstractDCPModel

#     model::AbstractModel
#     topology::Topology
#     var::Dict{Symbol, AbstractArray}
#     con::Dict{Symbol, AbstractArray}
#     sol::Dict{Symbol, Matrix{Float64}}

#     function PM_DCPPowerModel(
#         model::AbstractModel,
#         topology::Topology,
#         var::Dict{Symbol, AbstractArray},
#         con::Dict{Symbol, AbstractArray},
#         sol::Dict{Symbol, Matrix{Float64}}
#     )
#     return new(model, topology, var, con, sol)
#     end
# end

#abstract type OptimizationContainer end
# ""
# struct DatasetContainer{T}
#     object::Dict{Symbol, T}
#     function DatasetContainer{T}() where {T <: AbstractArray}
#         return new(Dict{Symbol, T}())
#     end
# end


# ""
# function type(pmodel::String)

#     if pmodel == "AbstractDCPModel"
#         apm = DCPPowerModel
#     elseif pmodel == "AbstractDCMPPModel" 
#         apm = DCMPPowerModel
#     elseif pmodel == "AbstractNFAModel" 
#         apm = NFAPowerModel
#     elseif pmodel == "PM_AbstractDCPModel"
#         apm = PM_DCPPowerModel
#     else
#         error("AbstractPowerModel = $(pmodel) not supported, DCPPowerModel has been selected")
#         apm = DCPPowerModel
#     end
#     return apm
# end

# function empty_model!(system::SystemModel{N}, pm::AbstractDCPowerModel, settings::Settings; timeseries=false) where {N}

#     empty!(pm.model)
#     MOIU.reset_optimizer(pm.model)
#     #OPF.set_optimizer(pm.model, deepcopy(field(settings, :optimizer)); add_bridges = false)
#     if timeseries == true
#         reset_object_container!(var(pm, :pg), field(system, :generators, :keys), timesteps=1:N)
#         reset_object_container!(var(pm, :va), field(system, :buses, :keys), timesteps=1:N)
#         reset_object_container!(var(pm, :plc), field(system, :loads, :keys), timesteps=1:N)
#         reset_object_container!(var(pm, :p), topology(pm, :arcs), timesteps=1:N)
#     else
#         reset_object_container!(var(pm, :pg), field(system, :generators, :keys), timesteps=1:1)
#         reset_object_container!(var(pm, :va), field(system, :buses, :keys), timesteps=1:1)
#         reset_object_container!(var(pm, :plc), field(system, :loads, :keys), timesteps=1:1)
#         reset_object_container!(var(pm, :p), topology(pm, :arcs), timesteps=1:1)
#     end 
#     fill!(sol(pm, :plc), 0.0)

#     return
# end

# "a macro for adding the standard AbstractPowerModel fields to a type definition"
# CompositeAdequacy.@def ca_fields begin
    
#     model::AbstractModel
#     topology::Topology
#     var::Variables
#     sol::Matrix{Float32}

# end


#struct DCPPowerModel <: AbstractDCPModel @ca_fields end
#struct DCMPPowerModel <: AbstractDCMPPModel @ca_fields end
#struct NFAPowerModel <: AbstractNFAModel @ca_fields end
#struct PM_DCPPowerModel <: PM_AbstractDCPModel @ca_fields end

# """
# Cache: a OptimizationContainer structure that stores variables and results in mutable containers.
# """
# struct Cache <: OptimizationContainer

#     var::Variables

#     function Cache(system::SystemModel{N}; multiperiod::Bool=false) where {N}

#         var = Variables(system, multiperiod=multiperiod)
#         return new(var)

#     end
# end

# """
# The `def` macro is used to build other macros that can insert the same block of
# julia code into different parts of a program.
# """
# macro def(name, definition)
#     return quote
#         macro $(esc(name))()
#             esc($(Expr(:quote, definition)))
#         end
#     end
# end

# struct DCPPowerModel <: AbstractDCPModel

#     model::AbstractModel
#     topology::Topology
#     var::Dict{Symbol, AbstractArray}
#     con::Dict{Symbol, AbstractArray}
#     sol::Dict{Symbol, Matrix{Float64}}

#     function DCPPowerModel(
#         model::AbstractModel,
#         topology::Topology,
#         var::Dict{Symbol, AbstractArray},
#         con::Dict{Symbol, AbstractArray},
#         sol::Dict{Symbol, Matrix{Float64}}
#     )
#         return new(model, topology, var, con, sol)
#     end
# end

# ""
# struct DCMPPowerModel <: AbstractDCMPPModel

#     model::AbstractModel
#     topology::Topology
#     var::Dict{Symbol, AbstractArray}
#     con::Dict{Symbol, AbstractArray}
#     sol::Dict{Symbol, Matrix{Float64}}

#     function DCMPPowerModel(
#         model::AbstractModel,
#         topology::Topology,
#         var::Dict{Symbol, AbstractArray},
#         con::Dict{Symbol, AbstractArray},
#         sol::Dict{Symbol, Matrix{Float64}}
#     )
#     return new(model, topology, var, con, sol)
#     end
# end

# ""
# struct NFAPowerModel <: AbstractNFAModel

#     model::AbstractModel
#     topology::Topology
#     var::Dict{Symbol, AbstractArray}
#     con::Dict{Symbol, AbstractArray}
#     sol::Dict{Symbol, Matrix{Float64}}

#     function NFAPowerModel(
#         model::AbstractModel,
#         topology::Topology,
#         var::Dict{Symbol, AbstractArray},
#         con::Dict{Symbol, AbstractArray},
#         sol::Dict{Symbol, Matrix{Float64}}
#     )
#     return new(model, topology, var, con, sol)
#     end
# end

# ""
# struct PM_DCPPowerModel <: PM_AbstractDCPModel

#     model::AbstractModel
#     topology::Topology
#     var::Dict{Symbol, AbstractArray}
#     con::Dict{Symbol, AbstractArray}
#     sol::Dict{Symbol, Matrix{Float64}}

#     function PM_DCPPowerModel(
#         model::AbstractModel,
#         topology::Topology,
#         var::Dict{Symbol, AbstractArray},
#         con::Dict{Symbol, AbstractArray},
#         sol::Dict{Symbol, Matrix{Float64}}
#     )
#     return new(model, topology, var, con, sol)
#     end
# end


    # if all(view(states.branches,:,t)) ≠ true
    #     JuMP.delete(pm.model, con(pm, :ohms_yt_from, 1).data)
    #     JuMP.delete(pm.model, con(pm, :voltage_angle_diff_upper, 1).data)
    #     JuMP.delete(pm.model, con(pm, :voltage_angle_diff_lower, 1).data)

    #     add_con_container!(pm.con, :ohms_yt_from, assetgrouplist(topology(pm, :branches_idxs)))
    #     add_con_container!(pm.con, :voltage_angle_diff_upper, assetgrouplist(topology(pm, :branches_idxs)))
    #     add_con_container!(pm.con, :voltage_angle_diff_lower, assetgrouplist(topology(pm, :branches_idxs)))

    #     for i in field(system, :branches, :keys)
    #         if field(states, :branches)[i,t] ≠ 0
    #             con_ohms_yt(pm, system, i)
    #             con_voltage_angle_difference(pm, system, i)
    #         end
    #     end
    # end


#     ""
# function update_solve!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

#     update_idxs!(
#         filter(i->BaseModule.field(states, :generators, i, t), field(system, :generators, :keys)), 
#         pm.topology.generators_idxs, field(pm.topology, :generators_nodes), field(system, :generators, :buses))

#     update_idxs!(
#         filter(i->BaseModule.field(states, :shunts, i, t), field(system, :shunts, :keys)), 
#         pm.topology.shunts_idxs,  field(pm.topology, :shunts_nodes), field(system, :shunts, :buses))    

#     update_branch_idxs!(
#         field(system, :branches), pm.topology.branches_idxs, pm.topology, field(states, :branches), t)       

#     build_method!(pm, system, states, t)
#     optimize_method!(pm)
#     build_result!(pm, system, t)
#     return

# end

# ""
# function build_method_idxs!(pm::AbstractDCPowerModel, system::SystemModel, t)
#     # Add Optimization and State Variables
#     var_bus_voltage(pm, system, nw=t, idxs=true)
#     var_gen_power(pm, system, nw=t, idxs=true)
#     var_branch_power(pm, system, nw=t, idxs=true)
#     var_load_curtailment(pm, system, nw=t, idxs=true)
#     #variable_storage_power_mi(pm)
#     #var_dcline_power(pm)

#     # Add Constraints
#     # ---------------
#     for i in field(system, :ref_buses)
#         con_theta_ref(pm, i, nw=t)
#     end

#     for i in assetgrouplist(topology(pm, :buses_idxs))
#         con_power_balance(pm, system, i, t)
#     end

#     for i in assetgrouplist(topology(pm, :branches_idxs))
#         con_ohms_yt(pm, system, i, nw=t)
#         con_voltage_angle_difference(pm, system, i, nw=t)
#         #con_thermal_limits(pm, system, i, t)
#     end
#     objective_min_load_curtailment(pm, system, nw=t)
#     return

# end

# JuMP.delete(pm.model, con(pm, :power_balance, 1).data)

# for i in field(system, :buses, :keys)
#     con_power_balance(pm, system, i, t)
# end





#"***************************************************************************************************************************"
#"Needs to be fixed/updated"

#"DC LINES "
# function con_dcline_power_losses(pm::AbstractDCPowerModel, i::Int)
#     dcline = ref(pm, :dcline, i)
#     f_bus = dcline["f_bus"]
#     t_bus = dcline["t_bus"]
#     f_idx = (i, f_bus, t_bus)
#     t_idx = (i, t_bus, f_bus)
#     loss0 = dcline["loss0"]
#     loss1 = dcline["loss1"]

#     _con_dcline_power_losses(pm, f_bus, t_bus, f_idx, t_idx, loss0, loss1)
# end

# """
# Creates Line Flow constraint for DC Lines (Matpower Formulation)

# ```
# p_fr + p_to == loss0 + p_fr * loss1
# ```
# """
# function _con_dcline_power_losses(pm::AbstractDCPowerModel, f_bus, t_bus, f_idx, t_idx, loss0, loss1)
#     p_fr = var(pm, :p_dc, f_idx)
#     p_to = var(pm, :p_dc, t_idx)

#     @constraint(pm.model, (1-loss1) * p_fr + (p_to - loss0) == 0)
# end

# "Fixed Power Factor"
# function con_power_factor(pm::AbstractACPowerModel)

#     z_demand = var(pm, :z_demand)
#     plc = var(pm, :plc)
#     q_lc = var(pm, :q_lc)
    
#     for (l,_) in ref(pm, :load)
#         @constraint(pm.model, z_demand[i]*plc[i] - q_lc[i] == 0.0)      
#     end
# end

# ""
# function con_voltage_magnitude_diff(pm::AbstractDCPowerModel, i::Int)

#     branch = ref(pm, :branch, i)
#     f_bus = branch["f_bus"]
#     t_bus = branch["t_bus"]
#     f_idx = (i, f_bus, t_bus)
#     t_idx = (i, t_bus, f_bus)

#     r = branch["br_r"]
#     x = branch["br_x"]
#     g_sh_fr = branch["g_fr"]
#     b_sh_fr = branch["b_fr"]
#     tm = branch["tap"]

#     _con_voltage_magnitude_difference(pm, i, f_bus, t_bus, f_idx, t_idx, r, x, g_sh_fr, b_sh_fr, tm)
# end

# """
# Defines voltage drop over a branch, linking from and to side voltage magnitude
# """
# function _con_voltage_magnitude_difference(pm::AbstractDCPowerModel, i, f_bus, t_bus, f_idx, t_idx, r, x, g_sh_fr, b_sh_fr, tm)
#     p_fr = var(pm, :p, f_idx)
#     #q_fr = var(pm, n, :q, f_idx)
#     q_fr = 0
#     w_fr = var(pm, :w, f_bus)
#     w_to = var(pm, :w, t_bus)
#     ccm =  var(pm, :ccm, i)

#     ym_sh_sqr = g_sh_fr^2 + b_sh_fr^2

#     @constraint(pm.model, (1+2*(r*g_sh_fr - x*b_sh_fr))*(w_fr/tm^2) - w_to ==  2*(r*p_fr + x*q_fr) - (r^2 + x^2)*(ccm + ym_sh_sqr*(w_fr/tm^2) - 2*(g_sh_fr*p_fr - b_sh_fr*q_fr)))
# end


# if all(view(states.branches,:,t)) ≠ true
#     JuMP.delete(pm.model, con(pm, :ohms_yt_from, 1).data)
#     #JuMP.delete(pm.model, con(pm, :voltage_angle_diff_upper, 1).data)
#     #JuMP.delete(pm.model, con(pm, :voltage_angle_diff_lower, 1).data)

#     add_con_container!(pm.con, :ohms_yt_from, assetgrouplist(topology(pm, :branches_idxs)))
#     #add_con_container!(pm.con, :voltage_angle_diff_upper, assetgrouplist(topology(pm, :branches_idxs)))
#     #add_con_container!(pm.con, :voltage_angle_diff_lower, assetgrouplist(topology(pm, :branches_idxs)))

#     for i in assetgrouplist(topology(pm, :branches_idxs))
#         con_ohms_yt(pm, system, i)
#         #con_voltage_angle_difference(pm, system, i)
#     end
# end

# "Transportation"
# function build_method!(pm::AbstractNFAModel, system::SystemModel, t)
 
#     var_gen_power(pm, system)
#     var_branch_power(pm, system)
#     var_load_curtailment(pm, system, t)

#     # Add Constraints
#     # ---------------
#     for i in assetgrouplist(topology(pm, :buses_idxs))
#         con_power_balance(pm, system, i, t)
#     end

#     objective_min_load_curtailment(pm, system)
#     return

# end




# ""
# function var_bus_voltage(pm::AbstractPowerModel, system::SystemModel; kwargs...)
#     var_bus_voltage_angle(pm, system; kwargs...)
#     var_bus_voltage_magnitude(pm, system; kwargs...)
# end

# ""
# function var_bus_voltage_angle(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, idxs::Bool=false)

#     if !idxs
#         var(pm, :va)[nw] = @variable(pm.model, [field(system, :buses, :keys)])
#     else
#         var(pm, :va)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :buses_idxs))])
#     end

# end

# ""
# function var_bus_voltage_magnitude(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, idxs::Bool=false)
# end

# "variable: `v[i]` for `i` in `bus`es"
# function var_bus_voltage_magnitude(pm::AbstractACPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, idxs::Bool=false)

#     if !idxs

#         vm = var(pm, :vm)[nw] = @variable(pm.model, [field(system, :buses, :keys)], start =1.0)
#         if bounded
#             for i in eachindex(field(system, :buses, :keys))
#                 JuMP.set_lower_bound(vm[i], field(system, :buses, :vmin)[i])
#                 JuMP.set_upper_bound(vm[i], field(system, :buses, :vmax)[i])
#             end
#         end

#     else

#         vm = var(pm, :vm)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :buses_idxs))], start =1.0)
#         if bounded
#             for i in assetgrouplist(topology(pm, :buses_idxs))
#                 JuMP.set_lower_bound(vm[i], field(system, :buses, :vmin)[i])
#                 JuMP.set_upper_bound(vm[i], field(system, :buses, :vmax)[i])
#             end
#         end
        
#     end

# end

# ""
# function var_gen_power(pm::AbstractPowerModel, system::SystemModel; kwargs...)
#     var_gen_power_real(pm, system; kwargs...)
#     var_gen_power_imaginary(pm, system; kwargs...)
# end

# ""
# function var_gen_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; kwargs...)
#     var_gen_power_real(pm, system, states, t; kwargs...)
#     var_gen_power_imaginary(pm, system, states, t; kwargs...)
# end

# ""
# function var_gen_power_real(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, idxs::Bool=false)

#     if !idxs
#         pg = var(pm, :pg)[nw] = @variable(pm.model, [field(system, :generators, :keys)])

#         if bounded
#             for l in eachindex(field(system, :generators, :keys))
#                 JuMP.set_upper_bound(pg[l], field(system, :generators, :pmax)[l])
#                 JuMP.set_lower_bound(pg[l], 0.0)
#             end
#         end
#     else
#         pg = var(pm, :pg)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :generators_idxs))])

#         if bounded
#             for l in assetgrouplist(topology(pm, :generators_idxs))
#                 JuMP.set_upper_bound(pg[l], field(system, :generators, :pmax)[l])
#                 JuMP.set_lower_bound(pg[l], 0.0)
#             end
#         end
    
#     end

# end

# ""
# function var_gen_power_real(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)

#     pg = var(pm, :pg)[nw] = @variable(pm.model, [field(system, :generators, :keys)])

#     if bounded
#             for l in eachindex(field(system, :generators, :keys))
#             JuMP.set_upper_bound(pg[l], field(system, :generators, :pmax)[l]*field(states, :generators)[l,t])
#             JuMP.set_lower_bound(pg[l], 0.0)
#         end
#     end

# end

# "Model ignores reactive power flows"
# function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, idxs::Bool=false)
# end

# "Model ignores reactive power flows"
# function var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)
# end

# "Defines DC or AC power flow variables p to represent the active power flow for each branch"
# function var_branch_power(pm::AbstractPowerModel, system::SystemModel; kwargs...)
#     var_branch_power_real(pm, system; kwargs...)
#     var_branch_power_imaginary(pm, system; kwargs...)
# end

# "Defines DC or AC power flow variables p to represent the active power flow for each branch"
# function var_branch_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int; kwargs...)
#     var_branch_power_real(pm, system, states, t; kwargs...)
#     var_branch_power_imaginary(pm, system, states, t; kwargs...)
# end

# ""
# function var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, idxs::Bool=false)

#     if !idxs
#         p = @variable(pm.model, [topology(pm, :arcs)])
#     else
#         arcs_from = filter(!ismissing, skipmissing(topology(pm, :arcs_from)))
#         arcs = filter(!ismissing, skipmissing(topology(pm, :arcs)))
#         p = @variable(pm.model, [arcs])
#     end

#     if bounded
#         for (l,i,j) in topology(pm, :arcs)
#             JuMP.set_lower_bound(p[(l,i,j)], -field(system, :branches, :rate_a)[l])
#             JuMP.set_upper_bound(p[(l,i,j)], field(system, :branches, :rate_a)[l])
#         end
#     end

#     # this explicit type erasure is necessary
#     var(pm, :p)[nw] = merge(
#         Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from)), 
#         Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from))
#     )


# end

# ""
# function var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)

#     p = @variable(pm.model, [topology(pm, :arcs)])

#     if bounded
#         for (l,i,j) in  topology(pm, :arcs)
#             JuMP.set_lower_bound(p[(l,i,j)], -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
#             JuMP.set_upper_bound(p[(l,i,j)], field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
#         end
#     end

#     # this explicit type erasure is necessary
#     var(pm, :p)[nw] = merge(
#         Dict{Tuple{Int, Int, Int}, Any}(((l,i,j), p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from)), 
#         Dict{Tuple{Int, Int, Int}, Any}(((l,j,i), -1.0*p[(l,i,j)]) for (l,i,j) in topology(pm, :arcs_from))
#     )

# end

# "DC models ignore reactive power flows"
# function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, idxs::Bool=false)
# end

# "DC models ignore reactive power flows"
# function var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int; nw::Int=1, bounded::Bool=true)
# end

# "Defines load curtailment variables p to represent the active power flow for each branch"
# function var_load_curtailment(pm::AbstractPowerModel, system::SystemModel; kwargs...)
#     var_load_curtailment_real(pm, system; kwargs...)
#     var_load_curtailment_imaginary(pm, system; kwargs...)
# end

# "Defines load curtailment variables p to represent the active power flow for each branch"
# function var_load_curtailment(pm::AbstractPowerModel, system::SystemModel, t::Int; kwargs...)
#     var_load_curtailment_real(pm, system, t; kwargs...)
#     var_load_curtailment_imaginary(pm, system, t; kwargs...)
# end

# ""
# function var_load_curtailment_real(pm::AbstractPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, idxs::Bool=false)

#     if !idxs
#         plc = var(pm, :plc)[nw] = @variable(pm.model, [field(system, :loads, :keys)], start =0.0)

#         for l in eachindex(field(system, :loads, :keys))
#             JuMP.set_upper_bound(plc[l], field(system, :loads, :pd)[l,nw])
#             JuMP.set_lower_bound(plc[l],0.0)
#         end

#     else

#         plc = var(pm, :plc)[nw] = @variable(pm.model, [assetgrouplist(topology(pm, :loads_idxs))], start =0.0)

#         for l in assetgrouplist(topology(pm, :loads_idxs))
#             JuMP.set_upper_bound(plc[l], field(system, :loads, :pd)[l,nw])
#             JuMP.set_lower_bound(plc[l],0.0)
#         end

#     end

# end

# ""
# function var_load_curtailment_real(pm::AbstractPowerModel, system::SystemModel, t::Int; nw::Int=1, bounded::Bool=true)

#     plc = var(pm, :plc)[nw] = @variable(pm.model, [field(system, :loads, :keys)], start =0.0)

#     for l in eachindex(field(system, :loads, :keys))
#         JuMP.set_upper_bound(plc[l], field(system, :loads, :pd)[l,t])
#         JuMP.set_lower_bound(plc[l],0.0)
#     end

# end

# ""
# function var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel; nw::Int=1, bounded::Bool=true, idxs::Bool=false)
# end

# ""
# function var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel, t::Int; nw::Int=1, bounded::Bool=true)
# end

# # ""
# # function comp_start_value(comp::Dict{String,<:Any}, key::String, default=0.0)
# #     return get(comp, key, default)
# # end

# ""
# function update_var_gen_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
#     update_var_gen_power_real(pm, system, states, t)
#     update_var_gen_power_imaginary(pm, system, states, t)
# end

# ""
# function update_var_gen_power_real(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)

#     pg = var(pm, :pg, 1)

#     for l in eachindex(field(system, :generators, :keys))
#         JuMP.set_upper_bound(pg[l], field(system, :generators, :pmax)[l]*field(states, :generators)[l,t])
#         JuMP.set_lower_bound(pg[l], 0.0)
#     end

# end

# "Model ignores reactive power flows"
# function update_var_gen_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)
# end

# "Defines DC or AC power flow variables p to represent the active power flow for each branch"
# function update_var_branch_power(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
#     update_var_branch_power_real(pm, system, states, t)
#     update_var_branch_power_imaginary(pm, system, states, t)
# end

# ""
# function update_var_branch_power_real(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)


#     p = var(pm, :p, 1)

#     for (l,i,j) in topology(pm, :arcs)

#         if typeof(p[(l,i,j)]) ==JuMP.AffExpr
#             p_var = first(keys(p[(l,i,j)].terms))
#         elseif typeof(p[(l,i,j)]) ==JuMP.VariableRef
#             p_var = p[(l,i,j)]
#         else
#             @error("Expression $(typeof(p[(l,i,j)])) not supported")
#         end

#         JuMP.set_lower_bound(p_var, -field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])
#         JuMP.set_upper_bound(p_var, field(system, :branches, :rate_a)[l]*field(states, :branches)[l,t])

#     end


# end

# "DC models ignore reactive power flows"
# function update_var_branch_power_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)
# end

# "Defines load curtailment variables p to represent the active power flow for each branch"
# function update_var_load_curtailment(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)
#     update_var_load_curtailment_real(pm, system, states, t)
#     update_var_load_curtailment_imaginary(pm, system, states, t)
# end


# ""
# function update_var_load_curtailment_real(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

#     plc = var(pm, :plc, 1)
#     for l in eachindex(field(system, :loads, :keys))
#         JuMP.set_upper_bound(plc[l], field(system, :loads, :pd)[l,t]*field(states, :loads)[l,t])
#         JuMP.set_lower_bound(plc[l],0.0)
#     end

# end

# "Model ignores reactive power flows"
# function update_var_load_curtailment_imaginary(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)
# end

# "SystemStates structure for NonSequential MCS"
# function SystemStates(system::SystemModel{N}, method::NonSequentialMCS) where {N}

#     @inbounds buses = field(system, :buses, :bus_type)

#     @inbounds loads = Array{Bool, 1}(undef, length(system.loads))
#     @inbounds loads_nexttransition = Array{Int, 1}(undef, length(system.loads))
        
#     @inbounds branches = Array{Bool, 1}(undef, length(system.branches))
#     @inbounds branches_nexttransition = Array{Int, 1}(undef, length(system.branches))

#     @inbounds shunts = Array{Bool, 1}(undef, length(system.shunts))
#     @inbounds shunts_nexttransition = Array{Int, 1}(undef, length(system.shunts))

#     @inbounds generators = Array{Bool, 1}(undef, length(system.generators))
#     @inbounds generators_nexttransition = Array{Int, 1}(undef, length(system.generators))

#     @inbounds storages = Array{Bool, 1}(undef, length(system.storages))
#     @inbounds storages_nexttransition = Array{Int, 1}(undef, length(system.storages))

#     @inbounds generatorstorages = Array{Bool, 1}(undef, length(system.generatorstorages))
#     @inbounds generatorstorages_nexttransition = Array{Int, 1}(undef, length(system.generatorstorages))

#     @inbounds storages_energy = Array{Float32, 1}(undef, length(system.storages))
#     @inbounds generatorstorages_energy = Array{Float32, 1}(undef, length(system.generatorstorages))
    
#     @inbounds sys = [true]

#     return SystemStates(
#         buses, loads, branches, shunts, generators, storages, generatorstorages,
#         loads_nexttransition, branches_nexttransition, shunts_nexttransition, 
#         generators_nexttransition, storages_nexttransition, generatorstorages_nexttransition,
#         storages_energy, generatorstorages_energy, sys)
# end

# "Transportation"
# function build_method!(pm::AbstractNFAModel, system::SystemModel, t)
 
#     var_gen_power(pm, system)
#     var_branch_power(pm, system)

#     objective_min_fuel_and_flow_cost(pm, system)

#     # Add Constraints
#     # ---------------
#     for i in field(system, :buses, :keys)
#         con_power_balance(pm, system, i, t)
#     end
    
#     return

# end


# "Transportation"
# function update_method!(pm::AbstractNFAModel, system::SystemModel, states::SystemStates, t::Int)

#     update_var_gen_power(pm, system, states, t)
#     update_var_branch_power(pm, system, states, t)
#     update_con_power_balance(pm, system, states, t)
#     return

# end

# Peak = Array{Float32, 2}(undef, 1, N)
# for t in 1:N
#     if iszero((t+23)%24)
#         for k in t:t+23
#             Peak[k] = sum(maximum([field(system, :loads, :pd)[:,k] for k in t:t+23]))
#         end
#     end
# end

    # gen_cost = Dict{Int, Any}()
    # gen_idxs = assetgrouplist(topology(pm, :generators_idxs))

    # for i in system.generators.keys
    #     cost = reverse(system.generators.cost[i])
    #     pg = var(pm, :pg, nw)[i]
    #     if length(cost) == 1
    #          gen_cost[i] = @expression(pm.model, cost[1])
    #     elseif length(cost) == 2
    #          gen_cost[i] = @expression(pm.model, cost[1] + cost[2]*pg)
    #     #elseif length(cost) == 3
    #          #gen_cost[i] = JuMP.@NLexpression(pm.model, cost[1] + cost[2]*pg + cost[3]*pg^2)
    #     else
    #          @error("Nonlinear problems not supported")
    #          gen_cost[i] = @expression(pm.model, 0.0)
    #     end
    #  end

    # fg = @expression(pm.model, sum(gen_cost[i] for i in eachindex(gen_idxs)))



#     "Load Minimization version of DCOPF"
# function update_method!(pm::AbstractDCPowerModel, system::SystemModel, states::SystemStates, t::Int)

#     update_var_gen_power(pm, system, states, t)
#     update_var_branch_power(pm, system, states, t)
#     update_var_load_curtailment(pm, system, states, t)
#     #update_var_storage_power_mi(pm, system, states, t)
#     update_con_power_balance(pm, system, states, t)
    
#     if any(i -> i==4,view(states.buses, :, t)) == true || any(i -> i==4,view(states.buses, :, t-1)) == true

#         JuMP.delete(pm.model, con(pm, :power_balance, 1).data)
#         add_con_container!(pm.con, :power_balance, field(system, :buses, :keys))

#         for i in assetgrouplist(topology(pm, :buses_idxs))
#             con_power_balance(pm, system, i, t)
#         end

#     else
#         update_con_power_balance(pm, system, states, t)
#     end

#     update_con_voltage_angle_difference(pm, system, states, t)
#     update_con_storage(pm, system, states, t)


#     if all(view(states.branches,:,t)) ≠ true || all(view(states.branches,:,t-1)) ≠ true

#         JuMP.delete(pm.model, con(pm, :ohms_yt_from, 1).data)
#         add_con_container!(pm.con, :ohms_yt_from, assetgrouplist(topology(pm, :branches_idxs)))

#         for i in assetgrouplist(topology(pm, :branches_idxs))
#             con_ohms_yt(pm, system, i)
#         end  
    
#     end

#     return

# end

    # for i in field(system, :loads, :keys)
    #     if view(field(states, :loads), i, t) != 0 && all(view(field(system, :loads, :pd), :, t) .== 0.0) && all(view(field(system, :loads, :qd), :, t) .== 0.0)
    #         field(states, :loads)[i,t] = 0
    #         revised = true
    #     end
    # end

    # for i in field(system, :shunts, :keys)
    #     if view(field(states, :shunts), i, t) != 0 && all(view(field(system, :shunts, :gs), :, t) .== 0.0) && all(view(field(system, :shunts, :bs), :, t) .== 0.0)
    #         field(states, :shunts)[i,t] = 0
    #         revised = true
    #     end
    # end


"""
attempts to deactive components that are not needed in the network by repeated
calls to `propagate_topology_status!` and `deactivate_isolated_components!`

warning: this implementation has quadratic complexity, in the worst case
"""
function simplify!(system::SystemModel, systemstates::SystemStates, topology::Topology, t::Int)
    revised = true
    iteration = 0
    while revised
        iteration += 1
        revised = false
        revised |= deactivate_isolatedcomponents!(system, systemstates, topology, t)
        revised |= propagate_topologystatus!(system, systemstates, topology, t)
    end
    return iteration
end


"""
removes buses with single branch connections and without any other attached
components.  Also removes connected components without suffuceint generation
or loads.

also deactivates 0 valued loads and shunts.
"""
function deactivate_isolatedcomponents!(system::SystemModel, states::SystemStates, topology::Topology, t::Int)

    revised = false

    changed = true
    while changed
        changed = false
        for i in field(system, :buses, :keys)
            if states.buses[i,t] != 4
                incident_active_edge = 0
                busarcs = filter(!ismissing, skipmissing(topology.busarcs[i,:]))
                if length(busarcs) > 0
                    incident_branch_count = sum([0; [field(states, :branches)[l,t] for (l,i,j) in busarcs]])
                    incident_active_edge = incident_branch_count
                end

                if incident_active_edge == 1 && length(topology.generators_nodes[i]) == 0 && 
                    length(topology.loads_nodes[i]) == 0 && length(topology.storages_nodes[i]) == 0 &&
                    length(topology.shunts_nodes[i]) == 0
                    states.buses[i,t] = 4
                    changed = true
                    @info("deactivating bus $(i) due to dangling bus without generation, load or storage")
                elseif incident_active_edge == 0
                    states.buses[i,t] = 4
                    changed = true
                    @info("deactivating bus $(i) due to dangling bus without generation, load or storage")
                end
            end
        end

        if changed
            for i in field(system, :branches, :keys)
                if states.branches[i,t] != 0
                    f_bus = field(states, :buses)[system.branches.f_bus[i], t]
                    t_bus = field(states, :buses)[system.branches.t_bus[i], t]
                    if f_bus == 4 || t_bus == 4
                        states.branches[i,t] = 0
                    end
                end
            end
            update_idxs!(filter(i->states.buses[i,t] ≠ 4, field(system, :buses, :keys)), getfield(topology, :buses_idxs))
            update_idxs!(filter(i-> states.branches[i,t], field(system, :branches, :keys)), getfield(topology, :branches_idxs))
        end

    end

    ccs = OPF.calc_connected_components(topology, system.branches)

    for cc in ccs
        cc_active_loads = [0]
        cc_active_shunts = [0]
        cc_active_gens = [0]
        cc_active_strg = [0]

        for i in cc
            cc_active_loads = push!(cc_active_loads, length(topology.loads_nodes[i]))
            cc_active_shunts = push!(cc_active_shunts, length(topology.shunts_nodes[i]))
            cc_active_gens = push!(cc_active_gens, length(topology.generators_nodes[i]))
            cc_active_strg = push!(cc_active_strg, length(topology.storages_nodes[i]))
        end

        active_load_count = sum(cc_active_loads)
        active_shunt_count = sum(cc_active_shunts)
        active_gen_count = sum(cc_active_gens)
        active_strg_count = sum(cc_active_strg)

        if (active_load_count == 0 && active_shunt_count == 0 && active_strg_count == 0) || active_gen_count == 0
            @info("deactivating connected component $(cc) due to isolation without generation, load or storage")
            for i in cc
                states.buses[i,t] = 4
            end
            revised = true
        end
    end
    
    return revised

end

"""
propagates inactive active network buses status to attached components so that
the system status values are consistent.

returns true if any component was modified.
"""
function propagate_topologystatus!(system::SystemModel, states::SystemStates, topology::Topology, t::Int)

    revised = false
    for i in field(system, :buses, :keys)
        if states.buses[i,t] == 4
            for k in topology.loads_nodes[i]
                if getfield(states, :loads)[k, t] != 0
                    field(states, :loads)[k, t] = 0
                    revised = true
                end
             end
            for k in topology.shunts_nodes[i]
                if getfield(states, :shunts)[k, t] != 0
                    field(states, :shunts)[k, t] = 0
                    revised = true
                end
            end
            for k in topology.generators_nodes[i]
                if getfield(states, :generators)[k, t] != 0
                    field(states, :generators)[k, t] = 0
                    revised = true
                end
            end
            for k in topology.storages_nodes[i]
                if getfield(states, :storages)[k, t] != 0
                    field(states, :storages)[k, t] = 0
                    revised = true
                end
            end
        end
    end

    for i in field(system, :branches, :keys)
        if states.branches[i,t] != 0
            f_bus = field(states, :buses)[system.branches.f_bus[i], t]
            t_bus = field(states, :buses)[system.branches.t_bus[i], t]
            if f_bus == 4 || t_bus == 4
                states.branches[i,t] = 0
            end
        end
    end

    # if revised == true
    #     update_idxs!(filter(i->BaseModule.field(states, :loads, i, t), field(system, :loads, :keys)), topology.loads_idxs)
    #     update_idxs!(filter(i->BaseModule.field(states, :shunts, i, t), field(system, :shunts, :keys)), topology.shunts_idxs)
    #     update_idxs!(filter(i->BaseModule.field(states, :generators, i, t), field(system, :generators, :keys)), topology.generators_idxs)
    #     update_idxs!(filter(i->BaseModule.field(states, :storages, i, t), field(system, :storages, :keys)), topology.storages_idxs)
    # end

    return revised

end

# "Creates AbstractAsset - Loads with time-series data"
# function container(dict_core::Dict{<:Any}, dict_timeseries::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Loads}, N, baseMVA)

#     container_key = [i for i in keys(dict_timeseries)]
#     key_order_series = sortperm(container_key)
#     container_data = container(network, asset)

#     tmp_cost = Dict(Int(dict_core[:key][i]) => Float32(dict_core[Symbol("customerloss[USD/MWh]")][i]) for i in eachindex(dict_core[:key]))
#     for (i,load) in network[:load]
#         get!(load, "cost", tmp_cost[i])
#     end

#     for i in eachindex(container_data[:cost])
#         container_data[:cost][i] = tmp_cost[i]
#     end

#     if isempty(dict_timeseries) error("Load data must be provided") end

#     if length(container_key) ≠ length(container_data[:keys])
#         for i in container_data[:keys]
#             if in(container_key).(i) == false
#                 setindex!(dict_timeseries, [container_data[:pd][i] for k in 1:N]*baseMVA, i)
#             end
#             #get!(dict_timeseries_qd, i, Float32.(dict_timeseries_pd[i]*powerfactor))
#         end
#         container_key = [i for i in keys(dict_timeseries)]
#         key_order_series = sortperm(container_key)
#         @assert length(container_key) == length(container_data[:keys])
#     end

#     container_timeseries = [Float32.(dict_timeseries[i]/baseMVA) for i in keys(dict_timeseries)]
#     container_data[:pd] = reduce(vcat,transpose.(container_timeseries[key_order_series]))

#     return container_data

# end


# "Creates AbstractAsset - Branches with time-series data"
# function container(dict_core::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Branches}, N, B)

#     container_data = container(network, asset)
#     key_order_core = sortperm(container_data[:keys])

#     container_λ = Float64.(values(dict_core[Symbol("failurerate[f/year]")]))
#     container_μ = Vector{Float64}(undef, length(values(dict_core[Symbol("repairtime[hrs]")])))

#     for i in 1:length(values(dict_core[Symbol("repairtime[hrs]")]))
#         if values(dict_core[Symbol("repairtime[hrs]")])[i]≠0.0
#             container_μ[i] = Float64.(N/values(dict_core[Symbol("repairtime[hrs]")])[i])
#         else
#             container_μ[i] = 0.0
#         end
#     end

#     container_data[:λ] = deepcopy(container_λ[key_order_core])
#     container_data[:μ] = deepcopy(container_μ[key_order_core])

#     return container_data

# end

# "Creates AbstractAsset - Generators with time-series data"
# function container(dict_core::Dict{<:Any}, dict_timeseries::Dict{<:Any}, network::Dict{Symbol, <:Any}, asset::Type{Generators}, N, baseMVA)

#     container_key = [i for i in keys(dict_timeseries)]
#     key_order_series = sortperm(container_key)

#     container_data = container(network, asset)

#     if length(container_key) ≠ length(container_data[:keys])
#         for i in container_data[:keys]
#             if in(container_key).(i) == false
#                 setindex!(dict_timeseries, [container_data[:pg][i] for k in 1:N]*baseMVA, i)
#             end
#         end
#         container_key = [i for i in keys(dict_timeseries)]
#         key_order_series = sortperm(container_key)
#         @assert length(container_key) == length(container_data[:keys])
#     end

#     container_timeseries = [Float32.(dict_timeseries[i]/baseMVA) for i in keys(dict_timeseries)]

#     container_λ = Float64.(values(dict_core[Symbol("failurerate[f/year]")]))
#     container_μ = Vector{Float64}(undef, length(values(dict_core[Symbol("repairtime[hrs]")])))

#     for i in 1:length(values(dict_core[Symbol("repairtime[hrs]")]))
#         if values(dict_core[Symbol("repairtime[hrs]")])[i]≠0.0
#             container_μ[i] = Float64.(8736/values(dict_core[Symbol("repairtime[hrs]")])[i])
#         else
#             container_μ[i] = 0.0
#         end
#     end

#     key_order_core = sortperm(container_data[:keys])

#     container_data[:pg] = reduce(vcat,transpose.(container_timeseries[key_order_series]))
#     container_data[:λ] = deepcopy(container_λ[key_order_core])
#     container_data[:μ] = deepcopy(container_μ[key_order_core])

#     return container_data

# end