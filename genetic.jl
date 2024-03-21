using Random
using LinearAlgebra, StatsBase, Distances


# Función para calcular la distancia total de un recorrido
function total_distance(path, distances)
    d = 0
    for i in 1:length(path)-1
        d += distances[path[i], path[i+1]]
    end
    d += distances[path[end], path[1]]  # Volver al punto de inicio
    return d
end

# Función de fitness: inversa de la distancia total (mayor es mejor)
fitness(path, distances) = 1 / total_distance(path, distances)

# Algoritmo genético básico para TSP
function genetic_algorithm(coordinates, population_size, generations)
    n = size(coordinates, 1)
    distances = pairwise(Euclidean(), coordinates', dims=2)
    # Inicializar población aleatoriamente
    population = [randperm(n) for _ in 1:population_size]

    for gen in 1:generations
        if gen % 1 == 0  # Imprimir solo cada 100 generaciones
            println("Generación $gen")
        end
        # Calcular fitness de la población
        fitnesses = [fitness(individual, distances) for individual in population]

        # Selección
        selected_indices = sortperm(fitnesses, rev=true)[1:Int(round(population_size*.5))]
        population = population[selected_indices]

        # Cruce y mutación
        new_population = []
        while length(new_population) < population_size
            parents = sample(population, 2, replace=false)
            child = crossover(parents[1], parents[2])  
            mutate!(child)  
            child, _ = two_opt(child, distances)  # Mejorar con 2-opt
            push!(new_population, child)
        end

        population = new_population
    end

    best_solution = population[sortperm([fitness(individual, distances) for individual in population], rev=true)[1]]
    return best_solution, total_distance(best_solution, distances)
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
    if indicador < 0.3
        point1, point2 = randperm(n)[1:2]
        individual[point1], individual[point2] = individual[point2], individual[point1]
    end
end

function two_opt_swap(route, i, k)
    return vcat(route[1:i-1], reverse(route[i:k]), route[k+1:end])
end

function two_opt(route, distances)
    improvement = true
    best_distance = total_distance(route, distances)
    while improvement
        improvement = false
        for i in 2:length(route)-2
            for k in i+1:length(route)-1
                new_route = two_opt_swap(route, i, k)
                new_distance = total_distance(new_route, distances)
                if new_distance < best_distance
                    route = new_route
                    best_distance = new_distance
                    improvement = true
                end
            end
        end
    end
    return route, best_distance
end





