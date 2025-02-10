#struct FuelCell{T<:Real} <: AbstractFuelCell

#end

#function FuelCell()

#end

struct PEMFuelCell{T<:Real,N<:AbstractAffineMap} <: AbstractFuelCell
    area_effective::T   # Effective area of the fuel cell
    power_max::T        # Maximum power output of the fuel cell
    height::T           # Height of the fuel cell
    width::T            # Width of the fuel cell
    layer_thickness::T  # Thickness of the fuel cell layer
    affine::N           # Affine transformation

    function PEMFuelCell(A_eff, P_max, h, w, t, affine)
        # Type promotion
        T = promote_type(eltype(A_eff), eltype(P_max), eltype(h), eltype(w), eltype(t))
        N = typeof(affine)

        @assert A_eff > 0 "Effective area must be positive"
        @assert P_max > 0 "Maximum power output must be positive"
        @assert h > 0 "Height must be positive"
        @assert w > 0 "Width must be positive"
        @assert t > 0 "Layer thickness must be positive"

        new{T,N}{A_eff,P_max,h,w,t,affine}
    end
end

"""
PEMFuelCell(;

Define a proton exchange membrane fuel cell.

# Arguments
- `area_effective :: Real = 1.`: Effective area of the fuel cell (m²)
- `P_max :: Real = 1.`: Maximum power output required from the fuel cell (W)
- `height :: Real = 0.1`: Height of the fuel cell (m)
- `width :: Real = 0.1`: Width of the fuel cell (m)
- `layer_thickness :: Real = 0.001`: Thickness of the fuel cell layer (m)
- `affine :: AffineMap = AffineMap(AngleAxis(deg2rad(angle), axis...), position)`: Affine mapping for the position and orientation via `CoordinateTransformations.jl` (overrides `angle` and `axis` if specified)
"""
function PEMFuelCell(;
    area_effective=1.,
    power_max=1.,
    height=0.1,
    width=0.1,
    layer_thickness=0.001,
    position=zeros(3),
    angle=0.0,
    axis=[0.0, 1.0, 0.0],
    affine=AffineMap(AngleAxis(deg2rad(angle), axis...), SVector(position...)),
)
    PEMFuelCell(area_effective, power_max, height, width, layer_thickness, affine)
end