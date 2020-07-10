const UNKNOWN = -1
const PASSAGE = 0
const WALL = 1
const ENTRANCE = 2

# Information about maze
mutable struct Maze
    map::Array
    entrance
    total_keys
end

# Returns the value to be stored in the maze
function char2id(char)
    id = WALL
    if char == '.'
        id = PASSAGE
    elseif char == '#'
        id = WALL
    elseif char == '@'
        id = ENTRANCE
    else
        id = Int(char)
    end
    return id
end

# Keys are lowercase
function iskey(id)
    return Int('a') <= id <= Int('z')
end

# Doors are uppercase
function isdoor(id)
    return Int('A') <= id <= Int('Z')
end

# Given a key ID, returns the corresponding door ID
function key2door(id)
    return id + Int('A')-Int('a')
end

# Given a door ID, returns the corresponding key ID
function door2key(id)
    return id + Int('a')-Int('A')
end

# Override Base.show to allow for printing of maze
function Base.show(io::IO, maze::Maze)
    function id2char(id)
        char = ' '
        if id == PASSAGE
            char = ' '
        elseif id == WALL
            char = '#'
        elseif id == ENTRANCE
            char = '@'
        else
            char = Char(id)
        end
        return char
    end
    for i = 1:size(maze.map,1)
        for j = 1:size(maze.map,2)
            print(io,id2char(maze.map[i,j]))
        end
        println(io)
    end
    print(io,"entrance = $(maze.entrance)")
end

# Information about player
mutable struct Player
    location
    keys::Array
end

# Read file and initialize maze
function init_maze(filename)
    width = 0
    height = 0
    for line in eachline(filename)
        width = max(width,length(line))
        height += 1
    end
    maze = Maze(ones(Int8,height,width),[0,0], 0)
    for (i,line) in enumerate(eachline(filename))
        for j = 1:length(line)
            maze.map[i,j] = char2id(line[j])
            if maze.map[i,j] == ENTRANCE
                maze.entrance = [i,j]
                maze.map[i,j] = PASSAGE
            end
            if iskey(maze.map[i,j])
                maze.total_keys+=1
            end
        end
    end

    return maze
end

# directions for use in exploring maze
const NORTH = 1
const SOUTH = 2
const WEST = 3
const EAST = 4

# Helper function to convert directions to a separate index
function dir2ind(start,dir)
    if dir == NORTH
        return [start[1]-1,start[2]]
    elseif dir == SOUTH
        return [start[1]+1,start[2]]
    elseif dir == WEST
        return [start[1],start[2]-1]
    elseif dir == EAST
        return [start[1],start[2]+1]
    end
end

# Helper function to convert neighbors to a specific direction
function neighbor2dir(from,to)
    if from.-to == [1,0]
        return NORTH
    elseif from.-to == [-1,0]
        return SOUTH
    elseif from.-to == [0,1]
        return WEST
    elseif from.-to == [0,-1]
        return EAST
    else
        # Only occurs when you are trying to go to an non-neighbor location
        return UNKNOWN
    end
end

# Flood fill from starting location building up key dependency graph
function flood_fill_dependency(maze, start)
    # Initialize flood fill of maze from location = start
    distances = UNKNOWN .* ones(Int,size(maze.map))
    distances[start...] = 0
    dependencies = Array{Array{Int8,1},2}(undef,size(maze.map))
    dependencies[start...] = []
    all_keys = Dict{Int,Array{Int8,1}}()

    # BFS to explore maze, avoiding walls
    to_explore = [start]
    while !isempty(to_explore)
        location = popfirst!(to_explore)
        for dir = NORTH:EAST
            next_loc = dir2ind(location,dir)
            next_id = maze.map[next_loc...]
            # Only visit unvisited non-wall locations
            if next_id != WALL && distances[next_loc...] < 0
                push!(to_explore, next_loc)
                distances[next_loc...] = distances[location...]+1

                dependencies[next_loc...] = deepcopy(dependencies[location...])
                # Walking through door creates dependency
                if isdoor(next_id)
                    push!(dependencies[next_loc...], door2key(next_id))
                end
                # Store keys in a separate Dict for easy access
                if iskey(next_id)
                    all_keys[next_id] = next_loc
                    # All squares past this key technically require gaining the
                    # key on this square in order to access them...
                    push!(dependencies[next_loc...], next_id)
                end
            end
        end
    end

    # Key location itself should not be dependent on gaining the key
    for (k,loc) in all_keys
        deleteat!(dependencies[loc...], findall(x->x==k, dependencies[loc...]))
    end
    return (dependencies,all_keys)
end

# Flood fill from starting location to compute distances, ignoring doors
function flood_fill_distance(maze, start)
    # Initialize flood fill of maze from location = start
    distances = UNKNOWN .* ones(Int,size(maze.map))
    distances[start...] = 0
    to_explore = [start]

    # BFS to explore maze, avoiding walls
    while !isempty(to_explore)
        location = popfirst!(to_explore)
        for dir = NORTH:EAST
            next_loc = dir2ind(location,dir)
            next_id = maze.map[next_loc...]
            # Only visit unvisited non-wall locations
            if next_id != WALL && distances[next_loc...] < 0
                push!(to_explore, next_loc)
                distances[next_loc...] = distances[location...]+1
            end
        end
    end
    return distances
