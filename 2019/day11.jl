include("intcode.jl")

mutable struct Robot
    location
    direction
end

mutable struct Hull
    area::Array{Int8,2}
    painted::Array{Int64,2}
end

# Robot starts in center, facing up
function init_robot(n)::Robot
    Robot([n,n], [-1,0])
end

# Hull starts all black with nothing yet painted in part 1
function init_hull(n)::Hull
    Hull(zeros(Int8,2*n+1,2*n+1), zeros(Int64,2*n+1,2*n+1))
end

# Hull starts all black with center white pixel painted white in part 2
function init_hull_registration(n)::Hull
    area = zeros(Int8, 2*n+1,2*n+1)
    area[n,n] = 1
    Hull(area, zeros(Int64,2*n+1,2*n+1))
end

# Print the painted hull image to the console
function print_image(hull::Hull)
    printable(color) = color == 1 ? "*" : " "
    for col = 1:size(hull.area,1)
        for row = 1:size(hull.area,2)
            print(printable(hull.area[col,row]))
        end
        println()
    end
end

# Turns unit direction left
function turn_left(direction)
    if direction == [-1,0]
        return [0,-1]
    elseif direction == [0,-1]
        return [1,0]
    elseif direction == [1,0]
        return [0,1]
    elseif direction == [0,1]
        return [-1,0]
    end
end

# Turn unit direction right
function turn_right(direction)
    if direction == [-1,0]
        return [0,1]
    elseif direction == [0,-1]
        return [-1,0]
    elseif direction == [1,0]
        return [0,-1]
    elseif direction == [0,1]
        return [1,0]
    end
end

# Moves the robot according to program outputs
function eval_program_outputs!(robot::Robot, hull::Hull, color, direction)
    hull.area[robot.location...] = color
    hull.painted[robot.location...] += 1
    if direction == 0 # turn left 90 degrees
        robot.direction = turn_left(robot.direction)
    elseif direction == 1 # turn right 90 degrees
        robot.direction = turn_right(robot.direction)
    else
        error("unknown robot direction")
    end
    robot.location += robot.direction
end

# Repeatedly runs the program, passing inputs to and from robot and program
function run_program!(program::IntCode.Program, robot::Robot, hull::Hull)
    finished = false
    while !finished
        # Pass color of current location to program
        push!(program.inputs, hull.area[robot.location...])

        # Get next two outputs
        error_code = IntCode.interpret_program!(program)
        color = program.outputs[end]
        error_code = IntCode.interpret_program!(program)
        direction = program.outputs[end]

        # Keep repeating evaluation until program halt
        if error_code == IntCode.SUCCESS
            finished = true
        else
            eval_program_outputs!(robot, hull, color, direction)
        end
    end
end

# Counts the number of panels painted at least once
function count_panels(hull::Hull)
    count(hull.painted .> 0)
end

# Solves day 11-1
function paint_hull(filename="day11.input", n=80)
    file = open(filename)
    string = readline(file)
    close(file)
    program = IntCode.initialize_program(string)
    IntCode.single_output!(program)

    robot = init_robot(n)
    hull = init_hull(n)
    run_program!(program, robot, hull)
    count_panels(hull)
end

# Solves day 11-2
function registration_identifier(filename="day11.input", n=50)
    file = open(filename)
    string = readline(file)
    close(file)
    program = IntCode.initialize_program(string)
    IntCode.single_output!(program)

    robot = init_robot(n)
    hull = init_hull_registration(n)
    run_program!(program, robot, hull)
    print_image(hull)
end
