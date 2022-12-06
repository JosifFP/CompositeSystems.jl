include("solvers.jl")
import PowerModels, JuMP
using Test
import CompositeSystems: CompositeSystems, BaseModule, OPF, CompositeAdequacy, MathOptInterface, InfrastructureModels

Base_RawFile = "test/data/RBTS/Base/RBTS.m"
Base_ReliabilityFile = "test/data/RBTS/Base/R_RBTS2.m"

Storage_RawFile = "test/data/RBTS/Storage/RBTS.m"
Storage_ReliabilityFile = "test/data/RBTS/Storage/R_RBTS.m"

Case1_RawFile = "test/data/RBTS/Case1/RBTS.m"
Case1_ReliabilityFile = "test/data/RBTS/Case1/R_RBTS.m"

TimeSeriesFile = "test/data/RBTS/Loads.xlsx"

settings = CompositeSystems.Settings(gurobi_optimizer_1,modelmode = JuMP.AUTOMATIC)

resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Shortfall())
timeseries_load, SParametrics = BaseModule.extract_timeseriesload(TimeSeriesFile)

#system = BaseModule.SystemModel(Storage_RawFile, Storage_ReliabilityFile, timeseries_load, SParametrics)
system = BaseModule.SystemModel(Base_RawFile, Base_ReliabilityFile, timeseries_load, SParametrics)
method = CompositeAdequacy.SequentialMCS(samples=1, seed=100, threaded=false)
systemstates = CompositeAdequacy.SystemStates(system)
model = OPF.JumpModel(settings.modelmode, deepcopy(settings.optimizer))
pm = OPF.PowerModel(settings.powermodel, OPF.Topology(system), model)
recorders = CompositeAdequacy.accumulator.(system, method, resultspecs)
rng = CompositeAdequacy.Philox4x((0, 0), 10)
CompositeAdequacy.seed!(rng, (method.seed, 1))
CompositeAdequacy.initialize_states!(rng, systemstates, system)
#OPF.initialize_pm_containers!(pm, system; timeseries=false)
CompositeAdequacy.initialize_powermodel!(pm, system, systemstates, results=true)

t=4
system.loads.pd[:,t] = system.loads.pd[:,t]*2

CompositeAdequacy.update_model!(pm, system, systemstates, t)
#OPF.build_method!(pm, system, systemstates, t)
#OPF.optimize_method!(pm)
#OPF.build_result!(pm, system, systemstates, t)
systemstates.plc
systemstates.se

OPF.build_sol_values(OPF.var(pm, :se, 1))[1]
OPF.build_sol_values(OPF.var(pm, :sc, 1))[1]
OPF.build_sol_values(OPF.var(pm, :sd, 1))[1]
OPF.build_sol_values(OPF.var(pm, :ps, 1))[1]
OPF.build_sol_values(OPF.var(pm, :sc_on, 1))[1]
OPF.build_sol_values(OPF.var(pm, :sd_on, 1))[1]
OPF.empty_model!(pm)
JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)



for t in 2:24
    import InfrastructureModels
    system.loads.pd[:,t] = system.loads.pd[:,t]*1.25

    if t==17 || t==18 || t==19 || t==20
        CompositeSystems.field(systemstates, :branches)[3,t] = 0
        CompositeSystems.field(systemstates, :branches)[4,t] = 0
        CompositeSystems.field(systemstates, :branches)[8,t] = 0
        systemstates.system[t] = 0
    end

    #OPF.build_method!(pm, system, systemstates, t)
    #OPF.optimize_method!(pm)
    #OPF.build_result!(pm, system, systemstates, t)
    CompositeAdequacy.update_model!(pm, system, systemstates, t)
    #println(Float16.(values(sort(OPF.build_sol_values(OPF.var(pm, :pg, 1)*100)))))
    #println(Float16.(systemstates.se[t]))
    #println(Float16.(values(sort(OPF.build_sol_values(OPF.var(pm, :ps, 1)*100)))))
    #println(Float16.(systemstates.se[t]*100))
    println(Float16.(systemstates.plc[:,t]*100))
    #println(Float16.(values(sort(InfrastructureModels.build_solution_values(OPF.var(pm, :p, 1))))).*100)
    #println(values(sort(OPF.build_sol_values(OPF.var(pm, :va, 1)*180/pi))))
    OPF.empty_model!(pm)
end




#if OPF.is_empty(pm.model.moi_backend)
#    CompositeAdequacy.initialize_powermodel!(pm, system, systemstates, results=true)
#end

#CompositeAdequacy.initialize_powermodel!(pm, system, systemstates, results=true)
#t=1
#println(values(sort(OPF.build_sol_values(OPF.var(pm, :pg, 1)*100))))
#println(systemstates.se[t])

#CompositeAdequacy.update_model!(pm, system, systemstates, t)
CompositeAdequacy.build_method!(pm, system, systemstates, t)
OPF.optimize_method!(pm)
OPF.build_result!(pm, system, systemstates, t)
systemstates.se
systemstates.plc
OPF.build_sol_values(OPF.var(pm, :se, 1))[1]
OPF.build_sol_values(OPF.var(pm, :sc, 1))[1]
OPF.build_sol_values(OPF.var(pm, :sd, 1))[1]
OPF.build_sol_values(OPF.var(pm, :ps, 1))[1]
OPF.build_sol_values(OPF.var(pm, :sc_on, 1))[1]
OPF.build_sol_values(OPF.var(pm, :sd_on, 1))[1]
