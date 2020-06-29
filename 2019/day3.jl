using DelimitedFiles

# Trace a single input path from the starting location = (n,n) into grid
function trace_path!(grid, single_path, path_num::Int8)

    n = Int64((size(grid,1)-1)/2)
    path_lengths = Array{Int64,2}(undef, 2*n+1,2*n+1)
    path_lengths .= typemax(Int64)
    curr_loc = [n,n]
    path_length = 0
    for vector in single_path
        distance=parse(Int64,vector[2:end])

        if vector[1]=='U' # Up
            for y = 1:distance
                loc = (curr_loc[1]-y,curr_loc[2])
                grid[loc...] |= path_num
                path_lengths[loc...] = min(path_lengths[loc...],path_length+y)
            end
            curr_loc[1] -= distance

        elseif vector[1]=='D' # Down
            for y = 1:distance
                loc = (curr_loc[1]+y,curr_loc[2])
                grid[loc...] |= path_num
                path_lengths[loc...] = min(path_lengths[loc...],path_length+y)
            end
            curr_loc[1] += distance

        elseif vector[1]=='L' # Left
            for x = 1:distance
                loc = (curr_loc[1],curr_loc[2]-x)
                grid[loc...] |= path_num
                path_lengths[loc...] = min(path_lengths[loc...],path_length+x)
            end
            curr_loc[2] -= distance

        elseif vector[1]=='R' # Right
            for x = 1:distance
                loc = (curr_loc[1],curr_loc[2]+x)
                grid[loc...] |= path_num
                path_lengths[loc...] = min(path_lengths[loc...],path_length+x)
            end
            curr_loc[2] += distance
        end

        path_length += distance
    end
    return path_lengths
end

# Read input file and return grid of traced paths
function initialize_grid(n,filename)
    # grid == 1 if only 1, 2 if only 2, 3 if both
    grid = zeros(Int8,2*n+1,2*n+1)
    input = readdlm(filename, ',', String, '\n')
    for path_num in 1:2
        trace_path!(grid, input[path_num,:], Int8(path_num))
    end
    return grid
end

# Compute the manhattan distance (1-norm) between two points
function manhattan_distance(point1, point2)
    sum(abs.(point1-point2))
end

# From grid, find closest intersection (wrt 1-norm) to start=(n,n)
function find_min_distance(grid)
    n = Int64((size(grid,1)-1)/2)
    origin = [n,n]
    min_location = [2*n+1,2*n+1]
    min_distance = manhattan_distance(origin, min_location)

    for i = 1:2*n+1
        for j = 1:2*n+1
            if grid[i,j] == (1 | 2) # Intersection point between two paths
                dist = manhattan_distance(origin, [i,j])
                if dist < min_distance
                    min_distance = dist
                    min_location = CartesianIndex(i,j)

                end
            end
        end
    end

    return (min_distance,min_location)
end

# Returns the solution to day3-1
function solve_day3_1(n=10000,filename="day3.input")
    finished = false
    while !finished
        try
            grid = initialize_grid(n,filename)
            (min_distance, min_location) = find_min_distance(grid)
            finished = true
            println("final n needed = ", n)
            return min_distance
        catch err
            if isa(err, BoundsError)
                n *= 2
                finished = false
            else
                throw(err)
            end
        end
    end
end

# Read input file and return grid of traced paths
function initialize_grid_and_lengths(n,filename)
    # grid == 1 if only 1, 2 if only 2, 3 if both
    grid = zeros(Int8,2*n+1,2*n+1)
    all_path_lengths = []
    input = readdlm(filename, ',', String, '\n')
    for path_num in 1:2
        push!(all_path_lengths, trace_path!(grid, input[path_num,:], Int8(path_num)))
    end
    return (grid, all_path_lengths)
end

# Compute the minimum path length to an intersection point
function find_min_length(grid, all_path_lengths)
    n = Int64((size(grid,1)-1)/2)
    origin = [n,n]
    min_location = CartesianIndex(2*n+1,2*n+1)
    min_length = Inf

    for i = 1:2*n+1
        for j = 1:2*n+1
            if grid[i,j] == (1 | 2) # Intersection point between two paths
                length1 = all_path_lengths[1][i,j]
                length2 = all_path_lengths[2][i,j]

                if length1+length2 < min_length
                    min_length = length1+length2
                    min_location = CartesianIndex(i,j)
                end
            end
        end
    end

    return (min_length,min_location)
end

# Returns the solution to day3-2
function solve_day3_2(n=10000,filename="day3.input")
    (grid, all_path_lengths) = initialize_grid_and_lengths(n,filename)
    (min_length, min_location) = find_min_length(grid, all_path_lengths)
    return min_length
end
