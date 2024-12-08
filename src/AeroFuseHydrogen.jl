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
import .HydrogenElectric: CryogenicFuelTank, volume_to_length, internal_volume, dry_mass, wet_mass, boil_off

export CryogenicFuelTank, volume_to_length, internal_volume, dry_mass, wet_mass, boil_off

include("Tools/Tools.jl")

# Data import
import .Tools: read_data, K_air, α_air, ν_air, tank_surface_temperature, boil_off

export read_data, K_air, α_air, ν_air, tank_surface_temperature, boil_off

end
