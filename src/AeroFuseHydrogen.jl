module AeroFuseHydrogen

## Libraries
#==========================================================================================#

using AeroFuse

export greet_AeroFuse
include("functions.jl")

# include("Propulsion/Engine/electric_motor.jl")
# include("Propulsion/Engine/propeller.jl")
# include("Propulsion/FuelTank.jl")
# include("Propulsion/Power/fuel_cell.jl")

include("HydrogenPropulsion/HydrogenElectric.jl")

end
