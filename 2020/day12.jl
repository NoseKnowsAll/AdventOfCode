const NORTH = 0
const WEST = 1
const EAST = 2
const SOUTH = 3
const FORWARD = 4
const LEFT = 5
const RIGHT = 6
mutable struct Ship
    location
    direction # Part 1: direction of ship. Part 2: direction of waypoint relative to ship
end
" Compute the manhattan distance between two imaginary numbers "
function manhattan_distance(loc1, loc2)
    difference = loc1-loc2
    abs(real(difference))+abs(imag(difference))
end
" Turn direction (as complex number) left "
function turn_left!(direction)
    direction *= im
end
" Turn direction (as complex number) right "
function turn_right!(direction)
    direction *= -im
end
" Read instructions from filename into array of pairs "
function read_instructions(filename)
    instructions = Pair{Int, Int}[]
    for line in readlines(filename)
        if line[1] == 'N'
            push!(instructions, Pair(NORTH, parse(Int,line[2:end])))
        elseif line[1] == 'W'
            push!(instructions, Pair(WEST, parse(Int,line[2:end])))
        elseif line[1] == 'E'
            push!(instructions, Pair(EAST, parse(Int,line[2:end])))
        elseif line[1] == 'S'
            push!(instructions, Pair(SOUTH, parse(Int,line[2:end])))
        elseif line[1] == 'F'
            push!(instructions, Pair(FORWARD, parse(Int,line[2:end])))
        elseif line[1] == 'L'
            push!(instructions, Pair(LEFT, parse(Int,line[2:end])))
        elseif line[1] == 'R'
            push!(instructions, Pair(RIGHT, parse(Int,line[2:end])))
        else
            error("INCORRECT INSTRUCTION")
        end
    end
    return instructions
end
"""
    move_to_destination!(ship, instructions, waypoint=false)
According to instructions, move ship until it reaches its destination.
waypoint=false for ship movement according to N,S,E,W, waypoint=true for
ship direction/waypoint according to N,S,E,W.
"""
function move_to_destination!(ship, instructions, waypoint=false)
    for instruction in instructions
        if first(instruction) == NORTH
            if waypoint
                ship.direction += last(instruction)*im
            else
                ship.location += last(instruction)*im
            end
        elseif first(instruction) == WEST
            if waypoint
                ship.direction += last(instruction)*(-1)
            else
                ship.location += last(instruction)*(-1)
            end
        elseif first(instruction) == EAST
            if waypoint
                ship.direction += last(instruction)*1
            else
                ship.location += last(instruction)*1
            end
        elseif first(instruction) == SOUTH
            if waypoint
                ship.direction += last(instruction)*(-im)
            else
                ship.location += last(instruction)*(-im)
            end
        elseif first(instruction) == FORWARD
            ship.location += ship.direction*last(instruction)
        elseif first(instruction) == LEFT
            nturns = Int(last(instruction)/90)
            for turn = 1:nturns
                ship.direction = turn_left!(ship.direction)
            end
        elseif first(instruction) == RIGHT
            nturns = Int(last(instruction)/90)
            for turn = 1:nturns
                ship.direction = turn_right!(ship.direction)
            end
        end
    end
end
" Solve Day 12-1 "
function total_distance(filename="day12.input")
    ship = Ship(0+0*im, 1) # At origin, facing east == 1
    instructions = read_instructions(filename)
    move_to_destination!(ship, instructions, false)
    manhattan_distance(0+0*im, ship.location)
end
" Solve Day 12-2 "
function waypoint_distance(filename="day12.input")
    ship = Ship(0+0*im, 10+1*im) # At origin, waypoint at (10+1i)
    instructions = read_instructions(filename)
    move_to_destination!(ship, instructions, true)
    manhattan_distance(0+0*im, ship.location)
end
