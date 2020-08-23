using DataStructures

# Reads the entire file into a Dict of action dicts:
# Main key is guard ID, and the subdicts are ordered chronologically by timestamp
function read_file(filename)
    action_dict = SortedDict{Int64, String}()
    for line in readlines(filename)
        (digit_val, action) = interpret_line(line)
        action_dict[digit_val] = action
    end

    all_action_dicts = Dict{Int64,SortedDict}()
    curr_guard = 0
    for (k,action) in action_dict
        if action[1] == 'G' # Guard # begins shift
            m = match(r"(\d+)",action)
            curr_guard = parse(Int64,m.captures[1])
        else
            so_far = get!(all_action_dicts, curr_guard, SortedDict{Int64,String}())
            so_far[k] = action
        end
    end
    return all_action_dicts
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
function guard_most_asleep(all_action_dicts)
    asleep_minutes = Dict{Int64,Int64}()
    max_sleep_time = 0
    max_sleep_id = 0
    for (guard_id, action_dict) in all_action_dicts
        asleep_minutes[guard_id] = 0
        start_sleep_minute = 0
        for (k,action) in action_dict
            if action[1] == 'f' # falls asleep
                start_sleep_minute = rem(k,100)
            elseif action[1] == 'w' # wakes up
                total_sleep_minutes = rem(k,100) - start_sleep_minute
                asleep_minutes[guard_id] += total_sleep_minutes
                if asleep_minutes[guard_id] > max_sleep_time
                    max_sleep_time = asleep_minutes[guard_id]
                    max_sleep_id = guard_id
                end
            end
        end
    end
    return max_sleep_id
end

# Return the specific minute this guard is most often asleep from their action_dict
function find_most_asleep_minute(action_dict)
    MINUTES_PER_HOUR = 60
    minutes = zeros(MINUTES_PER_HOUR)
    start_sleep_minute = 0
    for (k,action) in action_dict
        if action[1] == 'f' # falls asleep
            start_sleep_minute = rem(k,100)
        elseif action[1] == 'w' # wakes up
            minutes[start_sleep_minute+1:rem(k,100)] .+= 1 # ONE-INDEXED
        end
    end
    (maxval, minute) = findmax(minutes)
    return minute-1 # ZERO-INDEXED
end

# Solves day 4-1
function most_asleep(filename="day4.input")
    all_action_dicts = read_file(filename)
    max_sleep_guard_id = guard_most_asleep(all_action_dicts)
    minute = find_most_asleep_minute(all_action_dicts[max_sleep_guard_id])
    return max_sleep_guard_id*minute
end

# Find the guard and minute on which this guard is most frequently asleep
function guard_most_asleep_minute(all_action_dicts)
    max_asleep_times = 0
    asleep_minute = 0
    asleep_guard = 0
    for (guard,action_dict) in all_action_dicts
        MINUTES_PER_HOUR = 60
        minutes = zeros(MINUTES_PER_HOUR)
        start_sleep_minute = 0
        for (k,action) in action_dict
            if action[1] == 'f' # falls asleep
                start_sleep_minute = rem(k,100)
            elseif action[1] == 'w' # wakes up
                minutes[start_sleep_minute+1:rem(k,100)] .+= 1 # ONE-INDEXED
            end
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

# Solves day 4-2
function same_minute_asleep(filename="day4.input")
    all_action_dicts = read_file(filename)
    (guard_id,minute) = guard_most_asleep_minute(all_action_dicts)
    return guard_id*minute
end
