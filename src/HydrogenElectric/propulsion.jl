"""
sfc(A_eff::Number=120., P::Number=1.e6, V::Number=100.0, η_prop::Number=0.8)
"""
function sfc(A_eff=120.::Number, P::Number=1.e6, V::Number=100.0, η_prop::Number=0.8)
    stack = PEMFCStack(area_effective=A_eff, power_max=P); # Create a PEMFCStack object with default parameters
    m_dot = fflow_H2(stack, 1.) # Calculate the mass flow rate of hydrogen (kg/s)

    return m_dot / P * V / η_prop # Calculate the specific fuel consumption (kg/Ws)
end