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

## Fuel Cell properties
#==========================================================================================#
include("Tools/PEMFCProps.jl")
import .PEMFCProps: pemfc_polarization
export pemfc_polarization

## Weights
#==========================================================================================#
include("Tools/Weights.jl")
import .Weights: crew_weight
export crew_weight

## Hydrogen Electric
#==========================================================================================#
include("HydrogenElectric/HydrogenElectric.jl")

# Abstract types
import .HydrogenElectric: AbstractHydrogenPropulsionSystem, AbstractFuelTank, AbstractEngine, AbstractPropeller, AbstractFuelCell

export AbstractHydrogenPropulsionSystem, AbstractFuelTank, AbstractEngine, AbstractPropeller, AbstractFuelCell

# Propulsion system
import .HydrogenElectric: TechLevel, psfc, motor_mass, Current, Future

export TechLevel, psfc, motor_mass, Current, Future

# Fuel tank
import .HydrogenElectric: FuelTank, ρ_LH2, length, cosine_interpolation, CryogenicFuelTank, volume_to_length, internal_volume, dry_mass, wet_mass, coordinates

export FuelTank, ρ_LH2, length, cosine_interpolation, CryogenicFuelTank, volume_to_length, internal_volume, dry_mass, wet_mass, coordinates

# Boil-off
import .HydrogenElectric: tank_surface_temperature, boil_off

export tank_surface_temperature, boil_off

# Fuel cell
import .HydrogenElectric: PEMFCStack, length, mass, j_cell, U_cell, η_FC, fflow_H2

export PEMFCStack, length, mass, j_cell, U_cell, η_FC, fflow_H2


## Post-processing
#==========================================================================================#
include("Tools/plot_tools.jl")
export plot_surface

end
