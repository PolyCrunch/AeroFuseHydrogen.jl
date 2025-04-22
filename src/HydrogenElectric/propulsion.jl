"""
psfc(A_eff::Number=120., P::Number=1.e6)
"""
function psfc(A_eff=120.::Number, P::Number=1.e6)
    stack = PEMFCStack(area_effective=A_eff, power_max=P); # Create a PEMFCStack object with default parameters
    m_dot = fflow_H2(stack, 1.) # Calculate the mass flow rate of hydrogen (kg/s)

    return m_dot / P # Calculate the power specific fuel consumption (kg/W)
end