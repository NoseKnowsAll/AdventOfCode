" Create a bag dict where each name has a list of children associated with it "
function create_dict(filename)
    bag_dict = Dict{String,Array{Pair{String,Int}}}()
    for line in eachline(filename)
        first_last = split(line," contain ")
        name = first_last[1][1:end-5] # Ignore trailing " bags"
        children_text = split(first_last[2],", ")
        children = Pair{String,Int}[]
        if children_text[1] != "no other bags."
            for child in children_text
                child = split(child," bag")[1]
                push!(children, Pair(child[3:end],parse(Int,child[1:2]))) # Assumes numbers are 1 character
            end
        end
        bag_dict[name] = children
    end
    return bag_dict
end
" Each name now has a list of parents associated with it "
function flip_dict(bag_dict::Dict)
    parent_dict = Dict{String, Array{String,1}}()
    for name in keys(bag_dict)
        parent_dict[name] = String[]
    end
    for (key,children) in bag_dict
        for child in children
            push!(parent_dict[first(child)], key)
        end
    end
    return parent_dict
end
" Count the global list of parents above search_name node "
function count_parents(parent_dict::Dict, search_name)
    searched = Dict{String,Bool}()
    for name in keys(parent_dict)
        searched[name] = false
    end
    parents_to_search = [search_name]
    searched[search_name] = true
    parent_count = 0
    while !isempty(parents_to_search)
        name = popfirst!(parents_to_search)
        for parent in parent_dict[name]
            if !searched[parent]
                push!(parents_to_search, parent)
                searched[parent] = true
                parent_count += 1
            end
        end
    end
    return parent_count
end
" Solves Day 7-1 "
function parent_bags(filename="day7.input")
    bag_dict = create_dict(filename)
    parent_dict = flip_dict(bag_dict)
    search_name = "shiny gold"
    count_parents(parent_dict, search_name)
end
" Count the global list of children below search_name node, multiplied by number.
Modifies bag_counts dictionary, which is presumed to be initialized by 0s. "
function count_children!(bag_dict::Dict, bag_counts::Dict, search_name)
    total = 1
    for child in bag_dict[search_name]
        name = first(child)
        num = last(child)
        if bag_counts[name] == 0
            count_children!(bag_dict, bag_counts, name)
        end
        total += bag_counts[name]*num
    end
    bag_counts[search_name] = total
end
" Solves Day 7-2 "
function one_shiny_gold_bag(filename="day7.input")
    bag_dict = create_dict(filename)
    search_name = "shiny gold"
    bag_counts = Dict{String,Int}()
    for name in keys(bag_dict)
        bag_counts[name] = 0
    end
    count_children!(bag_dict, bag_counts, search_name)
    return bag_counts[search_name]-1 # DO NOT INCLUDE YOURSELF!
end
