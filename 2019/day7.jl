import Combinatorics

include("intcode.jl")

# Solves day 7-1
function highest_thruster(filename="day7.input")
    global MAX_INSTRUCTION
    MAX_INSTRUCTION = 8

    file = open(filename)
    string = readline(file)
    close(file)
    master_program = IntCode.initialize_program(string)

    num_amps = 5
    max_output = 0
    max_signal = 0:num_amps-1
    for signal in Combinatorics.permutations(0:num_amps-1, num_amps)

        # Evaluate consecutive programs given specific phase setting
        previous_output = 0
        programs = [deepcopy(master_program) for i = 1:num_amps]
        for i = 1:num_amps
            programs[i].inputs = [signal[i], previous_output]
            IntCode.interpret_program!(programs[i])
            previous_output = programs[i].outputs[1]
        end

        # Check for maximum output signal
        if previous_output > max_output
            max_output = previous_output
            max_signal = signal
        end
    end

    println("max signal = $max_signal")
    return max_output
end

# Solves day 7-2
function highest_thruster_loop(filename="day7.input")
    global MAX_INSTRUCTION
    MAX_INSTRUCTION = 4

    file = open(filename)
    string = readline(file)
    #string = "3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5"
    #string = "3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,-5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10"
    close(file)
    master_program = IntCode.initialize_program(string)
    IntCode.single_output!(master_program)

    num_amps = 5
    max_output = 0
    max_signal = num_amps:2*num_amps-1
    for signal in Combinatorics.permutations(num_amps:2*num_amps-1, num_amps)

        # Initialize consecutive programs given specific phase setting
        programs = [deepcopy(master_program) for i = 1:num_amps]
        for i = 1:num_amps
            programs[i].inputs = [signal[i]]
        end

        # Loop over all programs, constantly running until they all halt
        curr_program = 1
        previous_output = 0
        finished = false
        while !finished
            # Add previous output to current program's input
            push!(programs[curr_program].inputs, previous_output)
            error_code = IntCode.interpret_program!(programs[curr_program])

            # Only Amp E (programs[num_amps]) can return final output signal
            if error_code == IntCode.SUCCESS && curr_program == num_amps
                finished = true
            end
            previous_output = programs[curr_program].outputs[end]
            curr_program = mod(curr_program, num_amps) + 1

        end

        # Check for maximum output signal
        if previous_output > max_output
            max_output = previous_output
            max_signal = signal
        end
    end

    println("max signal = $max_signal")
    return max_output
end
