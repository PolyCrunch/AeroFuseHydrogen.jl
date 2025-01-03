"""
    K_air(T)

Thermal conductivity of gaseous air at temperature `T` in Kelvin, assuming a pressure of 1 atm. The formula is taken from:

    Carroll D, Lo H, Stiel L. Thermal conductivity or gaseous air at moderate and high pressures. Journal of Chemical & Engineering Data. 1968 Jan 1;13(1)
"""
function K_air(T::Real)
    K = -1.116 + 4.030e-2 * T - 8.941e-5 * T^2 + 1.661e-7 * T^3 - 1.468e-10 * T^4 + 4.729e-14 * T^5 # cal /cm /s /K
    return K * 418.68 # W / m / K
end

"""
    α_air(T)

Diffusivity of gaseous air at temperature `T` in Kelvin.
"""
function α_air(T::Real)
    α = -3.119e-6 + 3.541e-8 * T + 1.679e-10 * T^2
    return α;
end

"""
    ν_air(T)

Kinematic viscosity of gaseous air at temperature `T` in Kelvin.
"""
function ν_air(T::Real)
    ν = -2.079e-6 + 2.777e-8 * T + 1.077e-10 * T^2;
    return ν;
end

# Nusselt number depends on R_ad, which depends on T_s