module AeroFuseHydrogen

## Libraries
#==========================================================================================#

using AeroFuse

export greet_AeroFuse
include("functions.jl")

## Tools
#==========================================================================================#
include("Tools/Tools.jl")

# Data import
import .Tools: read_data

export read_data

# Gas properties
import .Tools: K_air, α_air, ν_air

export K_air, α_air, ν_air

## Hydrogen Electric
#==========================================================================================#
include("HydrogenElectric/HydrogenElectric.jl")

# Abstract types
import .HydrogenElectric: AbstractHydrogenPropulsionSystem, AbstractFuelTank, AbstractEngine, AbstractPropeller

export AbstractHydrogenPropulsionSystem, AbstractFuelTank, AbstractEngine, AbstractPropeller

# Fuel tank
import .HydrogenElectric: CryogenicFuelTank, volume_to_length, internal_volume, dry_mass, wet_mass

export CryogenicFuelTank, volume_to_length, internal_volume, dry_mass, wet_mass

# Boil-off
import .HydrogenElectric: tank_surface_temperature, boil_off

export tank_surface_temperature, boil_off


end
