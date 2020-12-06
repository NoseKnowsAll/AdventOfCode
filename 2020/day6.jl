" Read in the file and store as array of Sets with questions-answered-yes
as the values. One user must answer yes for it to be included. "
function read_answers(filename)
    all_answers = Set[]
    curr_answer = Set{Char}()
    itr = 1
    for (i,line) in enumerate(eachline(filename))
        if line == ""
            itr += 1
            push!(all_answers, curr_answer)
            curr_answer = Set{Char}()
            continue
        end
        for char in collect(line) # Effectively, set union
            push!(curr_answer, char)
        end
    end
    push!(all_answers, curr_answer)
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
    all_answers = Set[]
    itr = 1
    curr_set = Set{Char}(collect("abcdefghijklmnopqrstuvwxyz"))
    for (i,line) in enumerate(eachline(filename))
        if line == ""
            itr += 1
            push!(all_answers, curr_set)
            curr_set = Set{Char}(collect("abcdefghijklmnopqrstuvwxyz"))
            continue
        end
        intersect!(curr_set, Set{Char}(collect(line))) # Set intersection
    end
    push!(all_answers, curr_set)
end
" Solves Day 6-2 "
function strict_sum_counts(filename="day6.input")
    answers = strict_read_answers(filename)
    sum(length.(answers))
end
