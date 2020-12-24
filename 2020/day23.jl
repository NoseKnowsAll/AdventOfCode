" Helper function: One-indexed version of rem(x,y) "
function rem1(x,y)
    return mod(x-1,y)+1
end
" Define a circular linked list as a node with a `value` and a `next` index "
mutable struct Node
    value
    next
end
" Print the clockwise cups, starting from `current` cup "
function print_nodes(cups, current)
    index = current
    for i = 1:length(cups)-1
        print(index)
        index = cups[index].next
    end
    println(index)
end
" Compute distance from start to finish "
function distance(cups, start, finish)
    index = cups[start].next
    for dist = 1:length(cups)-1
        if index == finish
            return dist
        end
        index = cups[index].next
    end
    error("Could not find $finish, starting from $start")
end
" Asserts that the distance from start to finish is >= specified `tolerance` "
function above_distance(cups, start, finish, tolerance)
    index = cups[start].next
    for dist = 1:tolerance
        if index == finish
            return false
        end
        index = cups[index].next
    end
    return true
end
" Perform one single move of cups game "
function perform_move!(cups, current)
    function destination(cups, current)
        offset = -1
        dest = rem1(current+offset,length(cups))
        # Cannot choose a destination cup that is within the next 3 cups
        while !above_distance(cups, current, dest, 3)
            dest = rem1(current+offset,length(cups))
            offset -= 1
        end
        return dest
    end
    # Pick up next 3 cups and move them immediately after destination cup
    destination = destination(cups, current)
    one_away   = cups[current].next
    three_away = cups[cups[cups[current].next].next].next
    cups[current].next = cups[three_away].next
    dest_next = cups[destination].next
    cups[destination].next = one_away
    cups[three_away].next = dest_next
    return cups[current].next
end
" Simulate a given number of moves of cups game "
function simulate_cups!(cups, current, total_moves)
    for move = 1:total_moves
        current = perform_move!(cups, current)
    end
    return cups
end
" Return an array of all the labels after a specified `cup_ID` "
function labels_after_cup(cups, cup_ID)
    index = cups[cup_ID].next
    labels = []
    for i = 1:length(cups)-1
        push!(labels, index)
        index = cups[index].next
    end
    return labels
end
" Solve Day 23-1 "
function cups_game_100(input=962713854, total_moves=100)
    cups = reverse(digits(input))
    nodes = Array{Node,1}(undef, length(cups))
    for (i,digit) in enumerate(cups)
        nodes[i] = Node(digit, cups[rem1(i+1,length(cups))])
    end
    sort!(nodes, by=x->x.value)
    current = cups[1]
    simulate_cups!(nodes, current, total_moves)
    labels_after_cup(nodes, 1)
end
" Initialize a node array (that is huge) labeled sequentially, except
 for the first few which are specified by cups array "
function init_huge_nodes(cups, total_size)
    temp_nodes = Array{Node,1}(undef, length(cups))
    for (i,digit) in enumerate(cups)
        temp_nodes[i] = Node(digit, cups[rem1(i+1,length(cups))])
    end
    temp_nodes[length(cups)].next = length(cups)+1
    sort!(temp_nodes, by=x->x.value)
    nodes = Array{Node,1}(undef, total_size)
    nodes[1:length(cups)] .= temp_nodes
    for i = length(cups)+1:total_size-1
        nodes[i] = Node(i, i+1)
    end
    nodes[total_size] = Node(total_size, cups[1])
    return nodes
end
" Solve Day 23-2 "
function cups_game_one_million(input=962713854, total_moves=10^7)
    cups = reverse(digits(input))
    SIZE = 10^6
    nodes = init_huge_nodes(cups, SIZE)
    current = cups[1]
    simulate_cups!(nodes, current, total_moves)
    nodes[1].next*nodes[nodes[1].next].next
end
