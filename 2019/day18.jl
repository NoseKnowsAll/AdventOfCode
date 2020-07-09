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

    total_keys = 0
    for (i,line) in enumerate(eachline(filename))
        for j = 1:length(line)
            maze.map[i,j] = char2id(line[j])
            if maze.map[i,j] == ENTRANCE
                maze.entrance = [i,j]
                maze.map[i,j] = PASSAGE
            end
            if PASSAGE != maze.map[i,j] != WALL
                total_keys+=1
            end
        end
    end
    maze.total_keys = Int(total_keys/2)

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

# Flood fill from starting location to as many keys as possible
function flood_fill(maze, start, collected_keys)
    # Initialize flood fill of maze from location = start
    previous = zeros(Int8,2,size(maze.map,1),size(maze.map,2))
    previous[:,start...] = [UNKNOWN,UNKNOWN]
    distances = UNKNOWN .* ones(Int,size(maze.map))
    distances[start...] = 0
    to_explore = [start]
    reachable_keys = Dict{Int,Array{Int8,1}}()

    # BFS to explore maze, avoiding walls
    while !isempty(to_explore)
        location = popfirst!(to_explore)
        for dir = NORTH:EAST
            next_loc = dir2ind(location,dir)
            next_id = maze.map[next_loc...]
            # Only visit unvisited non-wall locations
            if next_id != WALL && distances[next_loc...] < 0
                # Only walk through doors that are already opened
                if !isdoor(next_id) || door2key(next_id) ∈ collected_keys
                    if iskey(next_id)
                        # Only can collect keys that are not yet collected
                        if next_id ∉ collected_keys
                            reachable_keys[next_id] = next_loc
                        end
                    end
                    push!(to_explore, next_loc)
                    distances[next_loc...] = distances[location...]+1
                end
            end
        end
    end
    # TODO: will eventually need to return the computed distances as well
    return reachable_keys
end

# Returns the optimal number of steps needed to collect all keys
function explore_maze(maze)
    collected_keys = []
    flood_fill(maze, maze.entrance, collected_keys)

    # TODO: figure out which key to go for next
    # I need an obvious short circuit to avoid going way out of the way
    # for keys super far away...
    #for i = 1:maze.total_keys
    #end
end

# Solves day 18-1
function min_distance(filename="day18.input")
    maze = init_maze(filename)
    explore_maze(maze)
    #println(maze)
end
