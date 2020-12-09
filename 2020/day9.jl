const PREAMBLE_LENGTH = 25
" Search numbers array for first number that is not the sum of exactly two
of the previous 25 numbers "
function find_invalid_number(numbers)
    for index = PREAMBLE_LENGTH+1:length(numbers)
        test_num = numbers[index]
        valid = false
        for i = index-PREAMBLE_LENGTH:index-1
            num1 = numbers[i]
            for j = i+1:index-1
                num2 = numbers[j]
                if num1+num2 == test_num
                    valid = true
                    break
                end
            end
            if valid
                break
            end
        end
        if !valid
            return test_num
        end
    end
end
" Solve Day 9-1 "
function first_bad_number(filename="day9.input")
    numbers = parse.(Int,readlines(filename))
    find_invalid_number(numbers)
end
" Find arbitray length list of contiguous numbers in array that sum to `invalid_num` "
function contiguous_numbers(numbers, invalid_num)
    len = length(numbers)
    for index = 1:len-1
        curr_sum = numbers[index]
        for offset = 1:len-index
            curr_sum += numbers[index+offset]
            if curr_sum == invalid_num
                return numbers[index:index+offset]
            else
                if curr_sum > invalid_num
                    # Our sum is too large - scrap list and move on
                    break
                end
            end
        end
    end
end
" Solve Day 9-2 "
function contiguous_sum(filename="day9.input")
    numbers = parse.(Int,readlines(filename))
    invalid_num = find_invalid_number(numbers)
    sum_to_invalid = contiguous_numbers(numbers, invalid_num)
    return minimum(sum_to_invalid)+maximum(sum_to_invalid)
end
