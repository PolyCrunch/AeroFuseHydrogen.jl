module AeroFuseHydrogen

## Libraries
#==========================================================================================#

using AeroFuse
using RecipesBase # For defining how arbitrary objects are plotted

using SplitApplyCombine: combinedimsview, splitdimsview
export combinedimsview, splitdimsview


## Data tools
#==========================================================================================#
include("Tools/DataTools.jl")
import .DataTools: read_data
export read_data

## Atmospheric properties
#==========================================================================================#
include("Tools/AtmosProperties.jl")
import .AtmosProperties: K_air, α_air, ν_air, p_air, T_air
export K_air, α_air, ν_air, p_air, T_air

## Hydrogen Electric
#==========================================================================================#
include("HydrogenElectric/HydrogenElectric.jl")

# Abstract types
import .HydrogenElectric: AbstractHydrogenPropulsionSystem, AbstractFuelTank, AbstractEngine, AbstractPropeller

export AbstractHydrogenPropulsionSystem, AbstractFuelTank, AbstractEngine, AbstractPropeller

# Fuel tank
import .HydrogenElectric: FuelTank, length, cosine_interpolation, CryogenicFuelTank, volume_to_length, internal_volume, dry_mass, wet_mass, coordinates

export FuelTank, length, cosine_interpolation, CryogenicFuelTank, volume_to_length, internal_volume, dry_mass, wet_mass, coordinates

# Boil-off
import .HydrogenElectric: tank_surface_temperature, boil_off

export tank_surface_temperature, boil_off

# Fuel cell
#import .HydrogenElectric: 

#export 


## Post-processing
#==========================================================================================#
include("Tools/plot_tools.jl")
export plot_surface

end
