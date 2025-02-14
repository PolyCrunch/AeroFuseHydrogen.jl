#struct FuelCell{T<:Real} <: AbstractFuelCell

#end

#function FuelCell()

#end

struct PEMFCStack{T<:Real,N<:AbstractAffineMap} <: AbstractFuelCell
    area_effective::T   # Effective area of the fuel cell
    power_max::T        # Maximum power output of the fuel cell
    height::T           # Height of the fuel cell
    width::T            # Width of the fuel cell
    layer_thickness::T  # Thickness of the fuel cell layer
    affine::N           # Affine transformation

    function PEMFCStack(A_eff, P_max, h, w, t, affine)
        # Type promotion
        T = promote_type(eltype(A_eff), eltype(P_max), eltype(h), eltype(w), eltype(t))
        N = typeof(affine)

        @assert A_eff > 0 "Effective area must be positive"
        @assert P_max > 0 "Maximum power output must be positive"
        @assert h > 0 "Height must be positive"
        @assert w > 0 "Width must be positive"
        @assert t > 0 "Layer thickness must be positive"

        new{T,N}(A_eff,P_max,h,w,t,affine)
    end
end

"""
PEMFCStack(;

Define a proton exchange membrane fuel cell.

# Arguments
- `area_effective :: Real = 1.`: Effective area of the fuel cell (m²)
- `power_max :: Real = 1.e6`: Maximum power output required from the fuel cell (W)
- `height :: Real = 2.`: Height of the fuel cell (m)
- `width :: Real = 2.`: Width of the fuel cell (m)
- `layer_thickness :: Real = 0.0043`: Thickness of the fuel cell layer (m)
- `position :: Vector{3} = zeros(3)`: Position (m)
- `angle :: Real = 0.0`: Angle of rotation (degrees)
- `axis :: Vector{3} = [0.0, 1.0, 0.0]`: Axis of rotation, y-axis by default
- `affine :: AffineMap = AffineMap(AngleAxis(deg2rad(angle), axis...), position)`: Affine mapping for the position and orientation via `CoordinateTransformations.jl` (overrides `angle` and `axis` if specified)
"""
function PEMFCStack(;
    area_effective=1.0,
    power_max=1.e6,
    height=2.,
    width=2.,
    layer_thickness=0.0043, # Source: Rubio, Abel & Agila, Wilton & González, Leandro & Aviles-Cedeno, Jonathan. (2023). Distributed Intelligence in Autonomous PEM Fuel Cell Control. Energies. 16. 4830. 10.3390/en16204830.
    position=zeros(3),
    angle=0.0,
    axis=[0.0, 1.0, 0.0],
    affine=AffineMap(AngleAxis(deg2rad(angle), axis...), SVector(position...)),
)
    PEMFCStack(area_effective, power_max, height, width, layer_thickness, affine)
end

"""
j_cell(cell::PEMFuelCell, polarization_coefficients::Vector)

Compute the current density of a proton exchange membrane fuel cell.

# Arguments
- `cell::PEMFCStack`: Proton exchange membrane fuel cell stack
- `polarization_coefficients::Vector`: Polarization coefficients [α β] such that U_cell = α * j_cell + β
- `i_L::Number`: Limiting current density (A/cm²)
"""
function j_cell(cell::PEMFCStack, polarization_coefficients::Vector = [-0.213 0.873], i_L::Number = 1.6)
    @assert length(polarization_coefficients) == 2 "Polarization coefficients must be a vector [α β] such that U_cell = α * j_cell + β"

    a = polarization_coefficients[1]
    b = polarization_coefficients[2]
    c = -cell.power_max / cell.area_effective

    j = (-b + sqrt(b^2 - 4 * a * c)) / (2 * a) # Quadratic formula

    @assert j <= i_L "Current density is greater than the limiting current density. Consider increasing the effective area of the fuel cell."

    return j
end

"""
U_cell(j::Number, polarization_coefficients::Vector)

Compute the cell potential difference of a proton exchange membrane fuel cell.

# Arguments
- `j::Number`: Current density (A/cm²)
- `polarization_coefficients::Vector`: Polarization coefficients [α β] such that U_cell = α * j_cell + β
- `i_L::Number`: Limiting current density (A/cm²)
"""
function U_cell(j::Number, polarization_coefficients::Vector = [-0.213 0.873], i_L::Number = 1.6)
    @assert length(polarization_coefficients) == 2 "Polarization coefficients must be a vector [α β] such that U_cell = α * j_cell + β"

    @assert j <= i_L "Current density is greater than the limiting current density. Consider increasing the effective area of the fuel cell."

    a = polarization_coefficients[1]
    b = polarization_coefficients[2]

    return a * j + b
end