# Reads file into 2D coords array
function readfile(filename)
    size = countlines(filename)
    coords = Array{Int64,2}(undef,2,size)
    for (itr,line) in enumerate(readlines(filename))
        m = match(r"(\d+), (\d+)",line)
        coords[:,itr] .= parse.(Int64,m.captures)
    end
    return coords
end

# Compute the manhattan distance (1-norm) between two points
function manhattan_distance(point1, point2)
    sum(abs.(point1-point2))
end

# Form a grid where each gridpoint is the index into coords of closest point
function form_dist_grid(coords)
    x_min, ix_min = findmin(coords[1,:])
    x_max, ix_max = findmax(coords[1,:])
    y_min, iy_min = findmin(coords[2,:])
    y_max, iy_max = findmax(coords[2,:])
    width = x_max-x_min+1
    height = y_max-y_min+1
    # Initialize distance grid
    dist_grid = Array{Int64,2}(undef, height, width)
    for x = x_min:x_max
        for y = y_max:-1:y_min
            min_dist = x_max+y_max
            min_ind = 0
            for ind = 1:size(coords,2)
                dist = manhattan_distance([x,y], coords[:,ind])
                if dist < min_dist # Owner is point closest to [x,y]
                    min_dist = dist
                    min_ind = ind
                elseif dist == min_dist # No owner if tie between 2 points
                    min_dist = dist
                    min_ind = 0
                end
            end
            dist_grid[y_max-y+1,x-x_min+1] = min_ind
        end
    end
    dist_grid
end

# Compute the largest area that is actually finite
function compute_largest_finite_area(coords, dist_grid)
    # All exterior points necessarily have infinite area
    in_interior(ind) = !(ind∈dist_grid[1,:]||ind∈dist_grid[end,:]||ind∈dist_grid[:,1]||ind∈dist_grid[:,end])
    interior = filter(in_interior, 1:size(coords,2))

    function compute_area(ind)
        length(findall(x->x == ind, dist_grid))
    end
    maximum(compute_area.(interior))
end

# For debugging purposes: inspect a sub-portion of dist_grid near given coord
function debug_grid(dist_grid, coords, coord, size)
    x_min, ix_min = findmin(coords[1,:])
    y_max, iy_max = findmax(coords[2,:])
    coord_xoff = coord[1]-x_min+1
    coord_yoff = y_max-coord[2]+1
    to_print = dist_grid[coord_yoff-size[2]:coord_yoff+size[2], coord_xoff-size[1]:coord_xoff+size[1]]
    show(IOContext(stdout, :limit=>false), MIME"text/plain"(), to_print)
    println()
end

# Solve Day 6-1
function largest_area(filename="day6.input")
    coords = readfile(filename)
    dist_grid = form_dist_grid(coords)
    compute_largest_finite_area(coords, dist_grid)
end

# Form a grid containing the total distance to all points
function form_total_dist_grid(coords)
    x_min, ix_min = findmin(coords[1,:])
    x_max, ix_max = findmax(coords[1,:])
    y_min, iy_min = findmin(coords[2,:])
    y_max, iy_max = findmax(coords[2,:])
    width = x_max-x_min+1
    height = y_max-y_min+1
    # Initialize distance grid
    dist_grid = Array{Int64,2}(undef, height, width)
    for x = x_min:x_max
        for y = y_max:-1:y_min
            total_dist = 0
            for ind = 1:size(coords,2)
                dist = manhattan_distance([x,y], coords[:,ind])
                total_dist += dist
            end
            dist_grid[y_max-y+1,x-x_min+1] = total_dist
        end
    end
    dist_grid
end

# Computes the area of the region where the distance is less than max_dist
function compute_region_area(dist_grid, max_dist)
    length(filter(dist->(dist<max_dist), dist_grid))
end

# Solve Day 6-2
function area_of_region(filename="day6.input")
    coords = readfile(filename)
    dist_grid = form_total_dist_grid(coords)
    MAX_DISTANCE = 10000
    compute_region_area(dist_grid, MAX_DISTANCE)
end
