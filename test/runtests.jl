using AeroFuseHydrogen
using Test

@testset "AeroFuseHydrogen.jl" begin
    # Write your tests here.
    @test AeroFuseHydrogen.greet_AeroFuse() == "Hello AeroFuseHydrogen"
    @test AeroFuseHydrogen.greet_AeroFuse() != "Hello world!"
    @test AeroFuseHydrogen.CryogenicFuelTank() isa CryogenicFuelTank
end
