" Parses file into an array of numbers "
function file_numbers(filename)
    numbers = []
    for line in eachline(filename)
        number = parse(Int, line)
        push!(numbers, number)
    end
    return numbers
end

" Solves Day1-1 "
function two_numbers(filename="day1.input")
    NUMBER_TO_SUM_TO = 2020
    numbers = file_numbers(filename)
    for i = 1:length(numbers)
        num1 = numbers[i]
        for j = i+1:length(numbers)
            num2 = numbers[j]
            if num1+num2 == NUMBER_TO_SUM_TO
                return num1*num2
            end
        end
    end
end
" Solves Day1-2 "
function three_numbers(filename="day1.input")
    NUMBER_TO_SUM_TO = 2020
    numbers = file_numbers(filename)
    for i = 1:length(numbers)
        num1 = numbers[i]
        for j = i+1:length(numbers)
            num2 = numbers[j]
            for k = j+1:length(numbers)
                num3 = numbers[k]
                if num1+num2+num3 == NUMBER_TO_SUM_TO
                    return num1*num2*num3
                end
            end
        end
    end
end
