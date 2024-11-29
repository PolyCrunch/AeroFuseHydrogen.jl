
struct CryogenicFuelTank{T<:Real,N<:AbstractAffineMap} <: AbstractFuelTank
    radius::T
    internal_volume::T
    insulation_thickness::T
    affine::N
    length::T
    mass::T
    function CryogenicFuelTank(R, V_internal, t_wall, affine)
        # Type promotion
        T = promote_type(eltype(R), eltype(V_internal), eltype(t_wall))
        N = typeof(affine)

        @assert R > 0 "Radius must be positive"
        @assert V_internal > 0 "Internal volume must be positive"
        @assert t_wall > 0 "Wall thickness must be positive"

        new{T,N}(R, V_internal, t_wall, affine)
    end
end

"""
CryogenicFuelTank(; 

Define a cryogenic fuel tank.

# Arguments
- `radius :: Real = 1.`: Radius available for tank (m)
- `internal_volume :: Real = 10.`: Tank volume needed for fuel (m^3)
- `insulation_thickness :: Real = 0.05`: Insulation thickness (m)
- `position :: Vector{Real} = zeros(3)`: Position (m)
- `angle :: Real = 0.`: Angle of rotation (degrees)
- `axis :: Vector{Real} = [0, 1 ,0]`: Axis of rotation, y-axis by default
- `affine :: AffineMap = AffineMap(AngleAxis(deg2rad(angle), axis...), position)`: Affine mapping for the position and orientation via `CoordinateTransformations.jl` (overrides `angle` and `axis` if specified)
"""
function CryogenicFuelTank(;
    radius=1.0,
    internal_volume=10.0,
    insulation_thickness=0.05,
    position=zeros(3),
    angle=0.0,
    axis=[0.0, 1.0, 0.0],
    affine=AffineMap(AngleAxis(deg2rad(angle), axis...), SVector(position...)),
)

    return CryogenicFuelTank(radius, internal_volume, insulation_thickness, affine)
end

Base.length(fuel_tank::CryogenicFuelTank) = fuel_tank.internal_volume / (π * (fuel_tank.radius - fuel_tank.insulation_thickness)^2) + 2 / 3 * fuel_tank.radius + 4 / 3 * fuel_tank.insulation_thickness