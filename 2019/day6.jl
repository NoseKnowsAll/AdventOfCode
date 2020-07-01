# vertex in our graph of orbits
mutable struct Planet
    name::String          # name of this planet
    moons::Array          # list of planets that directly orbit this one
    distance::Integer

    function Planet(name_)
        new(name_, String[], 0)
    end
end

# Read the file of planets and store in dictionary containing orbits
function readfile(filename)

    dict = Dict{String, Planet}()
    dict["COM"] = Planet("COM") # center of mass orbits nothing

    # Initialize dictionary
    for line in eachline(filename)
        m = match(r"(\w+)\)(\w+)",line)
        moon_name   = m.captures[2]
        dict[moon_name] = Planet(moon_name)
    end

    # Setup graph of orbits
    for line in eachline(filename)
        m = match(r"(\w+)\)(\w+)",line)
        planet_name = m.captures[1]
        moon_name   = m.captures[2]
        push!(dict[planet_name].moons, moon_name)
    end

    return dict
end

# Modify planets by computing their distance from COM
# Return the total number of direct and indirect orbits
function compute_orbits!(graph_dict)
    to_compute = ["COM"]
    graph_dict["COM"].distance = 0
    total_orbits = 0

    # Breadth first search, assuming tree-like structure with "COM" as root
    while !isempty(to_compute)
        next_planet = popfirst!(to_compute)
        for moon in graph_dict[next_planet].moons
            graph_dict[moon].distance = graph_dict[next_planet].distance + 1
            total_orbits += graph_dict[moon].distance

            push!(to_compute, moon)
        end
    end

    return total_orbits
end

# Solve day 6-1
function orbits_in_map_data(filename="day6.input")
    graph_dict = readfile(filename)
    total_orbits = compute_orbits!(graph_dict)
    return total_orbits
end

# Helper function to perform depth first search recursively
function recursive_path(graph_dict, path_so_far, to_find)
    to_explore = path_so_far[end]
    if to_explore == to_find
        return true
    end

    for moon in graph_dict[to_explore].moons
        push!(path_so_far, moon)
        found = recursive_path(graph_dict, path_so_far, to_find)
        if found
            return true
        else
            pop!(path_so_far)
        end
    end
    return false
end

# Returns an array of the planets to go from COM to planet_name
function path_to_planet(graph_dict, planet_name)
    path_so_far = ["COM"]
    found = recursive_path(graph_dict, path_so_far, planet_name)
    if !found
        error("No path found to $(planet_name)!")
    end
    return path_so_far
end

# Computes the number of orbital transfers from planet_from to planet_to
function compute_transfers(graph_dict, planet_from, planet_to)
    path_from = path_to_planet(graph_dict, planet_from)
    pop!(path_from) # Only care about orbital transfers, not direct path
    path_to = path_to_planet(graph_dict, planet_to)
    pop!(path_to) # Only care about orbital transfers, not direct path

    # Compute the maximum index along both paths that is in common between them
    index = 1
    while index <= length(path_from) && index <= length(path_to)
        if path_from[index] != path_to[index]
            break
        end
        index+=1
    end
    index-=1 # To adjust for conditions only breaking after they are not true

    # Resulting path is sum(distances to common point)
    not_in_common = length(path_from)-index + length(path_to)-index
end

# Solves day 6-2
function orbital_transfers_required(filename="day6.input")
    graph_dict = readfile(filename)
    return compute_transfers(graph_dict, "YOU", "SAN")
end
