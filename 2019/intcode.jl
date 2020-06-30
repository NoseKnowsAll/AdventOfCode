module IntCode

export OpCode
export Instruction
export initialize_program, interpret_program!

# Enum just to specify which integer values correspond to which operations
@enum OpCode begin
    add=1
    multiply=2
    input=3
    output=4
    halt=99
    unknown=-1
end

# For backward compatibility among the different days - don't introduce
# functionality that wasn't yet introduced
global MAX_INSTRUCTION
MAX_INSTRUCTION = Int(halt)

# Number of digits that compose the opcode
OPCODE_LENGTH = 2

# Successful completion of program
SUCCESS = 0

# Invalid OpCode
INVALID_OPCODE = -1

# Writing instruction cannot be in immediate mode
IMMEDIATE_WRITE_ERROR = -2

# Returns the instruction length of a given opcode
function Base.length(opcode::OpCode)
    global MAX_INSTRUCTION
    if opcode == add
        return 4
    elseif opcode == multiply
        return 4
    elseif opcode == input && MAX_INSTRUCTION >= Int(input)
        return 2
    elseif opcode == output && MAX_INSTRUCTION >= Int(output)
        return 2
    elseif opcode == halt
        return 1
    else # Unrecognized opcode
        return 1
    end
end

# Mode of a given parameter
@enum Modes begin
    position=0  # interpret parameter as address
    immediate=1 # interpret parameter as value
end

# Struct containing all the information about the current instruction
struct Instruction
    opcode::OpCode
    length::Integer
    modes #::Array{Modes}
    parameters #::Array{Int32}

    function Instruction(opcode_::OpCode, relevant_program)
        # Handle unknown case immediately
        global MAX_INSTRUCTION
        if MAX_INSTRUCTION < Int(opcode_) && opcode_ != halt
            opcode_ = unknown
        end

        length_ = length(opcode_)
        instr_digits = digits(relevant_program[1], pad=length_)
        modes_ = instr_digits[OPCODE_LENGTH+1:end]
        parameters_ = relevant_program[2:length_]
        new(opcode_, length_, modes_, parameters_)
    end

    function Instruction(opcode_::Integer, relevant_program)
        # Handle unknown case immediately
        global MAX_INSTRUCTION
        if MAX_INSTRUCTION < opcode_ && opcode_ != halt
            true_opcode = unknown
        else
            true_opcode = OpCode(opcode_)
        end

        length_ = length(true_opcode)
        instr_digits = digits(relevant_program[1], pad=length_+1)
        modes_ = instr_digits[OPCODE_LENGTH+1:end]
        parameters_ = relevant_program[2:length_]
        new(true_opcode, length_, modes_, parameters_)
    end
end

function Base.show(io::IO, instruction::Instruction)
    print(io, "Instruction{OpCode=$(instruction.opcode), ")
    print(io, "len=$(instruction.length), ")
    print(io, "modes=$(instruction.modes), ")
    print(io, "params=$(instruction.parameters)}")
end

# Extracts information from instruction
function interpret_instruction(program, index)
    instr_digits = digits(program[index], pad=OPCODE_LENGTH)
    opcode = sum([instr_digits[k]*10^(k-1) for k = 1:OPCODE_LENGTH])
    relevant_program = program[index:index+length(OpCode(opcode))-1]
    return Instruction(opcode, relevant_program)
end

# Modify program by evaluating instruction
function eval_instruction!(program, instruction::Instruction; input_value=0)
    global MAX_INSTRUCTION

    if instruction.opcode == add
        val1 = 0
        if instruction.modes[1] == Int(position)
            val1 = program[instruction.parameters[1]+1] # ZERO-INDEXED INPUT
        elseif instruction.modes[1] == Int(immediate)
            val1 = instruction.parameters[1]
        end
        val2 = 0
        if instruction.modes[2] == Int(position)
            val2 = program[instruction.parameters[2]+1] # ZERO-INDEXED INPUT
        elseif instruction.modes[2] == Int(immediate)
            val2 = instruction.parameters[2]
        end
        val3 = instruction.parameters[3]+1 # ZERO-INDEXED INPUT
        if instruction.modes[3] != Int(position)
            error("adding to a value, not location")
            return IMMEDIATE_WRITE_ERROR
        end

        # Actually add
        program[val3] = val1+val2

    elseif instruction.opcode == multiply
        val1 = 0
        if instruction.modes[1] == Int(position)
            val1 = program[instruction.parameters[1]+1] # ZERO-INDEXED INPUT
        elseif instruction.modes[1] == Int(immediate)
            val1 = instruction.parameters[1]
        end
        val2 = 0
        if instruction.modes[2] == Int(position)
            val2 = program[instruction.parameters[2]+1] # ZERO-INDEXED INPUT
        elseif instruction.modes[2] == Int(immediate)
            val2 = instruction.parameters[2]
        end
        val3 = instruction.parameters[3]+1 # ZERO-INDEXED INPUT
        if instruction.modes[3] != Int(position)
            error("multiplying to a value, not location")
            return IMMEDIATE_WRITE_ERROR
        end

        # Actually multiply
        program[val3] = val1*val2

    elseif instruction.opcode == input && MAX_INSTRUCTION >= Int(input) # input
        val1 = instruction.parameters[1]+1 # ZERO-INDEXED INPUT
        if instruction.modes[1] != Int(position)
            error("inputting to a value, not location")
        end

        # Actually input
        program[val1] = input_value

    elseif instruction.opcode == output && MAX_INSTRUCTION >= Int(output) # output
        output_value = 0
        if instruction.modes[1] == Int(position)
            output_value = program[instruction.parameters[1]+1] # ZERO-INDEXED INPUT
        elseif instruction.modes[1] == Int(immediate)
            output_value = instruction.parameters[1]
        end

        # Actually output
        println("output = $output_value")

    else
        # an uknown opcode. Not necessarily an error
        return INVALID_OPCODE
    end
    return SUCCESS
end

# Reinterprets the string from the file as an array of integers to run as a program
function initialize_program(string)
    array_string = split(string,',')
    program = parse.(Int64,array_string)
    return program
end

# Actually evaluates the opcode program, updating program as it runs
function interpret_program!(program; input_value=0)
    index = 1
    # Handle input if necessary
    instruction = interpret_instruction(program, index)
    if instruction.opcode == input
        eval_instruction!(program, instruction, input_value=input_value)

        index += instruction.length
        instruction = interpret_instruction(program, index)
    end

    # Run program until it halts
    while instruction.opcode != halt
        error_code = eval_instruction!(program, instruction)
        if error_code != SUCCESS
            return error_code
        end

        # Setup for next instruction
        index += instruction.length
        instruction = interpret_instruction(program,index)
    end
    return SUCCESS
end

end
