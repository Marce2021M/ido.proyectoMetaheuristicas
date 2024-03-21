#CHECAR

using Distributions, Random
using StatsBase, LinearAlgebra  # Para la función sample

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
function levy_flights(λ, size)
    distribution = Levy(0, 1)  # location=0, scale=1
    return rand(distribution, size)
end

function cuckoo_search_step!(population, distances, nest_probability)
    n = length(population[1])
    new_population = deepcopy(population)
    
    for i in 1:length(population)
        # Obtén la solución actual de la población
        current_solution = population[i]

        # Genera un paso de Lévy para decidir cuántos swaps realizar
        num_swaps = min(n, max(1, round(Int, abs(levy_flights(1.5, 1)[1]))))

        new_solution = current_solution
        for swap in 1:num_swaps
            # Selecciona dos índices al azar para intercambiar
            idx1, idx2 = randperm(n)[1:2]
            new_solution[idx1], new_solution[idx2] = new_solution[idx2], new_solution[idx1]
        end
        
        # Aplica 2-opt a la nueva solución
        new_solution = two_opt2(new_solution, distances)[1]

        # Compara la nueva solución con la actual y actualiza si es mejor
        if fitness(new_solution, distances) > fitness(current_solution, distances)
            new_population[i] = new_solution
        end
    end
    fitnesses = [fitness(individual, distances) for individual in new_population]
    
    # Determina el umbral de fitness para el percentil 90 peor
    threshold = percentile(fitnesses, 10)  # 10% mejor == 90% peor

    for i in 1:length(new_population)
        # Abandonar y reemplazar nidos en el percentil 90 peor
        if fitnesses[i] <= threshold
            new_population[i] = randperm(n)
        else
            # Mantiene las soluciones que no están en el percentil 90 peor
            # Puedes seguir aplicando Lévy flights o cualquier otra operación aquí si es necesario
        end
    end

    return new_population
end




function genetic_algorithm(coordinates, population_size, generations, nest_probability=.45, elite_threshold=0.1)
    n = size(coordinates, 1)
    distances = [norm(coordinates[i, :] - coordinates[j, :]) for i in 1:n, j in 1:n]

    population = [randperm(n) for _ in 1:population_size]
    best_global_distance = Inf  # Inicialización necesaria
    best_global_solution = nothing  # Inicialización necesaria
    some_defined_performance_barrier = 0.1  # Necesitas definir este valor apropiadamente

    for gen in 1:generations
        fitnesses = [fitness(individual, distances) for individual in population]
        sorted_indices = sortperm(fitnesses, rev=true)
        # Preservar la élite
        elite_count = max(1, round(Int, population_size * elite_threshold))
        elite_indices = sorted_indices[1:elite_count]
        elite = population[elite_indices]
        
        # Comprobar si se debe aumentar el umbral de élite
        elite_fitnesses = fitnesses[elite_indices]
        if percentile(elite_fitnesses, 75) > some_defined_performance_barrier
            elite_threshold = min(elite_threshold + 0.05, 1.0)  # Aumentar el umbral, hasta un máximo de 1.0
        end
         # Selección para cruce y mutación
        selected_indices = sorted_indices[1:Int(round(population_size * 0.5))]
        population = population[selected_indices]
        
        # Integrar paso de búsqueda de Cuckoo
        population = cuckoo_search_step!(population, distances, nest_probability)
         # Generar nuevas soluciones
        new_population = copy(elite)  # Comenzar con la élite
        while length(new_population) < population_size
            parents = sample(population, 2, replace=false)
            child = crossover(parents[1], parents[2])  
            mutate!(child)  
            
            child, child_distance = two_opt2(child, distances)  # Mejorar con 2-opt
        
            if child_distance < best_global_distance
                best_global_solution = child
                best_global_distance = child_distance
            end
        
            push!(new_population, child)
        end
        population = new_population
        
        if gen % 1 == 0
            println("Generación $gen completada. Mejor distancia: $best_global_distance")
        end
    end

    return best_global_solution, best_global_distance
end


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
    indicador = rand()
    if indicador < 0.2
        point1, point2 = randperm(n)[1:2]
        individual[point1], individual[point2] = individual[point2], individual[point1]
    end
end



