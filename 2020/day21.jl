import Base.Iterators: flatten

" Read from filename a list of ingredients and known allergens that make up recipes "
function read_recipes(filename)
    all_ingredients = Array{String,1}[]
    all_allergens = Array{String,1}[]
    for line in readlines(filename)
        # Capturing each word before first "("
        ingredients = split(split(line," (")[1], " ")
        push!(all_ingredients, ingredients)
        # Optional non-capturing "(contains ", capturing repeating words ending with , or )
        matches = eachmatch(r"(?:\(contains )?(\w+?)(?:,|\))", line)
        allergens = [match.captures[1] for match in matches]
        push!(all_allergens, allergens)
    end
    return all_ingredients, all_allergens
end
" Find a list of all ingredients that are sure to be allergen-free "
function find_allergen_free(all_ingredients, all_allergens)
    allergens = Set(collect(Iterators.flatten(all_allergens)))
    ingredients = Set(collect(Iterators.flatten(all_ingredients)))
    potential_sources = Dict{String, Set{String}}()
    for allergen in allergens
        potential_sources[allergen] = deepcopy(ingredients)
        for (i_list, a_list) in zip(all_ingredients, all_allergens)
            if allergen ∈ a_list
                intersect!(potential_sources[allergen], i_list)
            end
        end
    end
    unsafe_choices = union(values(potential_sources)...)
    allergen_free = setdiff(ingredients, unsafe_choices)
end
" Solve Day 21-1 "
function allergen_free_ingredients(filename="day21.input")
    all_ingredients, all_allergens = read_recipes(filename)
    allergen_free = find_allergen_free(all_ingredients, all_allergens)
    sum(count(i_list->free ∈ i_list, all_ingredients) for free ∈ allergen_free)
end
" Collect ingredients that match each allergen via greedy algorithm "
function match_to_allergen(all_ingredients, all_allergens)
    # Repeat process to get ingredients that are unsafe choices
    allergens = Set(collect(Iterators.flatten(all_allergens)))
    ingredients = Set(collect(Iterators.flatten(all_ingredients)))
    potential_sources = Dict{String, Set{String}}()
    for allergen in allergens
        potential_sources[allergen] = deepcopy(ingredients)
        for (i_list, a_list) in zip(all_ingredients, all_allergens)
            if allergen ∈ a_list
                intersect!(potential_sources[allergen], i_list)
            end
        end
    end
    # Greedily match unsafe ingredients to each allergen
    matches = Dict{String,String}()
    while !isempty(potential_sources)
        for (allergen, ingredients) in potential_sources
            if length(ingredients) == 1
                ingredient = pop!(ingredients)
                matches[allergen] = ingredient
                delete!(potential_sources, allergen)
                for i_list in values(potential_sources)
                    delete!(i_list, ingredient)
                end
                break
            end
        end
    end
    return matches
end
" Solve Day 21-2 "
function canonical_dangerous_list(filename="day21.input")
    all_ingredients, all_allergens = read_recipes(filename)
    matches = match_to_allergen(all_ingredients, all_allergens)
    sorted_matches = sort(matches, by=kv->kv[1])
    join(values(sorted_matches), ",")
end
