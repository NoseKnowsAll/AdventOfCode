const WALL = -1
const SPACE = 0
@enum UnitType GOBLIN = 1 ELF = 2

mutable struct Unit
    attack::Int64
    health::Int64
    type::UnitType
    played_round::Bool
end
goblin() = Unit(3,200,GOBLIN,false)
elf(attack=3) = Unit(attack,200,ELF,false)
isdead(unit::Unit) = unit.health == 0
can_play(unit::Unit) = !isdead(unit) && !unit.played_round

" Convert input characters to map IDs "
function interpret_char(char, prev_id)
    if char == '#'
        return WALL
    elseif char == '.'
        return SPACE
    elseif char == 'G'
        return prev_id + 1
    elseif char == 'E'
        return prev_id + 1
    else
        error("INVALID CHARACTER FROM INPUT FILE")
    end
end

"""
    function read_maze(filename, elf_attack_power=3)
Read file; return the units sorted by location (`map`) and ID (`units`).
Optionally input elf attack power when creating unit array.
"""
function read_maze(filename, elf_attack_power=3)
    height = countlines(filename)
    width = length(readline(filename))
    map = Array{Int64,2}(undef, width, height)
    units = Unit[]
    prev_id = 0
    for (itr,line) in enumerate(readlines(filename))
        for i = 1:width
            map[i,itr] = interpret_char(line[i], prev_id)
            if map[i,itr] > 0
                prev_id += 1
                if line[i] == 'G'
                    push!(units, goblin())
                elseif line[i] == 'E'
                    push!(units, elf(elf_attack_power))
                end
            end
        end
    end
    return (map, units)
end

" Return the first location wrt reading order "
function min_reading_order(locations)
    min_i = typemax(Int64)
    min_j = typemax(Int64)
    min_index = 0
    for (index,loc) in enumerate(locations)
        if loc[2] < min_j
            min_i = loc[1]
            min_j = loc[2]
            min_index = index
        elseif loc[2] == min_j
            if loc[1] < min_i
                min_i = loc[1]
                min_j = loc[2]
                min_index = index
            end
        end
    end
    return locations[min_index]
end

" Return all non-wall adjacent neighbors of `loc` (in reading order) "
function get_neighbors(loc, map)
    tuple = Tuple(loc)
    tentative_neighbors = [CartesianIndex(tuple[1],tuple[2]-1), CartesianIndex(tuple[1]-1,tuple[2]),
        CartesianIndex(tuple[1]+1,tuple[2]), CartesianIndex(tuple[1],tuple[2]+1)]
    neighbors = []
    for i in eachindex(tentative_neighbors)
        if checkbounds(Bool, map, tentative_neighbors[i])
            if map[tentative_neighbors[i]] != WALL
                push!(neighbors, tentative_neighbors[i])
            end
        end
    end
    return neighbors
end

" Update neighbors to contain all non-wall adjacent neighbors of `loc` (in reading order) "
function get_neighbors!(neighbors, loc, map)
    tuple = Tuple(loc)
    tentative_neighbors = [CartesianIndex(tuple[1],tuple[2]-1), CartesianIndex(tuple[1]-1,tuple[2]),
        CartesianIndex(tuple[1]+1,tuple[2]), CartesianIndex(tuple[1],tuple[2]+1)]
    for i in eachindex(tentative_neighbors)
        if checkbounds(Bool, map, tentative_neighbors[i])
            if map[tentative_neighbors[i]] != WALL
                push!(neighbors, tentative_neighbors[i])
            end
        end
    end
    return neighbors
end

" Precompute all neighbors in all_neighbors array for performance purposes "
function compute_all_neighbors(map)
    all_neighbors = Array{Array{CartesianIndex,1},2}(undef,size(map)...)
    for loc in eachindex(view(map,1:size(map,1),1:size(map,2)))
        if map[loc] != WALL
            all_neighbors[loc] = CartesianIndex[]
            get_neighbors!(all_neighbors[loc], loc, map)
        end
    end
    return all_neighbors
end

