using Random, Distributions

# Función para calcular la distancia total de un recorrido
function total_distance(path, distances)
    d = sum(distances[path[i], path[i + 1]] for i in 1:length(path) - 1)
    d += distances[path[end], path[1]]
    return d
end

# Función de fitness: inversa de la distancia total
function fitness(individual, distances)
    return 1 / total_distance(individual, distances)
end

# Función para realizar Lévy flights
function levy_flight(current_solution, λ, n, distances)
    distribution = Levy(λ, 0.1)  # Suponiendo que Levy está definido correctamente
    step_size = rand(distribution, 1)[1]
    
    # Aplicar Lévy flights de manera que se respeten los límites del problema
    new_solution = current_solution
    for _ in 1:round(Int, abs(step_size))  # Realizar movimientos basados en el tamaño del paso
        i, j = randperm(n)[1:2]  # Escoger dos índices al azar para intercambiar
        new_solution[i], new_solution[j] = new_solution[j], new_solution[i]
    end

    new_fitness = fitness(new_solution, distances)
    return new_solution, new_fitness
end


# Algoritmo CS-TSP
function cs_tsp(coordinates, population_size, max_generations)
    n = size(coordinates, 1)
    distances = [norm(coordinates[i, :] - coordinates[j, :]) for i = 1:n, j = 1:n]
    population = [randperm(n) for _ in 1:population_size]
    fitnesses = [fitness(individual, distances) for individual in population]

    generation = 0
    while generation < max_generations
        # Paso 3: Obtener un cucú al azar y reemplazar su solución
        cuckoo_index = rand(1:population_size)
        cuckoo = population[cuckoo_index]
        new_cuckoo, new_fitness = levy_flight(cuckoo, 1.5, n, distances)

        # Paso 5: Elegir un nido al azar
        nest_index = rand(1:population_size)
        if nest_index != cuckoo_index && new_fitness > fitnesses[nest_index]
            # Paso 6: Reemplazar si la nueva solución es mejor
            population[nest_index] = new_cuckoo
            fitnesses[nest_index] = new_fitness
        end

        # Paso 7: Abandonar peores nidos y construir nuevos
        worst_indices = sortperm(fitnesses)[1:round(Int, population_size * 0.2)]
        for index in worst_indices
            population[index] = randperm(n)
            fitnesses[index] = fitness(population[index], distances)
        end

        generation += 1

        # Paso 8: Mantener las mejores soluciones
        # Esto ya se maneja automáticamente en nuestro enfoque al mantener y actualizar la población
    end

    # Paso 9: Seleccionar los mejores nidos que representan la solución
    best_index = argmax(fitnesses)
    best_solution = population[best_index]

    return best_solution, total_distance(best_solution, distances)
end
