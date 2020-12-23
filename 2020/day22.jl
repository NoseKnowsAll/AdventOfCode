include("utility.jl")

" Read deck from file into two arrays "
function read_decks(filename)
    all_groups = enter_separated_read(filename)
    player1 = parse.(Int, all_groups[1][2:end])
    player2 = parse.(Int, all_groups[2][2:end])
    return player1,player2
end
" Advance one round of normal combat "
function one_round!(player1, player2)
    card1 = popfirst!(player1)
    card2 = popfirst!(player2)
    if card1 > card2
        push!(player1, card1)
        push!(player1, card2)
    else
        push!(player2, card2)
        push!(player2, card1)
    end
end
" Compute the score of a given players deck "
function score(player)
    (length(player):-1:1)'*player
end
" Play a game of normal combat until one player wins "
function play_combat!(player1, player2)
    rounds = 0
    while !(isempty(player1) || isempty(player2))
        one_round!(player1, player2)
        rounds += 1
    end
    if isempty(player1)
        return 2, score(player2)
    elseif isempty(player2)
        return 1, score(player1)
    end
end
" Solve Day 22-1 "
function winning_score(filename="day22.input")
    player1,player2 = read_decks(filename)
    play_combat!(player1,player2)
end
" Play a game of recursive combat until one player wins "
function play_recursive_combat!(player1, player2)
    history = Set{Int}()
    SEPARATOR = 10^7
    winner = 0
    while !(isempty(player1) || isempty(player2))
        # Codify current state into a single Int to save on storage
        current_state = score(player1)+SEPARATOR*score(player2)
        if current_state ∈ history
            # Player 1 instantly wins if we've been here before
            return 1, score(player1)
        end
        push!(history, current_state)
        card1 = popfirst!(player1)
        card2 = popfirst!(player2)
        if card1 <= length(player1) && card2 <= length(player2)
            # Recursively play a game of combat to determine winner of round
            winner, _ = play_recursive_combat!(player1[1:card1], player2[1:card2])
        else
            # Play a normal round of combat to determine winner
            winner = (card1 > card2) ? 1 : 2
        end
        if winner == 1
            push!(player1, card1)
            push!(player1, card2)
        else
            push!(player2, card2)
            push!(player2, card1)
        end
    end
    if isempty(player1)
        return 2, score(player2)
    elseif isempty(player2)
        return 1, score(player1)
    end
end
" Solve Day 22-2 "
function winning_score_recursive(filename="day22.input")
    player1,player2 = read_decks(filename)
    play_recursive_combat!(player1,player2)
end
