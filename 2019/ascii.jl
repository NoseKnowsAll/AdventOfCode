module ASCII

include("intcode.jl")

const MAX_INPUT_LENGTH = 20
const MAX_ASCII = Int('z')

# Initialize program for running ASCII-capable code
function init_program(filename)
    file = open(filename)
    string = readline(file)
    close(file)

    program = IntCode.initialize_program(string)
    IntCode.single_output!(program)

    return program
end

# Input string to program, one ASCII code at a time
function input_argument!(program::IntCode.Program, input_string)
    if length(input_string) > MAX_INPUT_LENGTH + 1 # Not including endline
        error("routine is too long for input!")
    end
    inputs = Int.(collect(input_string))
    for i = 1:length(inputs)
        push!(program.inputs, inputs[i])
    end
    push!(program.inputs, Int('\n')) # Always end with an endline
end

# Run program until output is breakpoint (default = '\n')
function run_to_enter!(program::IntCode.Program, show_output=false, breakpoint='\n')
    finished = false
    error_code = IntCode.SUCCESS
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

end
