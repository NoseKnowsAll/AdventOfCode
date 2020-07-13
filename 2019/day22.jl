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
    permutation = run_instructions_p(deck_size,filename)
    final_deck = permutation*deck
    return (findfirst(final_deck .== search_card)-1) # ZERO-INDEXED INPUT
end

# Permutation vector - column representation of permutation matrix
mutable struct Pvec
    p
end

# Matrix multiplication of two permutation vectors
function Base.:*(pvec1::Pvec, pvec2::Pvec)
    pvec3 = Pvec(pvec2.p[pvec1.p])
end

# Left matrix multiplication of two permutation vectors. pvec1 is updated with
# MM Pmat2*Pmat1
function left_mult!(pvec1::Pvec, pvec2::Pvec)
    pvec1.p = pvec1.p[pvec2.p]
end

# Matrix-vector multiplication
function Base.:*(pvec1::Pvec, vec)
    return vec[pvec1.p]
end

# Returns Pvec equivalent of deal!
function deal_p(deck_size)
    return Pvec(collect(deck_size:-1:1))
end

# Returns Pvec equivalent of cut_n!
function cut_p(deck_size, n)
    if n > 0
        return Pvec(union(n+1:deck_size, 1:n))
    elseif n < 0
        return Pvec(union(deck_size+n+1:deck_size, 1:deck_size+n))
    else
        error("Cannot cut with size 0")
    end
end

# Returns Pvec equivalent of increment_n!
function increment_p(deck_size, n)
    p = Pvec(zeros(Int,deck_size))
    for i=1:deck_size
        inc_i = mod((i-1)*n, deck_size)+1
        p.p[inc_i] = i
    end
    return p
end

# Interprets input file command into a permutation matrix
function interpret_instruction_p(deck_size, string)
    m = match(r"deal with increment (\d+)", string)
    if m !== nothing
        n = parse(Int,m.captures[1])
        return increment_p(deck_size, n)
    end
    m = match(r"deal into new stack", string)
    if m !== nothing
        return deal_p(deck_size)
    end
    m = match(r"cut (-?\d+)", string)
    if m !== nothing
        n = parse(Int, m.captures[1])
        return cut_p(deck_size, n)
    end
    error("$string did not match any known command!")
end

# Reads in instructions specified by filename and forms permutation matrix
function run_instructions_p(deck_size, filename)
    overall_p = Pvec(collect(1:deck_size)) # Identity matrix
    for line in readlines(filename)
        new_p = interpret_instruction_p(deck_size, line)
        left_mult!(overall_p, new_p)
    end
    return overall_p
end

# Solves day 20-2
function space_cards(filename="day22.input", deck_size=119315717514047)
    # Compute one total shuffle process as a permutation matrix
    perm = run_instructions_p(deck_size, filename)
    total_perm = deepcopy(perm)
    # Repeat shuffle process shuffle_iterations number of times
    shuffle_iterations = 101741582076661
    powers = Int64(1)
    while powers*2 <= shuffle_iterations
        left_mult!(total_perm, total_perm)
        powers *= 2
    end
    while powers < shuffle_iterations
        left_mult!(total_perm, perm)
        powers += 1
    end
    # Finally, apply permutation to our deck
    deck = factory_order(deck_size)
    position_of_interest = 2020
    final_deck = total_perm*deck
    return final_deck[position_of_interest+1] # ZERO-INDEXED INPUT
end
