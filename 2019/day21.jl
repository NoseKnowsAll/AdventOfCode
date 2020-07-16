include("ascii.jl")

# Supply springscript to program
function supply_springscript!(program::ASCII.IntCode.Program, script, finalize_string)
    ASCII.run_to_enter!(program) # "Input instructions:"
    for i = 1:length(script)
        ASCII.input_argument!(program, script[i])
    end
    ASCII.input_argument!(program, finalize_string) # "WALK" or "RUN"
    ASCII.run_to_enter!(program) # '\n'
end

# Prints the droid's last moments to the console
function show_last_moments!(program)
    finished = false
    while !finished
        error_code = ASCII.run_to_enter!(program, true)
        finished = (error_code == IntCode.SUCCESS)
    end
end

# Runs springscript until either inevitable death or solution is attained
function run_springscript!(program::ASCII.IntCode.Program)
    ASCII.run_to_enter!(program) # "[finalize_string]ing..."
    ASCII.run_to_enter!(program) # '\n'

    ASCII.IntCode.interpret_program!(program) # Actually run program
    if program.outputs[end] > ASCII.MAX_ASCII
        return program.outputs[end]
    else
        show_last_moments!(program)
    end
end

# Solves day 21-1
function hull_damage(filename="day21.input")
    program = ASCII.init_program(filename)
    # Max of 15 strings
    # if the gap is at least 2, make sure to end just after it
    # otherwise if there's any single gap at all, just jump
    # and ground to jump to is solid, just jump
    # [!(B || !C) && D] || !A
    script = ["NOT B J", "NOT C T", "OR T J", "AND D J", "NOT A T", "OR T J"]
    supply_springscript!(program, script, "WALK")
    run_springscript!(program)
end

# Solves day 22-1
function hull_damage_run(filename="day21.input")
    program = ASCII.init_program(filename)
    # Same logic as before, but we also plan wrt H
    # If H is not ground, there should be two jumps between A and H
    # But if H is hole, then we have to jump after D, so necessarily E is safe
    # and we jump over H after E
    # [!(B || !C) && D && H] || !A
    script = ["NOT B J", "NOT C T", "OR T J", "AND D J", "AND H J", "NOT A T", "OR T J"]
    supply_springscript!(program, script, "RUN")
    run_springscript!(program)
end
