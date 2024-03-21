using Random, Distributions, LinearAlgebra
using StatsBase

# Ahora puedes usar Weights en tu función


function ant_colony_optimization(distance_matrix, num_ants, num_iterations; alpha=1.7, beta=6.0, evaporation_rate=0.5)
    num_cities = size(distance_matrix, 1)
    max_distance = maximum(distance_matrix)
    pheromone_matrix = 1 .- (distance_matrix ./ (1.5 * max_distance)) .^ 3
    best_path = Int[]
    best_distance = Inf

    for i in 1:num_iterations
        println("Iteración $i")
        flag = false
        counter = 0
        for ant in 1:num_ants
            current_city = rand(1:num_cities)
            visited = falses(num_cities)
            visited[current_city] = true
            path = [current_city]
            total_distance = 0.0

            for _ in 1:num_cities - 1
                probabilities = [!visited[city] ? (pheromone_matrix[current_city, city] ^ alpha) * ((1 / distance_matrix[current_city, city]) ^ beta) : 0 for city in 1:num_cities]
                probabilities /= sum(probabilities)
                next_city = sample(1:num_cities, Weights(probabilities))

                push!(path, next_city)
                visited[next_city] = true
                total_distance += distance_matrix[current_city, next_city]
                current_city = next_city
            end

            total_distance += distance_matrix[path[end], path[1]]
            push!(path, path[1])

            if total_distance < best_distance
                best_distance = total_distance
                best_path = path
                println("Mejor distancia: $best_distance")
                flag = true
            end
        end
        if flag == true
            i += 1
        end
        # Adjust the evaporation rate if necessary
        if i >= 20
            evaporation_rate = rand(0.4:0.01:0.7)
        end
        if i >= 30
            a = rand(-0.3:0.01:0.3)
            beta *= (1 + a)
        end

        # Evaporate pheromones
        pheromone_matrix *= (1 - evaporation_rate)

        # Update pheromones along the best path
        for i in 1:length(best_path)-1
            x = distance_matrix[best_path[i], best_path[i+1] % num_cities + 1]
            a = exp(-x)
            pheromone_matrix[best_path[i], best_path[i+1]% num_cities + 1] += ((50 / best_distance) + a)
        end
    end

    return best_path, best_distance
end

# Ejemplo de uso (necesitarás definir `distance_matrix` de acuerdo a tu problema específico)
# num_ants = 10
# num_iterations = 50
# best_path, best_distance = ant_colony_optimization(distance_matrix, num_ants, num_iterations)
