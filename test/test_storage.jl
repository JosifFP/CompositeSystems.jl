include("solvers.jl")
import PowerModels, JuMP
using Test
import CompositeSystems: CompositeSystems, BaseModule, OPF, CompositeAdequacy, MathOptInterface, InfrastructureModels
import InfrastructureModels
Base_RawFile = "test/data/RBTS/Base/RBTS.m"
Base_ReliabilityFile = "test/data/RBTS/Base/R_RBTS2.m"

Storage_RawFile = "test/data/RBTS/Storage/RBTS.m"
Storage_ReliabilityFile = "test/data/RBTS/Storage/R_RBTS.m"
TimeSeriesFile = "test/data/RBTS/Loads.xlsx"

#DCMPPowerModel
#DCPLLPowerModel
settings = CompositeSystems.Settings(gurobi_optimizer_1, modelmode=JuMP.AUTOMATIC, powermodel=OPF.DCPLLPowerModel)

resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Shortfall())
timeseries_load, SParametrics = BaseModule.extract_timeseriesload(TimeSeriesFile)

system = BaseModule.SystemModel(Storage_RawFile, Storage_ReliabilityFile, timeseries_load, SParametrics)
#system = BaseModule.SystemModel(Base_RawFile, Base_ReliabilityFile, timeseries_load, SParametrics)

run()

function run()
    method = CompositeAdequacy.SequentialMCS(samples=1, seed=100, threaded=false)
    systemstates = CompositeAdequacy.SystemStates(system)
    model = OPF.JumpModel(settings.modelmode, deepcopy(settings.optimizer))
    pm = OPF.PowerModel(settings.powermodel, OPF.Topology(system), model)
    recorders = CompositeAdequacy.accumulator.(system, method, resultspecs)
    rng = CompositeAdequacy.Philox4x((0, 0), 10)
    CompositeAdequacy.seed!(rng, (method.seed, 1))
    CompositeAdequacy.initialize_states!(rng, systemstates, system)
    t=1
    system.loads.pd[:,t] = system.loads.pd[:,t]*1.25
    CompositeAdequacy.initialize_powermodel!(pm, system, systemstates, results=true)
    #println(Float32.(systemstates.se[t]*100))
    #println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :pg, 1)*100)))))
    #println(Float32.(values(sort(InfrastructureModels.build_solution_values(OPF.var(pm, :p, 1))))).*100)
    println(values(sort(OPF.build_sol_values(OPF.var(pm, :va, 1)*180/pi))))

    for t in 2:24
        #import InfrastructureModels
        system.loads.pd[:,t] = system.loads.pd[:,t]*1.25

        if t==17 || t==18 || t==19 || t==20
            #CompositeSystems.field(systemstates, :branches)[5,t] = 0
            #CompositeSystems.field(systemstates, :branches)[8,t] = 0
            #system.branches.rate_a[5] = 0.3
            #systemstates.system[t] = 0
        end
        #OPF.build_method!(pm, system, systemstates, t)
        #OPF.optimize_method!(pm)
        #OPF.build_result!(pm, system, systemstates, t)
        CompositeAdequacy.update!(pm, system, systemstates, t)
        CompositeAdequacy.resolve!(pm, system, systemstates, t)
        #println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :pg, 1)*100)))))
        #println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :ps, 1)*100)))))
        #println(Float32.(systemstates.se[t]*100))
        #println(Float32.(systemstates.plc[:,t]*100))
        #println(Float32.(values(sort(InfrastructureModels.build_solution_values(OPF.var(pm, :p, 1))))).*100)
        println(values(sort(OPF.build_sol_values(OPF.var(pm, :va, 1)*180/pi))))
        #OPF.empty_model!(pm)
    end
end




OPF.empty_model!(pm)
JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)