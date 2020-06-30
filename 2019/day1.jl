function compute_fuel(mass)
    return floor(Int64,mass/3)-2
end

function compute_total_fuel(total_mass)
    total_fuel = 0
    mass = compute_fuel(total_mass)
    while mass > 0
        total_fuel += mass
        mass = compute_fuel(mass)
    end
    return total_fuel
end

# Solve day1-1
function fuel_requirement(filename="day1.input")
    total_fuel = 0
    for line in eachline(filename)
        total_fuel += compute_fuel(parse(Int64, line))
    end
    return total_fuel
end

# Solve day1-2
function fuel_requirement2(filename="day1.input")
    total_fuel = 0
    for line in eachline(filename)
        total_fuel += compute_total_fuel(parse(Int64, line))
    end
    return total_fuel
end
