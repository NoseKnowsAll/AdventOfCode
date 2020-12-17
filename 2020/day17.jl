const ACTIVE = 1
const INACTIVE = 0
" Read in 2D slice from file "
function read_2d_slice(filename)
    height = countlines(filename)
    width = length(readline(filename))
    slice = zeros(Int, height, width)
    function char2int(char)
        if char == '#'
            return ACTIVE
        elseif char == '.'
            return INACTIVE
        else
            error("$char NOT A VALID CHAR!")
        end
    end
    for (i,line) in enumerate(readlines(filename))
        slice[i,:] = char2int.(collect(line))
    end
    return slice
end
" Test for adjacent neighbor in the given direction specified by `off` from `loc`. "
function check_direction!(neighbors, loc, cube, off)
    tentative_neighbor = loc+off
    if !checkbounds(Bool, cube, tentative_neighbor)
        return
    end
    push!(neighbors, tentative_neighbor)
end
" Update neighbors to contain all adjacent neighbors of `loc` "
function get_neighbors!(neighbors, loc, cube)
    origin = CartesianIndex(zeros(Int,ndims(cube))...)
    for off in CartesianIndices(ntuple(x->UnitRange(-1:1), ndims(cube)))
        if !(off == origin)
            check_direction!(neighbors, loc, cube, off)
        end
    end
    return neighbors
end
" Precompute all neighbors in all_neighbors array for performance purposes.
Useful for advancing across many time steps with cubes that have few dimensions.
Otherwise it is best to simply recompute neighbors every iteration. "
function compute_all_neighbors(cube)
    all_neighbors = Array{Array{CartesianIndex,1},ndims(cube)}(undef,size(cube)...)
    for loc in CartesianIndices(cube)
        all_neighbors[loc] = CartesianIndex[]
        get_neighbors!(all_neighbors[loc], loc, cube)
    end
    return all_neighbors
end
" Advance cube one time step according to automata rules and return next cube "
function advance(cube)
    new_cube = deepcopy(cube)
    for loc in CartesianIndices(cube)
        active_neighbors = 0
        neighbors = CartesianIndex[]
        get_neighbors!(neighbors, loc, cube)
        for neighbor in neighbors
            if cube[neighbor] == ACTIVE
                active_neighbors += 1
            end
        end
        # Rules for cellular automata advancement
        if cube[loc] == INACTIVE && active_neighbors == 3
            new_cube[loc] = ACTIVE
        elseif cube[loc] == ACTIVE && !(2 <= active_neighbors <= 3)
            new_cube[loc] = INACTIVE
        end
    end
    return new_cube
end
" Advance the cube NCYCLES iterations and return the active hypercubes "
function run_cycles(cube, NCYCLES)
    # For large dimensions this unnecessary memory allocation slows performance
    #all_neighbors = compute_all_neighbors(cube)
    for i = 1:NCYCLES
        cube = advance(cube)
    end
    sum(cube)
end
" Solve Day 17-1 "
function six_cycles_3d(filename="day17.input")
    slice = read_2d_slice(filename)
    NCYCLES = 6
    cube = zeros(Int, size(slice,1)+2*NCYCLES, size(slice,2)+2*NCYCLES, 1+2*NCYCLES)
    cube[NCYCLES+1:NCYCLES+size(slice,1),NCYCLES+1:NCYCLES+size(slice,2),NCYCLES+1] .= slice
    run_cycles(cube, NCYCLES)
end
" Solve Day 17-2 "
function six_cycles_4d(filename="day17.input")
    slice = read_2d_slice(filename)
    NCYCLES = 6
    cube = zeros(Int, size(slice,1)+2*NCYCLES, size(slice,2)+2*NCYCLES, 1+2*NCYCLES, 1+2*NCYCLES)
    cube[NCYCLES+1:NCYCLES+size(slice,1),NCYCLES+1:NCYCLES+size(slice,2),NCYCLES+1,NCYCLES+1] .= slice
    run_cycles(cube, NCYCLES)
end
" Solve Day 17-3: Bonus edition - 5D "
function six_cycles_5d(filename="day17.input")
    slice = read_2d_slice(filename)
    NCYCLES = 6
    cube = zeros(Int, size(slice,1)+2*NCYCLES, size(slice,2)+2*NCYCLES, 1+2*NCYCLES, 1+2*NCYCLES, 1+2*NCYCLES)
    cube[NCYCLES+1:NCYCLES+size(slice,1),NCYCLES+1:NCYCLES+size(slice,2),NCYCLES+1,NCYCLES+1,NCYCLES+1] .= slice
    run_cycles(cube, NCYCLES)
end
