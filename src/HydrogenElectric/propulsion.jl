"""
sfc(throttle::Number=1.0, V::Number=0.0, η_prop::Number=0.8)

Estimate the specific fuel consumption (SFC) of a proton exchange membrane fuel cell propulsion system.

"""
function sfc(throttle::Number=1.0, V::Number=0.0, η_prop::Number=0.8)
    stack = PEMFCStack(); # Create a PEMFCStack object with default parameters
    m_dot = fflow_H2(stack, throttle)
    P = stack.power_max * throttle

    return m_dot / P * V / η_prop
end