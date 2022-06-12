using ChainRulesCore
using ChainRules
#using DistributionsAD
using ChainRulesOverloadGeneration
# resolve conflicts while this code exists in both.
const on_new_rule = ChainRulesOverloadGeneration.on_new_rule
const refresh_rules = ChainRulesOverloadGeneration.refresh_rules

##########################
# Define the AD

# Note that we never directly define Dual Number Arithmetic on Dual numbers
# instead it is automatically defined from the `frules`
struct Dual <: Real
    primal::Float64
    partial::Float64
end

primal(d::Dual) = d.primal
partial(d::Dual) = d.partial

primal(d::Real) = d
partial(d::Real) = 0.0

Base.convert(d::Type{Dual}, x::Real) = Dual(x, zero(x))
Base.convert(d::Type{Dual}, x::Dual) = x 
Base.promote_rule(::Type{Dual}, ::Type{<:Real}) = Dual

Base.to_power_type(x::Dual) = x
using ExprTools

function define_dual_overload(sig)
    opT, argTs = Iterators.peel(ExprTools.parameters(sig))
    opT <: Type{<:Type} && return  # not handling constructors
    sig <: Tuple{Type, Vararg{Any}} && return
    opT <: Core.Builtin && return false  # can't do operator overloading for builtins

    isabstracttype(opT) || fieldcount(opT) == 0 || return false  # not handling functors
    isempty(argTs) && return false  # we are an operator overloading AD, need operands
    all(argT isa Type && Float64 <: argT for argT in argTs) || return  # only handling purely Float64 ops.

    N = length(ExprTools.parameters(sig)) - 1  # skip the op
    fdef = quote
        # we use the function call overloading form as it lets us avoid namespacing issues
        # as we can directly interpolate the function type into to the AST.
        function (op::$opT)(dual_args::Vararg{Dual, $N}; kwargs...)
            ȧrgs = (NoTangent(),  partial.(dual_args)...)
            args = (op, primal.(dual_args)...)
            y, ẏ = frule(ȧrgs, args...; kwargs...)
            return Dual(y, ẏ)  # if y, ẏ are not `Float64` this will error.
        end
    end
    eval(fdef)
end

# !Important!: Attach the define function to the `on_new_rule` hook
on_new_rule(define_dual_overload, frule)

# End AD definition
################################
