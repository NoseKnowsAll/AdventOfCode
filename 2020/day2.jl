" Password and ruleset for password "
struct Password
    min     # For part 2 this is the location in array
    max     # For part 2 this is the location in array
    char    # Which character to match
    string  # The actual password
end

" Import passwords from filename into Password array "
function password_pairs(filename)
    pairs = Password[]
    for line in eachline(filename)
        m = match(r"(\d+)-(\d+) (\w+): (\w+)",line)
        min = parse(Int64, m.captures[1])
        max = parse(Int64, m.captures[2])
        char = m.captures[3][1]
        password = Password(min,max,char,m.captures[4])
        push!(pairs, password)
    end
    return pairs
end
" Check if password is valid according to part 1 rules "
function is_valid_password1(password::Password)
    return password.min <= count(x->x==password.char,collect(password.string)) <= password.max
end
" Solves Day 2-1 "
function total_valid_passwords1(filename="day2.input")
    pairs = password_pairs(filename)
    return count(is_valid_password1, pairs)
end
" Check if password is valid according to part 2 rules "
function is_valid_password2(password::Password)
    return xor(password.string[password.min] == password.char,
               password.string[password.max] == password.char)
end
" Solves Day 2-2 "
function total_valid_passwords2(filename="day2.input")
    pairs = password_pairs(filename)
    return count(is_valid_password2, pairs)
end
