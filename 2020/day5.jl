const ROW_DIGITS = 7
const COL_DIGITS = 3

" Read in file into array of seat strings "
function read_seats(filename)
    all_seats = []
    for line in eachline(filename)
        push!(all_seats, line)
    end
    return all_seats
end
""" Interpet a given string as a binary space partitioned row and column.
    First 7 numbers specify row. Last 3 numbers specify column. """
function interpret_seat(seat)
    first = 0
    last = 2^ROW_DIGITS-1
    mid = ceil(Int,(first+last)/2)
    for i = 1:ROW_DIGITS
        mid = ceil(Int,(first+last)/2)
        if seat[i] == 'F'
            last = mid-1 # BOTTOM HALF
        elseif seat[i] == 'B'
            first = mid # UPPER HALF
        else
            error("INVALID SEAT!")
        end
    end
    row = ceil(Int,(first+last)/2)

    first = 0
    last = 2^COL_DIGITS-1
    mid = ceil(Int,(first+last)/2)
    for i = 1:COL_DIGITS
        mid = ceil(Int,(first+last)/2)
        if seat[i+ROW_DIGITS] == 'L'
            last = mid-1 # BOTTOM HALF
        elseif seat[i+ROW_DIGITS] == 'R'
            first = mid # UPPER HALF
        else
            error("INVALID SEAT!")
        end
    end
    column = ceil(Int,(first+last)/2)

    return row, column
end
" Convert given row/column tuple into seat ID "
seat_id(row, column) = row*2^(COL_DIGITS)+column
" Find the maximum seat ID in an array of seat strings "
function find_max_seat_id(all_seats)
    composition(seat) = seat_id(interpret_seat(seat)...)
    max_id = maximum(composition, all_seats)
    return max_id
end
" Solves Day 5-1 "
function max_seat_id(filename="day5.input")
    all_seats = read_seats(filename)
    find_max_seat_id(all_seats)
end
" Solves Day 5-2 "
function find_your_seat(filename="day5.input")
    all_seats = read_seats(filename)
    ordered_ids = []
    for seat in all_seats
        push!(ordered_ids, seat_id(interpret_seat(seat)...))
    end
    sort!(ordered_ids)
    for (itr,id) in enumerate(ordered_ids)
        if !(ordered_ids[itr+1] == id+1)
            return id+1
        end
    end
    error("YOUR SEAT IS MISSING!")
end
