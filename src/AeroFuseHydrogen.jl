module AeroFuseHydrogen

## Libraries
#==========================================================================================#

using AeroFuse
using RecipesBase # For defining how arbitrary objects are plotted

export greet_AeroFuse
include("functions.jl")

## Data tools
#==========================================================================================#
include("Tools/DataTools.jl")
import .DataTools: read_data
export read_data

## Gas properties
#==========================================================================================#
include("Tools/GasProperties.jl")
import .GasProperties: K_air, α_air, ν_air
export K_air, α_air, ν_air

## Hydrogen Electric
#==========================================================================================#
include("HydrogenElectric/HydrogenElectric.jl")

# Abstract types
import .HydrogenElectric: AbstractHydrogenPropulsionSystem, AbstractFuelTank, AbstractEngine, AbstractPropeller

export AbstractHydrogenPropulsionSystem, AbstractFuelTank, AbstractEngine, AbstractPropeller

# Fuel tank
import .HydrogenElectric: FuelTank, length, cosine_interpolation, CryogenicFuelTank, volume_to_length, internal_volume, dry_mass, wet_mass

export FuelTank, length, cosine_interpolation, CryogenicFuelTank, volume_to_length, internal_volume, dry_mass, wet_mass

# Boil-off
import .HydrogenElectric: tank_surface_temperature, boil_off

export tank_surface_temperature, boil_off


## Post-processing
#==========================================================================================#
include("Tools/plot_tools.jl")
export plot_surface

end
