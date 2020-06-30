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