end

# Returns matrix with matrix[(i,j)] the distance from key i to j, ignoring doors
function create_distance_matrix(maze, all_keys)
    distance_matrix = Dict{Tuple{Int8,Int8},Int}()
    for (k,loc) in all_keys
        distances = flood_fill_distance(maze,loc)
        for (k2,loc2) in all_keys
            dist = distances[loc2...]
            distance_matrix[(k,k2)] = dist
        end
    end

    # Replace diagonal of matrix with distance to starting location
    distances = flood_fill_distance(maze, maze.entrance)
    for (k,loc) in all_keys
        dist = distances[loc...]
        distance_matrix[(k,k)] = dist
    end
    return distance_matrix
end

# Print the distance matrix as a matrix in order to better visualize
function print_dist_mat(distance_matrix, all_keys)
    for k in keys(all_keys)
        print(Char(k), ": ")
        for k2 in keys(all_keys)
            print(distance_matrix[(k,k2)]," ")
        end
        println()
    end
end

mutable struct KeyVertex
    id::Int8
    # All keys (excluding this one) necessarily collected to reach this key
    prev_collected::Array{Int8,1}
end

# Creates a graph where each vertex is a key and a dependency means that in
# order to reach that key you have to first have previous key
function create_dependency_graph(dependencies, all_keys)
    # Initialize graph without dependencies
    graph_dict = Dict{Int8,KeyVertex}()
    visited = Dict{Int8,Bool}()
    for k in keys(all_keys)
        graph_dict[k] = KeyVertex(k,[])
        visited[k] = false
    end

    # Connect vertices to direct dependencies
    for (k,loc) in all_keys
        graph_dict[k].prev_collected = deepcopy(dependencies[loc...])
        if graph_dict[k].prev_collected == []
            visited[k] = true
        end
    end

    # BFS to connect all vertices to all dependencies
    while !all(values(visited))
        for (k,loc) in all_keys
            if !visited[k]
                # Can only expand if all parents have been expanded
                ready_to_expand = true
                for k_parent in graph_dict[k].prev_collected
                    if !visited[k_parent]
                        ready_to_expand = false
                    end
                end
                # Expand out all parents (direct and indirect)
                if ready_to_expand
                    new_list = deepcopy(graph_dict[k].prev_collected)
                    for k_parent in graph_dict[k].prev_collected
                        for k_grandp in graph_dict[k_parent].prev_collected
                            if k_grandp ∉ new_list
                                push!(new_list, k_grandp)
                            end
                        end
                    end
                    graph_dict[k].prev_collected = new_list
                    visited[k] = true
                end
            end
        end
    end

    @assert all(values(visited))
    return graph_dict
end

# Computes the distance you would have to travel to collect this key permutation
function distance_of_permutation(perm, distance_matrix)
    # Distance to starting key is on the diagonal
    dist = distance_matrix[(perm[1],perm[1])]
    for i = 1:length(perm)-1
        dist += distance_matrix[(perm[i],perm[i+1])]
    end
    return dist
end

# Generates all permutations of length of graph_dict s.t. dependencies are valid
# and compute the minimum distance to travel amongst the maze to all of them
function compute_minimum_distance(graph_dict, distance_matrix)
    so_far = Int8[]
    n = length(graph_dict)
    it = 0
    min_dist = typemax(Int)
    correct_perm = UNKNOWN

    # Pushes to all_permutations where so_far = unfinished list to complete
    function perm_recursion(curr_dist)
        # Short-circuit if we've already over-stepped the min distance
        if curr_dist >= min_dist
            return
        end
        # Base case: final distance is new minimum distance
        if length(so_far) == n
            min_dist = curr_dist
            correct_perm = deepcopy(so_far)

            it += 1
            println(it, ": ",so_far, " @ ",min_dist)
            return
        end
        # Recursive case: Check all possible next keys and repeat
        for k in keys(graph_dict)
            if k ∉ so_far && issubset(graph_dict[k].prev_collected, so_far)
                dist = 0
                if isempty(so_far)
                    dist = distance_matrix[(k,k)]
                else
                    dist = distance_matrix[(so_far[end],k)]
                end

                push!(so_far, k)
                perm_recursion(curr_dist+dist)
                pop!(so_far)
            end
        end
    end
    # Kickstart algorithm with empty list of so_far
    perm_recursion(0)

    return (min_dist, correct_perm)
end

# Returns the optimal number of steps needed to collect all keys
function explore_maze(maze)
    (dependencies, all_keys) = flood_fill_dependency(maze, maze.entrance)
    distance_matrix = create_distance_matrix(maze, all_keys)
    graph_dict = create_dependency_graph(dependencies, all_keys)
    for (k,v) in graph_dict
       println("$(Char(k)) => $(Char.(v.prev_collected))")
    end
    (min_dist, correct_perm) = compute_minimum_distance(graph_dict, distance_matrix)
end

# Solves day 18-1
function min_distance(filename="day18.input")
    maze = init_maze(filename)
    explore_maze(maze)
    # Final answer = [119, 105, 118, 121, 106, 100, 115, 114, 111, 113, 116, 117, 108, 101, 122, 103, 110, 120, 112, 102, 98, 107, 99, 104, 97, 109]
    # in 4668 steps
end