" Return the location the unit specified by its ID should move to on its turn "
function move_loc(id, map, units, all_neighbors)
    distances = similar(map)
    UNEXPLORED = -1
    fill!(distances, UNEXPLORED)
    start = findfirst(x->x==id, map)
    to_visit = [start]
    distances[start] = 0
    finished = false
    adjacent_to_enemies = []
    # Find closest location adjacent to enemies using BFS
    while !finished
        to_next_visit = []
        if isempty(to_visit)
            # NO VALID PATH TOWARDS ANY ENEMIES
            return start
        end
        while !isempty(to_visit)
            loc = popfirst!(to_visit)
            for neighbor in all_neighbors[loc]
                if distances[neighbor] == UNEXPLORED
                    if map[neighbor] > 0 # not possible to walk on this spot
                        if units[map[neighbor]].type != units[id].type
                            # CONFIRMED: loc is adjacent to enemy
                            push!(adjacent_to_enemies, loc)
                            finished = true
                        end
                    else
                        # Explore neighbor next iteration of BFS
                        push!(to_next_visit, neighbor)
                        distances[neighbor] = distances[loc]+1
                    end
                end
            end
        end
        to_visit = deepcopy(to_next_visit)
    end
    # If already next to enemy, don't move
    if start in adjacent_to_enemies
        return start
    end

    # Head towards this location
    travel_loc = min_reading_order(adjacent_to_enemies)
    if distances[travel_loc] == 1
        return travel_loc
    end

    # Retrace steps in order to find path towards `travel_loc`
    possible_path = [travel_loc]
    for distance = distances[travel_loc]:-1:2
        next_possible_path = []
        for loc in possible_path
            for neighbor in all_neighbors[loc]
                if distances[neighbor] == distance-1
                    if neighbor ∉ next_possible_path
                        push!(next_possible_path, neighbor)
                    end
                end
            end
        end
        possible_path = deepcopy(next_possible_path)
    end
    # Location to actually move to is neighbor of starting location in the
    # direction of `travel_loc`, but minimum reading order
    return min_reading_order(possible_path)
end

" Move unit specified by ID on its turn, if applicable "
function move!(id, map, units, all_neighbors)
    loc = move_loc(id, map, units, all_neighbors)
    start = findfirst(x->x==id, map)
    # Perform move action, even if "moving" in place
    map[start] = SPACE
    map[loc] = id
end

" Return the ID of the enemy within attacking range (neighboring) of unit with specified ID "
function get_enemy_to_attack(id, map, units, all_neighbors)
    loc = findfirst(x->x==id, map)
    neighbors = all_neighbors[loc]
    # All neighboring IDs of enemies, in reading order
    enemy_ids = []
    for neighbor in neighbors
        if map[neighbor] > 0 && units[map[neighbor]].type != units[id].type
            push!(enemy_ids, map[neighbor])
        end
    end
    # Attack neighboring enemy with minimum health
    min_health = typemax(Int64)
    min_id = false
    for enemy in enemy_ids
        if units[enemy].health < min_health
            min_health = units[enemy].health
            min_id = enemy
        end
    end
    return min_id
end

" Perform attack action of specified ID, whether or not there is an neighboring enemy "
function attack!(id, map, units, all_neighbors)
    enemy_id = get_enemy_to_attack(id, map, units, all_neighbors)
    if enemy_id != false
        units[enemy_id].health = max(0, units[enemy_id].health-units[id].attack)
        if isdead(units[enemy_id]) # Kill enemy
            #println("$enemy_id has died!")
            enemy_loc = findfirst(x->x==enemy_id, map)
            map[enemy_loc] = SPACE
        end
    end
    units[id].played_round = true
end

"""
    function run_battle!(map, units)
Actually run battle, editing map and units as they move and attack.
Return the number of complete turns it takes for one side to lose, total health
remaining on the side that one, and whether or not there are acceptable losses
on the side of the Elves.
"""
function run_battle!(map, units)
    finished = false
    turns = 0
    health_of_combatants = zeros(Int64,2)
    all_neighbors = compute_all_neighbors(map)
    while !finished
        # Move based on initial locations in reading order
        for id in map
            if id > 0 && can_play(units[id]) # Found a unit not yet played its round
                move!(id, map, units, all_neighbors)
                attack!(id, map, units, all_neighbors)
            end
        end
        # Tally up health, and quit if one side has lost
        health_of_combatants .= 0
        for unit in units
            health_of_combatants[Int(unit.type)] += unit.health
        end
        if 0 in health_of_combatants
            finished = true
        else
            turns += 1 # Final round is not counted
        end
        # Reset units
        ids = filter(x->x > 0, map)
        for id in ids
            units[id].played_round = false
        end
    end
    # If any elf dies, there are unacceptable losses
    acceptable_losses = true
    for unit in units
        if unit.type == ELF && isdead(unit)
            acceptable_losses = false
        end
    end
    return (turns, filter(x->x>0,health_of_combatants)[1], acceptable_losses)
end

" Solve Day 15-1 "
function battle_outcome(filename="day15.input")
    (map, units) = read_maze(filename)
    (turns,total_health_remaining,) = run_battle!(map, units)
    println("turns = $turns")
    println("total health = $total_health_remaining")
    return turns*total_health_remaining
end

" Solve Day 15-2 "
function minimum_attack_power(filename="day15.input")
    MAX_ATTACK = 200
    for elf_attack_power = 1:MAX_ATTACK
        (map, units) = read_maze(filename, elf_attack_power)
        (turns,total_health_remaining,acceptable_losses) = run_battle!(map, units)
        if acceptable_losses
            println("attack power = $elf_attack_power")
            println("turns = $turns")
            println("total health = $total_health_remaining")
            return turns*total_health_remaining
        end
    end
end
