include("utility.jl")

abstract type Rule end
struct LeafRule <: Rule
    ID::Int
    char::Char
end
struct CompositeRule <: Rule
    ID::Int
    subrules
end
" Read filename and interpret into list of rules and list of messages "
function read_rules(filename)
    all_groups = enter_separated_read(filename)
    all_rules = Dict{Int,Rule}()
    for rule in all_groups[1]
        split1 = split(rule, ": ")
        rule_id = parse(Int, split1[1])
        if split1[2][1] == '\"' # Leaf Rule - only one character
            curr_rule = LeafRule(rule_id, split1[2][2])
            all_rules[rule_id] = curr_rule
        else # Composite Rule - options of subrules
            split2 = split(split1[2], " | ")
            subrules = Vector{Int}[]
            for sub_rules in split2
                options = parse.(Int, split(sub_rules, " "))
                push!(subrules, options)
            end
            curr_rule = CompositeRule(rule_id, subrules)
            all_rules[rule_id] = curr_rule
        end
    end
    return all_rules, all_groups[2]
end
" Check whether a given message at a specified offset satisfies a specific rule.
Also return the new offset after applying the given rule."
function satisfy_rule_id(message, offset, rule_ID, all_rules)
    #println("off: $offset, rule: $(rule_ID)")
    if offset > length(message)
        return false, offset
    end
    if all_rules[rule_ID] isa LeafRule
        return message[offset] == all_rules[rule_ID].char, offset+1
    else
        for consecutive_rules in all_rules[rule_ID].subrules
            satisfies_rules = true
            offset_so_far = offset
            for rule in consecutive_rules
                satisfy, offset_so_far = satisfy_rule_id(message, offset_so_far, rule, all_rules)
                if !satisfy
                    satisfies_rules = false
                    break
                end
            end
            if satisfies_rules
                #println("rules: $(consecutive_rules) satisfied $offset-$offset_so_far")
                return satisfies_rules, offset_so_far
            end
        end
        return false, offset
    end
end
" Return all possible string options that a specified rule could represent "
function collect_rule_options(rule_ID, all_rules)
    function combine_options(list1, list2)
        combined = []
        for el1 in list1
            for el2 in list2
                push!(combined, el1*el2)
            end
        end
        return combined
    end
    if all_rules[rule_ID] isa LeafRule
        return [all_rules[rule_ID].char]
    else
        all_options = []
        for consecutive_rules in all_rules[rule_ID].subrules
            curr_options = [""]
            for rule in consecutive_rules
                curr_options = combine_options(curr_options, collect_rule_options(rule, all_rules))
            end
            append!(all_options, curr_options)
        end
        return all_options
    end
end
" Solve Day 19-1 "
function satisfy_rule_0(filename="day19.input")
    all_rules, messages = read_rules(filename)
    RULE_TO_SATISFY = 0
    count = 0
    for message in messages
        satisfies, offset = satisfy_rule_id(message, 1, RULE_TO_SATISFY, all_rules)
        if satisfies && offset-1 == length(message)
            count += 1
        end
    end
    return count
end
" Modify the rules to represent loop without explicitly defining a loop "
function modify_rules_for_loop!(all_rules, messages)
    max_message_length = maximum(length.(messages))
    RULE_TO_MODIFY = 8
    rule_to_explore = all_rules[RULE_TO_MODIFY].subrules[1][1]
    options = collect_rule_options(rule_to_explore, all_rules)
    min_length = minimum(length.(options))
    max_repetitions = ceil(Int, max_message_length/min_length)
    # Old rule 8: 42
    # New rule 8: 42 | 42 42 | 42 42 42 ... max possible times
    for repetition = 2:max_repetitions
        pushfirst!(all_rules[RULE_TO_MODIFY].subrules, fill(rule_to_explore,repetition))
    end

    RULE_TO_MODIFY = 11
    rules_to_explore = all_rules[RULE_TO_MODIFY].subrules[1]
    min_length = 0
    for rule in rules_to_explore
        options = collect_rule_options(rule, all_rules)
        min_length += minimum(length.(options))
    end
    max_repetitions = ceil(Int, max_message_length/min_length)
    # Old rule 11: 42 31
    # New rule 11: 42 31 | 42 42 31 31 | 42 42 42 31 31 31 ...
    for repetition = 2:max_repetitions
        new_subrule = cat(fill(rules_to_explore[1],repetition), fill(rules_to_explore[2],repetition); dims=1)
        pushfirst!(all_rules[RULE_TO_MODIFY].subrules, new_subrule)
    end
