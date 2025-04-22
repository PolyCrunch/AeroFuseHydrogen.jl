"""
sfc(throttle::Number=1.0, V::Number=0.0, η_prop::Number=0.8)
"""
function sfc(A_eff=120.::Number, P_max::Number=1.e6, throttle::Number=1.0, V::Number=0.0, η_prop::Number=0.8)
    stack = PEMFCStack(area_effective=A_eff, power_max = P_max); # Create a PEMFCStack object with default parameters
    m_dot = fflow_H2(stack, throttle)
    P = stack.power_max * throttle

    return m_dot / P * V / η_prop
end