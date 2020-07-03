include("intcode.jl")

# Unit test of new features to ensure IntCode dictionary is working
function test_features()
    global MAX_INSTRUCTION
    MAX_INSTRUCTION = 9

    # Produces a copy of itself as output
    string = "109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99"
    program = IntCode.initialize_program(string)
    println(program)
    IntCode.interpret_program!(program)
    println(program.outputs)

    # Outputs a 16 digit number
    string = "1102,34915192,34915192,7,4,7,99,0"
    program = IntCode.initialize_program(string)
    println(program)
    IntCode.interpret_program!(program)
    println(program.outputs)

    # Outputs the large number in the center
    string = "104,1125899906842624,99"
    program = IntCode.initialize_program(string)
    println(program)
    IntCode.interpret_program!(program)
    println(program.outputs)
end

# Solves day 9-1
function boost_program(filename="day9.input")
    global MAX_INSTRUCTION
    MAX_INSTRUCTION = 9

    file = open(filename)
    string = readline(file)
    close(file)
    program = IntCode.initialize_program(string)
    push!(program.inputs, 1) # test value = 1
    IntCode.interpret_program!(program)
    return program.outputs

end

# Solves day 9-2
function distress_coordinates(filename="day9.input")
    global MAX_INSTRUCTION
    MAX_INSTRUCTION = 9

    file = open(filename)
    string = readline(file)
    close(file)
    program = IntCode.initialize_program(string)
    push!(program.inputs, 2) # input instruction = 2
    IntCode.interpret_program!(program)
    return program.outputs

end