end
" Compute block length of `BUILDING_BLOCK_RULES` and assert all blocks are this length "
function get_block_length(BUILDING_BLOCK_RULES, all_rules)
    options = collect_rule_options(BUILDING_BLOCK_RULES[1], all_rules)
    BLOCK_LENGTH = length(options[1])
    # Sanity check - all options must be the same length
    for option in options
        @assert BLOCK_LENGTH == length(option) "$option not the correct length!"
    end
    options = collect_rule_options(BUILDING_BLOCK_RULES[2], all_rules)
    for option in options
        @assert BLOCK_LENGTH == length(option) "$option not the correct length!"
    end
    return BLOCK_LENGTH
end
" Attempt to split message cleanly into blocks of `BLOCK_LENGTH`. Return
whether this was possible as well as the blocks message was split into "
function split_into_blocks(message, BLOCK_LENGTH, BUILDING_BLOCK_RULES, all_rules)
    num_blocks = length(message)/BLOCK_LENGTH
    if num_blocks != ceil(Int, num_blocks)
        # Can't be valid if message cannot be divided evenly into blocks
        return false, nothing
    else
        num_blocks = Int(num_blocks)
        blocks = zeros(Int, num_blocks)
        satisfies = false
        for i = 1:num_blocks
            start=1+BLOCK_LENGTH*(i-1)
            msg_block = message[start:start+BLOCK_LENGTH-1]
            satisfies = false
            for rule in BUILDING_BLOCK_RULES
                test, offset = satisfy_rule_id(msg_block, 1, rule, all_rules)
                if test && offset-1 == BLOCK_LENGTH
                    @assert !satisfies "$msg_block SATISFIED MORE THAN ONE BUILDING BLOCK RULE!"
                    satisfies = true
                    blocks[i] = rule
                end
            end
            if !satisfies
                break
            end
        end
        return satisfies, blocks
    end
end
" Return whether or not the list of blocks can separate exactly into given subrules "
function fit_blocks_into_rule(blocks, subrules, all_rules)
    for list1 in all_rules[subrules[1]].subrules
        for list2 in all_rules[subrules[2]].subrules
            if cat(list1, list2; dims=1) == blocks
                return true
            end
        end
    end
    return false
end
" Solve Day 19-2 "
function satisfy_rule_0_loop(filename="day19.input")
    all_rules, messages = read_rules(filename)
    RULE_0 = [8, 11]
    @assert all_rules[0].subrules == [RULE_0] "ASSUMES RULE 0: 8 11"
    BUILDING_BLOCK_RULES = [42, 31]
    @assert all_rules[8].subrules == [[42]] "ASSUMES RULE 8: 42"
    @assert all_rules[11].subrules == [[42, 31]] "ASSUMES RULE 11: 42 31"
    BLOCK_LENGTH = get_block_length(BUILDING_BLOCK_RULES, all_rules)
    modify_rules_for_loop!(all_rules, messages)

    count = 0
    for message in messages
        valid_split, blocks = split_into_blocks(message, BLOCK_LENGTH, BUILDING_BLOCK_RULES, all_rules)
        if valid_split # All blocks fit exactly one rule
            if fit_blocks_into_rule(blocks, RULE_0, all_rules)
                count += 1
            end
        end
    end
    return count
end
