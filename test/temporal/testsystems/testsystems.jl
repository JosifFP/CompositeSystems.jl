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

    singlenode_a_lole = 0.355
    singlenode_a_lolps = [0.028, 0.271, 0.028, 0.028]
    singlenode_a_eue = 1.59
    singlenode_a_eues = [0.29, 0.832, 0.29, 0.178]


    stors_a = Storages{4,1,Hour,MW,MWh}(
        ["Stor1", "Stor2"], ["Storage", "Storage"],
        repeat([10,0], 1, 4), repeat([10,0], 1, 4), fill(4, 2, 4),
        fill(1.0, 2, 4), fill(1.0, 2, 4), fill(.99, 2, 4),
        fill(0.0, 2, 4), fill(1.0, 2, 4))

    singlenode_a_2 = SystemModel(
        gens1, stors_a, emptygenstors1,
        DateTime(2010,1,1,0):Hour(1):DateTime(2010,1,1,3),
        [25, 28, 27, 24]
    )


##

## Single-Region System B
gens2 = Generators{6,1,Hour,MW}(
    ["Gen1", "Gen2", "VG"], ["Gens", "Gens", "VG"],
    [10 10 10 15 15 15; 20 20 20 25 25 25; 7 8 9 9 8 7],
    [fill(0.1, 2, 6); fill(0.0, 1, 6)],
    [fill(0.9, 2, 6); fill(1.0, 1, 6)])

emptystors2 = Storages{6,1,Hour,MW,MWh}((empty_str for _ in 1:2)...,
                  (empty_int(6) for _ in 1:3)...,
                  (empty_float(6) for _ in 1:5)...)

emptygenstors2 = GeneratorStorages{6,1,Hour,MW,MWh}(
    (empty_str for _ in 1:2)...,
    (empty_int(6) for _ in 1:3)..., (empty_float(6) for _ in 1:3)...,
    (empty_int(6) for _ in 1:3)..., (empty_float(6) for _ in 1:2)...)

genstors2 = GeneratorStorages{6,1,Hour,MW,MWh}(
    ["Genstor1", "Genstor2"], ["Genstorage", "Genstorage"],
    fill(0, 2, 6), fill(0, 2, 6), fill(4, 2, 6),
    fill(1.0, 2, 6), fill(1.0, 2, 6), fill(.99, 2, 6),
    fill(0, 2, 6), fill(0, 2, 6), fill(0, 2, 6),
    fill(0.0, 2, 6), fill(1.0, 2, 6))

singlenode_b = SystemModel(
    gens2, emptystors2, emptygenstors2,
    DateTime(2015,6,1,0):Hour(1):DateTime(2015,6,1,5),
    [28,29,30,31,32,33])

singlenode_b_lole = 0.96
singlenode_b_lolps = [0.19, 0.19, 0.19, 0.1, 0.1, 0.19]
singlenode_b_eue = 7.11
singlenode_b_eues = [1.29, 1.29, 1.29, 0.85, 1.05, 1.34]
##

# Single-Region System B, with storage
#TODO: Storage tests

stors2 = Storages{6,1,Hour,MW,MWh}(
    ["Stor1", "Stor2"], ["Storage", "Storage"],
    repeat([1,0], 1, 6), repeat([1,0], 1, 6), fill(4, 2, 6),
    fill(1.0, 2, 6), fill(1.0, 2, 6), fill(.99, 2, 6),
    fill(0.0, 2, 6), fill(1.0, 2, 6))

genstors2 = GeneratorStorages{6,1,Hour,MW,MWh}(
    ["Genstor1", "Genstor2"], ["Genstorage", "Genstorage"],
    fill(0, 2, 6), fill(0, 2, 6), fill(4, 2, 6),
    fill(1.0, 2, 6), fill(1.0, 2, 6), fill(.99, 2, 6),
    fill(0, 2, 6), fill(0, 2, 6), fill(0, 2, 6),
    fill(0.0, 2, 6), fill(1.0, 2, 6))

singlenode_stor = SystemModel(
    gens2, stors2, genstors2,
    DateTime(2015,6,1,0):Hour(1):DateTime(2015,6,1,5),
    [28,29,30,31,32,33])




## Single-Region System X
gensx = Generators{4,1,Hour,MW}(
    ["Gen1", "Gen2", "Gen3", "VG"], ["Gens", "Gens", "Gens", "VG"],
    [fill(10, 3, 4); [5 6 7 8]],
    [fill(0.3, 3, 4); fill(0.0, 1, 4)],
    [fill(0.7, 3, 4); fill(1.0, 1, 4)]
)

emptystorsx = Storages{4,1,Hour,MW,MWh}((empty_str for _ in 1:2)...,
                (empty_int(4) for _ in 1:3)...,
                (empty_float(4) for _ in 1:5)...
)

emptygenstorsx = GeneratorStorages{4,1,Hour,MW,MWh}(
    (empty_str for _ in 1:2)...,
    (empty_int(4) for _ in 1:3)..., (empty_float(4) for _ in 1:3)...,
    (empty_int(4) for _ in 1:3)..., (empty_float(4) for _ in 1:2)...
)

singlenode_x = SystemModel(
    gensx, emptystorsx, emptygenstorsx,
    DateTime(2010,1,1,0):Hour(1):DateTime(2010,1,1,3),
    [25, 28, 27, 24]
)





end
import .TestSystems


