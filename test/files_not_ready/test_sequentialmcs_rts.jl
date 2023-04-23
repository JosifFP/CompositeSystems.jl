import CompositeSystems
import CompositeSystems.BaseModule
import CompositeSystems.OPF
import CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, BenchmarkTools, JuMP
import JuMP: termination_status
import BenchmarkTools: @btime
import Dates, XLSX
using Test, BenchmarkTools


include("solvers.jl")
resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    min_generators_off = 0,
    set_string_names_on_creation = false,
    count_samples = true
)

timeseriesfile = "test/data/SMCS/RTS_79_A/Loads_system.xlsx"
rawfile = "test/data/SMCS/RTS_79_A/RTS_AC_HIGH_modified.m"
Base_reliabilityfile = "test/data/SMCS/RTS_79_A/R_RTS.m"

method = CompositeAdequacy.SequentialMCS(samples=2000, seed=100, threaded=true)
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)
shortfall, util = CompositeSystems.assess(system, method, settings, resultspecs...)
CompositeSystems.print_results(system, shortfall)
CompositeSystems.print_results(system, util)


CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall, system.buses.keys))
CompositeAdequacy.stderror.(CompositeSystems.EDLC.(shortfall, system.buses.keys))
CompositeAdequacy.val.(CompositeSystems.EDLC.(shortfall))
CompositeAdequacy.stderror.(CompositeSystems.EDLC.(shortfall))

CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall, system.buses.keys))
CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall, system.buses.keys))
CompositeAdequacy.val.(CompositeSystems.EENS.(shortfall))
CompositeAdequacy.stderror.(CompositeSystems.EENS.(shortfall))

A = getindex(util, :)
B = CompositeAdequacy.PTV(util, :)

Base.print_matrix(Base.stdout, A)
Base.print_matrix(Base.stdout, B)

CompositeSystems.print_results(system, shortfall)
CompositeSystems.print_results(system, util)