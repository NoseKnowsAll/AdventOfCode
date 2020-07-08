# Return the ones digit of input, ignoring negative signs
function ones_digit(n)
    return mod(abs(n),10)
end

# Return the number based on an array of digits
function digits2num(digits)
    sum([digits[k]*10^(k-1) for k=1:length(digits)])
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

# Computes one phase of the "FFT" in-place of output
function phase_FFT!(input, output, base)
    for element = 1:length(output)
        mult_pattern = pattern(element, base, length(input))
        output[element] = ones_digit(sum(input .* mult_pattern))
    end
end

# Solves day 16-1
function eight_digits(filename="day16.input", phases=100)
    current = read_file(filename)
    next = deepcopy(current)
    base = [0 1 0 -1]
    for phase = 1:phases
        if mod(phase,2) == 0
            phase_FFT!(current, next, base)
        else
            phase_FFT!(next, current, base)
        end
    end

    # Only consider first 8 digits
    return digits2num(next[8:-1:1])
end

# Solves day 16-2
function eight_digits_repeat(filename="day16.input", phases=100)
    REPEAT = 10000
    current = read_file(filename,REPEAT)
    offset = digits2num(current[7:-1:1])
    base = [0 1 0 -1]
    for phase = 1:phases
        println(phase)
        current = phase_FFT(current, base)
    end

    # Only consider 8 digits, specified by the first seven digits of input
    return digits2num(current[offset+7:-1:offset])
end
