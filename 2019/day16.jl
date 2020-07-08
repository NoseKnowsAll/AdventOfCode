using LinearAlgebra

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
    pat = zeros(Int8, element, length(base))
    for i = 1:length(base)
        for e = 1:element
            pat[e,i] = base[i]
        end
    end
    pattern_n = zeros(Int8, n+1)
    for index = 1:n+1
        pattern_n[index] = pat[mod(index-1,length(base)*element)+1]
    end
    popfirst!(pattern_n) # Pattern for first element is left shifted once
    return pattern_n
end

# Create the pattern matrix to multiply input by for all elements
function pattern_matrix(n)
    base = [0, 1, 0, -1]
    matrix = zeros(Int8, n,n)
    for element = 1:n
        mult = pattern(element, base, n)
        matrix[element,:] = mult
    end
    return matrix
end

# Computes one phase of the "FFT" assuming the pattern matrix has been precomputed
function phase_FFT_mat(input, mult_matrix)
    return ones_digit.(mult_matrix*input)
end

# Solves day 16-1 (full matrix implementation)
function eight_digits_mat(filename="day16.input", phases=100)
    current = read_file(filename)
    mult_matrix = pattern_matrix(length(current))
    for phase = 1:phases
        current = phase_FFT_mat(current, mult_matrix)
    end

    # Only consider first 8 digits
    return digits2num(current[8:-1:1])
end

# Out of place performant computation of next phase using multithreading
function phase_fft(input, offset=0)
    output = zeros(Int,size(input))

    function compute_row(right_half, element)
        row = 0
        len = length(right_half)
        repeats = floor(Int,len/(4*element))
        for it = 1:repeats
            off = 4*element*(it-1)
            row += sum(@view right_half[off+1:off+element])
            row -= sum(@view right_half[off+2*element+1:off+3*element])
        end
        # Finish computation using any missing values at end of row
        off = 4*element*repeats
        row += sum(@view right_half[off+1:min(off+element,len)])
        row -= sum(@view right_half[off+2*element+1:min(off+3*element,len)])
        return ones_digit(row)
    end

    # Update each row using only the values below current row similar to
    # Gauss-Seidel because pattern_matrix forms an upper triangular matrix
    Threads.@threads for element = 1:length(input)
        right_half = @view input[element:length(input)]
        output[element] = compute_row(right_half, element+offset)
    end
    return output
end

# In-place updates input to the values at next phase
function phase_fft!(input, offset=0)
    function compute_row(right_half, element)
        row = 0
        len = length(right_half)
        repeats = floor(Int,len/(4*element))
        for it = 1:repeats
            off = 4*element*(it-1)
            row += sum(@view right_half[off+1:off+element])
            row -= sum(@view right_half[off+2*element+1:off+3*element])
        end
        # Finish computation using any missing values at end of row
        off = 4*element*repeats
        row += sum(@view right_half[off+1:min(off+element,len)])
        row -= sum(@view right_half[off+2*element+1:min(off+3*element,len)])
        return ones_digit(row)
    end

    # Update each row using only the values below current row similar to
    # Gauss-Seidel because pattern_matrix forms an upper triangular matrix
    for element = 1:length(input)
        right_half = @view input[element:length(input)]
        input[element] = compute_row(right_half, element+offset)
    end
end

# Solves day 16-1 (performant implementation)
function eight_digits_perf(filename="day16.input", phases=100)
    current = read_file(filename)
    for phase = 1:phases
        current = phase_fft(current)
    end

    # Only consider first 8 digits
    return digits2num(current[8:-1:1])
end

# Solves day 16-2
function eight_digits_repeat(filename="day16.input", phases=100)
    REPEAT = 10000
    initial = read_file(filename,REPEAT)
    offset = digits2num(initial[7:-1:1])
    # MM with upper-triangular matrix means causality flows one way and we do
    # not need to consider input before this offset!
    current = initial[offset+1:end]
    for phase = 1:phases
        println(phase)
        current = phase_fft(current,offset)
    end

    # Only consider 8 digits, specified by the first seven digits of input
    return digits2num(current[8:-1:1])
end
