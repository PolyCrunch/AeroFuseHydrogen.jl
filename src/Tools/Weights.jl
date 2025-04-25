module Weights

    function crew_weight(n_flightdeck::Int, n_passengers::Int)
        # Weight of crew
        @assert n_flightdeck >= 0 "Number of flight deck crew must be non-negative"
        @assert n_passengers >= 0 "Number of passengers must be non-negative"

        n_cabin = ceil(n_passengers / 50); # One cabin crew for every 50 passengers

        return (
            n_flightdeck * (85 + 15) + # Flight deck crew
            n_cabin * (75 + 15) # Cabin crew
        )
    end

end