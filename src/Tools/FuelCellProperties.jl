module FuelCellProperties
using Base: LinRange

"""

"""
function pemfc_polarization(i::Number, E_rTP::Number=0.0, T::Number=333.0, α::Number=1.0, n::Integer=2, i_loss::Number=20.0, i_0::Number=0.03, i_L::Number=16000.0, R_i::Number=1500.0)
    F = 96485.  # Faraday constant (C/mol)
    R = 8.314   # Ideal gas constant (J/mol/K)

    #E_cell = @. E_rTP - (R * T) / (α * F) * log((i + i_loss) / i_0) - (R * T) / (n * F) * log(i_L / (i_L - i)) - R_i * i

    E_cell = @. E_rTP - (R * T) / (α * F) * log(i / i_0) - (R * T) / (n * F) * log(i_L / (i_L - i)) - R_i * i

    return E_cell
end


end