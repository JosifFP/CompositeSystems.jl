import Profile
import BenchmarkTools
import ProfileView
using PRATS
import XLSX

Profile.init(delay=0.01)
loadfile = "test/data/rts_Load.xlsx"
@btime sys = PRATS.SystemModel(loadfile);
@time sys = PRATS.SystemModel(loadfile);


@time f = Dict{Symbol,Any}()
@time XLSX.openxlsx(loadfile, enable_cache=false) do of
    f[:loads] = XLSX.gettable(of["loads"])
    f[:generators] = XLSX.gettable(of["generators"])
    f[:storages] = XLSX.gettable(of["storages"])
    f[:generatorstorages] = XLSX.gettable(of["generatorstorages"])
    f[:interfaces] = XLSX.gettable(of["interfaces"])
    f[:lines] = XLSX.gettable(of["lines"])
    f[:regions] = string.(XLSX.gettable(of["regions"])[1][1])
    f[:total_load] = zeros(Int64,length(f[:loads][1][1]))
end;


struct HashDict{T<:Base.Symbol}; i::T 
    function HashDict(i)
        return Symbol(i)
    end
end
import XLSX
loadfile = "test/data/rts_Load.xlsx"

f = Dict{Symbol,Any}()
@time XLSX.openxlsx(loadfile, enable_cache=false) do xf
    for x in XLSX.sheetnames(xf)
        if x!="core"
            #f[HashDict(x)] = XLSX.eachtablerow(xf[x])
            f[HashDict(x)] = XLSX.gettable(xf[x])
        end
    end
end




#######################################################################################

simspec = SequentialMonteCarlo(samples=100,seed=1, threaded=false)

resultspecs = (Shortfall(), Surplus(), Flow(), Utilization(),
               ShortfallSamples(), SurplusSamples(),
               FlowSamples(), UtilizationSamples(),
               GeneratorAvailability())

               @time shortfall, surplus, flow, utilization, shortfallsamples, surplussamples, flowsamples,
               utilizationsamples, generatoravailability = assess(sys, simspec, resultspecs...)


Profile.clear()
@profile (for i=1:10;
shortfall, surplus, flow, utilization, shortfallsamples, surplussamples, flowsamples,
               utilizationsamples, generatoravailability = assess(sys, simspec, resultspecs...); end)
Profile.print()
ProfileView.view()


#@time @allocated result = ContingencySolver.min_load(file, optimizer, load_curt_info, t_contingency_info, ContingencySolver.dc_opf_lc)
#cd C:\Users\jfiguero\AppData\Local\Programs\Julia-1.7.2\bin
#julia --track-allocation=user
