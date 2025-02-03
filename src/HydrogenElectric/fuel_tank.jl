struct FuelTank{T<:Real} <: AbstractFuelTank
    length   ::T # I do not know what weights or radii represent.
    weights  ::Vector{T}
    radii    ::Vector{T}
    position ::SVector{3,T}
end

function FuelTank(L, weights, radii, position = zeros(3))
    T = promote_type(eltype(L), eltype(weights), eltype(radii), eltype(position))
    @assert all(x -> 0 <= x <= 1., weights) "The distribution of weights must lie in [0,1] ⊂ ℝ."
    perms = sortperm(weights); sort!(weights)
    FuelTank{T}(L, weights, radii[perms], position)
end

@views function coordinates(tank :: FuelTank, n)
    ws_rads = cosine_interpolation(tank, n)

    [ ws_rads[:,1] .* tank.length ws_rads[:,2] ]

end

function cosine_interpolation(tank :: FuelTank, n)
    xs = tank.weights
    ys = tank.radii
    
    x_min, x_max = extrema(xs)
    x_circ = cosine_spacing((x_min + x_max) / 2, x_max - x_min, n)
    
    y_u = linear_interpolation(xs, ys).(x_circ)
    
    return [ x_circ y_u ]
end

struct CryogenicFuelTank{T<:Real,N<:AbstractAffineMap} <: AbstractFuelTank
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
    radius=1.,
    length=5.,
    insulation_thickness=0.05,
    insulation_density=35.3, # Example taken from rigid closed cell polymethacrylimide foam
    position=zeros(3),
    angle=0.0,
    axis=[0.0, 1.0, 0.0],
    affine=AffineMap(AngleAxis(deg2rad(angle), axis...), SVector(position...)),
)

    return CryogenicFuelTank(radius, length, insulation_thickness, insulation_density, affine)
end

# Generate circles in the y-z plane
function circle3D_yz(x, R, n) 
    ts = LinRange(0, 2π, n)
    @. [ fill(x, n) R * cos(ts) R * sin(ts) ]
end

function curve(tank :: CryogenicFuelTank, ts)
    # Check parametric curve domain
    @assert ts[1] == 0
    @assert ts[end] == 1

    R_T = tank.radius
    L_T = tank.length

    L_hemisphere = R_T
    L_cylinder = L_T - 2 * R_T

    # x-coordinates for front hemisphere, cylindrical section, and rear hemisphere
    x_fr = @. ts * L_hemisphere
    x_main = @. ts * L_cylinder + L_hemisphere
    x_re = @. ts * L_hemisphere + L_hemisphere + L_cylinder

    # z-coordinates for front hemisphere, cylindrical section, and rear hemisphere
    z_fr = @. R_T * sqrt(1 - (1 - ts)^2)
    z_main = fill(R_T, length(x_main))
    z_re = @. R_T * sqrt(1 - ts^2)

    xzs = [
        x_fr z_fr;
        x_main z_main;
        x_re z_re;
    ]

    return xzs
end

"""
    function volume_to_length(V_internal :: Float64, R :: Float64, t_wall :: Float64)

Compute the length of a CryogenicFuelTank, given an internal volume, radius and insulation thickness.
"""
function volume_to_length(V_internal::Real, R::Real, t_wall::Real)

    @assert V_internal > 0 "Internal volume must be positive"
    @assert R > 0 "Radius must be positive"
    @assert t_wall > 0 "Wall thickness must be positive"

    return V_internal / (π * (R - t_wall)^2) + 2 * R / 3 + 4 * t_wall / 3
end

"""
    internal_volume(fuel_tank :: CryogenicFuelTank)

Compute the internal volume of a "CryogenicFuelTank" object.
"""
function internal_volume(fuel_tank::CryogenicFuelTank)
    return -pi * (fuel_tank.radius - fuel_tank.insulation_thickness)^2 * (2 * fuel_tank.radius - 3 * fuel_tank.length + 4 * fuel_tank.insulation_thickness) / 3
end

"""
    dry_mass(fuel_tank :: CryogenicFuelTank)

Compute the dry mass of a "CryogenicFuelTank" object.
"""
function dry_mass(fuel_tank::CryogenicFuelTank)
    ρ_w = fuel_tank.insulation_density
    R = fuel_tank.radius
    L = fuel_tank.length

    V_ext = pi * R^2 * (3 * L - 2 * R) / 3 # External volume of the tank
    V_int = internal_volume(fuel_tank) # Internal volume of the tank

    V_w = V_ext - V_int # Volume of the insulation

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
    coordinates(fuse :: CryogenicFuelTank, t) 

Get the coordinates of a `CryogenicFuelTank` given the parameter distribution ``t``. Note that the distribution must have endpoints `0` and `1`.
"""
function coordinates(tank :: CryogenicFuelTank, ts, n_circ = 20)
    x_fr, x_main, x_re, z_fr, z_main, z_re = curve(tank, ts) # NEED TO DEFINE CURVE

    # Generate 3D coordinates
    coo = reduce(vcat, [ 
        circle3D_yz.(x_fr, z_fr, n_circ); 
        circle3D_yz.(x_main, z_main, n_circ); 
        circle3D_yz.(x_re, z_re, n_circ)
    ])

    print("Coo:")
    print(coo)

    # Do the affine map
    aff_coo = combinedimsview(map(tank.affine, splitdimsview(coo, (1))), (1))

    # Reshape with indices [rad_number,sec_number,xyz]
    return reshape(aff_coo, n_circ, length(ts) * 3, 3)
end