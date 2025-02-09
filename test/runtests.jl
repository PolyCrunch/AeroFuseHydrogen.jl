using AeroFuseHydrogen
using Test

@testset "AeroFuseHydrogen.jl" begin
    # Fuel Tank Tests
    @test AeroFuseHydrogen.CryogenicFuelTank() isa CryogenicFuelTank

    tank1 = CryogenicFuelTank(
        radius=3,
        length=volume_to_length(100.0, 3, 0.1),
        insulation_thickness=0.1,
        insulation_density=120,
        position=[0, 0, 0]
    )
    tank_length = tank1.length

    tank2 = CryogenicFuelTank(
        radius=3,
        length=tank_length,
        insulation_thickness=0.1,
        insulation_density=120,
        position=[0, 0, 0]
    )

    @test internal_volume(tank1) ≈ internal_volume(tank2) atol = 1e-6

    # Atmospheric Property Tests
    @test K_air(100) ≈ 909.286 atol = 1e-3
    @test α_air(100) ≈ 2.101e-6 atol = 1e-8
    @test ν_air(100) ≈ 1.775e-6 atol = 1e-8
    @test p_air(10000) ≈ 26436.233 atol = 1e-3
    @test T_air(10000) ≈ 23.150 atol = 1e-3
end
