" Get the differences between all the numbers+charging+adapter"
function get_shifts(numbers)
    new_numbers = deepcopy(numbers)
    pushfirst!(numbers, 0) # Charging outlet is at 0
    push!(new_numbers, numbers[end]+3) # Adapter is 3 more than end
    new_numbers -= numbers
end
" Solve Day 10-1 "
function differences_3_1(filename="day10.input")
    numbers = parse.(Int, readlines(filename))
    sort!(numbers)
    differences = get_shifts(numbers)
    count(x->x==1, differences)*count(x->x==3, differences)
end
" Solve Day 10-2 "
function total_arrangements(filename="day10.input")
    numbers = parse.(Int, readlines(filename))
    sort!(numbers)
    valid_arrangements = Dict{Int,Int}()
    valid_arrangements[numbers[end]] = 1
    pop!(numbers)
    for curr_num in reverse(numbers)
        valid_arrangements[curr_num] = 0
        if curr_num+3 in keys(valid_arrangements)
            valid_arrangements[curr_num] += valid_arrangements[curr_num+3]
        end
        if curr_num+2 in keys(valid_arrangements)
            valid_arrangements[curr_num] += valid_arrangements[curr_num+2]
        end
        if curr_num+1 in keys(valid_arrangements)
            valid_arrangements[curr_num] += valid_arrangements[curr_num+1]
        end
    end
    total = get(valid_arrangements,1,0)+get(valid_arrangements,2,0)+get(valid_arrangements,3,0)
end
