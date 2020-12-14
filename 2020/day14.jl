struct BitMask
    mask    # String
    indices # Int
    values  # Int
end
" Read file and return an array of `BitMask`s so that we know instructions to
edit our memory addresses."
function read_mem_instructions(filename)
    all_masks = BitMask[]
    itr = 1
    mask = ""
    indices = []
    values = []
    for (i,line) in enumerate(eachline(filename))
        if line[1:4] == "mask"
            if i > 1
                itr += 1
                push!(all_masks, BitMask(mask, indices, values))
            end
            mask = line[8:end]
            indices = []
            values = []
        else
            m = match(r"mem\[(\d+)\] = (\d+)", line)
            push!(indices, parse(Int, m.captures[1]))
            push!(values, parse(Int, m.captures[2]))
        end
    end
    push!(all_masks, BitMask(mask, indices, values))
    return all_masks
end
" Convert digits array back to integer value. Assumes lowest digits are last in array. "
function digits2num(digits)
    len = length(digits)
    return sum([digits[len-i+1]*2^(i-1) for i = 1:len])
end
" Apply a given bitmask to the integer value and return the integer "
function bitmask(mask, value)
    binary_value = reverse(digits(value, base = 2, pad = length(mask)))
    for i = 1:length(mask)
        if mask[i] != 'X'
            binary_value[i] = parse(Int, mask[i]) # Apply mask
        end
    end
    # Convert back to actual value
    return digits2num(binary_value)
end
" Solve Day 14-1 "
function sum_of_values(filename="day14.input")
    memory = Dict{Int, Int}()
    all_masks = read_mem_instructions(filename)
    for mask in all_masks
        for i = 1:length(mask.indices)
            memory[mask.indices[i]] = bitmask(mask.mask, mask.values[i])
        end
    end
    sum(values(memory))
end
" Recursion helper function to accumulate all addresses that can be formed from
applying floating mask to `value_so_far`, assuming the address is complete up to
given `index`. To loop over entire mask, use
`recur_all_floating_values(binary_value, mask, 1)`."
function recur_all_floating_values(value_so_far, mask, index)
    to_add = []
    i = findfirst(x->x=='X', mask[index:end])
    new_value = deepcopy(value_so_far)
    if isnothing(i) # No more 'X' in mask - our value is the final value!
        return [digits2num(new_value)]
    end
    new_value[i+index-1] = 0
    append!(to_add, recur_all_floating_values(new_value, mask, i+index))
    new_value[i+index-1] = 1
    append!(to_add, recur_all_floating_values(new_value, mask, i+index))
    return to_add
end
" Apply a given bitmask to the integer address and return all addresses it could
translate to according to v2 decoder chip: X = 0|1, 1 = 1, 0 = unchanged"
function bitmask_floating(mask, address)
    binary_value = reverse(digits(address, base = 2, pad = length(mask)))
    len = length(binary_value)
    for i = 1:len
        if mask[i] == '1'
            binary_value[i] = 1 # Apply 1-mask
        end
    end
    # Use recursion to get all X mask values
    return recur_all_floating_values(binary_value, mask, 1)
end
" Solve Day 14-2 "
function sum_of_values_floating_mask(filename="day14.input")
    memory = Dict{Int, Int}()
    all_masks = read_mem_instructions(filename)
    for mask in all_masks
        for i = 1:length(mask.indices)
            addresses = bitmask_floating(mask.mask, mask.indices[i])
            for address in addresses
                memory[address] = mask.values[i]
            end
        end
    end
    sum(values(memory))
end
