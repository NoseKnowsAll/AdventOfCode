struct Rectangle
    ID
    left
    top
    width
    height
end

# Parse an input line with REGEX in order to capture only the 5 integers
function parse_line(string)
    m = match(r"(\d+) @ (\d+),(\d+): (\d+)x(\d+)",string)
    return parse.(Int64, m.captures)
end

# Returns a 1000x1000 array containing a list of IDs that claimed each location
function overlap_rects(all_rects)
    MAX_SIZE = 1000
    ID_array = Array{Array{Int64}}(undef, MAX_SIZE, MAX_SIZE)
    for i = 1:MAX_SIZE
        for j = 1:MAX_SIZE
            ID_array[i,j] = Int64[]
        end
    end

    for rect in all_rects
        for x = rect.left+1:rect.left+rect.width
            for y = rect.top+1:rect.top+rect.height
                push!(ID_array[x,y], rect.ID)
            end
        end
    end
    return ID_array
end

# From ID array, compute total square inches with two or more claims
function compute_overlapping_fabric(ID_array)
    total_inches = 0
    for location in ID_array
        if length(location) > 1
            total_inches += 1
        end
    end
    return total_inches
end

# Solve day3-1
function total_overlap_area(filename="day3.input")
    all_rects = Rectangle[]
    file = open(filename)
    for line in eachline(file)
        values = parse_line(line)
        push!(all_rects, Rectangle(values...))
    end
    close(file)

    square_inches = compute_overlapping_fabric(overlap_rects(all_rects))
end
