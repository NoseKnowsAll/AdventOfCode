module ASCII

include("intcode.jl")

const SUCCESS = IntCode.SUCCESS
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

# Run program once, regardless of output
function interpret_program!(program::IntCode.Program)
    IntCode.interpret_program!(program)
end

# Run program until output is breakpoint (default = '\n')
function run_to_enter!(program::IntCode.Program, store_output=false, breakpoint='\n')
    finished = false
    error_code = IntCode.SUCCESS
    output_string = ""
    while !finished
        error_code = interpret_program!(program)
        if program.outputs[end] == Int(breakpoint)
            finished = true
        elseif store_output
            output_string *= Char(program.outputs[end])
        end
    end
    if store_output
        return (error_code, output_string)
    else
        return error_code
    end
end

end
