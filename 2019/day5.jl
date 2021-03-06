include("intcode.jl")

# Solves day 5-1
function print_diagnostic_codes(filename="day5.input")
    global MAX_INSTRUCTION
    MAX_INSTRUCTION = 4

    file = open(filename)
    string = readline(file)
    close(file)

    program = IntCode.initialize_program(string)
    input_value = 1
    program.inputs = [input_value]
    IntCode.interpret_program!(program)

    println("outputs = $(program.outputs)")
end

# Solves day 5-2
function extend_thermal_radiators(filename="day5.input")
    global MAX_INSTRUCTION
    MAX_INSTRUCTION = 8

    file = open(filename)
    string = readline(file)
    close(file)

    program = IntCode.initialize_program(string)
    input_value = 5
    program.inputs = [input_value]
    IntCode.interpret_program!(program)

    println("diagnostic code = $(program.outputs[end])")

end
