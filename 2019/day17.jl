include("ascii.jl")

const UNKNOWN = -1
const UP = 0
const DOWN = 1
const LEFT = 2
const RIGHT = 3
const TUMBLE = 4
const SCAFFOLD = 5
const SPACE = 6
const MAX_SEGMENT_LENGTH = 20

# Interprets a character on the map to an integer to be stored
function char2int(char)
    if char == '#'
        return SCAFFOLD
    elseif char == '.'
        return SPACE
    elseif char == '^'
        return UP
    elseif char == 'v'
        return DOWN
    elseif char == '<'
        return LEFT
    elseif char == '>'
        return RIGHT
    elseif char == 'X'
        return TUMBLE
    else
        return UNKNOWN
    end
end

# All information about scaffolding
mutable struct Scaffolding
    map::Array
end

# Override Base.show to allow for viewing scaffold state
function Base.show(io::IO, scaffold::Scaffolding)
    function id2char(id)
        char = " "
        if id == SPACE
            char = " "
        elseif id == SCAFFOLD
            char = "#"
        elseif id == UP
            char = "^"
        elseif id == DOWN
            char = "v"
        elseif id == LEFT
            char = "<"
        elseif id == RIGHT
            char = ">"
        elseif id == TUMBLE
            char = "X"
        elseif id == UNKNOWN
            char = "?"
        end
        return char
    end
    for i = 1:size(scaffold.map,1)
        for j = 1:size(scaffold.map,2)
            print(io,"$(id2char(scaffold.map[i,j]))")
        end
        println(io, "")
    end
end

# Create the Scaffolding struct
function init_scaffolding!(program::ASCII.IntCode.Program)::Scaffolding
    scaffold_strings = ASCII.run_to_string!(program, "")

    width = length(scaffold_strings[1]) # ASSUMES THEY ARE ALL THE SAME SIZE
    height = length(scaffold_strings)
    scaffold = Scaffolding(UNKNOWN.*ones(Int,height,width))
    for i = 1:height
        scaffold.map[i,:] = char2int.(collect(scaffold_strings[i]))
    end
    return scaffold
end

# Returns a list of all scaffolding intersections
function scaffold_intersections(scaffold::Scaffolding)
    intersections = []
    for j = 2:size(scaffold.map,2)-1
        for i = 2:size(scaffold.map,1)-1
            if scaffold.map[i,j] == SCAFFOLD
                if scaffold.map[i-1,j] == SCAFFOLD &&
                    scaffold.map[i+1,j] == SCAFFOLD &&
                    scaffold.map[i,j-1] == SCAFFOLD &&
                    scaffold.map[i,j+1] == SCAFFOLD
                    push!(intersections,[i,j])
                end
            end
        end
    end
    return intersections
end

# Compute the sum of the product of the i-j offsets of all intersections
function sum_alignment_parameters(intersections)
    sum((first.(intersections).-1).*(last.(intersections).-1))
end

# Solves day 17-1
function alignment_parameters(filename="day17.input")
    program = ASCII.init_program(filename)
    scaffold = init_scaffolding!(program)
    # Returns the sum of the alignment parameters
    intersections = scaffold_intersections(scaffold)
    sum_alignment_parameters(intersections)
end

# Set starting location and direction
function init_loc(scaffold::Scaffolding)
    for j = 1:size(scaffold.map,2)
        for i = 1:size(scaffold.map,1)
            if scaffold.map[i,j] == UP
                return ([i,j],UP)
            elseif scaffold.map[i,j] == DOWN
                return ([i,j],DOWN)
            elseif scaffold.map[i,j] == LEFT
                return ([i,j],LEFT)
            elseif scaffold.map[i,j] == RIGHT
                return ([i,j],RIGHT)
            end
        end
    end
end

# Helper function to convert directions to a separate index
function dir2ind(start,dir)
    if dir == UP
        return [start[1]-1,start[2]]
    elseif dir == DOWN
        return [start[1]+1,start[2]]
    elseif dir == LEFT
        return [start[1],start[2]-1]
    elseif dir == RIGHT
        return [start[1],start[2]+1]
    end
end

# Helper function to check if a given location is in-bounds of our scaffold
function inbounds(scaffold::Scaffolding, loc)
    return 1<=loc[1]<=size(scaffold.map,1) && 1<=loc[2]<=size(scaffold.map,2)
end

# Given a location and direction, turn right and move 1 step
function turn_right(loc, dir)
    new_dir = deepcopy(dir)
    if dir == UP
        new_dir = RIGHT
    elseif dir == DOWN
        new_dir = LEFT
    elseif dir == LEFT
        new_dir = UP
    elseif dir == RIGHT
        new_dir = DOWN
    end
    new_loc = dir2ind(loc, new_dir)
    return (new_loc, new_dir)
end

# Returns the string corresponding to the directions the droid will have to
# travel in order to walk along the entire scaffolding
function get_scaffold_string(scaffold::Scaffolding)
    (loc,dir) = init_loc(scaffold)
    finished = false
    scaffold_string = ""
    curr_steps = UNKNOWN
    while !finished
        next_loc = dir2ind(loc, dir)
        if inbounds(scaffold,next_loc) && scaffold.map[next_loc...] == SCAFFOLD
            # Continue heading in the same direction robot was heading
            loc = next_loc
            curr_steps += 1
        else # Must turn
            if curr_steps > UNKNOWN
                scaffold_string*=(string(curr_steps)*",")
            end
            (next_loc, next_dir) = turn_right(loc, dir)
            if inbounds(scaffold,next_loc) && scaffold.map[next_loc...] == SCAFFOLD
                # Right turn leads us on our way
                loc = next_loc
                dir = next_dir
                curr_steps = 1
                scaffold_string*="R,"
                continue
            end
            (next_loc, next_dir) = turn_right(loc, next_dir)
            (next_loc, next_dir) = turn_right(loc, next_dir)
            if inbounds(scaffold,next_loc) && scaffold.map[next_loc...] == SCAFFOLD
                # Left turn leads us on our way
                loc = next_loc
                dir = next_dir
                curr_steps = 1
                scaffold_string*="L,"
                continue
            end
            # No more turns available, finish up
            finished = true
            scaffold_string = scaffold_string[1:end-1] # Remove trailing comma
        end
    end
    return scaffold_string
