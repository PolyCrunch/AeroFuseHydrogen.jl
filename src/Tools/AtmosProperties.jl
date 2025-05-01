module AtmosProperties

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
    return α
end

"""
    ν_air(T)

Kinematic viscosity of gaseous air at temperature `T` in Kelvin.
"""
function ν_air(T::Real)
    ν = -2.079e-6 + 2.777e-8 * T + 1.077e-10 * T^2
    return ν
end

# Nusselt number depends on R_ad, which depends on T_s

"""
    p_air(h)

ISA pressure of gaseous air at altitude `h` in meters. Valid for 0 ≤ h < 11000 m.
"""
function p_air(h::Real=0)
    @assert (0 <= h < 11000) "Altitude out of range 0 ≤ h < 11000 m"
    p = 101325 * (1 - 2.25577e-5 * h)^5.25588
    return p
end

"""
    T_air(h)

ISA temperature of gaseous air at altitude `h` in meters. Valid for 0 ≤ h < 11000 m.
"""
function T_air(h::Real=0)
    @assert (0 <= h < 11000) "Altitude out of range 0 ≤ h < 11000 m"
    T = 288.15 - 0.0065 * h
    return T
end


function TAS(h::Real=0, EAS::Real=0)::Real
    @assert (0 <= h < 11000) "Altitude out of range 0 ≤ h < 11000 m"
    ρ = 1.225 * (1 - 2.2558e-5 * h)^4.2559; # kg/m^3

    TAS = EAS * sqrt(1.225 / ρ); # m/s
    return TAS
end

end