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
    #println("off: $offset, rule: $(rule_ID-1)")
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
    println(all_rules[RULE_TO_MODIFY])
    rule_to_explore = all_rules[RULE_TO_MODIFY].subrules[1][1]
    options = collect_rule_options(rule_to_explore, all_rules)
    min_length = minimum(length.(options))
    max_repetitions = ceil(Int, max_message_length/min_length)
    # Old rule 8: 42
    # New rule 8: 42 | 42 42 | 42 42 42 ... max possible times
    for repetition = 2:max_repetitions
        push!(all_rules[RULE_TO_MODIFY].subrules, fill(rule_to_explore,repetition))
    end
    println(all_rules[RULE_TO_MODIFY])

    RULE_TO_MODIFY = 11
    println(all_rules[RULE_TO_MODIFY])
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
        push!(all_rules[RULE_TO_MODIFY].subrules, new_subrule)
    end
    println(all_rules[RULE_TO_MODIFY])
end
" Solve Day 19-2 "
function satisfy_rule_0_loop(filename="day19.input")
    all_rules, messages = read_rules(filename)
    modify_rules_for_loop!(all_rules, messages)
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
