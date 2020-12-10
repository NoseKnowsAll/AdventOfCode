"""
    enter_separated_read(filename)
Read in the entire contents from a specified file into an array of an array
of `Strings`. Each element of the outer array consists of one group of lines,
where the groups are separated by an enter in the file. Each element of the
inner arrays consists of one line (as a `String`) of the group.
"""
function enter_separated_read(filename)
    all_groups = []
    itr = 1
    group = String[]
    for (i,line) in enumerate(eachline(filename))
        if line == ""
            itr += 1
            push!(all_groups, group)
            group = String[]
        else
            push!(group, line)
        end
    end
    if all_groups[end] != group # In case last line is not an enter
        push!(all_groups, group)
    end
    return all_groups
end
