#include <stddef.h>
#include <stdio.h>

double total_distance(const int* path, int path_length, const double* distances, int num_cities) {
    double d = 0.0;
    for (int i = 0; i < path_length - 1; ++i) {
        d += distances[(path[i] - 1) * num_cities + (path[i + 1] - 1)];
    }
    d += distances[(path[path_length - 1] - 1) * num_cities + (path[0] - 1)];
    return d;
}
double fitness(const int* individual, int path_length, const double* distances, int num_cities) {
    double dist = total_distance(individual, path_length, distances, num_cities);
    return 1.0 / dist;
}

void compute_fitnesses(const int* population, int population_size, int path_length, const double* distances, int num_cities, double* fitnesses) {
    for (int i = 0; i < population_size; i++) {
        const int* individual = population + i * path_length;
        fitnesses[i] = fitness(individual, path_length, distances, num_cities);
    }
}