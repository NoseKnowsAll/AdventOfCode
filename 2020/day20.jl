include("utility.jl")
const WHITE = 0
const BLACK = 1
struct Tile
    ID
    image
end
const LEFT_COLUMN = 0
const BOTTOM_ROW = 1
const RIGHT_COLUMN = 2
const TOP_ROW = 3
" Read filename into array of `Tile`s "
function read_tiles(filename)
    all_groups = enter_separated_read(filename)
    function char2int(char)
        if char == '#'
            return BLACK
        elseif char == '.'
            return WHITE
        else
            error("INVALID CHARACTER!")
        end
    end
    IMG_SIZE = 10
    tiles = Tile[]
    for group in all_groups
        m = match(r"Tile (\d+):", group[1])
        ID = parse(Int, m.captures[1])
        img = Array{Int,2}(undef, IMG_SIZE, IMG_SIZE)
        for i = 1:IMG_SIZE
            img[i,:] = char2int.(collect(group[i+1]))
        end
        push!(tiles, Tile(ID, img))
    end
    return tiles
end
" Return the array of edge elements for a specific `tile`, `side` number,
and rotation/flip specified by `d4` ∈ [0, 7]"
function get_edge(tile, side, d4)
    @views begin
        if d4 < 4 # Unflipped
            if mod(side-d4, 4) == LEFT_COLUMN
                return tile.image[1:end,1]
            elseif mod(side-d4, 4) == BOTTOM_ROW
                return tile.image[end,1:end]
            elseif mod(side-d4, 4) == RIGHT_COLUMN
                return tile.image[end:-1:1,end]
            elseif mod(side-d4, 4) == TOP_ROW
                return tile.image[1,end:-1:1]
            end
        else # Flipped
            if mod(d4-side-1,4) == LEFT_COLUMN
                return tile.image[end:-1:1,1]
            elseif mod(d4-side-1,4) == BOTTOM_ROW
                return tile.image[end,end:-1:1]
            elseif mod(d4-side-1,4) == RIGHT_COLUMN
                return tile.image[1:end,end]
            elseif mod(d4-side-1,4) == TOP_ROW
                return tile.image[1,1:end]
            end
        end
    end
