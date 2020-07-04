# Array of structs for performance benefits
mutable struct Moons
    positions::Matrix{Int}
    velocities::Matrix{Int}
end

# From filename, extract initial position values
function read_init_positions(filename)::Moons
    moons = Moons(zeros(Int,3,4), zeros(Int,3,4))
    for (iter,line) in enumerate(eachline(filename))
        m = match(r"<x=(-?\d+), y=(-?\d+), z=(-?\d+)>", line)
        moons.positions[:,iter] = parse.(Int, m.captures)
    end
    return moons
end

# The poor man's gravity
function apply_force!(moons::Moons,i,j, index)
    for d in index
        vel_diff = sign(moons.positions[d,i] - moons.positions[d,j])
        moons.velocities[d,i] -= vel_diff
        moons.velocities[d,j] += vel_diff
    end
end

# Apply gravity amongst all the moons
function apply_forces!(moons::Moons, index)
    for i = 1:size(moons.positions,2)
        for j = i+1:size(moons.positions,2)
            apply_force!(moons,i,j, index)
        end
    end
end

# Move positions acccording to velocity
function apply_velocity!(moons::Moons, index)
    moons.positions[index,:] .+= moons.velocities[index,:]
end

# Time step the moons
function timestep!(moons::Moons, index=1:size(moons.positions,1))
    apply_forces!(moons,index)
    apply_velocity!(moons,index)
end

# Poor man's energy of the system
function compute_energy(moons::Moons)
    p_energy = sum(abs.(moons.positions),dims=1)
    k_energy = sum(abs.(moons.velocities),dims=1)
    return sum(p_energy.*k_energy)
end

# Solves day 12-1
function total_energy(filename="day12.input", timesteps=1000)
    moons = read_init_positions(filename)
    for i = 1:timesteps
        timestep!(moons)
    end
    compute_energy(moons)
end

# Solves day 12-2
function history_repeats_itself(filename="day12.input")
    init_moons = read_init_positions(filename)
    moons = deepcopy(init_moons)

    # Simulate each dimension separately in order to get back to the init state
    dims = size(moons.positions,1)
    timesteps_to_repeat = zeros(Int,dims)
    Threads.@threads for d = 1:dims
        timesteps = 0
        while !(moons.positions[d,:] == init_moons.positions[d,:] &&
            moons.velocities[d,:] == init_moons.velocities[d,:]) ||
            timesteps == 0
            timestep!(moons, d)
            timesteps += 1
        end
        timesteps_to_repeat[d] = timesteps
    end
    # Compute the number of timesteps to repeat the entire state using lcm
    total_lcm = 1
    for d = 1:dims
        total_lcm = lcm(timesteps_to_repeat[d],total_lcm)
    end
    return total_lcm
end
