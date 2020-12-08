" Successful completion of instruction "
const SUCCESS = 0
" Invalid OpCode "
const INVALID_OPCODE = -1
" Accessing invalid instruction_index in BootCode program "
const INVALID_ACCESS = -2
" Successful completion of entire BootCode program "
const PROGRAM_SUCCESS = 1
" Enum defining all possible Operation codes "
@enum OpCode begin
    acc=1
    jmp=2
    nop=3
    UNKNOWN = 0
end
" Define an instruction according to its operation and integer value "
struct Instruction
    opcode::OpCode
    value::Int
    Instruction(opcode::OpCode, value::Int) = new(opcode,value)
    " Converts an input instruction string into the underlying instruction "
    function Instruction(string::String)
        m = match(r"(\w+) ((\+|-)?\d+)", string)
        name = m.captures[1]
        value = parse(Int, m.captures[2])
        opcode = OpCode(0)
        if name == "acc"
            opcode = OpCode(1)
        elseif name == "jmp"
            opcode = OpCode(2)
        elseif name == "nop"
            opcode = OpCode(3)
        else
            error("Invalid instruction name!")
        end
        new(opcode, value)
    end
end
" Define a BootCode as a sequence of instructions and accumulator value "
mutable struct BootCode
    accumulator::Int
    instruction_index::Int
    instructions::Array{Instruction}
    BootCode(file_array) = new(0,1,Instruction.(file_array))
end
" Creates BootCode from file "
function read_boot_code(filename)
    BootCode(readlines(filename))
end
" Evaluate acc (accumulator) instruction "
function eval_acc!(program::BootCode, instruction::Instruction)
    program.accumulator += instruction.value
    program.instruction_index += 1
end
" Evaluate jmp instruction "
function eval_jmp!(program::BootCode, instruction::Instruction)
    program.instruction_index += instruction.value
end
" Evaluate No OPeration instruction "
function eval_nop!(program::BootCode, instruction::Instruction)
    program.instruction_index += 1
end
" Interprets the instruction at the internal instruction_index and evaluates it "
function interpret_instruction!(program::BootCode)
    if program.instruction_index == length(program.instructions)+1
        return PROGRAM_SUCCESS
    elseif 1 <= program.instruction_index <= length(program.instructions)
        return eval_instruction!(program, program.instructions[program.instruction_index])
    else
        return INVALID_ACCESS
    end
end
" Modify BootCode by evaluating instruction "
function eval_instruction!(program::BootCode, instruction::Instruction)
    if instruction.opcode == acc
        return eval_acc!(program, instruction)
    elseif instruction.opcode == jmp
        return eval_jmp!(program, instruction)
    elseif instruction.opcode == nop
        return eval_nop!(program, instruction)
    else
        # An uknown opcode. Not necessarily an error
        return INVALID_OPCODE
    end
    return SUCCESS
end

" Solves Day 8-1 "
function infinite_loop(filename="day8.input")
    program = read_boot_code(filename)
    instructions_executed = Set{Int}()
    while program.instruction_index ∉ instructions_executed
        push!(instructions_executed, program.instruction_index)
        interpret_instruction!(program)
    end
    return program.accumulator
end
" Swaps the instruction at specified index from jmp<->nop and returns copy of program "
function swap_jmp_nop(master_program::BootCode, index)
    program = deepcopy(master_program)
    valid = false
    if master_program.instructions[index].opcode == jmp
        program.instructions[index] = Instruction(nop, master_program.instructions[index].value)
        valid = true
    elseif master_program.instructions[index].opcode == nop
        program.instructions[index] = Instruction(jmp, master_program.instructions[index].value)
        valid = true
    end
    return program, valid
end
" Solves Day 8-2 "
function terminate_program(filename="day8.input")
    master_program = read_boot_code(filename)
    for index = 1:length(master_program.instructions)
        program, valid = swap_jmp_nop(master_program, index)
        if valid
            # Only execute if it is a valid swap
            instructions_executed = Set{Int}()
            while program.instruction_index ∉ instructions_executed
                push!(instructions_executed, program.instruction_index)
                success = interpret_instruction!(program)
                if success == PROGRAM_SUCCESS
                    # BootCode successfuly completed with final answer in accumulator
                    return program.accumulator
                end
            end
        end
    end
    error("PROGRAM NEVER SUCCESSFULLY EXECUTED!")
end
