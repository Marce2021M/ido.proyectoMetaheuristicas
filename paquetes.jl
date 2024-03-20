using DelimitedFiles

function read_tsp(filename::String)
    lines = readlines(filename)

    start_index = findfirst(occursin("NODE_COORD_SECTION"), lines)
    if start_index === nothing
        start_index = findfirst(occursin("EDGE_WEIGHT_SECTION"), lines)
    end

    if start_index === nothing
        error("No se encontró la sección de coordenadas o pesos.")
    end

    start_index += 1

    data = []
    for line in lines[start_index:end]
        if occursin("EOF", line)
            break
        end
        push!(data, parse.(Float64, split(strip(line))))
    end

    return data
end



