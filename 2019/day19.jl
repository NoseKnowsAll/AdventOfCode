include("intcode.jl")

# Initialize program for reading in tractor beam info
function init_program(filename)
    file = open(filename)
    string = readline(file)
    close(file)

    program = IntCode.initialize_program(string)
    IntCode.single_output!(program)
    return program
end

# Returns whether or not a specific (x,y) ZERO-INDEXED coordinate is in tractor beam
function in_tractor_beam(program::IntCode.Program, x, y)
    program_to_run = deepcopy(program)
    push!(program_to_run.inputs, x)
    push!(program_to_run.inputs, y)
    IntCode.interpret_program!(program_to_run)
    return (program_to_run.outputs[end] == 1)
end

# Computes the number of points in [area_of_interest]^2 affected by tractor beam
function affected_points(program::IntCode.Program, AREA_OF_INTEREST)
    total_points = 0
    for i = 0:AREA_OF_INTEREST-1 # ZERO-INDEXED
        for j = 0:AREA_OF_INTEREST-1 # ZERO-INDEXED
            if in_tractor_beam(program, i, j)
                total_points += 1
            end
        end
    end
    return total_points
end

# Solves day 19-1
function tractor_beam(filename="day19.input")
    program = init_program(filename)
    AREA_OF_INTEREST = 50
    affected_points(program, AREA_OF_INTEREST)
end

# Finds the x location at the edge of the beam at y location = position.
# Starts in center point (x,y) = position and increments or decrements until
# it reaches the edge
function find_beam(program::IntCode.Program, position, increment, fit_width)
    # Increment by fit_width until you find tractor beam
    x_point = 0
    in_tractor = false
    for test_point = position:fit_width:10*position
        if in_tractor_beam(program, test_point, position)
            x_point = test_point
            in_tractor = true
            break
        end
    end
    # Increment by fit_width until you leave tractor beam
    while in_tractor
        x_point += increment*fit_width
        x_point = max(min(x_point, 10000), 0)
        in_tractor = in_tractor_beam(program, x_point, position)
        if x_point == 0 || x_point == 10000
            break
        end
    end
    # Increment by one until you get back into the tractor beam
    while !in_tractor
        x_point += -1*increment
        in_tractor = in_tractor_beam(program, x_point, position)
    end
    return x_point
end

# Returns the top left point of the square of given width that can fit in tractor beam
function find_closest_point(program::IntCode.Program, width)
    position = 4*width
    fitting_in_beam = false
    widths = zeros(Int,2,10000)

    while !fitting_in_beam
        widths[1,position] = find_beam(program, position, -1, width)
        widths[2,position] = find_beam(program, position, +1, width)
        #println("@ $position, [$(widths[1,position]), $(widths[2,position])]")
        if widths[2,position] - widths[1,position] >= width
            if widths[1,position] >= widths[1,position-width+1] &&
                widths[1,position]+width-1 <= widths[2,position-width+1]
                fitting_in_beam = true
            end
        end
        position += 1
    end
    position -= 1
    closest_point = [widths[1,position], position-width+1]
    return closest_point
end

# Sanity check that result to part 2 makes sense
function test_result(program, point, width)
    in_square = true
    for i = 0:width-1
        for j = 0:width-1
            in_square = in_square && in_tractor_beam(program, i+point[1], j+point[2])
        end
    end
    return in_square
end

# Solves day 19-2
function fit_square(filename="day19.input")
    program = init_program(filename)
    SQUARE_SIZE = 100
    point = find_closest_point(program, SQUARE_SIZE)
    # Solution wants 10000*x + y
    return point[1]*10000+point[2]
end
