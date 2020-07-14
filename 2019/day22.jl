# Create a deck with factory order (0:deck_size-1)
function factory_order(deck_size)
    collect(0:deck_size-1)
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

# Returns Pvec equivalent of dealing a deck from scratch
function deal_p(deck_size)
    return Pvec(collect(deck_size:-1:1))
end

# Returns Pvec equivalent of cutting a deck with offset n
function cut_p(deck_size, n)
    if n > 0
        return Pvec(union(n+1:deck_size, 1:n))
    elseif n < 0
        return Pvec(union(deck_size+n+1:deck_size, 1:deck_size+n))
    else
        error("Cannot cut with size 0")
    end
end

# Returns Pvec equivalent of dealing a deck with increment n
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

# Solves day 22-1
function position_of_2019(filename="day22.input", deck_size=10007)
    deck = factory_order(deck_size)
    search_card = 2019
    permutation = run_instructions_p(deck_size,filename)
    final_deck = permutation*deck
    return (findfirst(final_deck .== search_card)-1) # ZERO-INDEXED INPUT
end

# Permutation matrices are now stored via an affine map a*x+b (mod size)
mutable struct AffinePerm
    # (P*v)[i] == v[a*i + b (mod size)]
    a::Int128
    b::Int128
    size::Int64

    function AffinePerm(a_::Integer, b_::Integer, size_::Integer)
        new(mod(a_, size_), mod(b_, size_), size_)
    end
end

# Returns AffinePerm equivalent of dealing a deck from scratch
function deal_affine(deck_size)
    return AffinePerm(-1, -1, deck_size)
end

# Returns AffinePerm equivalent of cutting a deck with offset n
function cut_affine(deck_size, n)
    return AffinePerm(1, n, deck_size)
end

# Returns AffinePerm equivalent of dealing a deck with increment n
function increment_affine(deck_size, n)
    return AffinePerm(invmod(n,deck_size), 0, deck_size)
end

# perm1 = perm2(perm1), which is only possible because affine maps form a group
function left_compose!(perm1::AffinePerm, perm2::AffinePerm)
    @assert perm1.size == perm2.size
    perm1.b = mod(perm2.a*perm1.b + perm2.b, perm1.size)
    perm1.a = mod(perm2.a*perm1.a, perm1.size)
end

# perm1 = perm1(perm2), which is only possible because affine maps form a group
function right_compose!(perm1::AffinePerm, perm2::AffinePerm)
    @assert perm1.size == perm2.size
    perm1.b = mod(perm1.a*perm2.b + perm1.b, perm2.size)
    perm1.a = mod(perm1.a*perm2.a, perm2.size)
end

# Evaluate the affine permutation in order to find the value at given index
function eval(perm::AffinePerm, index)
    return mod(perm.a*index + perm.b, perm.size)
end

# Interprets input file command into an affine mapping
function interpret_instruction_affine(deck_size, string)
    m = match(r"deal with increment (\d+)", string)
    if m !== nothing
        n = parse(Int,m.captures[1])
        return increment_affine(deck_size, n)
    end
    m = match(r"deal into new stack", string)
    if m !== nothing
        return deal_affine(deck_size)
    end
    m = match(r"cut (-?\d+)", string)
    if m !== nothing
        n = parse(Int, m.captures[1])
        return cut_affine(deck_size, n)
    end
    error("$string did not match any known command!")
end

# Reads in instructions specified by filename and forms affine mapping
function run_instructions_affine(deck_size, filename)
    overall_p = AffinePerm(Int128(1), Int128(0), deck_size) # Identity mapping
    for line in readlines(filename)
        new_p = interpret_instruction_affine(deck_size, line)
        right_compose!(overall_p, new_p)
    end
    return overall_p
end

# Repeatedly apply permutation given number of iterations
function repeat_permutation(perm::AffinePerm, iterations)
    total_perm = deepcopy(perm)
    powers = Int128(1)
    powers_of_two = [deepcopy(total_perm)]
    highest_power = 1
    # Increment by powers of 2 due to associativity of permutations
    while powers*2 <= iterations
        right_compose!(total_perm, total_perm)
        powers *= 2
        push!(powers_of_two, deepcopy(total_perm))
        highest_power += 1
    end
    # Increment by decreasing powers of 2
    for power = highest_power-1:-1:1
        while powers + (1<<(power-1)) <= iterations
            right_compose!(total_perm, powers_of_two[power])
            powers += (1<<(power-1))
        end
    end
    return total_perm
end

# Solves day 22-2
function space_cards(filename="day22.input", deck_size=119315717514047)
    # Compute one total shuffle process as an affine mapping
    perm = run_instructions_affine(deck_size, filename)
    shuffle_iterations = 101741582076661
    total_perm = repeat_permutation(perm, shuffle_iterations)
    # Finally, apply permutation to figure out what happens to position of interest
    position_of_interest = 2020
    final_value = eval(total_perm, position_of_interest)
end
