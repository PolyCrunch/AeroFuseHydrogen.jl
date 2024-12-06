struct CryogenicFuelTank{T<:Real,N<:AbstractAffineMap} <: AbstractFuelTank
    # I THINK THE USER SHOULD SPECIFY LENGTH INSTEAD OF INTERNAL VOLUME. SEE NOTES FROM DEC 4
    radius::T
    length::T
    insulation_thickness::T
    insulation_density::T
    affine::N
    function CryogenicFuelTank(R, L, t_wall, ρ_wall, affine)
        # Type promotion
        T = promote_type(eltype(R), eltype(L), eltype(t_wall), eltype(ρ_wall))
        N = typeof(affine)

        @assert R > 0 "Radius must be positive"
        @assert L > 0 "Length must be positive"
        @assert t_wall > 0 "Wall thickness must be positive"

        new{T,N}(R, L, t_wall, ρ_wall, affine)
    end
end

"""
CryogenicFuelTank(; 

Define a cryogenic fuel tank.

# Arguments
- `radius :: Real = 1.`: Radius available for tank (m)
- `length :: Real = 5.`: External length of tank (m)
- `insulation_thickness :: Real = 0.05`: Insulation thickness (m)
- 'insulation_density :: Real = 35.3`: Insulation density (kg/m^3)
- `position :: Vector{Real} = zeros(3)`: Position (m)
- `angle :: Real = 0.`: Angle of rotation (degrees)
- `axis :: Vector{Real} = [0, 1 ,0]`: Axis of rotation, y-axis by default
- `affine :: AffineMap = AffineMap(AngleAxis(deg2rad(angle), axis...), position)`: Affine mapping for the position and orientation via `CoordinateTransformations.jl` (overrides `angle` and `axis` if specified)
"""
function CryogenicFuelTank(;
    radius=1.0,
    length=5.0,
    insulation_thickness=0.05,
    insulation_density=35.3, # Example taken from rigid closed cell polymethacrylimide foam
    position=zeros(3),
    angle=0.0,
    axis=[0.0, 1.0, 0.0],
    affine=AffineMap(AngleAxis(deg2rad(angle), axis...), SVector(position...)),
)

    return CryogenicFuelTank(radius, length, insulation_thickness, insulation_density, affine)
end

"""
    function volume_to_length(V_internal :: Float64, R :: Float64, t_wall :: Float64)

Compute the length of a CryogenicFuelTank, given an internal volume, radius and insulation thickness.
"""
function volume_to_length(V_internal::Real, R::Real, t_wall::Real)

    @assert V_internal > 0 "Internal volume must be positive"
    @assert R > 0 "Radius must be positive"
    @assert t_wall > 0 "Wall thickness must be positive"

    return V_internal / (π * (R - t_wall)^2) + 2 / 3 * R + 4 / 3 * t_wall
end

"""
    internal_volume(fuel_tank :: CryogenicFuelTank)

Compute the internal volume of a "CryogenicFuelTank" object.
"""
function internal_volume(fuel_tank::CryogenicFuelTank)
    return pi / 3 * (fuel_tank.radius - fuel_tank.insulation_thickness)^2 * (3 * fuel_tank.length - 10 * fuel_tank.radius + 4 * fuel_tank.insulation_thickness)
end

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
    @assert 0.0 <= fraction <= 1.0 "Fraction must be between 0 and 1"

    V_fuel = fraction * internal_volume(fuel_tank)
    return dry_mass(fuel_tank) + V_fuel * ρ_fuel
end

"""
    boil_off(fuel_tank :: CryogenicFuelTank)

Calculate the boil-off rate for a "CryogenicFuelTank" object.
"""
function boil_off(fuel_tank::CryogenicFuelTank)
    # Do stuff

    return 0.5 # Placeholder
end