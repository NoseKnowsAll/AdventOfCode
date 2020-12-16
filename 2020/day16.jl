include("utility.jl")

" Struct that defines a rule: name and value valid if lows[i] <= value <= highs[i] "
struct Rule
    name
    lows
    highs
end
" Check if value is valid according to given rule "
function valid_value(rule::Rule, value)
    valid = false
    for i = 1:length(rule.lows)
        if rule.lows[i] <= value <= rule.highs[i]
            valid = true
        end
    end
    return valid
end
" Read file and interpret as a set of rules, your ticket, and nearby tickets"
function read_input(filename)
    all_groups = enter_separated_read(filename)
    @assert length(all_groups) == 3
    rules = Rule[]
    for line in all_groups[1] # Rules
        rule_str = split(line, ": ")
        name = rule_str[1]
        intervals = split(rule_str[2], " or ")
        lows = Array{Int}(undef, length(intervals))
        highs = Array{Int}(undef, length(intervals))
        for (i,interval) in enumerate(intervals)
            temp = split(interval, "-")
            lows[i] = parse(Int,temp[1])
            highs[i] = parse(Int,temp[2])
        end
        push!(rules, Rule(name, lows, highs))
    end
    line = all_groups[2][2] # Your ticket
    your_ticket = parse.(Int, split(line, ","))
    tickets = []
    for (i,line) in enumerate(all_groups[3]) # Nearby tickets
        if i > 1
            push!(tickets, parse.(Int, split(line, ",")))
        end
    end
    return rules, your_ticket, tickets
end
" Modify tickets array, discarding all tickets that do not have a valid field.
Return the error scanning rate "
function discard_invalid_tickets!(rules, tickets)
    error_rate = 0
    to_discard = []
    for (ticket_ID,ticket) in enumerate(tickets)
        for value in ticket
            valid = false
            for rule in rules
                if valid_value(rule, value)
                    valid = true
                    break
                end
            end
            if !valid
                error_rate += value
                push!(to_discard, ticket_ID)
            end
        end
    end
    deleteat!(tickets, to_discard)
    return error_rate
end
" Solve Day 16-1 "
function ticket_error_scanning_rate(filename="day16.input")
    rules, your_ticket, tickets = read_input(filename)
    err_rate = discard_invalid_tickets!(rules, tickets)
end
" Given valid tickets, find all possible positions each rule could be in ticket "
function determine_possible_positions(rules, tickets)
    n_rules = length(rules)
    possible_positions = Array{Array{Int,1}}(undef, n_rules)
    for (rule_ID,rule) in enumerate(rules)
        possible_positions[rule_ID] = Int[]
        for position = 1:n_rules
            valid_position = true
            for ticket in tickets
                if !valid_value(rule, ticket[position])
                    valid_position = false
                end
            end
            if valid_position
                push!(possible_positions[rule_ID], position)
            end
        end
    end
    return possible_positions
end
" Given valid tickets, find which rule corresponds to which position in ticket "
function determine_rule_positions(rules, tickets)
    n_rules = length(rules)
    possible_positions = determine_possible_positions(rules, tickets)
    # This algorithm only works because each rule has an increasing number
    # of possible positions. Therefore we can be sure that the rule with only
    # 1 possible position must match, the rule with 2 possible positions must
    # match the rule not yet matched, and so on.
    rule2position = zeros(Int,n_rules)
    positions_matched = []
    for len = 1:n_rules
        for (rule_ID,positions) in enumerate(possible_positions)
            if length(positions) == len
                for final_position in positions
                    if final_position ∉ positions_matched
                        rule2position[rule_ID] = final_position
                        break
                    end
                end
                positions_matched = deepcopy(positions)
            end
        end
    end
    return rule2position
end
" Solve Day 16-2 "
function mult_departure_fields(filename="day16.input")
    rules, your_ticket, tickets = read_input(filename)
    discard_invalid_tickets!(rules, tickets)
    rule2position = determine_rule_positions(rules, tickets)
    departure_rules = occursin.("departure", [rule.name for rule in rules])
    prod(your_ticket[rule2position[departure_rules]])
end
