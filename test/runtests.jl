using PRATS
using PRAS
using Test

sys = PRAS.SystemModel("test/data/rts.pras")
shortfalls, flows = PRAS.assess(sys, SequentialMonteCarlo(samples=100), Shortfall(), Flow())
lole, eue = LOLE(shortfalls), EUE(shortfalls)

assess(sys, SequentialMonteCarlo(samples=100),
GeneratorAvailability(), LineAvailability(),
StorageAvailability(), GeneratorStorageAvailability(),
StorageEnergy(), GeneratorStorageEnergy(),
StorageEnergySamples(), GeneratorStorageEnergySamples())




#using Pkg
#Pkg.develop(PackageSpec(path = "C:/Users/jfiguero/.julia/dev/ContingencySolver"))

@testset "PRATS.jl" begin
    # Write your tests here.
end
