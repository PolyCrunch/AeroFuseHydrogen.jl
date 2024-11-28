struct CryogenicFuelTank{T <: Real, N <: AbstractAffineMap} <: AbstractFuelTank
    internal_volume :: T
    wall_thickness  :: T
    radius          :: T
    length          :: T
    mass            :: T
    affine          :: N
    function CryogenicFuelTank(R, V_internal, t_wall)
        # Type promotion
        T = promote_type(eltype(R), eltype(V_internal), eltype(t_wall))
        N = typeof(affine)

        @assert R > 0 "Radius must be positive"
        @assert V_internal > 0 "Internal volume must be positive"
        @assert t_wall > 0 "Wall thickness must be positive"

        new{T, N}(R, V_internal, t_wall)
    end
end

function CryogenicFuelTank(;
        internal_volume = 1.,
        wall_thickness  = 0.05,
        radius          = 1.,
        position        = zeros(3),
        angle           = 0.,
        axis            = [0., 1., 0.],
        affine          = AffineMap(AngleAxis(deg2rad(angle), axis...), SVector(position...)),
    )

    length = 1.
    mass = 1.

    return CryogenicFuelTank(internal_volume, wall_thickness, radius, length, mass, affine)
end