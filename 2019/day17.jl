include("ascii.jl")

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
            print(io,"$(id2char(scaffold.map[i,j]))")
        end
        println(io, "")
    end
end

# Create the Scaffolding struct
function init_scaffolding!(program::ASCII.IntCode.Program)::Scaffolding
    # Concatenate output characters to string
    scaffold_strings = String[]
    finished = false
    while !finished
        prev_index = length(program.outputs)
        (error_code, string) = ASCII.run_to_enter!(program, true)
        if length(string) == 0
            finished = true
        else
            push!(scaffold_strings, string)
        end
    end

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
    program = ASCII.init_program(filename)
    scaffold = init_scaffolding!(program)
    # Returns the sum of the alignment parameters
    intersections = scaffold_intersections(scaffold)
    sum_alignment_parameters(intersections)
end

# Supply all arguments to program
function supply_arguments!(program::ASCII.IntCode.Program, solution,A,B,C,cont_feed)
    ASCII.input_argument!(program, solution)
    ASCII.run_to_enter!(program)
    ASCII.input_argument!(program, A)
    ASCII.run_to_enter!(program)
    ASCII.input_argument!(program, B)
    ASCII.run_to_enter!(program)
    ASCII.input_argument!(program, C)
    ASCII.run_to_enter!(program)
    ASCII.input_argument!(program, cont_feed)
    ASCII.run_to_enter!(program)
    ASCII.run_to_enter!(program)
end

# Solves day 17-2
function space_dust(filename="day17.input")
    program = ASCII.init_program(filename)
    # TODO: figure out these strings from the scaffolding itself
    solution = "A,A,B,C,B,C,B,C,B,A"
    A = "R,6,L,12,R,6"
    B = "L,12,R,6,L,8,L,12"
    C = "R,12,L,10,L,10"
    continuous_feed = "n"

    # Wake up robot and supply it its instructions
    program.program[1] = 2
    scaffold = init_scaffolding!(program)
    #println(scaffold)
    supply_arguments!(program, solution,A,B,C,continuous_feed)

    # Run program and reach end of scaffolding
    scaffold = init_scaffolding!(program)
    #println(scaffold)

    # Get final output
    ASCII.interpret_program!(program)
    return program.outputs[end]
end
