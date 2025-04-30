@enum TechLevel begin
    Current
    Future
end

"""
psfc(A_eff::Number=120., P::Number=1.e6)
"""
function psfc(A_eff=120.::Number, P::Number=1.e6)
    stack = PEMFCStack(area_effective=A_eff, power_max=P); # Create a PEMFCStack object with default parameters
    m_dot = fflow_H2(stack, 1.) # Calculate the mass flow rate of hydrogen at full throttle (worst case) [kg/s]

    return m_dot / P # Calculate the power specific fuel consumption [kg/W]
end

"""
motor_mass(P_out::Number=1.e6, tech::TechLevel=Current)
Calculate the mass of the motor based on the output power and technology level. Figures are based on linear regression of data on current and future motors.
- P_out: Output power of the motor [W]
- tech: Technology level (Current or Future)
Returns the mass of the motor [kg].
"""
function motor_mass(P_out::Number=1.e6, tech::TechLevel=Current)
    if tech == Current
        # Current technology
        return 2.886e-4 * P_out; # Mass of the motor [kg]
    elseif tech == Future
        # Future technology
        return 8.138e-5 * P_out; # Mass of the motor [kg]
    else
        error("Unknown technology level")
    end

end