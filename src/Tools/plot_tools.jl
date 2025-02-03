# Fuel tank
function plot_surface(tank::CryogenicFuelTank, n_secs=5)
    n_pts = 20
    xys = cosine_interpolation(tank, n_secs)

    circs = combinedimsview(
        permutedims.(
            combinedimsview.(
                [
                eachrow(circ) .+ Ref([x; 0.0; 0.0] + tank.position)
                for (x, circ) in zip(
                    xys[:, 1] .* tank.length,
                    circle3D.(xys[:, 2], n_pts)
                )
            ]
            )
        )
    )

    return circs
end

## Plots.jl recipes
#============================================#

@recipe function tank_plot(tank::FuelTank, n=20)
    tank_pans = plot_surface(tank, n)

    for k in axes(tank_pans, 3)[1:end-1]
        for n in axes(tank_pans, 1)[1:end-1]
            @series begin
                seriestype := :path
                primary := false

                coo = tank_pans[n:(n+1), :, (k+1):-1:k]
                coords = @views [coo[:, :, 1]; coo[:, :, 2]]
                @views coords[:, 1], coords[:, 2], coords[:, 3]
            end
        end
    end
end

@recipe function tank_plot(tank :: CryogenicFuelTank; n_secs = 10, n_circ = 20)
    ts = LinRange(0, 1, n_secs)
    tank_coo = coordinates(tank, ts, n_circ) # Get coordinates
    tank_ske = [ tank_coo[end÷4,:,1:3]; tank_coo[end÷2,:,1:3]; tank_coo[3*end÷4,:,1:3] ] 
    tank_plan = [ reshape(tank_coo, n_circ * n_secs * 3, 3)l tank_ske ]
    @series begin
        @views tank_plan[:,1], tank_plan[:,2], tank_plan[:,3]
    end
end