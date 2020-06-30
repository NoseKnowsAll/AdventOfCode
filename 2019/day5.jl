include("intcode.jl")

function print_diagnostic_codes(filename="day5.input")
    global MAX_INSTRUCTION
    MAX_INSTRUCTION = 4

    file = open(filename)
    string = readline(file)
    close(file)

    program = IntCode.initialize_program(string)
    input_value = 1
    IntCode.interpret_program!(program, input_value=1)
    return program[1]
end

function extend_thermal_radiators(filename="day5.input")
    global MAX_INSTRUCTION
    MAX_INSTRUCTION = 8

    # TODO
end
