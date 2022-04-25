module PRATS

# Write your package code here.
using Reexport: @reexport

const PRATS_VERSION = "v0.1.0"

include("core/Base.jl")
include("PRE/PRE.jl")
end
