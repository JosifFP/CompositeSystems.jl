module TestSystems
using PRATS
using TimeZones
const tz = tz"UTC"

empty_str = String[]
empty_int(x) = Matrix{Int}(undef, 0, x)
empty_float(x) = Matrix{Float64}(undef, 0, x)


## Single-Region System A
    gens1 = Generators{4,1,Hour,MW}(
        ["Gen1", "Gen2", "Gen3", "VG"], ["Gens", "Gens", "Gens", "VG"],
        [fill(10, 3, 4); [5 6 7 8]],
        [fill(0.1, 3, 4); fill(0.0, 1, 4)],
        [fill(0.9, 3, 4); fill(1.0, 1, 4)]
    )

    emptystors1 = Storages{4,1,Hour,MW,MWh}((empty_str for _ in 1:2)...,
                    (empty_int(4) for _ in 1:3)...,
                    (empty_float(4) for _ in 1:5)...
    )

    emptygenstors1 = GeneratorStorages{4,1,Hour,MW,MWh}(
        (empty_str for _ in 1:2)...,
        (empty_int(4) for _ in 1:3)..., (empty_float(4) for _ in 1:3)...,
        (empty_int(4) for _ in 1:3)..., (empty_float(4) for _ in 1:2)...
    )

    singlenode_a = SystemModel(
        gens1, emptystors1, emptygenstors1,
        DateTime(2010,1,1,0):Hour(1):DateTime(2010,1,1,3),
        [25, 28, 27, 24]
    )
##

## Single-Region System B
gens2 = Generators{2,1,Hour,MW}(
    ["Gen1", "Gen2"], ["Gens", "Gens"],
    [fill(10, 2, 2);],[fill(0.1, 2, 2);],[fill(0.9, 2, 2);]
)

emptystors2 = Storages{2,1,Hour,MW,MWh}((empty_str for _ in 1:2)...,
                (empty_int(2) for _ in 1:3)...,
                (empty_float(2) for _ in 1:5)...
)

emptygenstors2 = GeneratorStorages{2,1,Hour,MW,MWh}(
    (empty_str for _ in 1:2)...,
    (empty_int(2) for _ in 1:3)..., (empty_float(2) for _ in 1:3)...,
    (empty_int(2) for _ in 1:3)..., (empty_float(2) for _ in 1:2)...
)

singlenode_b = SystemModel(
    gens2, emptystors2, emptygenstors2,
    DateTime(2010,1,1,0):Hour(1):DateTime(2010,1,1,1),
    [25, 28]
)
##

end
import .TestSystems


