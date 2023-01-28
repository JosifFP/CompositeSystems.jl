include("solvers.jl")
import PowerModels, JuMP
using Test
import CompositeSystems: CompositeSystems, BaseModule, OPF, CompositeAdequacy, MathOptInterface, InfrastructureModels
import InfrastructureModels
rawfile = "test/data/RBTS/Base/RBTS_AC.m"
Base_reliabilityfile = "test/data/RBTS/Base/R_RBTS2.m"

Storage_rawfile = "test/data/RBTS/Storage/RBTS_AC.m"
Storage_reliabilityfile = "test/data/RBTS/Storage/R_RBTS_FULL.m"
timeseriesfile = "test/data/RBTS/Loads.xlsx"

#DCMPPowerModel
#DCPLLPowerModel
settings = CompositeSystems.Settings(gurobi_optimizer_1, jump_modelmode=JuMP.AUTOMATIC, powermodel_formulation=OPF.DCPLLPowerModel)

resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Shortfall())
timeseries_load, SParametrics = BaseModule.extract_timeseriesload(timeseriesfile)

system = BaseModule.SystemModel(Storage_rawfile, Storage_reliabilityfile, timeseries_load, SParametrics)
#system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseries_load, SParametrics)

run()

function run()
    method = CompositeAdequacy.SequentialMCS(samples=1, seed=100, threaded=false)
    systemstates = CompositeAdequacy.SystemStates(system)
    pm = OPF.abstract_model(system, settings)
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
        end
        #OPF.build_method!(pm, system, systemstates, t)
        #OPF.optimize_method!(pm)
        #OPF.build_result!(pm, system, systemstates, t)
        OPF._update!(pm, system, systemstates, settings, t)
        CompositeAdequacy.resolve!(pm, system, systemstates, t)
        #println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :pg, 1)*100)))))
        #println(Float32.(values(sort(OPF.build_sol_values(OPF.var(pm, :ps, 1)*100)))))
        #println(Float32.(systemstates.se[t]*100))
        #println(Float32.(systemstates.plc[:]*100))
        #println(Float32.(values(sort(InfrastructureModels.build_solution_values(OPF.var(pm, :p, 1))))).*100)
        println(values(sort(OPF.build_sol_values(OPF.var(pm, :va, 1)*180/pi))))
        #OPF.empty_model!(pm)
    end
end




OPF.empty_model!(pm)
JuMP.termination_status(pm.model)
@show JuMP.solution_summary(pm.model, verbose=true)