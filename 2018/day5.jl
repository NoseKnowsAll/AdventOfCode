# Return whether these two characters can react
function can_react(char1, char2)
    return ( char1 == lowercase(char2) && isuppercase(char2) ||
        char1 == uppercase(char2) && islowercase(char2) )
end

# Fully react a given polymer into its smallest units
function react_polymer(polymer)
    still_reacting = true
    valid_indices = collect(1:length(polymer))
    while still_reacting
        still_reacting = false
        for itr = 1:length(valid_indices)-1 # Do not go out of bounds
            if can_react(polymer[valid_indices[itr]], polymer[valid_indices[itr+1]])
                still_reacting = true
                # Delete reactants
                deleteat!(valid_indices, itr)
                deleteat!(valid_indices, itr)
                break
            end
        end
    end
    return polymer[valid_indices]
end

# Solve Day 5-1
function polymer_units(filename="day5.input")
    polymer = readline(filename)
    final_polymer = react_polymer(polymer)
    return length(final_polymer)
end

# Remove all copies of a specified unit found in this polymer
function remove_unit(polymer, unit)
    unit1 = lowercase(unit)
    unit2 = uppercase(unit)
    new_polymer = filter(x -> !(x==unit1 || x==unit2), polymer)
end

# Return a Set containing all lowercase units found in this polymer
function all_units(polymer)
    units = Set(lowercase.(polymer))
end


# Solve Day 5-2
function polymer_reduction(filename="day5.input")
    start_polymer = readline(filename)
    # Reacting after deleting each unit is equivalent to first
    # reacting, then deleting each unit, and reacting
    polymer = react_polymer(start_polymer)
    units = all_units(polymer)
    min_length = length(polymer)
    for unit in units
        new_polymer = remove_unit(polymer, unit)
        final_polymer = react_polymer(new_polymer)
        min_length = min(min_length, length(final_polymer))
    end
    return min_length
end
