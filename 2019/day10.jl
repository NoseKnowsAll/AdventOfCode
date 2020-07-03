# Reads in file and returns asteroid field as bit map where 1 == asteroid
function read_asteroid_field(filename)
    lines = []
    height = 0
    for line in eachline(filename)
        push!(lines, line)
        height += 1
    end
    width = length(lines[1]) # Assumes lines all the same length

    field = zeros(Int8, height, width)
    for (row,line) in enumerate(lines)
        for (col,char) in enumerate(line)
            field[row, col] = (char == '#') ? 1 : 0
        end
    end
    return field
end

# Helper function just to visualize AoC solution
function aoc_notation(location)
    return (location[2]-1,location[1]-1)
end

# Returns a tuple corresponding to the most reduced fraction equal to x/y
function minimal_fraction(x,y)
    g = gcd(x,y)
    return (Int(x/g), Int(y/g))
end

# Computes the number of asteroids visible from given location
function line_of_sight_asteroids(field, loc)
    asteroids = Set([])
    for col = 1:size(field,2)
        for row = 1:size(field,1)
            if field[row,col] == 1 && (row,col) != loc
                # Set of minimal fractions avoids duplicates
                push!(asteroids, minimal_fraction(row-loc[1],col-loc[2]))
            end
        end
    end
    return asteroids
end

# Solves day 10-1
function compute_max_asteroids(filename="day10.input")
    field = read_asteroid_field(filename)

    # Loop over all asteroids and find asteroid with most line of sight
    max_asteroids = 0
    final_loc = (1,1)
    for col = 1:size(field,2)
        for row = 1:size(field,1)
            if field[row,col] == 1
                asteroids = line_of_sight_asteroids(field, (row,col))
                if length(asteroids) > max_asteroids
                    max_asteroids = length(asteroids)
                    final_loc = (row,col)
                end
            end
        end
    end
    return (final_loc, max_asteroids)
end

# Sort offset offsets into clockwise direction with up being at the front
function clockwise_directions(asteroid_offsets)
    # atan(-x,-y) transforms vectors into radial coordinates with -pi at top
    # clockwise through pi at top
    clockwise_ordering(loc) = atan(-loc[2],loc[1])
    sorted = sort(collect(asteroid_offsets), by=clockwise_ordering)
    last = pop!(sorted)
    if last == (-1,0)
        # atan does not handle this direction properly wrt our ordering
        pushfirst!(sorted, last)
    else
        push!(sorted, last)
    end
    return sorted
end

# Vaporizes the first n asteroids in sorted array (repeating)
# Return the nth location of the asteroid
function vaporize_directions(field, main_loc, sorted, n)
    in_bounds(loc) = 1<=loc[1]<=size(field,1) && 1<=loc[2]<=size(field,2)

    start = [main_loc...]
    last_vaporized = start
    vaporized = falses(size(field))
    n_vaporized = 1
    offset = 1
    while n_vaporized <= n
        direction = sorted[offset]
        curr_loc = copy(start)
        while in_bounds(curr_loc .+ direction)
            curr_loc .+= direction
            if field[curr_loc...] == 1 && !vaporized[curr_loc...]
                # Vaporize current location
                vaporized[curr_loc...] = true
                last_vaporized = curr_loc
                n_vaporized += 1
                break
            end
        end
        # Change direction
        offset = mod(offset,length(sorted))+1
    end
    return last_vaporized
end

# Solves day 10-2 - we care about the 200th asteroid
function vaporize_locations(filename="day10.input", n=200)
    field = read_asteroid_field(filename)
    (main_loc, max_asteroids) = compute_max_asteroids(filename)

    asteroids = line_of_sight_asteroids(field, main_loc)
    sorted = clockwise_directions(asteroids)
    final_loc = vaporize_directions(field, main_loc, sorted, n)
    printout = aoc_notation(final_loc)
    return printout[1]*100+printout[2]
end
