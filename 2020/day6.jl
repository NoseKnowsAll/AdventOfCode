include("utility.jl")

" Count questions-answered-yes. One user must answer yes for it to be included. "
function count_union_answers(all_groups)
    count = 0
    for group in all_groups
        curr_group = Set{Char}()
        for line in group
            union!(curr_group, Set{Char}(line))
        end
        count += length(curr_group)
    end
    return count
end
" Solve Day 6-1 "
function sum_counts(filename="day6.input")
    all_groups = enter_separated_read(filename)
    count_union_answers(all_groups)
end
" Count questions-answered-yes. All users must answer yes for it to be included. "
function count_intersect_answers(all_groups)
    count = 0
    for group in all_groups
        curr_group = Set{Char}("abcdefghijklmnopqrstuvwxyz")
        for line in group
            intersect!(curr_group, Set{Char}(line))
        end
        count += length(curr_group)
    end
    return count
end
" Solve Day 6-2 "
function strict_sum_counts(filename="day6.input")
    all_groups = enter_separated_read(filename)
    count_intersect_answers(all_groups)
end