end
" Apply the D_4 transformation to a specified tile's image "
function apply_transformation(tile, d4)
    if d4 < 4
        return rotl90(tile.image, d4)
    else
        return rotl90(tile.image', mod(d4,4))
    end
end
" Return the edge (0-indexed) corresponding to the `side` number rotated/flipped
according to d4 ∈ [0,7] "
function edge(side, d4)
    if d4 < 4
        return mod(side-d4, 4)
    else
        return mod(d4-side-1,4)
    end
end
" Return the side (0-indexed) corresponding to the `edge` number rotated/flipped
according to d4 ∈ [0,7] "
function side(edge, d4)
    if d4 < 4 # Unflipped
        if mod(4-edge, 4) == d4
            return LEFT_COLUMN
        elseif mod(1-edge, 4) == d4
            return BOTTOM_ROW
        elseif mod(2-edge, 4) == d4
            return RIGHT_COLUMN
        elseif mod(3-edge, 4) == d4
            return TOP_ROW
        end
    else # Flipped
        if mod(1+edge,4)+4 == d4
            return LEFT_COLUMN
        elseif mod(2+edge,4)+4 == d4
            return BOTTOM_ROW
        elseif mod(3+edge,4)+4 == d4
            return RIGHT_COLUMN
        elseif mod(edge,4)+4 == d4
            return TOP_ROW
        end
    end
end
" Return the side opposite a given side "
function opposite_side(side)
    if side == LEFT_COLUMN
        return RIGHT_COLUMN
    elseif side == BOTTOM_ROW
        return TOP_ROW
    elseif side == RIGHT_COLUMN
        return LEFT_COLUMN
    elseif side == TOP_ROW
        return BOTTOM_ROW
    end
end
" Return the neighbor relative to a given side of a location "
function get_neighbor(loc, side)
    if side == LEFT_COLUMN
        return [loc[1], loc[2]-1]
    elseif side == BOTTOM_ROW
        return [loc[1]+1, loc[2]]
    elseif side == RIGHT_COLUMN
        return [loc[1], loc[2]+1]
    elseif side == TOP_ROW
        return [loc[1]-1, loc[2]]
    end
end
" Return the indices of the tiles that are in the corners and on edges "
function get_corners(tiles)
    corner_indices = []
    global_edge_IDs = Dict{Int,Array{Int}}()
    edge_indices = []
    interior_indices = []
    for i = 1:length(tiles)
        global_edges = 0
        for edge = 0:3
            edge_to_check = get_edge(tiles[i], edge, 0)
            found_adjacent_edge = false
            for j = 1:length(tiles)
                if i != j
                    for d4 = 0:7
                        edge_to_compare = get_edge(tiles[j], LEFT_COLUMN, d4)
                        if edge_to_check == reverse(edge_to_compare)
                            found_adjacent_edge = true
                            break
                        end
                    end
                    if found_adjacent_edge
                        break
                    end
                end
                if found_adjacent_edge
                    break
                end
            end
            if !found_adjacent_edge
                global_edges += 1
                so_far = get!(global_edge_IDs, i, Int[])
                push!(so_far, edge)
            end
        end
        if global_edges == 2
            push!(corner_indices, i)
        elseif global_edges == 1
            push!(edge_indices, i)
        else
            push!(interior_indices, i)
        end
    end
    return corner_indices, edge_indices, interior_indices, global_edge_IDs
end
" Solve Day 20-1 "
function multiply_corner_IDs(filename="day20.input")
    tiles = read_tiles(filename)
    corner_indices, edge_indices, interior_indices = get_corners(tiles)
    prod(x->tiles[x].ID, corner_indices)
end
" Orient tiles into a grid such that each edge is identical to tile adjacent to it.
Tiles can be flipped or rearranged => D_4 group. "
function orient_tiles(tiles, corner_indices, edge_indices, interior_indices, global_edge_IDs)
    n_tiles = length(tiles)
    width = Int(sqrt(n_tiles))
    tile_array = zeros(Int, width, width)
    orientations = zeros(Int, width, width)
    visited = falses(width, width)
    # Initialize top-left corner of tile array as first corner
    tile_array[1,1] = corner_indices[1]
    for d4 = 0:7
        edges = global_edge_IDs[tile_array[1,1]]
        valid = side(edges[1],d4)==LEFT_COLUMN && side(edges[2],d4)==TOP_ROW
        if valid
            orientations[1,1] = d4
            break
        end
    end
    visited[1,1] = true
    on_corner(loc) = (loc[1] == 1 || loc[1] == width) && (loc[2] == 1 || loc[2] == width)
    on_edge(loc) = (loc[1] == 1 || loc[1] == width) || (loc[2] == 1 || loc[2] == width)
    function place_pieces(new_loc)
        if visited[new_loc...]
            return true
        end
        possible_tiles = []
        if on_corner(new_loc)
            possible_tiles = corner_indices
        elseif on_edge(new_loc)
            possible_tiles = edge_indices
        else
            possible_tiles = interior_indices
        end
        for i ∈ possible_tiles
            if i ∈ tile_array # Cannot choose a tile already placed down
                continue
            end
            for d4 = 0:7
                valid = true
                for side = 0:3
                    neighbor = get_neighbor(new_loc, side)
                    if checkbounds(Bool, visited, neighbor...)
                        if visited[neighbor...] # Edge of neighbor must match our edge
                            edge_to_match = get_edge(tiles[tile_array[neighbor...]], opposite_side(side), orientations[neighbor...])
                            our_edge = get_edge(tiles[i], side, d4)
                            if !(edge_to_match == reverse(our_edge))
                                valid = false
                                break
                            end
                        end
                    else # Must be an edge
                        if !(edge(side, d4) ∈ global_edge_IDs[i])
                            valid = false
                            break
                        end
                    end
                end
                if valid
                    visited[new_loc...] = true
                    tile_array[new_loc...] = i
                    orientations[new_loc...] = d4
                    for side = 0:3
                        neighbor = get_neighbor(new_loc, side)
                        if checkbounds(Bool, visited, neighbor...)
                            if !place_pieces(neighbor)
                                # Failed further down the chain - must undo orientation
                                visited[new_loc...] = false
                                tile_array[new_loc...] = 0
                                valid = false
                                break
                            end
                        end
                    end
                    if valid # Never failed further down - successful piece placement!
                        return true
                    end
                end
            end
        end
        # No possible piece can be placed at this location
        return false
    end
    success = place_pieces([1,2])
    if !success
        error("DID NOT SUCCESSFULLY PLACE PIECES")
    end
    return tile_array, orientations
end
" Combine the puzzle pieces together according to specified locations and orientations.
Ignore 1-deep borders on all four sides. "
function glue_puzzle(tiles, tile_array, orientations)
    # -2 to ignore borders
    final_puzzle = Array{Int,4}(undef,size(tiles[1].image,1)-2,size(tile_array,1),size(tiles[1].image,2)-2,size(tile_array,2))
    for i=1:size(tile_array,1)
        for j=1:size(tile_array,2)
            to_plug = apply_transformation(tiles[tile_array[i,j]], orientations[i,j])
            final_puzzle[:,i,:,j] .= to_plug[2:end-1,2:end-1]
        end
    end
    return reshape(final_puzzle, (size(tiles[1].image,1)-2)*size(tile_array,1),(size(tiles[1].image,2)-2)*size(tile_array,2))
end
" Define a sea monster: If #, then sea monster "
function init_sea_monster()
    MONSTER_HEIGHT = 3
    MONSTER_WIDTH = 20
    sea_monster = zeros(Int, MONSTER_HEIGHT,MONSTER_WIDTH)
    char2int(char) = char == '#' ? BLACK : WHITE
    sea_monster[1,:] .= char2int.(collect("                  # "))
    sea_monster[2,:] .= char2int.(collect("#    ##    ##    ###"))
    sea_monster[3,:] .= char2int.(collect(" #  #  #  #  #  #   "))
    return sea_monster
end
" For a given orientation in D_4 group, return the number of sea monsters "
function find_sea_monsters(tile, d4, sea_monster)
    image = apply_transformation(tile, d4)
    function is_monster(original, monster)
        for (orig,mon) in zip(original,monster)
            if mon == BLACK && orig != BLACK
                return false
            end
        end
        return true
    end
    count = 0
    size_1,size_2 = size(sea_monster)
    @views for left_j = 1:size(image,2)-size_2
        for top_i = 1:size(image,1)-size_1
            if is_monster(image[top_i:top_i+size_1-1,left_j:left_j+size_2-1], sea_monster)
                count += 1
            end
        end
    end
    return count
end
" Potentially rotate image until you find a sea monster. Then count all sea monsters. "
function count_sea_monsters(image, sea_monster)
    to_rotate = Tile("final", image)
    # Count sea monsters for a given rotation
    for d4 = 0:7
        count = find_sea_monsters(to_rotate, d4, sea_monster)
        if count > 0
            return count
        end
    end
    error("NO SEA MONSTERS FOUND!")
    return 0
end
" Solve Day 20-2 "
function sea_monsters(filename="day20.input", print_puzzle=false)
    tiles = read_tiles(filename)
    corner_indices, edge_indices, interior_indices, global_edge_IDs = get_corners(tiles)
    tile_array, orientations = orient_tiles(tiles, corner_indices, edge_indices, interior_indices, global_edge_IDs)
    final_image = glue_puzzle(tiles, tile_array, orientations)
    sea_monster = init_sea_monster()
    if print_puzzle
        for j = 1:size(final_image,2)
            for i = 1:size(final_image,1)
                print(final_image[i,j]==BLACK ? '#' : ' ')
            end
            println()
        end
        display(sea_monster)
    end
    monsters = count_sea_monsters(final_image, sea_monster)
    return count(x->x==BLACK,final_image) - monsters*count(x->x==BLACK,sea_monster)
end
