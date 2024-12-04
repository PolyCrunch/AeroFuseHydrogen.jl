function read_data(path::String)
    data = CSV.read(input, DataFrame;
        normalizenames=true
    )
    return data
end