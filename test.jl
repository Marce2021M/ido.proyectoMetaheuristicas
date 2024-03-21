#CHECAR

using Distributions, Random
using StatsBase, LinearAlgebra, Distances  # Para la función sample

function total_distance(path, distances)
    d = sum(distances[path[i], path[i + 1]] for i in 1:(length(path) - 1))
    d += distances[path[end], path[1]]  # Volver al punto de inicio
    return d
end

function fitness(individual, distances)
    total_dist = sum(distances[individual[i], individual[i + 1]] for i in 1:length(individual) - 1)
    total_dist += distances[individual[end], individual[1]]
    return 1 / total_dist
end
# function levy_flights(lambda, size)
#     distribution = Levy(lambda, 1)  # location=0, scale=1
#     return rand(distribution, size)
# end

# function cuckoo_search_step!(population, distances, nest_probability, tabuList)
#     n = length(population[1])
#     new_population = deepcopy(population)
    
#     for i in 1:length(population)
#         # Obtén la solución actual de la población
#         current_solution = population[i]

#         # Genera un paso de Lévy para decidir cuántos swaps realizar
#         num_swaps = min(n, max(1, round(Int, abs(levy_flights(1.5, 1)[1]))))

#         new_solution = current_solution
#         for swap in 1:num_swaps
#             # Selecciona dos índices al azar para intercambiar
#             idx1, idx2 = randperm(n)[1:2]
#             new_solution[idx1], new_solution[idx2] = new_solution[idx2], new_solution[idx1]
#         end
        
#         # Aplica 2-opt a la nueva solución
#         new_solution = two_opt2(new_solution, distances)[1]

#         # Compara la nueva solución con la actual y actualiza si es mejor
#         if fitness(new_solution, distances) > fitness(current_solution, distances)
#             new_population[i] = new_solution
#         end
#     end
#     fitnesses = [fitness(individual, distances) for individual in new_population]
    
#     # Determina el umbral de fitness para el percentil 90 peor
#     threshold = percentile(fitnesses, 10)  # 10% mejor == 90% peor

#     for i in 1:length(new_population)
#         # Abandonar y reemplazar nidos en el percentil 90 peor
#         if fitnesses[i] <= threshold
#             new_population[i] = randperm(n)
#         else
#             # Mantiene las soluciones que no están en el percentil 90 peor
#             # Puedes seguir aplicando Lévy flights o cualquier otra operación aquí si es necesario
#         end
#     end

#     return new_population
# end




