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
    maze = Maze(ones(Int8,height,width),[0,0])

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

# Solves day 18-1
function min_distance(filename="day18.input")
    maze = init_maze(filename)
end
