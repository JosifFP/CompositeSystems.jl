# Augment time units

export timeunits, powerunits, energyunits, voltageunits

unitsymbol(T::Type{<:Period}) = string(T)
unitsymbol(::Type{Hour}) = "h"
unitsymbol(::Type{Day}) = "d"
unitsymbol(::Type{Year}) = "y"

conversionfactor(F::Type{<:Period}, T::Type{<:Period}) = conversionfactor(F, Hour) * conversionfactor(Hour, T)
conversionfactor(::Type{Hour}, ::Type{Hour}) = 1
conversionfactor(::Type{Hour}, ::Type{Day}) = 1 / 24
conversionfactor(::Type{Day}, ::Type{Hour}) = 24

timeunits = Dict(unitsymbol(T) => T for T in [Hour, Day, Year])

# Define power units
abstract type PowerUnit end
struct kW <: PowerUnit end
struct MW <: PowerUnit end
struct GW <: PowerUnit end

unitsymbol(T::Type{<:PowerUnit}) = string(T)
unitsymbol(::Type{kW}) = "kW"
unitsymbol(::Type{MW}) = "MW"
unitsymbol(::Type{GW}) = "GW"

conversionfactor(F::Type{<:PowerUnit}, T::Type{<:PowerUnit}) = conversionfactor(F, MW) * conversionfactor(MW, T)
conversionfactor(::Type{kW}, ::Type{MW}) = 1 / 1000
conversionfactor(::Type{MW}, ::Type{kW}) = 1000
conversionfactor(::Type{MW}, ::Type{MW}) = 1
conversionfactor(::Type{MW}, ::Type{GW}) = 1 / 1000
conversionfactor(::Type{GW}, ::Type{MW}) = 1000

powerunits = Dict(unitsymbol(T) => T for T in [kW, MW, GW])

# Define energy units
abstract type EnergyUnit end
struct kWh <: EnergyUnit end
struct MWh <: EnergyUnit end
struct GWh <: EnergyUnit end

unitsymbol(T::Type{<:EnergyUnit}) = string(T)
unitsymbol(::Type{kWh}) = "kWh"
unitsymbol(::Type{MWh}) = "MWh"
unitsymbol(::Type{GWh}) = "GWh"

subunits(::Type{kWh}) = (kW, Hour)
subunits(::Type{MWh}) = (MW, Hour)
subunits(::Type{GWh}) = (GW, Hour)

subunits(::Type{kW}) = (kW)
subunits(::Type{MW}) = (MW)
subunits(::Type{GW}) = (GW)
energyunits = Dict(unitsymbol(T) => T for T in [kWh, MWh, GWh])

function conversionfactor(F::Type{<:EnergyUnit}, T::Type{<:EnergyUnit})
    from_power, from_time = subunits(F)
    to_power, to_time = subunits(T)
    powerconversion = conversionfactor(from_power, to_power)
    timeconversion = conversionfactor(from_time, to_time)
    return powerconversion * timeconversion
end

function conversionfactor(L::Int, P::Type{<:PowerUnit}, B::Float32)
    to_power = subunits(P)
    powerconversion = conversionfactor(P, to_power)
    return powerconversion * L * B
end

function conversionfactor(L::Int, T::Type{<:Period}, P::Type{<:PowerUnit}, E::Type{<:EnergyUnit}, B::Float32)
    to_power, to_time = subunits(E)
    powerconversion = conversionfactor(P, to_power)
    timeconversion = conversionfactor(T, to_time)
    return powerconversion * timeconversion * L * B
end

function conversionfactor(L::Int, T::Type{<:Period}, P::Type{<:PowerUnit}, E::Type{<:EnergyUnit})
    to_power, to_time = subunits(E)
    powerconversion = conversionfactor(P, to_power)
    timeconversion = conversionfactor(T, to_time)
    return powerconversion * timeconversion * L
end

function conversionfactor(L::Int, T::Type{<:Period}, E::Type{<:EnergyUnit}, P::Type{<:PowerUnit})
    from_power, from_time = subunits(E)
    powerconversion = conversionfactor(from_power, P)
    timeconversion = conversionfactor(from_time, T)
    return powerconversion * timeconversion / L
end

powertoenergy(
    p::Real, P::Type{<:PowerUnit},
    L::Real, T::Type{<:Period},
    E::Type{<:EnergyUnit}) = p*conversionfactor(L, T, P, E)

energytopower(
    e::Real, E::Type{<:EnergyUnit},
    L::Real, T::Type{<:Period},
    P::Type{<:PowerUnit}) = e*conversionfactor(L, T, E, P)


abstract type VoltageUnit end
struct kV <: VoltageUnit end
unitsymbol(T::Type{<:VoltageUnit}) = string(T)
unitsymbol(::Type{kV}) = "kV"
voltageunits = Dict(unitsymbol(T) => T for T in [kV])