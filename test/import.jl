
using PRATS, Reexport, XLSX
using PRAS
#using ContingencySolver

networkfile = "test/data/RTS.raw"
loadfile = "test/data/rts_Load.xlsx"
studycase = [networkfile, loadfile]
#data = ContingencySolver.build_data(studycase[1])

sys = PRATS.SystemModel(loadfile)
shortfalls, flows = PRAS.assess(sys, SequentialMonteCarlo(samples=100), Shortfall(), Flow())
lole =  PRAS.EUE(shortfalls, "1")