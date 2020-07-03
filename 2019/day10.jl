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
    return length(asteroids)
end

# Solves day 10-1
function compute_max_asteroids(filename="day10.input")
    field = read_asteroid_field(filename)

    # Loop over all asteroids and find asteroid with most line of sight
    max_asteroids = 0
    for col = 1:size(field,2)
        for row = 1:size(field,1)
            if field[row,col] == 1
                asteroids = line_of_sight_asteroids(field, (row,col))
                if asteroids > max_asteroids
                    max_asteroids = asteroids
                end
            end
        end
    end
    return max_asteroids
end
