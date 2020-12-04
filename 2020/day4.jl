" Read in the file and store as array of dictionaries all_passports "
function read_passports(filename)
    all_passports = []
    curr_passport = Dict{String,String}()
    itr = 1
    for (i,line) in enumerate(eachline(filename))
        if line == ""
            itr += 1
            push!(all_passports, curr_passport)
            curr_passport = Dict{String,String}()
            continue
        end
        pairs = split(line," ")
        for pair in pairs
            words = split(pair, ":")
            curr_passport[words[1]] = words[2]
        end
    end
    push!(all_passports, curr_passport)
    return all_passports
end

" Checks that given passport has necessary fields to be considered valid for part 1 "
function passport_has_fields(passport::Dict)
    necessary_fields = ["byr","iyr","eyr","hgt","hcl","ecl","pid"] # not cid
    for field in necessary_fields
        if !(field ∈ keys(passport))
            return false
        end
    end
    return true
end

" Solves Day 4-1 "
function valid_passports(filename="day4.input")
    all_passports = read_passports(filename)
    count(passport_has_fields, all_passports)
end

" Passport is only valid if it has correct fields AND each field is valid "
function strict_valid_passport(passport::Dict)
    function valid_byr(byr)
        try
            birthyear = parse(Int,byr)
            return 1920 <= birthyear <= 2002
        catch
            return false
        end
    end
    function valid_iyr(iyr)
        try
            issueyear = parse(Int,iyr)
            return 2010 <= issueyear <= 2020
        catch
            return false
        end
    end
    function valid_exp(eyr)
        try
            expyear = parse(Int, eyr)
            return 2020 <= expyear <= 2030
        catch
            return false
        end
    end
    function valid_height(hgt)
        try
            unit = hgt[end-1:end]
            num = parse(Int, hgt[1:end-2])
            return (unit == "cm" && 150 <= num <= 193) || (unit == "in" && 59 <= num <= 76)
        catch
            return false
        end
    end
    function valid_hair(hcl)
        if hcl[1] == '#'
            possible = collect("0123456789abcdef")
            for letter in collect(hcl[2:end])
                if letter ∉ possible
                    return false
                end
            end
            return true
        else
            return false
        end
    end
    function valid_eye(ecl)
        possible = ["amb","blu","brn","gry","grn","hzl","oth"]
        return ecl ∈ possible
    end
    function valid_pid(pid)
        if length(pid) == 9
            try
                num = parse(Int, pid)
                return true
            catch
                return false
            end
        else
            return false
        end
    end
    return passport_has_fields(passport) &&
        valid_byr(passport["byr"]) && valid_iyr(passport["iyr"]) &&
        valid_exp(passport["eyr"]) && valid_height(passport["hgt"]) &&
        valid_hair(passport["hcl"]) && valid_eye(passport["ecl"]) &&
        valid_pid(passport["pid"])
end

" Solves Day 4-2 "
function strict_valid_passports(filename="day4.input")
    all_passports = read_passports(filename)
    count(strict_valid_passport, all_passports)
end
