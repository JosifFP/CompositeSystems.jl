"""
    _reset!(topology::Topology)

Reset the availability and flows of various assets within the topology to 
their default states. This prepares the topology for a new round of 
calculations or simulations.

# Arguments
- `topology`: The topology data structure to reset.
"""
function _reset!(topology::Topology)
   fill!(topology.branches_available, 1)
   fill!(topology.generators_available, 1)
   fill!(topology.storages_available, 1)
   fill!(topology.loads_available, 1)
   fill!(topology.shunts_available, 1)
   fill!(topology.interfaces_available, 1)
   fill!(topology.buses_available, 1)
   return
end

"Classic OPF from _PM.jl."
function solve_opf!(system::SystemModel, settings::Settings)
   pm = CompositeSystems.abstract_model(system, settings)
   CompositeSystems.build_opf!(pm, system)
   JuMP.optimize!(pm.model)
   return pm
end

resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

settings_NFAPowerModel = CompositeSystems.Settings(
   optimizer = juniper_optimizer,
   jump_modelmode = JuMP.AUTOMATIC,
   powermodel_formulation = OPF.NFAPowerModel,
   select_largest_splitnetwork = false,
   deactivate_isolated_bus_gens_stors = false
)

settings_DCPPowerModel = CompositeSystems.Settings(
   optimizer = juniper_optimizer,
   jump_modelmode = JuMP.AUTOMATIC,
   powermodel_formulation = OPF.DCPPowerModel,
   select_largest_splitnetwork = false,
   deactivate_isolated_bus_gens_stors = false
)

settings_DCMPPowerModel = CompositeSystems.Settings(;
   optimizer = juniper_optimizer,
   jump_modelmode = JuMP.AUTOMATIC,
   powermodel_formulation = OPF.DCMPPowerModel,
   select_largest_splitnetwork = false,
   deactivate_isolated_bus_gens_stors = false,
)

settings_LPACCPowerModel = CompositeSystems.Settings(;
   optimizer = juniper_optimizer,
   jump_modelmode = JuMP.AUTOMATIC,
   powermodel_formulation = OPF.LPACCPowerModel,
   select_largest_splitnetwork = false,
   deactivate_isolated_bus_gens_stors = false
)

rawfile_rbts = "../test/data/RBTS/Base/RBTS.m"
relfile_rbts = "../test/data/RBTS/Base/R_RBTS.m"
tseriesfile_rbts = "../test/data/RBTS/SYSTEM_LOADS.csv"
rawfile_rbts_strg = "../test/data/RBTS/Storage/RBTS.m"
relfile_rbts_strg = "../test/data/RBTS/Storage/R_RBTS.m"

sys_rbts = BaseModule.SystemModel(rawfile_rbts, relfile_rbts)
sys_rbts_tseries = BaseModule.SystemModel(rawfile_rbts, relfile_rbts, tseriesfile_rbts)
sys_rbts_strg = BaseModule.SystemModel(rawfile_rbts_strg, relfile_rbts_strg)
sys_rbts_tseries_strg = BaseModule.SystemModel(rawfile_rbts_strg, relfile_rbts_strg, tseriesfile_rbts)

costs_rbts = [9632.5; 4376.9; 8026.7; 8632.3; 5513.2]
CompositeSystems.field(sys_rbts, :loads, :cost)[:] = costs_rbts
CompositeSystems.field(sys_rbts_tseries, :loads, :cost)[:] = costs_rbts
CompositeSystems.field(sys_rbts_strg, :loads, :cost)[:] = costs_rbts
CompositeSystems.field(sys_rbts_tseries_strg, :loads, :cost)[:] = costs_rbts
data_rbts = OPF.build_network(rawfile_rbts, symbol=false)

load_pd = Dict{Int, Float64}()
for (k,v) in data_rbts["load"]
    load_pd[parse(Int,k)] = v["pd"]
    sys_rbts_tseries.loads.qd[parse(Int,k)] = v["qd"]
    sys_rbts_tseries_strg.loads.qd[parse(Int,k)] = v["qd"]
end

for t in 1:8736
   for i in sys_rbts_tseries.loads.keys
      sys_rbts_tseries.loads.pd[i,t] = load_pd[i]
      sys_rbts_tseries_strg.loads.pd[i,t] = load_pd[i]
   end
end

rawfile_rts = "../test/data/RTS_79_A/Base/RTS_highrate.m"
relfile_rts = "../test/data/RTS_79_A/Base/R_RTS.m"
tseriesfile_rts = "../test/data/RTS_79_A/SYSTEM_LOADS.csv"
rawfile_rts_strg = "../test/data/RTS_79_A/Storage/RTS_highrate.m"
relfile_rts_strg = "../test/data/RTS_79_A/Storage/R_RTS.m"

sys_rts = BaseModule.SystemModel(rawfile_rts, relfile_rts)
sys_rts_tseries = BaseModule.SystemModel(rawfile_rts, relfile_rts, tseriesfile_rts)
sys_rts_strg = BaseModule.SystemModel(rawfile_rts_strg, relfile_rts_strg)
sys_rts_tseries_strg = BaseModule.SystemModel(rawfile_rts_strg, relfile_rts_strg, tseriesfile_rts)

costs_rts = [
   8981.5; 7360.6; 5899; 9599.2; 9232.3; 6523.8; 
   7029.1; 7774.2; 3662.3; 5194; 7281.3; 4371.7; 
   5974.4; 7230.5; 5614.9; 4543; 5683.6;
]

CompositeSystems.field(sys_rts, :loads, :cost)[:] = costs_rts
CompositeSystems.field(sys_rts_tseries, :loads, :cost)[:] = costs_rts
CompositeSystems.field(sys_rts_strg, :loads, :cost)[:] = costs_rts
CompositeSystems.field(sys_rts_tseries_strg, :loads, :cost)[:] = costs_rts
data_rts = OPF.build_network(rawfile_rts, symbol=false)

load_pd = Dict{Int, Float64}()
for (k,v) in data_rts["load"]
   load_pd[parse(Int,k)] = v["pd"]
   sys_rts_tseries.loads.qd[parse(Int,k)] = v["qd"]
   sys_rts_tseries_strg.loads.qd[parse(Int,k)] = v["qd"]
end

for t in 1:8736
   for i in sys_rts_tseries.loads.keys
      sys_rts_tseries.loads.pd[i,t] = load_pd[i]
      sys_rts_tseries_strg.loads.pd[i,t] = load_pd[i]
   end
end

rates_rts = zeros(Float64,length(sys_rts_tseries_strg.branches.rate_a))

for i in 1:length(sys_rts_tseries_strg.branches.rate_a)
   rates_rts[i] = sys_rts_tseries_strg.branches.rate_a[i]
end