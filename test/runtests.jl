using TestChainRulesOverload
using Test

@testset "TestChainRulesOverload.jl" begin

    "Do a calculus. `f` should have a single input."
    function derv(f, arg)
        duals = Dual(arg, one(arg))
        return partial(f(duals...))
    end

    foo(x) = x + x
    @test derv(foo, 1.6) ≈ 2

    bar(x) = x + 2.1 * x
    @test derv(bar, 1.2) == 3.1

    baz(x) = 2.0 * x^2 + 3.0*x + 1.2
    @test derv(baz, 1.7) == 2*2.0*1.7 + 3.0

    qux(x) = foo(x) + bar(x) + baz(x)
    @test derv(qux, 1.7) == (2*2.0*1.7 + 3.0) + 3.1 + 2

    function quux(x)
        y = 2.0*x + 3.0*x
        return 4.0*y + 5.0*y
    end
    @test derv(quux, 11.1) == 4*(2+3) + 5*(2+3)
end
