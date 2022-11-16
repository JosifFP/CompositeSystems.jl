"SequentialMCS"
#update_idxs!(
    #    filter(i->states.buses[i]!= 4,field(system, :buses, :keys)), topology(pm, :buses_idxs))

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
    #    update_constraint_power_balance(pm, system, states, i, t)
    #end
    
    # JuMP.delete(pm.model, con(pm, :ohms_yt_from, 1).data)
    # JuMP.delete(pm.model, con(pm, :voltage_angle_diff_upper, 1).data)
    # JuMP.delete(pm.model, con(pm, :voltage_angle_diff_lower, 1).data)

    # for i in field(system, :branches, :keys)
    #     if field(states, :branches)[i,t] != 0
    #         constraint_ohms_yt(pm, system, i)
    #         constraint_voltage_angle_diff(pm, system, i)
    #     end
    # end   

    # if t > 1
    #     for i in field(system, :branches, :keys)
    #         if field(states, :branches)[i,t] != 0 && field(states, :branches)[i,t-1] == 0
    #             constraint_ohms_yt(pm, system, i)
    #             constraint_voltage_angle_diff(pm, system, i)
    #         elseif field(states, :branches)[i,t] == 0 && field(states, :branches)[i,t-1] != 0
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
    #         if field(states, :branches)[i,t] != 0
    #             constraint_ohms_yt(pm, system, i)
    #             constraint_voltage_angle_diff(pm, system, i)
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
#     sol::Matrix{Float16}

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
#     sol::Matrix{Float16}

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


    # if all(view(states.branches,:,t)) != true
    #     JuMP.delete(pm.model, con(pm, :ohms_yt_from, 1).data)
    #     JuMP.delete(pm.model, con(pm, :voltage_angle_diff_upper, 1).data)
    #     JuMP.delete(pm.model, con(pm, :voltage_angle_diff_lower, 1).data)

    #     add_con_container!(pm.con, :ohms_yt_from, assetgrouplist(topology(pm, :branches_idxs)))
    #     add_con_container!(pm.con, :voltage_angle_diff_upper, assetgrouplist(topology(pm, :branches_idxs)))
    #     add_con_container!(pm.con, :voltage_angle_diff_lower, assetgrouplist(topology(pm, :branches_idxs)))

    #     for i in field(system, :branches, :keys)
    #         if field(states, :branches)[i,t] != 0
    #             constraint_ohms_yt(pm, system, i)
    #             constraint_voltage_angle_diff(pm, system, i)
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
# function build_method_idxs!(pm::Union{AbstractDCMPPModel, AbstractDCPModel}, system::SystemModel, t)
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
#         constraint_theta_ref(pm, i, nw=t)
#     end

#     for i in assetgrouplist(topology(pm, :buses_idxs))
#         constraint_power_balance(pm, system, i, t)
#     end

#     for i in assetgrouplist(topology(pm, :branches_idxs))
#         constraint_ohms_yt(pm, system, i, nw=t)
#         constraint_voltage_angle_diff(pm, system, i, nw=t)
#         #constraint_thermal_limits(pm, system, i, t)
#     end
#     objective_min_load_curtailment(pm, system, nw=t)
#     return

# end

# JuMP.delete(pm.model, con(pm, :power_balance, 1).data)

# for i in field(system, :buses, :keys)
#     constraint_power_balance(pm, system, i, t)
# end





#"***************************************************************************************************************************"
#"Needs to be fixed/updated"

#"DC LINES "
# function constraint_dcline_power_losses(pm::AbstractDCPowerModel, i::Int)
#     dcline = ref(pm, :dcline, i)
#     f_bus = dcline["f_bus"]
#     t_bus = dcline["t_bus"]
#     f_idx = (i, f_bus, t_bus)
#     t_idx = (i, t_bus, f_bus)
#     loss0 = dcline["loss0"]
#     loss1 = dcline["loss1"]

#     _constraint_dcline_power_losses(pm, f_bus, t_bus, f_idx, t_idx, loss0, loss1)
# end

# """
# Creates Line Flow constraint for DC Lines (Matpower Formulation)

# ```
# p_fr + p_to == loss0 + p_fr * loss1
# ```
# """
# function _constraint_dcline_power_losses(pm::AbstractDCPowerModel, f_bus, t_bus, f_idx, t_idx, loss0, loss1)
#     p_fr = var(pm, :p_dc, f_idx)
#     p_to = var(pm, :p_dc, t_idx)

#     @constraint(pm.model, (1-loss1) * p_fr + (p_to - loss0) == 0)
# end

# "Fixed Power Factor"
# function constraint_power_factor(pm::AbstractACPowerModel)

#     z_demand = var(pm, :z_demand)
#     plc = var(pm, :plc)
#     q_lc = var(pm, :q_lc)
    
#     for (l,_) in ref(pm, :load)
#         @constraint(pm.model, z_demand[i]*plc[i] - q_lc[i] == 0.0)      
#     end
# end

# ""
# function constraint_voltage_magnitude_diff(pm::AbstractDCPowerModel, i::Int)

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

#     _constraint_voltage_magnitude_difference(pm, i, f_bus, t_bus, f_idx, t_idx, r, x, g_sh_fr, b_sh_fr, tm)
# end

# """
# Defines voltage drop over a branch, linking from and to side voltage magnitude
# """
# function _constraint_voltage_magnitude_difference(pm::AbstractDCPowerModel, i, f_bus, t_bus, f_idx, t_idx, r, x, g_sh_fr, b_sh_fr, tm)
#     p_fr = var(pm, :p, f_idx)
#     #q_fr = var(pm, n, :q, f_idx)
#     q_fr = 0
#     w_fr = var(pm, :w, f_bus)
#     w_to = var(pm, :w, t_bus)
#     ccm =  var(pm, :ccm, i)

#     ym_sh_sqr = g_sh_fr^2 + b_sh_fr^2

#     @constraint(pm.model, (1+2*(r*g_sh_fr - x*b_sh_fr))*(w_fr/tm^2) - w_to ==  2*(r*p_fr + x*q_fr) - (r^2 + x^2)*(ccm + ym_sh_sqr*(w_fr/tm^2) - 2*(g_sh_fr*p_fr - b_sh_fr*q_fr)))
# end


# if all(view(states.branches,:,t)) != true
#     JuMP.delete(pm.model, con(pm, :ohms_yt_from, 1).data)
#     #JuMP.delete(pm.model, con(pm, :voltage_angle_diff_upper, 1).data)
#     #JuMP.delete(pm.model, con(pm, :voltage_angle_diff_lower, 1).data)

#     add_con_container!(pm.con, :ohms_yt_from, assetgrouplist(topology(pm, :branches_idxs)))
#     #add_con_container!(pm.con, :voltage_angle_diff_upper, assetgrouplist(topology(pm, :branches_idxs)))
#     #add_con_container!(pm.con, :voltage_angle_diff_lower, assetgrouplist(topology(pm, :branches_idxs)))

#     for i in assetgrouplist(topology(pm, :branches_idxs))
#         constraint_ohms_yt(pm, system, i)
#         #constraint_voltage_angle_diff(pm, system, i)
#     end
# end