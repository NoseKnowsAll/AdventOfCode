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
function apply_force!(moons::Moons,i,j)
    for d = 1:size(moons.positions,1)
        vel_diff = sign(moons.positions[d,i] - moons.positions[d,j])
        moons.velocities[d,i] -= vel_diff
        moons.velocities[d,j] += vel_diff
    end
end

# Apply gravity amongst all the moons
function apply_forces!(moons::Moons)
    for i = 1:size(moons.positions,2)
        for j = i+1:size(moons.positions,2)
            apply_force!(moons,i,j)
        end
    end
end

# Move positions acccording to velocity
function apply_velocity!(moons::Moons)
    moons.positions .+= moons.velocities
end

# Time step the moons
function timestep!(moons::Moons)
    apply_forces!(moons)
    apply_velocity!(moons)
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
