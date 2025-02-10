module HydrogenElectric

## Package imports
#==========================================================================================#
using StaticArrays
using CoordinateTransformations
using Rotations
using Roots # For solving for T_s in boil-off rate
using SplitApplyCombine

# Gas properties
import ..AtmosProperties: K_air, α_air, ν_air

## Types
#==========================================================================================#

abstract type AbstractHydrogenPropulsionSystem end

abstract type AbstractFuelTank <: AbstractHydrogenPropulsionSystem end
abstract type AbstractEngine <: AbstractHydrogenPropulsionSystem end
abstract type AbstractPropeller <: AbstractHydrogenPropulsionSystem end
abstract type AbstractFuelCell <: AbstractHydrogenPropulsionSystem end

## Fuel tank
#==========================================================================================#

include("fuel_tank.jl")

## Fuel cell
#==========================================================================================#

include("fuel_cell.jl")

## Boil-off
#==========================================================================================#

include("boil_off.jl")

end