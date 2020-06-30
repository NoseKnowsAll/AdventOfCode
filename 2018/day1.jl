function compute_frequency_shift(filename="day1.input")
    total_shift = 0
    for line in eachline(filename)
        sign = line[1]=='+' ? 1 : -1
        shift = parse(Int64, line[2:end])
        total_shift += sign*shift
    end
    return total_shift
end

using DataStructures

function first_frequency(filename="day1.input")
    all_shifts = SortedSet{Int64}()
    total_shift = 0
    iterations = 1
    MAX_ITERATIONS = 500
    while iterations < MAX_ITERATIONS
        for line in eachline(filename)
            sign = line[1]=='+' ? 1 : -1
            shift = parse(Int64, line[2:end])
            total_shift += sign*shift
            if total_shift in all_shifts
                return total_shift
            else
                push!(all_shifts, total_shift)
            end
        end
        iterations += 1
    end
end
