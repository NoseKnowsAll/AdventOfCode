const OCCUPIED = 2
const EMPTY    = 1
const FLOOR    = 0
" Read seat_map from specified filename "
function read_seat_map(filename)
    len = countlines(filename)
    width = length(readline(filename))
    map = Array{Int,2}(undef, len, width)
    function char2int(char)
        if char == '#'
            return OCCUPIED
        elseif char == 'L'
            return EMPTY
        elseif char == '.'
            return FLOOR
        else
            error("INVALID CHAR!")
        end
    end
    for (i,line) in enumerate(readlines(filename))
        map[i,:] = char2int.(collect(line))
    end
    return map
end
" Test for neighbors in the given direction specified by `off` from `loc`.
If new_visibility, then explore all the way to edge of map and find
first seat. Otherwise, just consider adjacent neighbor. "
function check_direction!(neighbors, loc, map, new_visibility, off)
    MAX_DISTANCE_AWAY = new_visibility ? size(map,2) : 1
    for i = 1:MAX_DISTANCE_AWAY
        tentative_neighbor = loc+i*off
        if !checkbounds(Bool, map, tentative_neighbor)
            return
        end
        if map[tentative_neighbor] != FLOOR
            push!(neighbors, tentative_neighbor)
            return
        end
    end
end
" Update neighbors to contain all non-floor neighbors of `loc` "
function get_neighbors!(neighbors, loc, map, new_visibility)
    origin = CartesianIndex(zeros(Int,ndims(map))...)
    for off in CartesianIndices(ntuple(x->UnitRange(-1:1), ndims(map)))
        if !(off == origin)
            check_direction!(neighbors, loc, map, new_visibility, off)
        end
    end
    return neighbors
end
" Precompute all neighbors in all_neighbors array for performance purposes "
function compute_all_neighbors(map, new_visibility)
    all_neighbors = Array{Array{CartesianIndex,1},ndims(map)}(undef,size(map)...)
    for loc in CartesianIndices(map)
        if map[loc] != FLOOR
            all_neighbors[loc] = CartesianIndex[]
            get_neighbors!(all_neighbors[loc], loc, map, new_visibility)
        end
    end
    return all_neighbors
end
" Advance the map one step according to seating rules "
function advance(map, all_neighbors, new_visibility)
    new_map = deepcopy(map)
    converged = true
    TOLERANCE = new_visibility ? 5 : 4
    for loc in eachindex(map)
        if map[loc] != FLOOR
            occupied_neighbors = count(x->map[x] == OCCUPIED, all_neighbors[loc])
            if map[loc] == EMPTY && occupied_neighbors == 0
                new_map[loc] = OCCUPIED
                converged = false
            elseif map[loc] == OCCUPIED && occupied_neighbors >= TOLERANCE
                new_map[loc] = EMPTY
                converged = false
            end
        end
    end
    return new_map, converged
end
" Keep iterating in time until map reaches steady state "
function converge_to_steady_state(map, new_visibility=false)
    converged = false
    all_neighbors = compute_all_neighbors(map, new_visibility)
    while !converged
        map, converged = advance(map, all_neighbors, new_visibility)
    end
    return map
end
" Solve Day 11-1 "
function seats_occupied(filename="day11.input")
    map = read_seat_map(filename)
    map = converge_to_steady_state(map)
    count(x->x==OCCUPIED, map)
end
" Solve Day 11-2 "
function seats_occupied_new_visibility(filename="day11.input")
    map = read_seat_map(filename)
    map = converge_to_steady_state(map, true)
    count(x->x==OCCUPIED, map)
end
