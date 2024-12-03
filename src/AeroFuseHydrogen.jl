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

include("HydrogenElectric/HydrogenElectric.jl")

# Abstract types
import .HydrogenElectric: AbstractHydrogenPropulsionSystem, AbstractFuelTank, AbstractEngine, AbstractPropeller

export AbstractHydrogenPropulsionSystem, AbstractFuelTank, AbstractEngine, AbstractPropeller

# Fuel tank
import .HydrogenElectric: CryogenicFuelTank, length, dry_mass, wet_mass

export CryogenicFuelTank, length, dry_mass, wet_mass

end
