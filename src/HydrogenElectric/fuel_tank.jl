struct CryogenicFuelTank{T<:Real,N<:AbstractAffineMap} <: AbstractFuelTank
    radius::T
    internal_volume::T
    insulation_thickness::T
    affine::N
    # length::T
    # mass::T
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

function CryogenicFuelTank(;
    radius=1.0,
    internal_volume=1.0,
    insulation_thickness=0.05,
    position=zeros(3),
    angle=0.0,
    axis=[0.0, 1.0, 0.0],
    affine=AffineMap(AngleAxis(deg2rad(angle), axis...), SVector(position...)),
    )
    
    return CryogenicFuelTank(radius, internal_volume, insulation_thickness, affine)
end

Base.length(fuel_tank :: CryogenicFuelTank) = fuel_tank.V_internal / (π * (fuel_tank.radius - fuek_tank.insulation_thickness)^2) + 2 / 3 * fuel_tank.radius + 4 / 3 * fuel_tank.insulation_thickness