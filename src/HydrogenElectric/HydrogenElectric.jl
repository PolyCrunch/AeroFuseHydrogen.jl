module HydrogenElectric

## Package imports
#==========================================================================================#
using StaticArrays
using CoordinateTransformations
using Rotations

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

end