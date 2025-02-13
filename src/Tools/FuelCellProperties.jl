module FuelCellProperties
using Base: LinRange

"""

"""
function pemfc_polarization(i::Number, T::Number=333.0, α::Number=1.0, n::Integer=2, i_loss::Number=20.0, i_0::Number=0.03, i_L::Number=16000.0, R_i::Number=1500.0)
    F = 96485.  # Faraday constant (C/mol)
    R = 8.314   # Ideal gas constant (J/mol/K)

    E_rTP = 1.482 - 0.000845 * T + 0.0000431 * T * log(sqrt(0.21))

    print(E_rTP)
    print(- (R * T) / (α * F) * log((i + i_loss) / i_0))
    print(- (R * T) / (n * F) * log(i_L / (i_L - i)))
    print(- R_i * i)

    E_cell = @. E_rTP - (R * T) / (α * F) * log((i + i_loss) / i_0) - (R * T) / (n * F) * log(i_L / (i_L - i)) - R_i * i

    return E_cell
end


end