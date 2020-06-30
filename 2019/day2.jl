include("intcode.jl")

global MAX_INSTRUCTION
MAX_INSTRUCTION = 2

# Solve day2-1
function restore_gravity(filename="day2.input")
    file = open(filename)
    string = readline(file)
    close(file)

    program = IntCode.initialize_program(string)
    # 1202 program:
    program[2] = 12
    program[3] = 2
    IntCode.interpret_program!(program)
    return program[1]
end

# Solve day2-2
function determine_input(filename="day2.input")
    file = open(filename)
    string = readline(file)
    close(file)

    master_program = IntCode.initialize_program(string)

    # Test many different nouns and verbs until we output secret number
    for noun = 0:99
        for verb = 0:99
            program = deepcopy(master_program)
            program[2] = noun
            program[3] = verb
            error_code = IntCode.interpret_program!(program)
            if error_code == 0 # Sucessful completion
                if program[1] == 19690720 # SECRET NUMBER
                    return 100*noun+verb
                end
            end
        end
    end
end
