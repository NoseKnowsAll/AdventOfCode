" Possible colors/flips for a given tile "
const WHITE = 0
const BLACK = 1
" Tile defined at a given location in hexatille pattern, with a given color/flip "
mutable struct Tile
    # Origin is (0,0). Odd rows (x,0) are shifted a half-tile to the left==W
    location
    # Default is to start with WHITE up
    flip
end
" Flip WHITE to/from BLACK "
flip(color) = 1-color
" Possible directions in hexatille pattern "
const E = 0
const SE = 1
const SW = 2
const W = 3
const NW = 4
const NE = 5
" Read in filename into a sequence of directions to reach tile to flip "
function read_flips(filename)
    all_flips = []
    for line in readlines(filename)
        south = false
        north = false
        flips = Int[]
        for char in collect(line)
            if char == 's'
                south = true
                north = false
            elseif char == 'n'
                north = true
                south = false
            elseif char == 'e'
                if north
                    push!(flips, NE)
                elseif south
                    push!(flips, SE)
                else
                    push!(flips, E)
                end
                north = false
                south = false
            elseif char == 'w'
                if north
                    push!(flips, NW)
                elseif south
                    push!(flips, SW)
                else
                    push!(flips, W)
                end
                north = false
                south = false
            else
                error("INVALID CHARACTER $char IN FLIPS!")
            end
        end
        push!(all_flips, flips)
    end
    return all_flips
end
" Return the location relative to a starting place, given the directions "
function get_location(origin, directions)
    location = deepcopy(origin)
    for direction in directions
        if direction == E
            location[2] += 1
        elseif direction == SE
            location[1] += 1
            location[2] += (iseven(location[1]) ? 0 : 1)
        elseif direction == SW
            location[1] += 1
            location[2] -= (iseven(location[1]) ? 1 : 0)
        elseif direction == W
            location[2] -= 1
        elseif direction == NW
            location[1] -= 1
            location[2] -= (iseven(location[1]) ? 1 : 0)
        elseif direction == NE
            location[1] -= 1
            location[2] += (iseven(location[1]) ? 0 : 1)
        end
    end
    return location
end
" Return all the neighbor locations to a given `location` "
function get_neighbors(location)
    directions = [[E],[SE],[SW],[W],[NW],[NE]]
    neighbors = Array{Int}[]
    for direction in directions
        push!(neighbors, get_location(location, direction))
    end
    return neighbors
end
" Interpret the directions into a Dict of tiles at flipped/unflipped locations "
function interpret_directions(all_directions)
    tiles = Dict{Array{Int,1},Tile}()
    origin = [0,0]
    for directions in all_directions
        location = get_location(origin, directions)
        # Default tile is WHITE, so flipping once yields BLACK
        tile = get!(tiles, location, Tile(location, WHITE))
        tile.flip = flip(tile.flip)
    end
    return tiles
end
" Solve Day 24-1 "
function total_black_tiles(filename="day24.input")
    all_directions = read_flips(filename)
    tiles = interpret_directions(all_directions)
    count(x->x.flip == BLACK, values(tiles))
end
" Print all the tiles in a pretty array "
function print_tiles(tiles)
    locations = keys(tiles)
    i_extr = extrema(first.(locations))
    j_extr = extrema(last.(locations))
    for i = first(i_extr):last(i_extr)
        if iseven(i)
            print(" ")
        end
        for j = first(j_extr):last(j_extr)
            location = [i,j]
            if location ∈ locations
                if tiles[location].flip == BLACK
                    print("# ")
                else
                    print(". ")
                end
            else
                print("  ")
            end
        end
        println("    $i")
    end
end
" Compute the number of adjacent neighbors that have the color BLACK "
function count_adjacents(tiles, location)
    neighbors = get_neighbors(location)
    adjacents = 0
    for neighbor in neighbors
        if neighbor ∈ keys(tiles) && tiles[neighbor].flip == BLACK
            adjacents += 1
        end
    end
    return adjacents
end
" Advance tiles one step according to cellular automata rules "
function advance(tiles)
    new_tiles = deepcopy(tiles)
    all_neighbors = Set{Array{Int,1}}(keys(tiles))
    for location in keys(tiles)
        union!(all_neighbors, get_neighbors(location))
    end
    for location in all_neighbors
        adjacents = count_adjacents(tiles, location)
        curr_flip = get(tiles, location, Tile(0,WHITE)).flip
        if curr_flip == WHITE && adjacents == 2
            tile = get!(new_tiles, location, Tile(location, WHITE))
            tile.flip = BLACK
        elseif curr_flip == BLACK && (adjacents == 0 || adjacents > 2)
            new_tiles[location].flip = WHITE
        end
    end
    return new_tiles
end
" Simulate cellular automata rules over a specified number of days "
function simulate_changes(tiles, total_days)
    for day = 1:total_days
        tiles = advance(tiles)
    end
    return tiles
end
" Solve Day 24-2 "
function tiles_after_100_days(filename="day24.input")
    all_directions = read_flips(filename)
    tiles = interpret_directions(all_directions)
    TOTAL_DAYS = 100
    tiles = simulate_changes(tiles, TOTAL_DAYS)
    count(x->x.flip == BLACK, values(tiles))
end
