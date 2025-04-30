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
a
"""
function motor_mass(P_out::Number=1.e6, tech::TechLevel=TechLevel.Current)
    if tech == Current
        # Current technology
        return 0.5 * P_out^0.67 # Mass of the motor [kg] PLACEHOLDER
    elseif tech == Future
        # Future technology
        return 0.3 * P_out^0.67 # Mass of the motor [kg] PLACEHOLDER
    else
        error("Unknown technology level")
    end

end