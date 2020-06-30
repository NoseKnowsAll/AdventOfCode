# dict::Dict{Char, Int64} matches characters to number of occurences
function create_dictionary(string)
    dict = Dict{Char, Int64}()
    for char in string
        previous_value = get!(dict, char, 0)
        dict[char] += 1
    end
    return dict
end

function count_repeated_digits(string)

    # Create dictionary of characters->number of occurences
    dict = create_dictionary(string)

    # Specifically count doubles and triples
    doubles = false
    triples = false
    for key in keys(dict)
        if dict[key] == 2
            doubles = true
        elseif dict[key] == 3
            triples = true
        end
    end

    return (doubles, triples)
end

# Solve day2-1
function checksum(filename = "day2.input")
    total_doubles = 0
    total_triples = 0
    for line in eachline(filename)
        (doubles, triples) = count_repeated_digits(line)

        total_doubles += doubles ? 1 : 0
        total_triples += triples ? 1 : 0
    end
    return total_doubles*total_triples
end

# Convert dictionary of occurences of lowercase letters into 26-dim vector
function vectorize_dictionary(dict)
    total_chars_among_all_dicts = 26 # number of lowercase letters in english
    vector = zeros(Int64,total_chars_among_all_dicts)
    for key in keys(dict)
        index = Int64(key)-Int64('a')+1
        value = dict[key]
        vector[index] = value
    end
    return vector
end

# 1-norm of two vectors
function manhattan_distance(vector1, vector2)
    sum(abs.(vector2-vector1))
end

# Solve day2-2
function find_off_by_one_strings(filename="day2.input")

    vectors = []
    lines = String[]
    # Creates array of vectors
    for line in eachline(filename)
        push!(lines, line)
        push!(vectors, vectorize_dictionary(create_dictionary(line)))
    end

    # Finds indices of vectors that are identical except for 1 character
    string1_index = -1
    string2_index = -1
    for (ind1,vec1) in enumerate(vectors)
        for (ind2,vec2) in enumerate(vectors)
            #println(ind1," ", ind2,": ", manhattan_distance(vec1,vec2))
            if manhattan_distance(vec1, vec2) == 1 || manhattan_distance(vec1, vec2) == 2
                string1_index = ind1
                string2_index = ind2
            end
        end
    end
    if string1_index == -1 || string2_index == -1
        error("No strings off-by-one!")
    end

    # Identify substring in common between two strings
    for i = 1:length(lines[string1_index])
        if lines[string1_index][i] != lines[string2_index][i]
            common_substring = lines[string1_index][1:i-1]*lines[string1_index][i+1:end]
            return common_substring
        end
    end

end
