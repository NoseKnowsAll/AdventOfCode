# Vertex in our graph of chemicals
mutable struct Chemical
    name::String          # name of this chemical
    inputs::Array         # list of chemicals that directly make this one
    quantities::Array     # Amount of input chemicals to make this one
    quantity::Integer

    function Chemical(name_, quantity_)
        new(name_, String[], Int[], quantity_)
    end
end

# Read filename and setup graph based on inputs
function read_file(filename)
    function interpret(ingredient)
        m = match(r"(\d+)", ingredient)
        quantity = parse(Int, m.captures[1])
        name = ingredient[m.offset+length(m.captures[1])+1:end]
        return (quantity, name)
    end

    # ORE is root node
    dict = Dict{String,Chemical}()
    dict["ORE"] = Chemical("ORE", 1)

    # Chemical reactions are reinterpreted as edges in graph
    for line in eachline(filename)
        equals = findfirst(" => ", line)
        inputs = split(line[1:first(equals)-1], ",")
        output = line[last(equals)+1:end]
        (quantity, name) = interpret(output)
        dict[name] = Chemical(name, quantity)
        for input in inputs
            (quant, nm) = interpret(input)
            push!(dict[name].quantities, quant)
            push!(dict[name].inputs, nm)
        end
    end

    return dict
end

# Function that resolves the amount of ore needed to produce 1 name
function resolve_ore!(dict, excess, to_resolve)
    name = popfirst!(to_resolve)
    # Amount of recipes of chemical name to produce
    to_produce = ceil(Int, -excess[name]/dict[name].quantity)
    if to_produce <= 0 # Should not resolve something we have excess of
        return
    end

    for i = 1:length(dict[name].inputs)
        if dict[name].inputs[i] == "ORE"
            if i > 1
                error("CANNOT HAVE MULTIPLE INPUTS WHERE ORE IS ONE OF THEM!")
            end
            return
        end
        input_needed = dict[name].quantities[i]*to_produce
        excess[dict[name].inputs[i]] -= input_needed

        if excess[dict[name].inputs[i]] < 0 # Must resolve to create necessary input
            push!(to_resolve, dict[name].inputs[i])
        end
    end

    # We have produced this much of chemical name
    excess[name] += to_produce*dict[name].quantity
end

# Sum up amount of ORE needed to make base chemicals
function total_ore(dict, excess)
    ore = 0
    for (name, chemical) in dict
        if "ORE" ∈ chemical.inputs
            to_produce = ceil(Int, -excess[name]/chemical.quantity)
            ore += to_produce*chemical.quantities[1] # ORE is only ingredient
        end
    end
    return ore
end

# Depth first search through graph in order to compute ore_needed for each
function compute_ore_needed!(dict)

    # Contains the amount of excess for each chemical (- => we need to produce it)
    excess = Dict{String, Int}()
    for k in keys(dict)
        excess[k] = 0
    end
    to_resolve = ["FUEL"]
    excess["FUEL"] = -1

    # Depth first search through our Dict starting from FUEL,
    # resolving all ingredients into base chemicals made directly from ORE
    while !isempty(to_resolve)
        resolve_ore!(dict, excess, to_resolve)
    end

    # Finally, add up the remaining amount of ore to produce base chemicals
    total_ore(dict, excess)
end

# Solves day 14-1
function min_ore(filename="day14.input")
    dict = read_file(filename)
    compute_ore_needed!(dict)
end
