import Combinatorics

include("intcode.jl")

# Solves day 7-1
function highest_thruster(filename="day7.input")
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
