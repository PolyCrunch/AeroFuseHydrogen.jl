struct CryogenicFuelTank{T<:Real,N<:AbstractAffineMap} <: AbstractFuelTank
    radius::T
    internal_volume::T
    insulation_thickness::T
    insulation_density::T
    affine::N
    function CryogenicFuelTank(R, V_internal, t_wall, ρ_wall, affine)
        # Type promotion
        T = promote_type(eltype(R), eltype(V_internal), eltype(t_wall), eltype(ρ_wall))
        N = typeof(affine)

        @assert R > 0 "Radius must be positive"
        @assert V_internal > 0 "Internal volume must be positive"
        @assert t_wall > 0 "Wall thickness must be positive"

        new{T,N}(R, V_internal, t_wall, ρ_wall, affine)
    end
end

"""
CryogenicFuelTank(; 

Define a cryogenic fuel tank.

# Arguments
- `radius :: Real = 1.`: Radius available for tank (m)
- `internal_volume :: Real = 10.`: Tank volume needed for fuel (m^3)
- `insulation_thickness :: Real = 0.05`: Insulation thickness (m)
- 'insulation_density :: Real = 35.3`: Insulation density (kg/m^3)
- `position :: Vector{Real} = zeros(3)`: Position (m)
- `angle :: Real = 0.`: Angle of rotation (degrees)
- `axis :: Vector{Real} = [0, 1 ,0]`: Axis of rotation, y-axis by default
- `affine :: AffineMap = AffineMap(AngleAxis(deg2rad(angle), axis...), position)`: Affine mapping for the position and orientation via `CoordinateTransformations.jl` (overrides `angle` and `axis` if specified)
"""
function CryogenicFuelTank(;
    radius=1.0,
    internal_volume=10.0,
    insulation_thickness=0.05,
    insulation_density=35.3, # Example taken from rigid closed cell polymethacrylimide foam
    position=zeros(3),
    angle=0.0,
    axis=[0.0, 1.0, 0.0],
    affine=AffineMap(AngleAxis(deg2rad(angle), axis...), SVector(position...)),
)

    return CryogenicFuelTank(radius, internal_volume, insulation_thickness, insulation_density, affine)
end

Base.length(fuel_tank::CryogenicFuelTank) = fuel_tank.internal_volume / (π * (fuel_tank.radius - fuel_tank.insulation_thickness)^2) + 2 / 3 * fuel_tank.radius + 4 / 3 * fuel_tank.insulation_thickness

"""
    dry_mass(fuel_tank :: CryogenicFuelTank)

Compute the dry mass of a "CryogenicFuelTank" object.
"""
function dry_mass(fuel_tank::CryogenicFuelTank)
    t_w = fuel_tank.insulation_thickness
    ρ_w = fuel_tank.insulation_density
    R = fuel_tank.radius
    L = length(fuel_tank)

    V_w = -pi * t_w * (24 * R^2 - 18 * R * t_w - 6 * L * R + 4 * t_w^2 + 3 * L * t_w) / 3 # Volume of the insulation

    return V_w * ρ_w # Mass of the insulation
end

"""
    wet_mass(fuel_tank :: CryogenicFuelTank, fraction :: Real, ρ_fuel :: Real)

Compute the wet mass of a "CryogenicFuelTank" object, given the fuel fraction ``fracton``, and optional fuel density (defaults to `70.8 kg m^{-3}`, based on liquid Hydrogen at 20 K). Note the fraction must be between `0` and `1`.
"""
function wet_mass(fuel_tank::CryogenicFuelTank, fraction::Real, ρ_fuel::Real=70.8)
    @assert 0. <= fraction <= 1. "Fraction must be between 0 and 1"

    V_fuel = fraction * fuel_tank.internal_volume
    return dry_mass(fuel_tank) + V_fuel * ρ_fuel
end

"""
    wet_mass(fuel_tank :: CryogenicFuelTank, fraction :: Array, ρ_fuel :: Real)

Compute the wet mass of a "CryogenicFuelTank" object, given an array of fuel fractions ``fracton``, and optional fuel density (defaults to `70.8 kg m^{-3}`, based on liquid Hydrogen at 20 K). Note the members of fraction be between `0` and `1`.
"""
function wet_mass(fuel_tank::CryogenicFuelTank, fraction::Array, ρ_fuel::Real=70.8)
    @assert all(0 .<= fraction .<= 1) "Fraction members must be between 0 and 1"

    V_fuel = fraction .* fuel_tank.internal_volume
    return dry_mass(fuel_tank) .+ V_fuel .* ρ_fuel
end