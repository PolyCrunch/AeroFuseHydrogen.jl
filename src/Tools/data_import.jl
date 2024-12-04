function read_data(path::String)
    data = CSV.read(path, DataFrame;
        normalizenames=true
    )
    return data
end