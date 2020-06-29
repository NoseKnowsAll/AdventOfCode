# Check if a given array of digits satisfies our password requirements
function valid_password1(digits)
    n = length(digits)
    # 6-digit number
    if n != 6
        return false
    end
    # From left to right, consecutive digits never decrease
    for i = 1:n-1
        if digits[i] < digits[i+1]
            return false
        end
    end
    # At least one pair of adjacent digits
    adjacent_digits = false
    for i = 1:n-1
        if digits[i] == digits[i+1]
            adjacent_digits = true
        end
    end
    return adjacent_digits
end

# Generate all possible passwords that are valid for part 1
function generate_passwords1(min_val=387638, max_val=919123)
    total_valid = 0
    for i = min_val:max_val
        if valid_password1(digits(i))
            total_valid += 1
        end
    end
    return total_valid
end

# Check if a given array of digits satisfies our password requirements
function valid_password2(digits)
    n = length(digits)
    # 6-digit number
    if n != 6
        return false
    end
    # From left to right, consecutive digits never decrease
    for i = 1:n-1
        if digits[i] < digits[i+1]
            return false
        end
    end
    # At least one pair of adjacent digits
    adjacent_digits = false
    consecutive_digits = 1
    for i = 1:n-1
        if digits[i] == digits[i+1]
            consecutive_digits += 1
        else
            if consecutive_digits == 2
                adjacent_digits = true
            end
            consecutive_digits = 1
        end
    end
    if consecutive_digits == 2
        adjacent_digits = true
    end
    return adjacent_digits
end

# Generate all possible passwords that are valid for part 1
function generate_passwords2(min_val=387638, max_val=919123)
    total_valid = 0
    for i = min_val:max_val
        if valid_password2(digits(i))
            total_valid += 1
        end
    end
    return total_valid
end
