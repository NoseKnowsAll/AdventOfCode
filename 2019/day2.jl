# Reinterprets the string from the file as an array of integers to run as a program
function initialize_program(string)
    array_string = split(string,',')
    program = parse.(Int64,array_string)
    return program
end

# Actually evaluates the opcode program, updating program as it runs
function interpret_program!(program)
    index = 1
    instruction = program[index]
    while instruction != 99
        from1 = program[index+1]+1 # ZERO-INDEXED INPUT
        from2 = program[index+2]+1 # ZERO-INDEXED INPUT
        to    = program[index+3]+1 # ZERO-INDEXED INPUT

        if instruction == 1 # add
            program[to] = program[from1] + program[from2]
        elseif instruction == 2 # multiply
            program[to] = program[from1] * program[from2]
        else
            # an error in interpreting program, not in running this simulation
            #println("INVALID OPCODE INSTRUCTION")
            return -1
        end

        index += 4
        instruction = program[index]
    end
    return 0
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

# Solve day2-2
function determine_input(filename="day2.input")
    file = open(filename)
    string = readline(file)
    close(file)

    master_program = initialize_program(string)

    # Test many different nouns and verbs until we output secret number
    for noun = 0:99
        for verb = 0:99
            program = deepcopy(master_program)
            program[2] = noun
            program[3] = verb
            error_code = interpret_program!(program)
            if error_code == 0 # Sucessful completion
                if program[1] == 19690720 # SECRET NUMBER
                    return 100*noun+verb
                end
            end
        end
    end
end
