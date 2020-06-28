# Reinterprets the string from the file as an array of integers to run as a program
function initialize_program(string)
    array_string = split(string,',')
    program = parse.(Int64,array_string)
    return program
end

# Actually evaluates the opcode program, updating program as it runs
function interpret_program!(program)
    index = 1
    opcode = program[index]
    while opcode != 99
        from1 = program[index+1]+1 # ZERO-INDEXED INPUT
        from2 = program[index+2]+1 # ZERO-INDEXED INPUT
        to    = program[index+3]+1 # ZERO-INDEXED INPUT

        if opcode == 1 # add
            program[to] = program[from1] + program[from2]
        elseif opcode == 2 # multiply
            program[to] = program[from1] * program[from2]
        else
            error("INVALID OPCODE")
        end

        index += 4
        opcode = program[index]
    end
end

# Solve day2-1
function restore_gravity(filename="day2.input")
    file = open(filename)
    string = readline(file)
    close(file)

    program = initialize_program(string)
    # 1202 program:
    program[2] = 12
    program[3] = 2
    interpret_program!(program)
    return program[1]
end
