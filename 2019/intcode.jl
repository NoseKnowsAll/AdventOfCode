module IntCode

export OpCode
export ProgramMode
export Program
export Instruction
export initialize_program, interpret_program!

# Enum just to specify which integer values correspond to which operations
@enum OpCode begin
    add=1
    multiply=2
    input=3
    output=4
    jump_if_true=5
    jump_if_false=6
    less_than=7
    equals=8
    relative_base=9
    halt=99
    unknown=-1
end

# For backward compatibility among the different days - don't introduce
# functionality that wasn't yet introduced
global MAX_INSTRUCTION
MAX_INSTRUCTION = Int(halt)

# Number of digits that compose the opcode
OPCODE_DIGITS = 2

# Successful completion of program
SUCCESS = 0

# Pause execution of program, not an error
PAUSE_EXECUTION = -3

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
    elseif opcode == jump_if_true && MAX_INSTRUCTION >= Int(jump_if_true)
        return 3
    elseif opcode == jump_if_false && MAX_INSTRUCTION >= Int(jump_if_false)
        return 3
    elseif opcode == less_than && MAX_INSTRUCTION >= Int(less_than)
        return 4
    elseif opcode == equals && MAX_INSTRUCTION >= Int(equals)
        return 4
    elseif opcode == relative_base && MAX_INSTRUCTION >= Int(relative_base)
        return 2
    elseif opcode == halt
        return 1
    else # Unrecognized opcode
        return 1
    end
end

# Mode of a program - how do we handle program outputs?
@enum ProgramMode begin
    multi_output=0  # Keep outputting until program halt
    single_output=1 # Pause program interpretation after single output
end

# Struct containing the all the information about the raw program
mutable struct Program
    program::Array{Int64}
    pointer::Int64
    relative_base::Int64
    inputs::Array{Int64}
    in_pointer::Int64
    outputs::Array{Int64}
    mode
end

# Sets program mode to multi_output (keep outputting until program halt)
function multi_output!(program::Program)
    program.mode = multi_output
end

# Sets program mode to single_output (pause execution after single output)
function single_output!(program::Program)
    program.mode = single_output
end

# Overload Base.show to allow for printing of program
function Base.show(io::IO, program::Program)
    print(io, "Program{")
    print(io, "@$(program.pointer) of $(program.program), ")
    print(io, "base $(program.relative_base), ")
    print(io, "@$(program.in_pointer) of inputs $(program.inputs), ")
    print(io, "outputs $(program.outputs)")
    print(io, "}")
end

# Mode of a given parameter
@enum ParameterMode begin
    position=0  # interpret parameter as address
    immediate=1 # interpret parameter as value
    relative=2  # interpret parameter as address, offset from relative base
end

# Struct containing all the information about a specific instruction
struct Instruction
    opcode::OpCode
    length::Integer
    modes #::Array{ParameterMode} # or single Mode
    parameters #::Array{Int64} # or single Integer

    function Instruction(opcode_::OpCode, relevant_program)
        # Handle unknown case immediately
        global MAX_INSTRUCTION
        if MAX_INSTRUCTION < Int(opcode_) && opcode_ != halt
            opcode_ = unknown
        end

        length_ = length(opcode_)
        instr_digits = digits(relevant_program[1], pad=length_)
        modes_ = instr_digits[OPCODE_DIGITS+1:end]
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
        modes_ = instr_digits[OPCODE_DIGITS+1:end]
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
function interpret_instruction(program::Program)
    index = program.pointer
    instr_digits = digits(program.program[index], pad=OPCODE_DIGITS)
    opcode = sum([instr_digits[k]*10^(k-1) for k = 1:OPCODE_DIGITS])
    #TODO: This fails if opcode isn't one that's recognized...
    relevant_program = program.program[index:index+length(OpCode(opcode))-1]
    return Instruction(opcode, relevant_program)
end

# Helper function to retrieve the value specified by instruction mode/param at index
function retrieve_value(program::Program, instruction::Instruction, index)
    value = 0
    if instruction.modes[index] == Int(position)
        value = program.program[instruction.parameters[index]+1] # ZERO-INDEXED INPUT
    elseif instruction.modes[index] == Int(immediate)
        value = instruction.parameters[index]
    elseif instruction.modes[index] == Int(relative)
        value = program.program[program.relative_base+instruction.parameters[index]]
    end
    return value
end

# Helper function to retrieve the value specified by instruction mode/param at index
# but does not allow for immediate mode
function retrieve_value_no_immediate(program::Program, instruction::Instruction, index)
    value = 0
    if instruction.modes[index] == Int(position)
        value = instruction.parameters[index]+1 # ZERO-INDEXED INPUT
    elseif instruction.modes[index] == Int(immediate)
        error("$(instruction.opcode)ing to a value, not location")
        return IMMEDIATE_WRITE_ERROR
    elseif instruction.modes[index] == Int(relative)
        value = instruction.parameters[index]+program.relative_base
    end
    return value
end

# Evaluate add instruction, updating program
function eval_add!(program::Program, instruction::Instruction)
    val1 = retrieve_value(program, instruction, 1)
    val2 = retrieve_value(program, instruction, 2)
    val3 = retrieve_value_no_immediate(program, instruction, 3)
    if val3 < 0
        return val3 # Could be error code
    end

    # Actually add
    program.program[val3] = val1+val2
    return SUCCESS
