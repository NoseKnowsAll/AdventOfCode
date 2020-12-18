@enum Operator addition=0 multiplication=1
" Define an expression as: left hand expression (op) right hand expression "
mutable struct Expression
    left  # Number or expression
    right # Number or expression
    operator::Operator
end
function Base.show(io::IO, expression::Expression)
    if expression.operator == addition
        print(io, "($(expression.left) + $(expression.right))")
    elseif expression.operator == multiplication
        print(io, "($(expression.left) * $(expression.right))")
    end
end
eval(expression::Number) = expression
function eval(expression::Expression)
    num1 = eval(expression.left)
    num2 = eval(expression.right)
    if expression.operator == addition
        return num1+num2
    elseif expression.operator == multiplication
        return num1*num2
    end
end
" Given a string, returns the Expression corresponding to the underlying math.
If `precedence`, then addition takes precedence over multiplication. "
function create_expression(string, precedence)
    #println("parse |$string|")
    if length(string) == 1 # String is simply a single character => number
        return parse(Int, string[1])
    end
    left = 0
    right = 0
    op_itr = length(string)-2
    if string[end] == ')'
        paren_depth = 1
        for itr = length(string)-1:-1:1
            if string[itr] == ')'
                paren_depth += 1
            elseif string[itr] == '('
                paren_depth -= 1
                if paren_depth == 0 # We have closed all parentheses
                    right = create_expression(string[itr+1:end-1], precedence)
                    op_itr = itr - 2
                    break
                end
            end
        end
    else
        right = parse(Int, string[end]) # Numbers are single character
    end
    if op_itr == -1 # Entire expression was in parentheses
        # TODO: Fix Hack:
        # Add zero so as to be able to steal in the case of addition precedence
        # Addition is NOT higher precedence than parentheses
        return precedence ? Expression(0, right, addition) : right
    end
    operator = (string[op_itr] == '+' ? addition : multiplication)
    left = create_expression(string[1:op_itr-2], precedence)
    if !precedence || operator == multiplication
        return Expression(left, right, operator)
    else
        # operator is addition, which takes precedence
        if left isa Number
            return Expression(left, right, operator)
        else
            new_expression = Expression(left.right, right, operator)
            return Expression(left.left, new_expression, left.operator)
        end
    end
end
" Read the file into an array of `Expression`s "
function read_math_into_expressions(filename, precedence=false)
    expressions = Expression[]
    for line in readlines(filename)
        push!(expressions, create_expression(line, precedence))
    end
    return expressions
end
" Solve Day 18-1 "
function sum_of_homework(filename="day18.input")
    homework = read_math_into_expressions(filename)
    sum(x->eval(x), homework)
end
" Solve Day 18-2 "
function sum_of_homework_precedence(filename="day18.input")
    homework = read_math_into_expressions(filename, true)
    sum(x->eval(x), homework)
end
