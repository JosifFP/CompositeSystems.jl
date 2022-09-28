# function convert(dictionary::Dict{Int, Any})
#     container_keys = [i for i in keys(dictionary)]
#     container_values = [i for i in values(dictionary)]
#     key_order = sortperm(container_keys)
#     return (container_keys[key_order], container_values[key_order])
# end


# function update_ref!(topology::Topology, state::SystemState, system::SystemModel{N}, t::Int) where {N}

#     for i in eachindex(system.loads.keys)
#         #dictionary[:load][i]["qd"] = Float16.(system.loads.pd[i,t]*Float32.(dictionary[:load][i]["qd"] / dictionary[:load][i]["pd"]))
#         topology.load[2][i]["pd"] = system.loads.pd[i,1]*1.5
#     end
    
#     for i in eachindex(system.generators.keys)
#         topology.gen[2][i]["pg"] = system.generators.pg[i,t]
#         if state.gens_available[i] == false topology.gen[2][i]["gen_status"] = state.gens_available[i,t] end
#     end

#     for i in eachindex(system.storages.keys)
#         if state.stors_available[i] == false topology.storage[2][i]["status"] = state.stors_available[i,t] end
#     end

#     if all(state.gens_available[:,t]) == true && all(state.branches_available[:,t]) == false
#         if all(state.branches_available[:,t]) == false
#             for i in eachindex(system.branches.keys)
#                 if state.branches_available[i] == false topology.branch[2][i]["br_status"] = state.branches_available[i,t] end
#             end
#         end
#     end

# end
# ""
# mutable struct Item
#     p::Vector{Float64}
#     q::Vector{Float64}
#     ps::Vector{Float64}
#     qs::Vector{Float64}
#     pg::Vector{Float64}
#     qg::Vector{Float64}
#     p_dc::Vector{Float64}
#     q_dc::Vector{Float64}
#     p_lc::Vector{Float64}
#     q_lc::Vector{Float64}
#     psw::Vector{Float64}
#     va::Vector{Float64}
#     vm::Vector{Float64}
#     w::Vector{Float64}
#     wr::Vector{Float64}
#     wi::Vector{Float64}
#     ccm::Vector{Float64}
#     z_demand::Vector{Float64}

#     function Item()
#         p = Float64[]
#         q = Float64[]
#         ps = Float64[]
#         qs = Float64[]
#         pg = Float64[]
#         qg = Float64[]
#         p_dc = Float64[]
#         q_dc = Float64[]
#         p_lc = Float64[]
#         q_lc = Float64[]
#         psw = Float64[]
#         va = Float64[]
#         vm = Float64[]
#         w = Float64[]
#         wr = Float64[]
#         wi = Float64[]
#         ccm = Float64[]
#         z_demand = Float64[]
#         return new(p,ps, pg, p_dc, p_lc, psw, va, w, wr, wi)
#     end
# end

#nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "max_cpu_time"=>1e+2,"constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
#mip_solver = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "output_flag"=>false)
#optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "mip_solver"=>mip_solver,"time_limit"=>1.0, "log_levels"=>[])
#optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-3, "branch_strategy"=>:PseudoCost ,"time_limit"=>1.5, "log_levels"=>[])
#optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-3, "log_levels"=>[])
#     #PRATSBase.SimplifyNetwork!(ref(pm))
#state.branches_available[:,t] == true ? ext(pm)[:type] = type = Transportation : ext(pm)[:type] = type = DCOPF