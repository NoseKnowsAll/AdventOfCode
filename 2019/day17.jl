include("intcode.jl")

const UNKNOWN = -1
const UP = 0
const DOWN = 1
const LEFT = 2
const RIGHT = 3
const TUMBLE = 4
const SCAFFOLD = 5
const SPACE = 6

# Interprets a character on the map to an integer to be stored
function char2int(char)
    if char == '#'
        return SCAFFOLD
    elseif char == '.'
        return SPACE
    elseif char == '^'
        return UP
    elseif char == 'v'
        return DOWN
    elseif char == '<'
        return LEFT
    elseif char == '>'
        return RIGHT
    elseif char == 'X'
        return TUMBLE
    else
        return UNKNOWN
    end
end

# All information about scaffolding
mutable struct Scaffolding
    map::Array
    robot::Array
end

# Override Base.show to allow for viewing scaffold state
function Base.show(io::IO, scaffold::Scaffolding)
    function id2char(id)
        char = " "
        if id == SPACE
            char = " "
        elseif id == SCAFFOLD
            char = "#"
        elseif id == UP
            char = "^"
        elseif id == DOWN
            char = "v"
        elseif id == LEFT
            char = "<"
        elseif id == RIGHT
            char = ">"
        elseif id == TUMBLE
            char = "X"
        elseif id == UNKNOWN
            char = "?"
        end
        return char
    end
    for i = 1:size(scaffold.map,1)
        for j = 1:size(scaffold.map,2)
#            if space.droid == [i,j]
#                print(io,"D")
#            else
                print(io,"$(id2char(scaffold.map[i,j]))")
#            end
        end
        println(io, "")
    end
end

# Initialize program for reading in Scaffolding
function init_program(filename)::IntCode.Program
    file = open(filename)
    string = readline(file)
    close(file)

    program = IntCode.initialize_program(string)
    IntCode.single_output!(program)

    return program
end

# Create the Scaffolding struct
function init_scaffolding(program::IntCode.Program)::Scaffolding
    # Concatenate output characters to string
    scaffold_string = ""
    finished = false
    while !finished
        error_code = IntCode.interpret_program!(program)
        if error_code == IntCode.SUCCESS
            finished = true
        else
            scaffold_string *= Char(program.outputs[end])
        end
    end
    # end-2 to ignore trailing 2 \n characters
    scaffold_strings = split(scaffold_string[1:end-2], '\n')
    width = length(scaffold_strings[1]) # ASSUMES THEY ARE ALL THE SAME SIZE
    height = length(scaffold_strings)
    scaffold = Scaffolding(UNKNOWN.*ones(Int,height,width),
                            [UNKNOWN,UNKNOWN])
    for i = 1:height
        scaffold.map[i,:] = char2int.(collect(scaffold_strings[i]))
    end
    return scaffold
end

# Returns a list of all scaffolding intersections
function scaffold_intersections(scaffold::Scaffolding)
    intersections = []
    for j = 2:size(scaffold.map,2)-1
        for i = 2:size(scaffold.map,1)-1
            if scaffold.map[i,j] == SCAFFOLD
                if scaffold.map[i-1,j] == SCAFFOLD &&
                    scaffold.map[i+1,j] == SCAFFOLD &&
                    scaffold.map[i,j-1] == SCAFFOLD &&
                    scaffold.map[i,j+1] == SCAFFOLD
                    push!(intersections,[i,j])
                end
            end
        end
    end
    return intersections
end

# Compute the sum of the product of the i-j offsets of all intersections
function sum_alignment_parameters(intersections)
    sum((first.(intersections).-1).*(last.(intersections).-1))
end

# Solves day 17-1
function alignment_parameters(filename="day17.input")
    program = init_program(filename)
    scaffold = init_scaffolding(program)
    println(scaffold)
    # Returns the sum of the alignment parameters
    intersections = scaffold_intersections(scaffold)
    sum_alignment_parameters(intersections)
end
