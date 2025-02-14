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
length(stack::PEMFCStack)

Compute the length of a proton exchange membrane fuel cell stack.

# Arguments
- `stack::PEMFCStack`: Proton exchange membrane fuel cell stack
"""
function Base.length(stack::PEMFCStack)
    n_layers::Int = floor(Int, stack.height / stack.layer_thickness)
    l = stack.area_effective / (stack.width * n_layers)

    return l
end

"""
j_cell(cell::PEMFuelCell, polarization_coefficients::Vector)

Compute the current density of a proton exchange membrane fuel cell.

# Arguments
- `cell::PEMFCStack`: Proton exchange membrane fuel cell stack
- `throttle::Number`: Throttle value (0-1)
- `polarization_coefficients::Vector`: Polarization coefficients [α β] such that U_cell = α * j_cell + β
- `i_L::Number`: Limiting current density (A/cm²)
"""
function j_cell(cell::PEMFCStack, throttle::Number = 1., polarization_coefficients::Vector = [-0.213; 0.873], i_L::Number = 1.6)
    @assert throttle > 0 "Throttle must be positive"
    @assert throttle <= 1 "Throttle must be less than or equal to 1"

    @assert length(polarization_coefficients) == 2 "Polarization coefficients must be a vector [α β] such that U_cell = α * j_cell + β"
    
    a = polarization_coefficients[1]
    b = polarization_coefficients[2]
    c = -cell.power_max * throttle / cell.area_effective
    
    @assert b^2 - 4 * a * c >= 0 "No real solution for current density. Consider increasing the effective area of the fuel cell."
    
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

"""
η_FC(U_cell::Number)

Compute the efficiency of a proton exchange membrane fuel cell.

# Arguments
- `U_cell::Number`: Cell potential difference (V)
"""
function η_FC(U_cell::Number)
    n = 2           # Number of electrons involved
    F = 96485.0     # Faraday constant (C/mol)
    H2_HHV = 285.8e3 # Higher Heating Value of hydrogen (J/mol)

    U_ideal = H2_HHV / (n * F) # Ideal cell potential difference

    η = U_cell / U_ideal
    return η
end

"""
η_FC(cell::PEMFCStack, throttle::Number, polarization_coefficients::Vector, i_L::Number)

Compute the efficiency of a proton exchange membrane fuel cell.

# Arguments
- `cell::PEMFCStack`: Proton exchange membrane fuel cell stack
- `throttle::Number`: Throttle value (0-1)
- `polarization_coefficients::Vector`: Polarization coefficients [α β] such that U_cell = α * j_cell + β
- `i_L::Number`: Limiting current density (A/cm²)
"""
function η_FC(cell::PEMFCStack, throttle::Number = 1., polarization_coefficients::Vector = [-0.213; 0.873], i_L::Number = 1.6)
    @assert throttle > 0 "Throttle must be positive"
    @assert throttle <= 1 "Throttle must be less than or equal to 1"

    j = j_cell(cell, throttle, polarization_coefficients, i_L)
    U = U_cell(j, polarization_coefficients, i_L)
    return η_FC(U)
end

"""
fflow_H2(cell::PEMFCStack, throttle::Number, polarization_coefficients::Vector, i_L::Number)

Compute the mass flow rate of hydrogen to a proton exchange membrane fuel cell for a given power.

# Arguments
- `cell::PEMFCStack`: Proton exchange membrane fuel cell stack
- `throttle::Number`: Throttle value (0-1)
- `polarization_coefficients::Vector`: Polarization coefficients [α β] such that U_cell = α * j_cell + β
- `i_L::Number`: Limiting current density (A/cm²)
"""
function fflow_H2(cell::PEMFCStack, throttle::Number = 1., polarization_coefficients::Vector = [-0.213; 0.873], i_L::Number = 1.6)
    # Stiochiometric ratio source: Hartmann, Christian & Nøland, Jonas Kristiansen & Nilssen, Robert & Mellerud, Runar. (2021). Conceptual Design, Sizing and Performance Analysis of a Cryo-Electric Propulsion System for a Next-Generation Hydrogen-Powered Aircraft. 10.36227/techrxiv.17102792.v1.
    λ_H2 = 1.05 # Assumed stoichiometric ratio of hydrogen, assuming recycling of exhaust hydrogen
    P_FC = cell.power_max * throttle
    η_cell = η_FC(cell, throttle, polarization_coefficients, i_L)
    Δh_H2 = 141.9e6 # Higher Heating Value of hydrogen (J/kg)

    m_dot_H2 = λ_H2 * P_FC / (η_cell * Δh_H2)

    return m_dot_H2
end