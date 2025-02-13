module FuelCellProperties
using Base: LinRange

"""
pemfc_polarization(
    i::Number, 
    T::Number=333.0, 
    α::Number=1.0, 
    n::Integer=2, 
    i_loss::Number=0.002, 
    i_0::Number=3e-6, 
    i_L::Number=1.6, 
    R_i::Number=0.15
)

Compute the cell potential difference of a H2/Air proton exchange membrane fuel cell.

# Arguments
- `i::Number`: Current density (A/cm²)
- `T::Number=333.0`: Temperature (K)
- `α::Number=1.0`: Charge transfer coefficient
- `n::Integer=2`: Number of electrons involved
- `i_loss::Number=0.002`: Current loss (A/cm²)
- `i_0::Number=3e-6`: Reference exchange current density (A/cm²)
- `i_L::Number=1.6`: Limiting current density (A/cm²)
- `R_i::Number=0.15`: Internal resistance (Ω/cm²)

Default values are obtained from F Barbir, CHAPTER 3 — Fuel Cell Electrochemistry, PEM Fuel Cells, Academic Press, 2005.
"""
function pemfc_polarization(i::Number, T::Number=333.0, α::Number=1.0, n::Integer=2, i_loss::Number=0.002, i_0::Number=3e-6, i_L::Number=1.6, R_i::Number=0.15)
    F = 96485.0 # Faraday constant (C/mol)
    R = 8.314   # Ideal gas constant (J/mol/K)

    E_rTP = 1.482 - 0.000845 * T + 0.0000431 * T * log(sqrt(0.21)) # Reversible cell potential at ISA standard pressure (V)

    E_cell = @. E_rTP - (R * T) / (α * F) * log((i + i_loss) / i_0) - (R * T) / (n * F) * log(i_L / (i_L - i)) - R_i * i

    return E_cell
end


end