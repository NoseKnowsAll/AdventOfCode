include("intcode.jl")

# First address of actual input queue
const INPUT_QUEUE = 2
# Specifies the input queue is empty
const EMPTY = -1

# Initialize program for sending/receiving packets
function init_program(filename)
    file = open(filename)
    string = readline(file)
    close(file)

    program = IntCode.initialize_program(string)
    IntCode.single_output!(program)
    return program
end

# Initialize network array
function create_network_array(program::IntCode.Program, ncomputers)
    network = IntCode.Program[]
    max_consecutive_inputs = 2*ncomputers
    for id = 1:ncomputers
        push!(network, deepcopy(program))
        # Computers must first know their own address
        push!(network[id].inputs, id-1) # ZERO-INDEXED ADDRESSES
        # Until there is an input packet, input queue is EMPTY
        append!(network[id].inputs, EMPTY.*ones(Int, max_consecutive_inputs))
    end
    return network
end

# Executes a single instruction in a non-blocking format. Only returns if output
function nonblocking_execute!(program::IntCode.Program)
    # Executes one instruction
    instruction = IntCode.interpret_instruction(program)
    error_code = IntCode.eval_instruction!(program, instruction)
    program.pointer += instruction.length
    if instruction.opcode == IntCode.output
        return program.outputs[end]
    end
end

# Runs a program until it has an entire packet to send. Returns that packet.
function send_packet!(program::IntCode.Program)
    #nonblocking_execute!(program) # Necessarily already executed
    neighbor_id = program.outputs[end] + 1 # ZERO-INDEXED ADDRESSES
    while nonblocking_execute!(program) === nothing
    end
    x_value = program.outputs[end]
    while nonblocking_execute!(program) === nothing
    end
    y_value = program.outputs[end]
    return (neighbor_id, x_value, y_value)
end

# Resets the input queue of a given program so that it does not run out of input memory
function reset_input_queue!(program::IntCode.Program)
    if program.inputs[program.in_pointer] == EMPTY
        # If computer is past the end of actual queue, reset queue to beginning
        program.inputs[INPUT_QUEUE:program.in_pointer] .= EMPTY
        program.in_pointer = INPUT_QUEUE
    elseif program.in_pointer >= INPUT_QUEUE
        # Shift remaining queue to the beginning and fill end with EMPTY
        old_queue = splice!(program.inputs, INPUT_QUEUE:program.in_pointer-1)
        append!(program.inputs, EMPTY.*ones(Int, length(old_queue)))
        program.in_pointer -= length(old_queue)
    end
end

# Receives the (x,y) packet in a given program
function receive_packet!(program::IntCode.Program, x, y)
    start_queue = findfirst(program.inputs .== EMPTY)
    @assert start_queue >= INPUT_QUEUE
    # Puts packet to end of non-empty queue
    program.inputs[start_queue] = x
    program.inputs[start_queue+1] = y
end

# Sends and receives all packets across the network until abort_address
# receives its first packet. Returns the Y value of that first packet
function send_receive_packets!(network, abort_address)
    while true
        for id = 1:length(network)
            result = nonblocking_execute!(network[id])
            if result !== nothing # Output something
                (nid, x, y) = send_packet!(network[id])
                # println("$id sent ($x,$y) to $nid") # debugging
                if nid == abort_address
                    return y
                end
                receive_packet!(network[nid], x, y)
            end
            reset_input_queue!(network[id])
        end
    end
end

# Solves day 23-1
function first_packet(filename="day23.input", final_address=255)
    program = init_program(filename)
    ncomputers = 50
    network = create_network_array(program, ncomputers)
    y = send_receive_packets!(network, final_address+1)
end