end

# Evaluate multiply instruction, updating program
function eval_multiply!(program::Program, instruction::Instruction)
    val1 = retrieve_value(program, instruction, 1)
    val2 = retrieve_value(program, instruction, 2)
    val3 = retrieve_value_no_immediate(program, instruction, 3)
    if val3 < 0
        return val3 # Could be error code
    end

    # Actually multiply
    program.program[val3] = val1*val2
    return SUCCESS
end

# Evaluate input instruction, updating program
function eval_input!(program::Program, instruction::Instruction)
    val1 = retrieve_value_no_immediate(program, instruction, 1)
    if val1 < 0
        return val1 # Could be error code
    end

    # Actually input
    program.program[val1] = program.inputs[program.in_pointer]
    program.in_pointer += 1
    return SUCCESS
end

# Evaluate output instruction
function eval_output!(program::Program, instruction::Instruction)
    output_value = retrieve_value(program, instruction, 1)

    # Actually output
    push!(program.outputs, output_value)

    # Depending on program mode, return success or pause execution
    if program.mode == multi_output
        return SUCCESS
    else
        return PAUSE_EXECUTION
    end
end

# Evaluate jump_if_true instruction, updating program pointer
function eval_jump_if_true!(program::Program, instruction::Instruction)
    val1 = retrieve_value(program, instruction, 1)
    val2 = retrieve_value(program, instruction, 2)

    if val1 != 0
        program.pointer = val2+1 # ZERO-INDEXED INPUT
        program.pointer -= instruction.length # in expectation of moving it forward
    end # else do nothing
    return SUCCESS
end

# Evaluate jump_if_false instruction, updating program pointer
function eval_jump_if_false!(program::Program, instruction::Instruction)
    val1 = retrieve_value(program, instruction, 1)
    val2 = retrieve_value(program, instruction, 2)

    if val1 == 0
        program.pointer = val2+1 # ZERO-INDEXED INPUT
        program.pointer -= instruction.length # in expectation of moving it forward
    end # else do nothing
    return SUCCESS
end

# Evaluate less_than instruction, updating program
function eval_less_than!(program::Program, instruction::Instruction)
    val1 = retrieve_value(program, instruction, 1)
    val2 = retrieve_value(program, instruction, 2)
    val3 = retrieve_value_no_immediate(program, instruction, 3)
    if val3 < 0
        return val3 # Could be error code
    end

    program.program[val3] = (val1 < val2) ? 1 : 0
    return SUCCESS
end

# Evaluate equals instruction, updating program
function eval_equals!(program::Program, instruction::Instruction)
    val1 = retrieve_value(program, instruction, 1)
    val2 = retrieve_value(program, instruction, 2)
    val3 = retrieve_value_no_immediate(program, instruction, 3)
    if val3 < 0
        return val3 # Could be error code
    end

    program.program[val3] = (val1 == val2) ? 1 : 0
    return SUCCESS
end

# Evaluate relative_base instruction, updating program's relative_base
function eval_relative_base!(program::Program, instruction::Instruction)
    val1 = retrieve_value(program, instruction, 1)
    program.relative_base += val1
    return SUCCESS
end

# Modify program by evaluating instruction
function eval_instruction!(program::Program, instruction::Instruction)
    global MAX_INSTRUCTION

    if instruction.opcode == add
        return eval_add!(program, instruction)
    elseif instruction.opcode == multiply
        return eval_multiply!(program, instruction)
    elseif instruction.opcode == input && MAX_INSTRUCTION >= Int(input)
        return eval_input!(program, instruction)
    elseif instruction.opcode == output && MAX_INSTRUCTION >= Int(output)
        return eval_output!(program, instruction)
    elseif instruction.opcode == jump_if_true && MAX_INSTRUCTION >= Int(jump_if_true)
        return eval_jump_if_true!(program, instruction)
    elseif instruction.opcode == jump_if_false && MAX_INSTRUCTION >= Int(jump_if_false)
        return eval_jump_if_false!(program, instruction)
    elseif instruction.opcode == less_than && MAX_INSTRUCTION >= Int(less_than)
        return eval_less_than!(program, instruction)
    elseif instruction.opcode == equals && MAX_INSTRUCTION >= Int(equals)
        return eval_equals!(program, instruction)
    elseif instruction.opcode == relative_base && MAX_INSTRUCTION >= Int(relative_base)
        return eval_relative_base!(program, instruction)
    else
        # an uknown opcode. Not necessarily an error
        return INVALID_OPCODE
    end
    return SUCCESS
end

# Reinterprets the string from the file as an array of integers to run as a program
function initialize_program(string)
    array_string = split(string,',')
    program_code = parse.(Int64,array_string)
    init_index = 1
    return Program(program_code, init_index, init_index,
                   Int64[], init_index, Int64[], multi_output)
end

# Actually evaluates the opcode program, updating program as it runs
function interpret_program!(program::Program)
    instruction = interpret_instruction(program)

    # Run program until it halts
    while instruction.opcode != halt
        # println(program); flush(stdout) # debugging
        error_code = eval_instruction!(program, instruction)
        program.pointer += instruction.length
        if error_code != SUCCESS
            return error_code
        end

        # Setup for next instruction
        instruction = interpret_instruction(program)
    end
    return SUCCESS
end

end
