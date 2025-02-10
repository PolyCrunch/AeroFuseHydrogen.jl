module FuelCellProperties

function pemfc_polarization(i::Vector{Number}=LinRange(0, 1.5, 20), E_rTP=0.0, T=333.0, α=1.0, n::Integer=2, i_loss=20.0, i_0=0.03, i_L=16000.0, R_i=1500.0)
    @assert length(i) ≥ 1 "Current density vector must have at least one element"

    F = 96485.  # Faraday constant (C/mol)
    R = 8.314   # Ideal gas constant (J/mol/K)

    @. E_cell = E_rTP - (R * T) / (α * F) * ln((i + i_loss) / i_0) - (R * T) / (n * F) * ln(i_L / (i_L - i)) - R_i * i

    return E_cell
end


end