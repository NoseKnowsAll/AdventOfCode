# Return the ones digit of input, ignoring negative signs
function ones_digit(n)
    return mod(abs(n),10)
end

# Read the file and store as a list of digits
function read_file(filename, repeat=1)
    file = open(filename)
    string = readline(file)
    close(file)
    string = string^repeat
    return parse.(Int,collect(string))
end

# The integer pattern to multiply an n digit list by for a given element
function pattern(element,base,n)
    pat = zeros(Int, element, length(base))
    for i = 1:length(base)
        for e = 1:element
            pat[e,i] = base[i]
        end
    end
    pattern_n = zeros(Int, n+1)
    for index = 1:n+1
        pattern_n[index] = pat[mod(index-1,length(base)*element)+1]
    end
    popfirst!(pattern_n) # Pattern for first element is left shifted once
    return pattern_n
end

# Computes one phase of the "FFT"
function phase_FFT(input, base)
    output = deepcopy(input)
    for element = 1:length(output)
        mult_pattern = pattern(element, base, length(input))
        output[element] = ones_digit(sum(input .* mult_pattern))
    end
    return output
end

# Solves day 16-1
function eight_digits(filename="day16.input", phases=100)
    current = read_file(filename)
    base = [0 1 0 -1]
    for phase = 1:phases
        current = phase_FFT(current, base)
    end

    # Only consider first 8 digits
    return current[1:8]
end

# Solves day 16-2
function eight_digits_repeat(filename="day16.input", phases=100)
    REPEAT = 10000
    current = read_file(filename,REPEAT)
    base = [0 1 0 -1]
    for phase = 1:phases
        println(phase)
        current = phase_FFT(current, base)
    end

    # Only consider first 8 digits
    return current[1:8]
end
