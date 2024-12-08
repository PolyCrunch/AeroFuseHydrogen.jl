module HydrogenElectric

## Package imports
#==========================================================================================#
using StaticArrays
using CoordinateTransformations
using Rotations
using Roots # For solving for T_s in boil-off rate

# Gas properties
import ..Tools: K_air, α_air, ν_air

## Types
#==========================================================================================#

abstract type AbstractHydrogenPropulsionSystem end

abstract type AbstractFuelTank <: AbstractHydrogenPropulsionSystem end
abstract type AbstractEngine <: AbstractHydrogenPropulsionSystem end
abstract type AbstractPropeller <: AbstractHydrogenPropulsionSystem end
# abstract type AbstractFuelCell <: AbstractHydrogenPropulsionSystem end

## Fuel tank
#==========================================================================================#

include("fuel_tank.jl")

## Boil-off
#==========================================================================================#

include("boil_off.jl")

end