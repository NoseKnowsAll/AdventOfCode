" Read in first line as `departure_time`, second line as `bus_times` and `positions` arrays "
function read_bus_times(filename)
    lines = readlines(filename)
    departure_time = parse(Int, lines[1])
    times = split(lines[2], ",")
    bus_times = []
    positions = []
    for (i,time) in enumerate(times)
        if time == "x"
            continue
        else
            push!(bus_times, parse(Int,time))
            push!(positions, i-1)
        end
    end
    return departure_time, bus_times, positions
end
" Solve Day 13-1 "
function id_mult_delay(filename="day13.input")
    departure_time, bus_times = read_bus_times(filename)
    min_delay = departure_time
    min_ID = 0
    for time in bus_times
        delay = time-mod(departure_time, time)
        if time == delay
            error("DID NOT HANDLE 0 case!")
        end
        if delay < min_delay
            min_delay = delay
            min_ID = time
        end
    end
    return min_ID*min_delay
end
" Find minimum solution to equations t == rem1 (mod mod1), t == rem2 (mod mod2).
Uses extended Euclidean algorithm in `gcdx` to construct solution we know
exists according to Chinese Remainder theorem. "
function construct_next_solution(rem1, mod1, rem2, mod2)
    #println("solving t == $rem1 (mod $mod1), t == $rem2 (mod $mod2)")
    d, bezout1, bezout2 = gcdx(mod1, mod2)
    @assert d == 1 "modulars must be prime!"
    soln = rem1*(mod2*bezout2) + rem2*(mod1*bezout1)
    new_mod = mod2*mod1
    new_rem = mod(soln, new_mod)
    # solution t satisfies new equation soln == new_rem (mod new_mod)
    return soln, new_rem, new_mod
end
" Solve Day 13-2 "
function offsets_meet_positions(filename="day13.input")
    departure_time, bus_times, positions = read_bus_times(filename)
    time2rem(position, time) = mod(-position, time)
    prev_rem = Int128(time2rem(positions[1], bus_times[1])) # Int64 not big enough
    prev_mod = Int128(bus_times[1])
    soln = 0
    for i = 2:length(bus_times)
        next_rem = Int128(time2rem(positions[i], bus_times[i]))
        next_mod = Int128(bus_times[i])
        soln, prev_rem, prev_mod = construct_next_solution(prev_rem, prev_mod, next_rem, next_mod)
    end
    return prev_rem
end