end

# Removes the given segment string from string list and returns remaining strings
function remove_string(segment, string_list)
    remaining_list = String[]
    for next_string in string_list
        offsets = findall(Regex(segment), next_string)
        if isempty(offsets) # segment does not appear in this string
            push!(remaining_list, next_string)
            continue
        end

        # remaining_list is everything but what is selected by offsets
        remaining = next_string[1:first(offsets[1])-2]
        if remaining != ""
            push!(remaining_list, remaining)
        end
        for j = 1:length(offsets)-1
            # Ignore commas before/after string
            remaining = next_string[last(offsets[j])+2:first(offsets[j+1])-2]
            if remaining != ""
                push!(remaining_list, remaining)
            end
        end
        remaining = next_string[last(offsets[end])+2:end]
        if remaining != ""
            push!(remaining_list, remaining)
        end
    end
    return remaining_list
end

# Given a specific segmentation, form the array composing the solution
function form_soln(segmentation, segment_names, original_string)
    candidate_soln = String[]
    prev_index = 1
    for i = 1:length(original_string)
        if original_string[i] != ','
            curr_test = original_string[prev_index:i]
            for (iseg,seg) in enumerate(segmentation)
                if curr_test == seg
                    push!(candidate_soln, segment_names[iseg])
                    prev_index = i+2 # Ignore commas
                    break
                end
            end
        end
    end
    return candidate_soln
end

# Convert candidate solution to string
function soln2str(candidate_soln)
    string = ""
    for (itr,next_instruction) in enumerate(candidate_soln)
        if itr > 1
            string *= (","*next_instruction)
        else
            string *= next_instruction
        end
    end
    return string
end

# Check if a given solution is valid
function check_validity(candidate_soln, segmentation)
    str_soln = soln2str(candidate_soln)
    valid = length(str_soln) <= MAX_SEGMENT_LENGTH
    for segment in segmentation
        valid &= length(segment) <= MAX_SEGMENT_LENGTH
    end
    return valid
end

# Recursive helper function to populate segmentation to contain the definitions
# for each segment_name. Returns the solution and validity of the solution.
# Initialize with: parse_recursion([], ["original_string"], ["A","B","C"],"original_string")
function parse_recursion!(segmentation, string_list, segment_names, original_string)
    if length(segmentation) == length(segment_names) # No more names to use for segmenting
        return (false, nothing)
    end
    # We only search through the first substring for next segment
    string = string_list[1]
    for i = 1:min(MAX_SEGMENT_LENGTH, length(string))
        if i == length(string) || string[i+1]==',' # Segment must end before a comma
            segment = string[1:i]
            push!(segmentation, segment)
            remaining_list = remove_string(segment, string_list)

            if isempty(remaining_list) # No more strings left to explore
                candidate_soln = form_soln(segmentation, segment_names, original_string)
                valid = check_validity(candidate_soln, segmentation)
                if valid # We have a valid answer!
                    return (true, candidate_soln)
                end
            else
                (valid, candidate_soln) = parse_recursion!(segmentation, remaining_list, segment_names, original_string)
                if valid # We have a child-derived parent answer!
                    return (valid, candidate_soln)
                end
            end
            pop!(segmentation)
        end
    end
    return (false, nothing)
end

# Segments the original_string into a list of segment_names with a fixed
# maximum length of MAX_SEGMENT_LENGTH
function parse_string_sequence(original_string, segment_names)
    segmentation = String[]
    # Calls helper function to parse the sequence into a given segmentation
    (valid, soln) = parse_recursion!(segmentation, [original_string], segment_names, original_string)
    @assert valid
    return (soln2str(soln), segmentation)
end

# Supply all arguments to program
function supply_arguments!(program::ASCII.IntCode.Program, solution,segmentation,cont_feed)
    ASCII.input_argument!(program, solution)
    ASCII.run_to_enter!(program)
    for segment in segmentation
        ASCII.input_argument!(program, segment)
        ASCII.run_to_enter!(program)
    end
    ASCII.input_argument!(program, cont_feed)
    ASCII.run_to_enter!(program)
    ASCII.run_to_enter!(program)
end

# Solves day 17-2
function space_dust(filename="day17.input")
    program = ASCII.init_program(filename)
    # Wake up robot and supply it its instructions
    program.program[1] = 2
    scaffold = init_scaffolding!(program)
    scaffold_string = get_scaffold_string(scaffold)
    (solution, segmentation) = parse_string_sequence(scaffold_string, ["A","B","C"])
    #solution = "A,A,B,C,B,C,B,C,B,A"
    #segmentation = ["R,6,L,12,R,6", "L,12,R,6,L,8,L,12", "R,12,L,10,L,10"]
    continuous_feed = "n"
    supply_arguments!(program, solution,segmentation,continuous_feed)

    # Run program and reach end of scaffolding
    scaffold = init_scaffolding!(program)

    # Get final output
    ASCII.interpret_program!(program)
    return program.outputs[end]
end
