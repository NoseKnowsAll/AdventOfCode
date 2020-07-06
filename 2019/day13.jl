include("intcode.jl")

const WALL_TILE = 1
const BLOCK_TILE = 2
const PADDLE_TILE = 3
const BALL_TILE = 4

mutable struct Game
    board::Array{Int,2}
    score::Int
    ball_x::Int
    paddle_x::Int
    blocks::Int
end

# Override Base.show to be able to print score and game state
function Base.show(io::IO, game::Game)
    function id2char(id)
        char = " "
        if id == 0
            char = " "
        elseif id == WALL_TILE
            char = "W"
        elseif id == BLOCK_TILE
            char = "B"
        elseif id == PADDLE_TILE
            char = "_"
        elseif id == BALL_TILE
            char = "O"
        end
        return char
    end
    for i = 1:size(game.board,1)
        for j = 1:size(game.board,2)
            print(io,"$(id2char(game.board[i,j])) ")
        end
        println(io, "")
    end
    print(io, "SCORE=$(game.score)")
end

# Runs the program until game completed
function create_game(program::IntCode.Program, ny,nx)::Game
    game = Game(zeros(Int, ny,nx), -1,0,0,0)

    # Create board based on 3 consecutive outputs (x,y,id)
    start_game = false
    while !start_game
        error_code = IntCode.interpret_program!(program)
        if error_code == IntCode.SUCCESS
            break
        end
        x = program.outputs[end]
        IntCode.interpret_program!(program)
        y = program.outputs[end]
        IntCode.interpret_program!(program)
        id = program.outputs[end]
        if (x,y) == (-1,0)
            game.score = id
            start_game = true
        else
            game.board[y+1,x+1] = id # ZERO-INDEXED INPUT
            if id == BLOCK_TILE
                game.blocks += 1
            elseif id == PADDLE_TILE
                game.paddle_x = x+1
            elseif id == BALL_TILE
                game.ball_x = x+1
            end
        end
    end

    return game
end

# Initialize program for reading in game info
function init_program(filename, quarters=0)::IntCode.Program
    file = open(filename)
    string = readline(file)
    close(file)

    program = IntCode.initialize_program(string)
    IntCode.single_output!(program)

    # Insert quarters into program
    if quarters > 0
        program.program[1] = quarters
    end

    return program
end

# Solves day 13-1
function block_tiles(filename="day13.input",ny=21,nx=44)
    program = init_program(filename)
    game = create_game(program, ny,nx)

    println(game)

    # Return the number of block tiles in game board
    game.blocks
end

# Returns the direction you should move the paddle in order to catch ball
function correct_direction(game::Game)
    return sign(game.ball_x - game.paddle_x)
end

# Runs the program during game mode until game is completed
function play_game!(game::Game, program::IntCode.Program)
    # Seed game with input
    push!(program.inputs, correct_direction(game))

    game_won = false
    while !game_won
        error_code = IntCode.interpret_program!(program)
        if error_code == IntCode.SUCCESS
            game_won = true
            break
        end
        x = program.outputs[end]
        IntCode.interpret_program!(program)
        y = program.outputs[end]
        IntCode.interpret_program!(program)
        id = program.outputs[end]
        if (x,y) == (-1,0)
            game.score = id
            #println(game) # debugging and fun to watch
        else
            if game.board[y+1,x+1] == BLOCK_TILE && id != BLOCK_TILE
                game.blocks -= 1
            end
            game.board[y+1,x+1] = id # ZERO-INDEXED INPUT
            #println("board update: ($x,$y) = $id") # debugging
            if id == BLOCK_TILE
                error("should not create blocks while playing")
                game.blocks += 1
            elseif id == PADDLE_TILE
                game.paddle_x = x+1
            elseif id == BALL_TILE
                game.ball_x = x+1
                # Program only asks for input after outputting ball's location
                push!(program.inputs, correct_direction(game))
            end
        end
    end
end

# Solves day 13-2
function play_game(filename="day13.input",ny=21,nx=44)
    # Insert 2 quarters into game to start
    program = init_program(filename, 2)
    game = create_game(program, ny,nx)
    # Play block break game
    play_game!(game, program)
    # Return final score
    return game.score

end