function genetic_algorithm(coordinates, population_size, generations,  elite_threshold=0.1)
    n = size(coordinates, 1)
    distances = pairwise(Euclidean(), coordinates', dims=2)
    
    population = [randperm(n) for _ in 1:population_size]
    best_global_distance = Inf  # Inicialización necesaria
    best_global_solution = nothing  # Inicialización necesaria
    fitnesses = [fitness(individual, distances) for individual in population]
    tabuList = []
    
    for gen in 1:generations
        
        sorted_indices = sortperm(fitnesses, rev=true)
        # Preservar la élite
        elite_count = max(1, round(Int, population_size * elite_threshold))
        elite_indices = sorted_indices[1:elite_count]
        elite = population[elite_indices]
        
        # Comprobar si se debe aumentar el umbral de élite
        fitnesses = fitnesses[elite_indices]

         # Selección para cruce y mutación
        selected_indices = sorted_indices[1:Int(round(population_size * 0.5))]
        population = population[selected_indices]

         # Generar nuevas soluciones
        new_population = copy(elite)  # Comenzar con la élite
        for (index, individual) in enumerate(new_population)
            improved_route, improved_distance = two_opt(individual, distances, tabuList)
        
            # Actualiza la mejor solución global si es necesario
            if improved_distance < best_global_distance
                best_global_distance = improved_distance
                best_global_solution = improved_route
            end
        
            # Reemplaza el individuo en la nueva población con la versión mejorada
            new_population[index] = improved_route
            fitnesses[index] = fitness(improved_route, distances)
        end

        if gen % 10 == 0
            println("Generación $gen completada. Mejor distancia: $best_global_distance")
        end
        
        while length(new_population) < population_size
            parents = sample(population, 2, replace=false)
            child = crossover(parents[1], parents[2])  
            
            mutate!(child)  # Ahora mutate! también actualizará el fitness y manejará la lista tabú
            
            child_distance = total_distance(child, distances)  # Mejorar con 2-opt
        
            if child_distance < best_global_distance
                best_global_solution = child
                best_global_distance = child_distance
            end
            push!(fitnesses, child_distance)
            push!(new_population, child)
        end
        population = new_population
        
        if gen % 10 == 0
            println("Generación $gen completada. Mejor distancia: $best_global_distance")
        end
    end

    return best_global_solution, best_global_distance
end

function two_opt_swap(route, i, k)
    return vcat(route[1:i], reverse(route[i+1:k]), route[k+1:end])
end

function two_opt(route, distances, tabuList)
    best_route = copy(route)
    best_distance = total_distance(route, distances)

    contador = 0

    for i in 2:length(route) - 2
        for k in i+1:length(route) - 1
            # Revisar si el cambio está en la lista tabú
            if ((route[i], route[i+1], route[k], route[k+1]) in tabuList ||
                (route[k], route[k+1], route[i], route[i+1]) in tabuList)
                continue  # Saltar este cambio si está en la lista tabú
            end

            delta_distance = calculate_delta_distance(route, i, k, distances)

            if delta_distance < 0
                new_route = two_opt_swap(route, i, k)
                new_distance = best_distance + delta_distance


                best_route = new_route
                best_distance = new_distance
                contador += 1
                    
                # Actualizar la lista tabú
                push!(tabuList, (route[i], route[i+1], route[k], route[k+1]))
                if length(tabuList) > length(route)*10  # Mantener un tamaño razonable para la lista tabú
                    popfirst!(tabuList)
                end
            end

            if contador > 10
                return best_route, best_distance
            end
        end
    end

    return best_route, best_distance  # Retorna la mejor ruta encontrada y su distancia
end

function calculate_delta_distance(route, i, k, distances)
    if i == k || abs(i - k) == 1
        return 0
    end
    # Calcula la distancia actual entre los puntos antes del swap
    current_distance = distances[route[i], route[i+1]] + distances[route[k], route[k+1]]
    # Calcula la distancia después del swap
    new_distance = distances[route[i], route[k]] + distances[route[i+1], route[k+1]]
    return new_distance - current_distance
end




function crossover(parent1, parent2)
    n = length(parent1)
    point1, point2 = sort(randperm(n)[1:2])
    
    # Inicializa el hijo con ceros
    child = fill(0, n)
    
    # Copia una subsecuencia del primer padre al hijo
    child[point1:point2] = parent1[point1:point2]
    
    # Llena las posiciones restantes con los genes del segundo padre
    current_index = 1
    for i in 1:n
        if !(parent2[i] in child)
            while child[current_index] != 0
                current_index += 1
            end
            child[current_index] = parent2[i]
        end
    end
    return child
end



function mutate!(individual)
    n = length(individual)
    if rand() < 0.4  # Probabilidad de mutación
        point1, point2 = randperm(n)[1:2]

        # Realizar la mutación
        individual[point1], individual[point2] = individual[point2], individual[point1]

    end
end




# function two_opt2(route, distances, max_attempts=10)
#     n = length(route)
#     best_distance = total_distance(route, distances)

#     improvement = true
#     while improvement
#         improvement = false

#         best_delta = 0
#         best_i = 0
#         best_k = 0

#         for attempt in 1:max_attempts
#             i = rand(1:n-2)
#             k = rand(i+2:n)

#             if i == 1 && k == n  # Evitar la inversión que simplemente rota la ruta
#                 continue
#             end

#             delta = distances[route[i], route[k]] + distances[route[i+1], route[k % n + 1]] -
#                     distances[route[i], route[i+1]] - distances[route[k], route[k % n + 1]]

#             if delta < best_delta
#                 best_delta = delta
#                 best_i = i
#                 best_k = k
#                 improvement = true
#             end
#         end

#         if !improvement && best_i > 0 && best_k > 0
#             # Realizar el mejor intercambio encontrado
#             reverse!(route, best_i+1, best_k)
#             best_distance += best_delta
#             improvement = true  # Asegurarse de que el ciclo continúe si se encontró un mejor cambio
#         end
#     end

#     return route, best_distance
# end
