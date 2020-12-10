include("utility.jl")

" Read in the file and store as array of Sets with questions-answered-yes
as the values. One user must answer yes for it to be included. "
function read_answers(filename)
    all_groups = enter_separated_read(filename)
    all_answers = Set[]
    for group in all_groups
        push!(all_answers, Set{Char}())
        for line in group
            union!(all_answers[end], Set{Char}(line))
        end
    end
    return all_answers
end
" Solves Day 6-1 "
function sum_counts(filename="day6.input")
    answers = read_answers(filename)
    sum(length.(answers))
end
" Ready in the file and store as array of Sets with questions-answered-yes
as the values. All users must answer yes for it to be included. "
function strict_read_answers(filename)
    all_groups = enter_separated_read(filename)
    all_answers = Set[]
    for group in all_groups
        push!(all_answers, Set{Char}("abcdefghijklmnopqrstuvwxyz"))
        for line in group
            intersect!(all_answers[end], Set{Char}(line))
        end
    end
    return all_answers
end
" Solves Day 6-2 "
function strict_sum_counts(filename="day6.input")
    answers = strict_read_answers(filename)
    sum(length.(answers))
end
