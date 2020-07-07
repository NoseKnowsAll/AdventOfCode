include("intcode.jl")

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

# Possible status commands
const UNKNOWN = -1
const WALL = 0
const EMPTY = 1
const OXYGEN = 2

# The entire space state
mutable struct Space
    map::Array
    droid::Array
    previous::Array
end

# Override Base.show to allow for viewing space state
function Base.show(io::IO, space::Space)
    function id2char(id)
        char = " "
        if id == EMPTY
            char = " "
        elseif id == WALL
            char = "#"
        elseif id == OXYGEN
            char = "O"
        elseif id == UNKNOWN
            char = "?"
        end
        return char
    end
    for i = 1:size(space.map,1)
        for j = 1:size(space.map,2)
            if space.droid == [i,j]
                print(io,"D")
            else
                print(io,"$(id2char(space.map[i,j]))")
            end
        end
        println(io, "")
    end
end

# Initialize program for reading in game info
function init_program(filename)::IntCode.Program
    file = open(filename)
    string = readline(file)
    close(file)

    program = IntCode.initialize_program(string)
    IntCode.single_output!(program)

    return program
end

# Initialize space struct for exploration
function init_space(n=22)
    # Start droid at center position [n,n]
    space = Space(UNKNOWN.*ones(Int, 2*n+1,2*n+1), [n,n],
        UNKNOWN.*ones(Int,2,2*n+1,2*n+1))
    space.map[space.droid...] = EMPTY
    # Ensure previous[start] is not a neighbor to trigger end of algorithm
    space.previous[:,n,n] = [-2,-2]
    return space
end

# Modify Space struct using status
function interpret_status!(space::Space, direction, status)
    if status == WALL
        # No movement occurs
        space.map[dir2ind(space.droid,direction)...] = WALL
    else
        # Droid successfully moves to new location
        new_loc = dir2ind(space.droid,direction)
        space.map[new_loc...] = status
        if space.previous[:,new_loc...] == [UNKNOWN;UNKNOWN]
            space.previous[:,new_loc...] = space.droid
        end
        space.droid = new_loc
    end
end

# Returns the direction necessary to head to in order to run flood fill of maze
function flood_fill_direction(space::Space)
    # Head in an unexplored direction
    for dir = NORTH:EAST
        next_loc = dir2ind(space.droid,dir)
        if space.map[next_loc...] == UNKNOWN
            return dir
        end
    end

    # Return to previous location
    return neighbor2dir(space.droid,space.previous[:,space.droid...])
end

# Run the program to explore all accessible space
function explore_space(program::IntCode.Program)
    space = init_space()
    finished = false
    while !finished
        direction = flood_fill_direction(space)
        if direction == UNKNOWN
            finished = true
        else
            push!(program.inputs, direction)
            IntCode.interpret_program!(program)
            status = program.outputs[end]
            interpret_status!(space, direction, status)
        end
    end
    return space
end

# Breadth first search to compute the minimum distance from start to oxygen
function compute_min_distance(space::Space)
    #oxygen = findfirst(space.map .== 2)
    distances = -1 .* ones(Int, size(space.map,1), size(space.map,2))

    # Seed BFS at starting location
    n = Int((size(space.map,1)-1)/2)
    start = [n,n]
    to_explore = [start]
    distances[start...] = 0
    min_distance = 0

    # BFS through queue of locations to explore
    found_oxygen = false
    while !isempty(to_explore) || !found_oxygen
        current = popfirst!(to_explore)
        for dir = NORTH:EAST
            neighbor = dir2ind(current,dir)
            if space.map[neighbor...] != WALL
                if space.map[neighbor...] == OXYGEN
                    min_distance = distances[current...]+1
                    found_oxygen = true
                    break
                end
                if distances[neighbor...] == -1 # Unvisited locations
                    distances[neighbor...] = distances[current...]+1
                    push!(to_explore, neighbor)
                end
            end
        end
    end

    return min_distance
end

# Solves day 15-1
function min_commands(filename="day15.input")
    program = init_program(filename)
    space = explore_space(program)
    println(space)
    compute_min_distance(space)
end
