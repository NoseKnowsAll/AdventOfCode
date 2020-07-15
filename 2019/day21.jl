include("intcode.jl")

module ASCII

include("intcode.jl")

const MAX_INPUT_LENGTH = 15
const UNKNOWN = -1
const TUMBLE = 4
const SCAFFOLD = 5
const MAX_ASCII = Int('z')

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

# Initialize program for running spring script
function init_program(filename)::IntCode.Program
    file = open(filename)
    string = readline(file)
    close(file)

    program = IntCode.initialize_program(string)
    IntCode.single_output!(program)

    return program
end

# Input string to program, one ASCII code at a time
function input_argument!(program::IntCode.Program, input_string)
    if length(input_string) > MAX_INPUT_LENGTH # Not including endline
        error("routine is too long for input!")
    end
    inputs = Int.(collect(input_string))
    for i = 1:length(inputs)
        push!(program.inputs, inputs[i])
    end
    push!(program.inputs, Int('\n')) # Always end with an endline
end

# Run program until output is breakpoint (default = '\n')
function run_to_enter!(program::IntCode.Program, breakpoint='\n', show_output=false)
    finished = false
    error_code = IntCode.halt
    while !finished
        error_code = IntCode.interpret_program!(program)
        if program.outputs[end] == Int(breakpoint)
            finished = true
            if show_output
                println()
            end
        elseif show_output
            print(Char(program.outputs[end]))
        end
    end
    return error_code
end

# Supply springscript to program
function supply_springscript!(program::IntCode.Program, script, walk="WALK")
    for i = 1:length(script)
        input_argument!(program, script[i])
    end
    input_argument!(program, walk)
    run_to_enter!(program)
    run_to_enter!(program)
    run_to_enter!(program)
end

# Prints the droid's last moments to the console
function show_last_moments!(program)
    breakpoint = '\n'
    finished = false
    while !finished
        error_code = run_to_enter!(program, breakpoint, true)
        finished = (error_code == IntCode.SUCCESS)
    end
end

# Runs springscript until either inevitable death or solution is attained
function run_springscript!(program::IntCode.Program)
    IntCode.interpret_program!(program)
    IntCode.interpret_program!(program)
    if program.outputs[end] > MAX_ASCII
        return program.outputs[end]
    else
        show_last_moments!(program)
    end
end

end

# Solves day 21-1
function hull_damage(filename="day21.input")
    program = ASCII.init_program(filename)
    # Max of 15 strings
    #script = ["NOT A J","NOT B T", "OR T J", "NOT C J", "OR T J", "AND D J"]
    #script = ["OR A T", "OR C J", "OR J T", "NOT T J", "NOT C T", "NOT T T", "AND D T", "OR T J"]
    script = ["OR A T","OR B J","OR J T","NOT T J","NOT C T","AND T J","NOT A T","NOT T T","AND B T","AND C T","NOT T T","OR T J","AND D J"]
    ASCII.supply_springscript!(program, script)
    ASCII.run_springscript!(program)
end
