# Interprets input file command into a function call that can be applied to deck
function interpret_instruction(string)
    m = match(r"deal with increment (\d+)", string)
    if m !== nothing
        n = parse(Int,m.captures[1])
        return x -> increment_n!(x, n)
    end
    m = match(r"deal into new stack", string)
    if m !== nothing
        return x -> deal!(x)
    end
    m = match(r"cut (-?\d+)", string)
    if m !== nothing
        n = parse(Int, m.captures[1])
        return x -> cut_n!(x, n)
    end
    error("$string did not match any known command!")
end

# Reads in and evaluates the instructions on deck specified by filename
function run_instructions!(deck, filename)
    for line in readlines(filename)
        func_call = interpret_instruction(line)
        func_call(deck)
    end
end

# Deals a new deck from previous deck (just reverses all cards)
function deal!(deck)
    reverse!(deck)
end

# Cuts the deck with a given number (strictly positive or negative)
function cut_n!(deck, n)
    if n > 0
        first = splice!(deck,1:n)
        append!(deck, first)
    elseif n < 0
        len = length(deck)
        last = splice!(deck, len+n+1:len)
        prepend!(deck, last)
    else
        error("Cannot cut with size 0")
    end
    return deck
end

# Deals a deck with increment n
function increment_n!(deck, n)
    len = length(deck)
    new_deck = deepcopy(deck)
    for i=1:len
        inc_i = mod((i-1)*n, len)+1
        deck[inc_i] = new_deck[i]
    end
    return deck
end

# Create a deck with factory order (0:deck_size-1)
function factory_order(deck_size)
    collect(0:deck_size-1)
end

# Solves day 22-1
function position_of_2019(filename="day22.input", deck_size=10007)
    deck = factory_order(deck_size)
    search_card = 2019
    run_instructions!(deck,filename)
    return (findfirst(deck .== search_card)-1) # ZERO-INDEXED INPUT
end
