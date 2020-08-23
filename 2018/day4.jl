using DataStructures

# Reads the entire file into a Dict of action dicts:
# Main key is guard ID, and the subdicts are ordered chronologically by timestamp
function read_file(filename)
    action_dict = SortedDict{Int64, String}()
    for line in readlines(filename)
        (digit_val, action) = interpret_line(line)
        action_dict[digit_val] = action
    end

    all_sleep_times = Dict{Int64,Array{Tuple}}()
    curr_guard = 0
    sleep_time = 0
    awake_time = 0
    for (k,action) in action_dict
        if action[1] == 'G' # Guard # begins shift
            m = match(r"(\d+)",action)
            curr_guard = parse(Int64,m.captures[1])
        elseif action[1] == 'f' # falls asleep
            sleep_time = rem(k,100)
        elseif action[1] == 'w' # wakes up
            awake_time = rem(k,100)
            so_far = get!(all_sleep_times, curr_guard, [])
            push!(so_far, (sleep_time,awake_time))
        end
    end
    return all_sleep_times
end

# Interprets a given line of code into (1) time and (2) action string
function interpret_line(line::String)
    m = match(r"(\d+)-(\d+)-(\d+) (\d+):(\d+)", line)
    times = parse.(Int64, m.captures)
    digit_val = times'* (100 .^(length(times)-1:-1:0))
    last_index = m.offsets[end]+length(m.captures[end])
    action = line[last_index+2:end]
    return (digit_val, action)
end

# Compute the guard who sleeps the most
function guard_most_asleep(all_sleep_times)
    asleep_minutes = Dict{Int64,Int64}()
    max_sleep_time = 0
    max_sleep_id = 0
    for (guard_id, sleep_times) in all_sleep_times
        asleep_minutes[guard_id] = 0
        for (sleep_minute, awake_minute) in sleep_times
            total_sleep_minutes = awake_minute - sleep_minute
            asleep_minutes[guard_id] += total_sleep_minutes
            if asleep_minutes[guard_id] > max_sleep_time
                max_sleep_time = asleep_minutes[guard_id]
                max_sleep_id = guard_id
            end
        end
    end
    return max_sleep_id
end

# Return the specific minute this guard is most often asleep from their action_dict
function find_most_asleep_minute(sleep_times)
    MINUTES_PER_HOUR = 60
    minutes = zeros(MINUTES_PER_HOUR)
    for (sleep_minute,awake_minute) in sleep_times
        minutes[sleep_minute+1:awake_minute] .+= 1 # ONE-INDEXED
    end
    (maxval, minute) = findmax(minutes)
    return minute-1 # ZERO-INDEXED
end

# Solves Day 4-1
function most_asleep(filename="day4.input")
    all_sleep_times = read_file(filename)
    max_sleep_guard_id = guard_most_asleep(all_sleep_times)
    minute = find_most_asleep_minute(all_sleep_times[max_sleep_guard_id])
    return max_sleep_guard_id*minute
end

# Find the guard and minute on which this guard is most frequently asleep
function guard_most_asleep_minute(all_sleep_times)
    max_asleep_times = 0
    asleep_minute = 0
    asleep_guard = 0
    for (guard,sleep_times) in all_sleep_times
        MINUTES_PER_HOUR = 60
        minutes = zeros(MINUTES_PER_HOUR)
        for (sleep_minute, awake_minute) in sleep_times
            minutes[sleep_minute+1:awake_minute] .+= 1 # ONE-INDEXED
        end
        (maxval, minute) = findmax(minutes)
        if maxval > max_asleep_times
            max_asleep_times = maxval
            asleep_minute = minute-1 # ZERO-INDEXED
            asleep_guard = guard
        end
    end
    return (asleep_guard, asleep_minute)
end

# Solves Day 4-2
function same_minute_asleep(filename="day4.input")
    all_sleep_times = read_file(filename)
    (guard_id,minute) = guard_most_asleep_minute(all_sleep_times)
    return guard_id*minute
end
