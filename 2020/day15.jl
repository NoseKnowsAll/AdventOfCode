get_numbers_example() = [0,3,6] # Example numbers for debugging
get_numbers() = [6,19,0,5,7,13,1] # No file necessary
" Play the game using given `starting_numbers` until we reach round `MAX_ROUND`"
function play_game(starting_numbers, MAX_ROUND)
    turn_num_spoken = Dict{Int,Int}() # Number -> turn number was spoken
    turn_num_spoken_before = Dict{Int,Int}() # Number -> previous turn number was spoken
    for i = 1:length(starting_numbers)
        turn_num_spoken[starting_numbers[i]] = i
    end
    last_num_spoken = starting_numbers[end]
    first_timer = true
    for i = length(starting_numbers)+1:MAX_ROUND
        if first_timer
            last_num_spoken = 0 # Current player says 0 if first time for last number
        else
            # Current player says difference in turns between last number being said
            last_num_spoken = turn_num_spoken[last_num_spoken] - turn_num_spoken_before[last_num_spoken]
        end
        first_timer = (last_num_spoken ∉ keys(turn_num_spoken))
        if !first_timer
            turn_num_spoken_before[last_num_spoken] = turn_num_spoken[last_num_spoken]
        end
        turn_num_spoken[last_num_spoken] = i
    end
    return last_num_spoken
end
" Solve Day 15-1 "
function memory_game_2020()
    MAX_ROUND = 2020
    numbers = get_numbers()
    play_game(numbers, MAX_ROUND)
end
" Solve Day 15-2 "
function memory_game_30000000()
    MAX_ROUND = 30000000
    numbers = get_numbers()
    play_game(numbers, MAX_ROUND)
end
