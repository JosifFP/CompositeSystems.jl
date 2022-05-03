module PRATS

# Write your package code here.
using Reexport

const PRATS_VERSION = "v0.1.0"

include("core/Root.jl")
include("PRE/PRE.jl")
end
