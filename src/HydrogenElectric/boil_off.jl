function tank_surface_temperature(fuel_tank::CryogenicFuelTank, T_s_initial_guess=100, T∞=293.15, T_LH2=20, ϵ=0.1)
    D = 2 * fuel_tank.radius # Diameter of the tank
    L = fuel_tank.insulation_thickness # Thickness of the insulation
    σ = 5.67e-8 # Stefan-Boltzmann constant
    g = 9.81 # Acceleration due to gravity
    K = K_air(T∞) # Thermal conductivity of air
    α = α_air(T∞) # Diffusivity of air
    ν = ν_air(T∞) # Kinematic viscosity of air

    # Define the function to solve (for T_s)
    function heat_transfer_eq(T_s)
        Qin = ϵ * σ * (T∞^4 - T_s^4) * (K * (T∞ - T_s) * ((387 * ((D^3 * g * (T∞ - T_s)) / (T∞ * α * ν))^(1 / 6)) / (1000 * (((559 * α) / (1000 * ν))^(9 / 16) + 1)^(8 / 27)) + 3 / 5)^2) / D # Ouch
        Qout = K * (T_s - T_LH2) / L

        return Qin - Qout
    end

    # Find the root (solve for T_s)
    T_s_solution = find_zero(heat_transfer_eq, T_s_initial_guess)

    return T_s_solution # Placeholder
end

"""
    boil_off(fuel_tank :: CryogenicFuelTank)

Calculate the boil-off rate for a "CryogenicFuelTank" object.
"""
function boil_off(fuel_tank::CryogenicFuelTank, T∞, T_LH2, h_fg=446592)
    D = 2 * fuel_tank.radius # Diameter of the tank

    K = K_air(T∞) # Thermal conductivity of air
    A = pi * D * (fuel_tank.length - 2 * fuel_tank.radius) + 4 * pi * fuel_tank.radius^2 # (External) surface area of the tank
    L = fuel_tank.insulation_thickness

    M = K * A * (tank_surface_temperature(fuel_tank, T∞) - T_LH2) / L / h_fg

    return M
end