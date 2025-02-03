module DataTools

## Package imports
#==========================================================================================#
using CSV
using DataFrames

## Functions
#==========================================================================================#

function read_data(path::String)
    data = CSV.read(path, DataFrame;
        normalizenames=true
    )
    return data
end

end