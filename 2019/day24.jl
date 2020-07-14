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
    for index = 1:length(bugmap)
        neighbors = all_neighbors[index]
        adj_bugs = isempty(neighbors) ? 0 : sum([bugmap[neighbors[k]...] for k=1:length(neighbors)])
        if bugmap[index] == BUG && adj_bugs != 1
            new_map[index] = SPACE
        elseif bugmap[index] == SPACE && (adj_bugs == 1 || adj_bugs == 2)
            new_map[index] = BUG
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

# Initializes recursive variant of bugmap
function init_recursive_map(filename, final_time)
    bugmap1 = read_file(filename)
    @assert mod(size(bugmap1,1),2)==1 && mod(size(bugmap1,2),2)==1
    center = [ceil(Int,size(bugmap1,1)/2),ceil(Int,size(bugmap1,2)/2)]
    @assert bugmap1[center...] == SPACE

    # The total number of layers of recursion we need to model t=final_time
    nlayers = ceil(Int,final_time/(minimum(center)-1))*2+3
    # Center layer of recursive bugmap is initialized from file
    bugmap = zeros(Int8,size(bugmap1)...,nlayers)
    for j=1:size(bugmap1,2)
        for i=1:size(bugmap1,1)
            bugmap[i,j,ceil(Int,nlayers/2)] = bugmap1[i,j]
        end
    end
    return bugmap
end

# Helper function to connect neighbors, even at different recursive depths
function add_neighbor!(neighbors, loc, dir, size)
    d = loc[3]
    center = [ceil(Int,size[1]/2), ceil(Int,size[2]/2)]
    new_loc = zeros(Int,2)
    if dir == 0 # Up
        new_loc = [loc[1]-1,loc[2]]
    elseif dir == 1 # Down
        new_loc = [loc[1]+1,loc[2]]
    elseif dir == 2 # Left
        new_loc = [loc[1],loc[2]-1]
    elseif dir == 3 # Right
        new_loc = [loc[1],loc[2]+1]
    end

    if inbounds(new_loc, size)
        if new_loc != center
            push!(neighbors, [new_loc...,d])
        else
            if dir == 0 # Up
                new_locs = [[size[1],j,d-1] for j = 1:size[2]]
                append!(neighbors, new_locs)
            elseif dir == 1 # Down
                new_locs = [[1,j,d-1] for j = 1:size[2]]
                append!(neighbors, new_locs)
            elseif dir == 2 # Left
                new_locs = [[i,size[2],d-1] for i = 1:size[1]]
                append!(neighbors, new_locs)
            elseif dir == 3 # Right
                new_locs = [[i,1,d-1] for i = 1:size[1]]
                append!(neighbors, new_locs)
            end
        end
    else
        high_new_loc = [center[1],center[2],d+1]
        if dir == 0 # Up
            high_new_loc[1] -= 1
        elseif dir == 1 # Down
            high_new_loc[1] += 1
        elseif dir == 2 # Left
            high_new_loc[2] -= 1
        elseif dir == 3 # Right
            high_new_loc[2] += 1
        end
        push!(neighbors, high_new_loc)
    end
end

# Get neighbors, including recursive neighbors at different depths
function get_rec_neighbors(loc, size)
    neighbors = []
    for dir = 0:3
        add_neighbor!(neighbors, loc, dir, size)
    end
    return neighbors
end

# Precomputes all neighbors, even recursive neighbors at different depths
function compute_all_recursive_neighbors(size)
    all_neighbors = [[] for i=1:size[1], j=1:size[2], d=1:size[3]]
    center = [ceil(Int,size[1]/2), ceil(Int,size[2]/2)]
    for d = 2:size[3]-1 # Skip top/bottom to avoid out-of-bounds errors
        for j = 1:size[2]
            for i = 1:size[1]
                if [i,j] != center # Center is actually recursively defined
                    all_neighbors[i,j,d] = get_rec_neighbors([i,j,d],size)
                end
            end
        end
    end
    return all_neighbors
end

# Time step until final_time on recursive bugmap. Return total number of bugs.
function total_bugs(bugmap, final_time)
    all_neighbors = compute_all_recursive_neighbors(size(bugmap))
    for it = 1:final_time
        bugmap = timestep(bugmap, all_neighbors)
    end
    return sum(bugmap)
end

# Solves day 24-2
function recursive_bugs(filename="day24.input", final_time=200)
    bugmap = init_recursive_map(filename, final_time)
    total_bugs(bugmap, final_time)
end
