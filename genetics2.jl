using LinearAlgebra
using StatsBase
using Random

# FUNCIONES AUXILIARES
# Función para calcular la distancia total de un recorrido
function total_distance(path, distances)
    d = sum(distances[path[i], path[i + 1]] for i in 1:length(path) - 1)
    d += distances[path[end], path[1]]  # Volver al punto de inicio
    return d
end

function fitness(individual, distances)
    total_dist = sum(distances[individual[i], individual[i + 1]] for i in 1:length(individual) - 1)
    total_dist += distances[individual[end], individual[1]]
    return 1 / total_dist
end

function genetic_algorithm(coordinates, population_size, generations)
    n = size(coordinates, 1)
    distances = [norm(coordinates[i,:] - coordinates[j,:]) for i in 1:n, j in 1:n]

    population = [randperm(n) for _ in 1:population_size]
    fitnesses = [fitness(individual, distances) for individual in population]

    for gen in 1:generations
        if gen % 100 == 0
            println("Generación $gen, mejor distancia: $(1/maximum(fitnesses))")
        end
        
        # Seleccionar padres del percentil 25
        percentile_75_index = Int(ceil(0.15 * population_size))
        selected_indices = sortperm(fitnesses, rev=true)[1:percentile_75_index]
        selected_population = population[selected_indices]

        new_population = similar(population, 0)
        if gen == generations/2
            population_size = population_size/2
        end

        while length(new_population) < population_size
            
            parents = sample(selected_population, 2, replace=false)
            child = crossover(parents[1], parents[2])
            mutate!(child)
            if gen == generations/2
                child = two_opt2(child, distances, 20)[1]  
            else
                child = two_opt2(child, distances)[1]  
            end
            push!(new_population, child)
        end

        population = new_population
        fitnesses = [fitness(individual, distances) for individual in population]
    end
    best_index = argmax(fitnesses)
    best_solution = population[best_index]
    return best_solution, total_distance(best_solution, distances)
end



# function genetic_algorithm(coordinates, population_size, generations)
#     n = size(coordinates, 1)
#     distances = [norm(coordinates[i,:] - coordinates[j,:]) for i in 1:n, j in 1:n]

#     population = [randperm(n) for _ in 1:population_size]
#     fitnesses = [fitness(individual, distances) for individual in population]

#     for gen in 1:generations
#         if gen % 10 == 0 println("Generación $gen") end  # Log each 100 generations
        
#         # Selección (considerar usar selección por torneo para mejorar la eficiencia)
#         selected_indices = sortperm(fitnesses, rev=true)[1:Int(round(population_size * 0.5))]
#         selected_population = population[selected_indices]

#         # Cruce, mutación y 2-opt
#         new_population = similar(population, 0)

#         while length(new_population) < population_size
#             parents = sample(selected_population, 2, replace=false)

#             child = crossover(parents[1], parents[2])
            
#             mutate!(child)  

#             child = two_opt(child, distances)[1]  

#             push!(new_population, child)
#         end
    
#         population = new_population
#         fitnesses = [fitness(individual, distances) for individual in population]
#     end

#     best_index = argmax(fitnesses)
#     best_solution = population[best_index]
#     return best_solution, total_distance(best_solution, distances)
# end

# Asegúrate de que las funciones crossover, mutate!, fitness, y two_opt estén definidas de manera eficiente.



# Aquí agregarías las definiciones de crossover, mutate! y two_opt...
function crossover(parent1, parent2)
    n = length(parent1)
    point1, point2 = sort(randperm(n)[1:2])
    
    child = fill(0, n)
    included = Set{Int}()
    
    for i in point1:point2
        child[i] = parent1[i]
        push!(included, parent1[i])  # Usar push! para añadir a un conjunto
    end
    
    current_index = 1
    for i in 1:n
        if !(parent2[i] in included)
            while current_index <= n && child[current_index] != 0
                current_index += 1
            end
            # Asegurarse de que current_index esté dentro del rango
            if current_index <= n
                child[current_index] = parent2[i]
                push!(included, parent2[i])
            end
        end
    end
    return child
end


function mutate!(individual)
    n = length(individual)
    indicador = rand()
    if indicador < 0.3
        point1, point2 = randperm(n)[1:2]
        individual[point1], individual[point2] = individual[point2], individual[point1]
    end
end

# Funciones principales auxiliares

function two_opt(route, distances)

    #nuevo intento
    n = length(route)
    best_distance = total_distance(route, distances)

    improvement = true
    while improvement
        improvement = false
        for i in 1:n-2
            for k in i+2:n
                if i == 1 && k == n  # Evitar la inversión que simplemente rota la ruta
                    continue
                end
                
                delta = distances[route[i], route[k]] + distances[route[i+1], route[(k % n) + 1]] -
                        distances[route[i], route[i+1]] - distances[route[k], route[(k % n) + 1]]
                
                if delta < 0
                    reverse!(route, i+1, k)
                    best_distance += delta
                    improvement = true
                    break
                end
            end
            if improvement  # Salir del bucle interno tan pronto como se encuentre una mejora
                break
            end
        end
    end

    return route, best_distance
end


# function two_opt_swap(route, i, k)
#     return vcat(route[1:i-1], reverse(route[i:k]), route[k+1:end])
# end

# function two_opt(route, distances)
#     n = length(route)
#     improvement = true
#     best_distance = total_distance(route, distances)

#     while improvement
#         improvement = false
#         for i in 1:n-1
#             for k in i+2:min(i+1+n, n)
#                 # Evita salir de los límites
#                 if k > n || i >= k
#                     continue
#                 end

#                 new_route = two_opt_swap(route, i, k)
#                 new_distance = total_distance(new_route, distances)

#                 if new_distance < best_distance
#                     route = new_route
#                     best_distance = new_distance
#                     improvement = true


#                 end
#             end
#         end
#     end
#     return route, best_distance
# end

function two_opt2(route, distances, max_attempts=10)
    n = length(route)
    best_distance = total_distance(route, distances)

    improvement = true
    while improvement
        improvement = false

        best_delta = 0
        best_i = 0
        best_k = 0

        for attempt in 1:max_attempts
            i = rand(1:n-2)
            k = rand(i+2:n)

            if i == 1 && k == n  # Evitar la inversión que simplemente rota la ruta
                continue
            end

            delta = distances[route[i], route[k]] + distances[route[i+1], route[k % n + 1]] -
                    distances[route[i], route[i+1]] - distances[route[k], route[k % n + 1]]

            if delta < best_delta
                best_delta = delta
                best_i = i
                best_k = k
                improvement = true
            end
        end

        if !improvement && best_i > 0 && best_k > 0
            # Realizar el mejor intercambio encontrado
            reverse!(route, best_i+1, best_k)
            best_distance += best_delta
            improvement = true  # Asegurarse de que el ciclo continúe si se encontró un mejor cambio
        end
    end

    return route, best_distance
end





