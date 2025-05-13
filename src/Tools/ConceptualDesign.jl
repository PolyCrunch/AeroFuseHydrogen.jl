module ConceptualDesign

function WS_Stall(V_stall::Real = 55., ρ::Real = 1.115, CL_max::Real = 2.7)
    WS = 0.5 * ρ * V_stall^2 / CL_max;
    
    return WS
end

function WS_Landing(ALD::Real = 1000., S_a::Real = 305., K_R::Real = 0.66, σ::Real = 1.0, CL_max::Real = 2.7)
    # Estimate the wing loading limit for landing
    WS::Real = (ALD - S_a) * σ * CL_max / (0.51 * K_R);

    return WS
end

function PW_50ftTakeoff(W_S, TODA_min::Real = 1500., σ::Real = 1., CL_TO::Real = 2.2)
    # Estimate the power-to-weight ratio required for takeoff over a 50ft obstacle
    P_W = 11.7 .* Float64(W_S) ./ (TODA_min * σ * CL_TO);

    return P_W
end

function PW_BFLTakeoff(W_S, N_E::Int, TODA_min::Real = 1500., σ::Real = 1., CL_TO::Real = 2.2)
    # Estimate the power-to-weight ratio required for takeoff over a balanced field length
    P_W = PW_50ftTakeoff(W_S, TODA_min, σ, CL_TO) .* (0.297 - 0.019 * Float64(N_E)) ./ 0.144;

    return P_W
end

function PW_Climb(W_S, α::Real, β::Real=1., V::Real=120., G::Real=0.06, ρ::Real = 0.56, η_prop::Real = 0.8, CD_0::Real = 0.05, AR::Real = 11.5, e::Real = 0.75)
    # Estimate the power-to-weight ratio required for climb
    CL = α .* W_S ./ (0.5 * ρ * V^2);
    PW = (V * α)/(η_prop * β) .* (G .+ CD_0 ./ (α .* CL) .+ (α .* CL)./(π * AR * e));

    return PW
end

function PW_Cruise(W_S, α::Real, β::Real=1., V::Real=120., η_prop::Real = 0.8, CD_0::Real = 0.05, AR::Real = 11.5, e::Real = 0.75)
    # Estimate the power-to-weight ratio required for cruise
    CL = α .* W_S ./ (0.5 * ρ * V^2);

    PW = (V * α)/(η_prop * β) .* (CD_0 ./ (α .* CL) .+ (α .* CL)./(π * AR * e));
    return PW
end

end
