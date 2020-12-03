const PATH = 0
const TREE = 1

" Read in the file and store in 2D map array "
function read_treeline(filename)
    function char2int(char)
        if char=='.'
            return PATH
        elseif char=='#'
            return TREE
        else
            error("INVALID CHARACTER")
        end
    end
    height = countlines(filename)
    first_line = readline(filename)
    width = length(first_line)

    map = zeros(Int8, height, width)
    for (i,line) in enumerate(eachline(filename))
        map[i,:] .= char2int.(collect(line))
    end
    return map
end

""" Traverse the map according to given slope where slope[1] is amount down
and slope[2] is amount right to move before checking next location in map """
function traverse_treeline(map, slope)
    trees = 0
    to_check = ceil(Int,size(map,1)/slope[1]) # Continue to bottom of map
    for itr = 1:to_check
        i = slope[1]*(itr-1)+1
        j = rem(slope[2]*(itr-1),size(map,2))+1 # Wrap around width
        if map[i,j] == TREE
            trees += 1
        end
    end
    return trees
end

" Solves Day 3-1 "
function slope_3_1(filename="day3.input")
    slope = [1,3] # Down then right
    map = read_treeline(filename)
    traverse_treeline(map, slope)
end

" Solves Day 3-2 "
function check_all_slopes(filename="day3.input")
    slopes = [[1,1], [1,3], [1,5], [1,7], [2,1]] # Down then right
    map = read_treeline(filename)
    total_trees = 1
    for slope in slopes
        total_trees *= traverse_treeline(map, slope)
    end
    return total_trees
end
