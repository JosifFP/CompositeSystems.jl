using PRATS
using PRATS.PRATSBase
using PRATS.CompositeAdequacy
import Memento; const _LOGGER = Memento.getlogger(@__MODULE__)
using PowerModels

RawFile =  "C:/Users/jfiguero/Desktop/PRATS Input Data/RTS.raw"
ReliabilityDataDir = "C:/Users/jfiguero/Desktop/PRATS Input Data/Reliability Data"
system = PRATSBase.SystemModel(RawFile, ReliabilityDataDir)

method = PRATS.SequentialMonteCarlo(samples=1_000,seed=1)
resultspecs = (Shortfall(),GeneratorAvailability())
#shortfalls, availability = PRATS.assess(system, method, resultspecs...)

#threads = Base.Threads.nthreads()
threads = 1
sampleseeds = Channel{Int}(2*threads)

results = PRATS.CompositeAdequacy.resultchannel(method, resultspecs, threads)
@async PRATS.CompositeAdequacy.makeseeds(sampleseeds, method.nsamples)

#assess(system, method, sampleseeds, results, resultspecs...)

    sequences = UpDownSequence(system)
    systemstate = SystemState(system)

    recorders = accumulator.(system, method, resultspecs)
    rng = PRATS.CompositeAdequacy.Philox4x((0, 0), 10)
    PRATS.CompositeAdequacy.seed!(rng, (method.seed, 1))  #using the same seed for entire period.
    N =8760
    t = 1

    #system.network
    #data = PRATSBase.conversion_to_pm_data(system.network)
    #pf_result = PowerModels.compute_dc_pf(data)
    #PowerModels.update_data!(data, pf_result["solution"])
    #flow = PowerModels.calc_branch_flow_dc(data)
    
    #update_problem!(dispatchproblem, state, system, t)


    #PowerModels.update_data!(data, flow)
    #network = Network{1,1,Hour,MW,MWh,kV}(data)
#

function advance!(
    sequences::UpDownSequence,
    state::SystemState,
    system::SystemModel{N}, t::Int) where N

    #update_energy!(state.stors_energy, system.storages, t)
    #update_energy!(state.genstors_energy, system.generatorstorages, t)
    update_problem!(dispatchproblem, state, system, t)

end


