const UNKNOWN = -1
const PASSAGE = 0
const WALL = 1
const ENTRANCE = 2
const EXIT = 3
const PORTAL = 4

# Teleporter to/from loc1/loc2
mutable struct Portal
    name::String
    loc1::Array
    loc2::Array
end

# Information about maze
mutable struct Maze
    map::Array
    entrance::Array
    exit::Array
    portals::Dict{String,Portal}
end

# Returns the id corresponding to a given input file character
function char2id(char)
    id = WALL
    if char == '#'
        id = WALL
    elseif char == '.'
        id = PASSAGE
    else
        id = UNKNOWN
    end
    return id
end

# Import maze from filename
function read_maze(filename)
    PADDING = 2 # characters needed to describe portals
    all_lines = readlines(filename)
    width = length(all_lines[1+PADDING])
    while all_lines[1+PADDING][width] == ' '
        width -= 1
    end
    width -= PADDING # IGNORE LEFT PORTAL CHARACTERS
    height = length(all_lines) - 2*PADDING   # IGNORE TOP+BOTTOM PORTAL CHARACTERS
    maze = Maze(UNKNOWN.*ones(Int8,height,width), [UNKNOWN, UNKNOWN],
                [UNKNOWN,UNKNOWN], Dict{String,Portal}())

    # Initialize the maze at location [i,j] to be a portal
    function init_portal!(i, j, dir, outside)
        maze.map[i,j] = PORTAL
        file_i = i+PADDING
        file_j = j+PADDING
        char1 = all_lines[file_i+1*dir[1]][file_j+1*dir[2]]
        char2 = all_lines[file_i+2*dir[1]][file_j+2*dir[2]]
        name = String([char1,char2])
        name2 = String([char2,char1])
        if name ∈ keys(maze.portals)
            if outside
                maze.portals[name].loc2 = [i,j]
            else
                maze.portals[name].loc1 = [i,j]
            end
        elseif name2 ∈ keys(maze.portals)
            if outside
                maze.portals[name2].loc2 = [i,j]
            else
                maze.portals[name2].loc1 = [i,j]
            end
        else
            if outside
                maze.portals[name] = Portal(name, [UNKNOWN,UNKNOWN], [i,j])
            else
                maze.portals[name] = Portal(name, [i,j], [UNKNOWN,UNKNOWN])
            end
        end
    end
    # (i,j) inside these outer bounds are blank or portal names
    inner_region_rows = [height, 1]
    inner_region_cols = [width, 1]
    # Interpret maze from file
    for i = 1:height
        file_i = i+PADDING
        for j = 1:width
            file_j = j+PADDING
            maze.map[i,j] = char2id(all_lines[file_i][file_j])
            if maze.map[i,j] == UNKNOWN
                inner_region_rows[1] = min(inner_region_rows[1],i)
                inner_region_rows[2] = max(inner_region_rows[2],i)
                inner_region_cols[1] = min(inner_region_cols[1],j)
                inner_region_cols[2] = max(inner_region_cols[2],j)
            end
        end
    end

    # Initialize all portals from just outside the walls of maze
    i = 1 # Top
    dir = [-1,0]
    for j = 1:width
        if maze.map[i,j]==PASSAGE
            init_portal!(i,j,dir,true)
        end
    end
    i = inner_region_rows[2]+1 # Inner bottom
    for j = inner_region_cols[1]:inner_region_cols[2]
        if maze.map[i,j] == PASSAGE
            init_portal!(i,j,dir,false)
        end
    end
    i = height # Bottom
    dir = [1,0]
    for j = 1:width
        if maze.map[i,j] == PASSAGE
            init_portal!(i,j,dir,true)
        end
    end
    i = inner_region_rows[1]-1 # Inner top
    for j = inner_region_cols[1]:inner_region_cols[2]
        if maze.map[i,j] == PASSAGE
            init_portal!(i,j,dir,false)
        end
    end

    j = 1 # Left
    dir = [0,-1]
    for i = 1:height
        if maze.map[i,j] == PASSAGE
            init_portal!(i,j,dir,true)
        end
    end
    j = inner_region_cols[2]+1 # Inner right
    for i = inner_region_rows[1]:inner_region_rows[2]
        if maze.map[i,j] == PASSAGE
            init_portal!(i,j,dir,false)
        end
    end
    j = width # Right
    dir = [0,1]
    for i = 1:height
        if maze.map[i,j] == PASSAGE
            init_portal!(i,j,dir,true)
        end
    end
    j = inner_region_cols[1]-1 # Inner left
    for i = inner_region_rows[1]:inner_region_rows[2]
        if maze.map[i,j] == PASSAGE
            init_portal!(i,j,dir,false)
        end
    end

    # Lastly initialize the entrance and exit
    for portal_name in keys(maze.portals)
        if portal_name == "AA"
            maze.entrance = maze.portals[portal_name].loc2
            maze.map[maze.entrance...] = ENTRANCE
        elseif portal_name == "ZZ"
            maze.exit = maze.portals[portal_name].loc2
            maze.map[maze.exit...] = EXIT
        end
    end

    return maze
end

# Directions for use in exploring maze
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

# Helper function to check if a given location is in-bounds of our maze
function inbounds(maze::Maze, loc)
    return 1<=loc[1]<=size(maze.map,1) && 1<=loc[2]<=size(maze.map,2)
end

# Returns a list of neighbor to this location, including portal jumps
function get_neighbors(maze::Maze, loc)
    neighbors = []
    for dir = NORTH:EAST
        next_loc = dir2ind(loc,dir)
        if inbounds(maze, next_loc) && maze.map[next_loc...] != UNKNOWN
            if maze.map[next_loc...] != WALL
                # All non-WALL directions should be added to neighbors
                push!(neighbors, next_loc)
            end
        elseif maze.map[loc...] == PORTAL
            # Portals only have one "out-of-bounds" direction - portal direction
            for (name,portal) in maze.portals
                if portal.loc1 == loc
                    push!(neighbors, portal.loc2)
                    break
                elseif portal.loc2 == loc
                    push!(neighbors, portal.loc1)
                    break
                end
            end
        end
    end
    return neighbors
end

# Flood fill from given location, using portals
function flood_fill_portal(maze::Maze, start)
    # Initialize flood fill of maze from location = start
    distances = UNKNOWN .* ones(Int,size(maze.map))
    distances[start...] = 0
    to_explore = [start]

    # BFS to explore maze, avoiding walls and going through portals
    while !isempty(to_explore)
        location = popfirst!(to_explore)
        neighbors = get_neighbors(maze, location)
        for next_loc in neighbors
            # Only visit unvisited neighbors
            if distances[next_loc...] < 0
                push!(to_explore, next_loc)
                distances[next_loc...] = distances[location...]+1
            end
        end
    end
    return distances
end

# Solves day 20-1
function min_steps(filename="day20.input")
    maze = read_maze(filename)
    distances = flood_fill_portal(maze, maze.entrance)
    return distances[maze.exit...]
end

# Solves day 20-2
function recursive_maze(filename="day20.input")
    maze = read_maze(filename)
    #distances = flood_fill_recursive_portal(maze, maze.entrance)
    #return distances[maze.exit...][1]
end
