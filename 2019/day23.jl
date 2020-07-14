include("intcode.jl")

# First address of actual input queue
const INPUT_QUEUE = 2
# Specifies the input queue is empty
const EMPTY = -1
# Address of NAT - 1-indexed
const NAT_ADDRESS = 255+1

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
    return instruction.opcode
end

# Runs a program until it has an entire packet to send. Returns that packet.
function send_packet!(program::IntCode.Program)
    #nonblocking_execute!(program) # Necessarily already executed
    neighbor_id = program.outputs[end] + 1 # ZERO-INDEXED ADDRESSES
    while nonblocking_execute!(program) != IntCode.output
    end
    x_value = program.outputs[end]
    while nonblocking_execute!(program) != IntCode.output
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
function send_receive_packets!(network)
    abort_address = NAT_ADDRESS
    while true
        for id = 1:length(network)
            result = nonblocking_execute!(network[id])
            if result == IntCode.output # Output something
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
function first_packet(filename="day23.input")
    program = init_program(filename)
    ncomputers = 50
    network = create_network_array(program, ncomputers)
    y = send_receive_packets!(network)
end

# Initialize NAT for use in restarting network
function init_nat()
    nat = [EMPTY, EMPTY]
end

# Update NAT with new packet
function update_nat_packet!(nat, x, y)
    push!(nat, x)
    push!(nat, y)
end

# Computer is idle if blocking on input and empty input queue
function idle_computer!(idle_network,network,id,last_instruction)
    if last_instruction == IntCode.input
        if network[id].inputs[network[id].in_pointer] == EMPTY
            idle_network[id] += 1
        end
    elseif last_instruction == IntCode.output
        idle_network[id] = 0
    end
end

# Restarts the network from the last package received at NAT
function restart_network!(network, nat, prev_nat, idle_network)
    receive_packet!(network[1], nat[end-1], nat[end])
    prev_nat[end-1] = nat[end-1]
    prev_nat[end] = nat[end]
    idle_network[:] .= 0
end

# Sends and receives all packets across the network and NAT. NAT will restart
# network if all computers have empty incoming packet queues and are continuously
# trying to recieve packets by giving network[1] a packet
function send_receive_packets!(network, nat)
    MAX_ITER = 10^6
    CONSIDER_IDLE = 150
    prev_nat = init_nat()
    idle_network = zeros(Int,length(network))
    iter = 1
    while iter < MAX_ITER
        for id = 1:length(network)
            result = nonblocking_execute!(network[id])
            if result == IntCode.output # Output something
                (nid, x, y) = send_packet!(network[id])
                #println("$id sent ($x,$y) to $nid @$iter") # debugging
                if nid == NAT_ADDRESS
                    update_nat_packet!(nat, x, y)
                else
                    receive_packet!(network[nid], x, y)
                end
            end
            idle_computer!(idle_network,network,id,result)
            reset_input_queue!(network[id])
        end

        if all(idle_network .> CONSIDER_IDLE) && iter > 1
            if nat[end] == prev_nat[end] # Quit once in infinite restart loop
                return nat[end]
            end
            restart_network!(network, nat, prev_nat, idle_network)
        end
        iter += 1
    end
end

# Solves day 23-2
function nat_packet(filename="day23.input")
    program = init_program(filename)
    ncomputers = 50
    network = create_network_array(program, ncomputers)
    nat = init_nat()
    send_receive_packets!(network, nat)
end
