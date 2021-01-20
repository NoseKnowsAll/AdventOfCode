include("ascii.jl")

const COMMAND = "Command?"

mutable struct Droid
    inventory::Vector{String}
end

# Return a random direction so that the console isn't needed for exploration
function random_direction()
    dir = rand(1:4)
    if dir == 1
        return "north"
    elseif dir == 2
        return "south"
    elseif dir == 3
        return "east"
    elseif dir == 4
        return "west"
    end
end

# Process shortcuts to allow for faster typing
function process_shortcuts(input_string)
    if input_string == "n"
        return "north"
    elseif input_string == "s"
        return "south"
    elseif input_string == "e"
        return "east"
    elseif input_string == "w"
        return "west"
    end
    if input_string[1:2] == "t "
        return "take"*input_string[2:end]
    elseif input_string[1:2] == "d "
        return "drop"*input_string[2:end]
    end
    return input_string
end

# Update bot inventory by probing the output of program's call to "inv"
function update_bot_inventory!(droid::Droid, program::ASCII.IntCode.Program)
    droid.inventory = Vector{String}()
    ASCII.input_argument!(program, "inv")
    all_strings = ASCII.run_to_string!(program, COMMAND)
    for string in all_strings
        println(string)
        m = match(r"^- (\w+( \w+)*)$", string)
        if !isnothing(m)
            push!(droid.inventory, m[1])
        end
    end
    println(COMMAND)
end

# Checks all combinations of bot inventories in order to pass through checkpoint
function pass_checkpoint!(droid::Droid, program::ASCII.IntCode.Program)
    all_items = deepcopy(droid.inventory)
    states = [deepcopy(all_items)]
    while !isempty(states)
        state = popfirst!(states)
        println("testing state: ", state)
        # Drop all items until we are at given state
        to_drop = setdiff(all_items, state)
        for item in to_drop
            ASCII.input_argument!(program, "drop "*item)
            ASCII.run_to_string!(program, COMMAND)
        end
        # Test given state
        ASCII.input_argument!(program, "south")
        output = ASCII.run_to_string!(program, COMMAND)
        one_line = join(output, "\n")
        if occursin("ejected back", one_line)
            # There's a reason we don't pass
            if occursin("lighter", one_line)
                # We have too much stuff
                for i = 1:length(state)
                    new_state = vcat(state[1:i-1], state[i+1:end])
                    push!(states, new_state)
                end
            end
        else
            # We pass checkpoint!
            println(one_line)
            if occursin("2424308736", one_line)
                println("GAME OVER! Thanks for playing!")
            else
                println(COMMAND)
            end
            break
        end
        for item in to_drop
            ASCII.input_argument!(program, "take "*item)
            ASCII.run_to_string!(program, COMMAND)
        end
    end
end

# Explores the ship and prints reports from droid to console
function explore_ship!(droid::Droid, program::ASCII.IntCode.Program)
    finished = false
    while !finished
        (error_code,string) = ASCII.run_to_enter!(program, true)
        println(string)
        if error_code == ASCII.SUCCESS
            finished = true
        elseif string == COMMAND
            input_string = process_shortcuts(readline())
            if input_string == "inv"
                update_bot_inventory!(droid, program)
                input_string = process_shortcuts(readline())
            elseif input_string == "crack"
                pass_checkpoint!(droid, program)
                input_string = process_shortcuts(readline())
            end

            ASCII.input_argument!(program, input_string)
        end
    end
end

# Solves day 25-1
function airlock_password(filename="day25.input")
    program = ASCII.init_program(filename)
    droid = Droid([])
    println("INSTRUCTIONS:")
    println("MOVE: [n]orth, [s]outh, [e]ast, or [w]est")
    println("INTERACT: [t]ake 'item_name', [d]rop 'item_name'")
    println("INVENTORY: inv")
    println("SOLVE: crack (requires you to type inv first)")
    print("Your mission is to move through pressure-sensitive floor")
    println(" to find the password for the main airlock.")
    explore_ship!(droid, program)
end
