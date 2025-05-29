module Weights

@enum AircraftType begin
    Business
    ShortHaul
    LongHaul
end

@enum RangeType begin
    Short
    VeryLong
end

    function n_cabincrew(n_passengers::Int)::Int
        # Number of cabin crew
        @assert n_passengers >= 0 "Number of passengers must be non-negative"

        n_cabin = ceil(n_passengers / 50); # One cabin crew for every 50 passengers

        return n_cabin
    end


    function crew_weight(n_flightdeck::Int, n_passengers::Int)::Number
        # Weight of crew
        @assert n_flightdeck >= 0 "Number of flight deck crew must be non-negative"
        @assert n_passengers >= 0 "Number of passengers must be non-negative"

        return (
            n_flightdeck * (85. + 15.) + # Flight deck crew
            n_cabincrew(n_passengers) * (75. + 15.) # Cabin crew
        )
    end

    function lavatory_weight_factor(type::AircraftType)::Number
        # Lavatory weight factor
        if type == Business
            return 3.90; # Lavatory weight factor business
        elseif type == ShortHaul
            return 0.31; # Lavatory weight factor short-haul
        elseif type == LongHaul
            return 1.11; # Lavatory weight factor long-haul
        else
            error("Unknown aircraft type")
        end
    end

    function food_weight_factor(range::RangeType)::Number
        # Food weight factor
        if range == Short
            return 1.02; # Food weight factor short-haul
        elseif range == VeryLong
            return 5.68; # Food weight factor very long-haul
        else
            error("Unknown range type")
        end
    end


    function furnishings_weight(N_flightdeck::Int = 2, N_pax::Int = 60, N_cabincrew::Int = 2, P_cabin::Number = 38251., W_0::Number = 30000., type::AircraftType = ShortHaul, range::RangeType = Short)::Number
        K_lav = lavatory_weight_factor(type) # Lavatory weight factor
        K_buf = food_weight_factor(range) # Food weight factor

        P_cabin *= 0.000145038; # Convert cabin pressure from Pa to psi
        W_0 *= 2.20462; # Convert weight from kg to lb

        # Calculate the weight of the furnishings
        W_furnishings = 55 * N_flightdeck + 32 * N_pax +
        15 * N_cabincrew + K_lav * N_pax^1.33 + K_buf * N_pax^1.12 + 109*(N_pax * (1 + P_cabin) / 100)^0.505 + 0.771 * (W_0 / 1000); # Weight of furnishings [kg], Roskam Part V
        
        W_furnishings /= 2.20462; # Convert weight from lb to kg
        return W_furnishings; # Convert weight from lb to kg
    end

end