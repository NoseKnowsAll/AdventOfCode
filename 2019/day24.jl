const SPACE = 0
const BUG = 1

# Mapping from file character to map ID
function char2id(char::Char)
    id = SPACE
    if char == '#'
        id = BUG
    elseif char == '.'
        id = SPACE
    end
    return id
end

# Reads in bug/empty space map from file
function read_file(filename, size=5)
    bugmap = zeros(Int8, size, size)
    for (it,line) in enumerate(eachline(filename))
        bugmap[it,:] .= char2id.(collect(line))
    end
    return bugmap
end

# Computes the biodiversity rating of a given bugmap
function bio_rating(bugmap)
    rating = 0
    for j = 1:size(bugmap,2)
        for i = 1:size(bugmap,1)
            power = (i-1)*size(bugmap,2)+j-1
            rating += 2^power*bugmap[i,j]
        end
    end
    return rating
end

# Returns whether or not location is in bounds
function inbounds(loc, size)
    return 1<=loc[1]<=size[1] && 1<=loc[2]<=size[2]
end

# Returns the inbounds neighbors to this loc
function get_neighbors(loc, size)
    neighbors = []
    new_loc = [loc[1]-1,loc[2]]
    if inbounds(new_loc, size)
        push!(neighbors, new_loc)
    end
    new_loc = [loc[1]+1,loc[2]]
    if inbounds(new_loc, size)
        push!(neighbors, new_loc)
    end
    new_loc = [loc[1],loc[2]-1]
    if inbounds(new_loc, size)
        push!(neighbors, new_loc)
    end
    new_loc = [loc[1],loc[2]+1]
    if inbounds(new_loc, size)
        push!(neighbors, new_loc)
    end
    return neighbors
end

# Returns a list of all neighbors for long term use
function compute_all_neighbors(size)
    all_neighbors = [[] for i=1:size[1],j=1:size[2]]
    for j = 1:size[2]
        for i = 1:size[1]
            append!(all_neighbors[i,j],get_neighbors([i,j],size))
        end
    end
    return all_neighbors
end

# Computes the new bugmap using game of life rules
function timestep(bugmap, all_neighbors)
    new_map = deepcopy(bugmap)
    for j = 1:size(bugmap,2)
        for i = 1:size(bugmap,1)
            neighbors = all_neighbors[i,j]
            adj_bugs = sum([bugmap[neighbors[i]...] for i=1:length(neighbors)])
            if bugmap[i,j] == BUG && adj_bugs != 1
                    new_map[i,j] = SPACE
            elseif bugmap[i,j] == SPACE && (adj_bugs == 1 || adj_bugs == 2)
                new_map[i,j] = BUG
            end
        end
    end
    return new_map
end

# Repeatedly time steps until we find a repeat biorating
function find_repeat_biorating(bugmap)
    MAX_ITER = 10^6
    all_ratings = Dict{Int,Int}()
    all_neighbors = compute_all_neighbors(size(bugmap))
    for it = 1:MAX_ITER
        bugmap = timestep(bugmap, all_neighbors)
        rating = bio_rating(bugmap)
        if rating ∈ keys(all_ratings)
            return rating
        else
            all_ratings[rating] = rating
        end
    end
    return false
end

# Solves day 24-1
function biodiversity(filename="day24.input")
    bugmap = read_file(filename)
    find_repeat_biorating(bugmap)
end
