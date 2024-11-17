### A Pluto.jl notebook ###
# v0.20.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 3d26ac1a-f679-4ff8-a6d5-e52fc83bcae1
using Pkg;

# ╔═╡ 3602500f-cbd8-43a9-a9d5-001fda45aa6b
Pkg.develop(url="https://github.com/PolyCrunch/AeroFuseHydrogen.jl");

# ╔═╡ 8802e233-9cfa-4ae6-b6bb-09f27215b5f4
using AeroFuse;

# ╔═╡ 87dfa675-cb8c-41e6-b03d-c5a983d99aa8
using Plots;

# ╔═╡ 3fc8039e-acb3-44eb-a7c3-176afe4ad6e0
using DataFrames;

# ╔═╡ 1aeef97f-112b-4d1c-b4b0-b176483a783b
begin
	using PlutoUI
	TableOfContents()
end

# ╔═╡ 316a98fa-f3e4-4b46-8c19-c5dbfa6a550f
md"""# AeroFuse: Hydrogen-Electric Aircraft Design Demo

**Author**: [Tom Gordon](https://github.com/PolyCrunch), Imperial College London.

"""

# ╔═╡ cf3ff4ea-03ed-4b53-982c-45d9d71a3ba2
md"""
Start by including AeroFuse.jl, AeroFuseHydrogen.jl, and other necessary packages.

Note: If you haven't already you will need to add the packages AeroFuse, Plots, Dataframe and PlutoUI to your Julia installation.
"""

# ╔═╡ b1e81925-32b5-45c0-888c-4b38a34e27b6
gr(
	size = (900, 700),  # INCREASE THE SIZE FOR THE PLOTS HERE.
	palette = :tab20    # Color scheme for the lines and markers in plots
)

# ╔═╡ b81ca63b-46e9-4808-8225-c36132e70084
md"""
## Aircraft information
The aircraft in this demo will be a fictional Hydrogen-electric powered aircraft, based on a De Havilland Canada *Dash 8 Q-400*.

For propulsion it will use an electric motor (with propeller) at the front of the aircraft, powered by PEM electric fuel cells which are fuelled by cryogenic liquid Hydrogen.

![Side view of a De Havilland Canada Dash 8 Q-400](https://static.wikia.nocookie.net/airline-club/images/4/4a/Bombardier-q400.png/revision/latest?cb=20220108202032)
"""

# ╔═╡ 6242fa28-1d3f-45d7-949a-646d2c7a9f52
md"## Defining the fuselage"

# ╔═╡ 0badf910-ef0d-4f6a-99b0-9a1a5d8a7213
# Fuselage definition
fuse = HyperEllipseFuselage(
    radius = 1.35,          # Radius, m ACCURATE
    length = 32.8,          # Length, m ACCURATE
    x_a    = 0.14,          # Start of cabin, ratio of length ACCURATE
    x_b    = 0.67,          # End of cabin, ratio of length QUITE ACCURATE (Drawings)
    c_nose = 1.6,           # Curvature of nose NO CLUE
    c_rear = 1.2,           # Curvature of rear NO CLUE
    d_nose = -0.5,          # "Droop" or "rise" of nose, m NO CLUE
    d_rear = 0.7,           # "Droop" or "rise" of rear, m NO CLUE
    position = [0.,0.,0.]   # Set nose at origin, m
)

# ╔═╡ d82a14c0-469e-42e6-abc2-f7b98173f92b
begin
	# Compute geometric properties
	ts = 0:0.1:1                # Distribution of sections for nose, cabin and rear
	S_f = wetted_area(fuse, ts) # Surface area, m²
	V_f = volume(fuse, ts)      # Volume, m³
end;

# ╔═╡ 165831ec-d5a5-4fa5-9e77-f808a296f09c
md"## Defining the wing"

# ╔═╡ 7bb33068-efa5-40d2-9e63-0137a44181cb
begin
	# AIRFOIL PROFILES
	foil_w_r = read_foil(download("http://airfoiltools.com/airfoil/seligdatfile?airfoil=naca633418-il")) # Root
	foil_w_m = read_foil(download("http://airfoiltools.com/airfoil/seligdatfile?airfoil=naca633418-il")) # Midspan
	foil_w_t = read_foil(download("http://airfoiltools.com/airfoil/seligdatfile?airfoil=n63415-il")) # Tip
end;

# ╔═╡ 3413ada0-592f-4a37-b5d0-6ff88baad66c
# Wing
wing = Wing(
    foils       = [foil_w_r, foil_w_m, foil_w_t], # Airfoils (root to tip) ROOT AND TIP ACCURATE
    chords      = [3.31, 3.00, 1.20],             # Chord lengths ROOT AND TIP ACCURATE
    spans       = [9.5, 28.4] / 2,                # Span lengths TIP ACCURATE
    dihedrals   = fill(1, 2),                     # Dihedral angles (deg) GUESS
    sweeps      = fill(4.4, 2),                   # Sweep angles (deg) MAYBE ACCURATE (taken from a Uni exam)
    w_sweep     = 0.,                             # Leading-edge sweep
    symmetry    = true,                           # Symmetry

	# Orientation
    angle       = 3,       # Incidence angle (deg) NOT SURE
    axis        = [0, 1, 0], # Axis of rotation, x-axis
    position    = [0.38fuse.length, 0., 1.35]
);

# ╔═╡ 08420a59-34c1-4a29-a1d9-b8a6aa56ff1f
md"### Wing Mesh"

# ╔═╡ 6ef141f2-4655-431e-b064-1c82794c9bac
wing_mesh = WingMesh(wing, 
	[8,16], # Number of spanwise panels
	10,     # Number of chordwise panels
    span_spacing = Uniform() # Spacing: Uniform() or Cosine()
);

# ╔═╡ 9f776e2f-1fa9-48f5-b554-6bf5a5d91441
md"## Plot definition"

# ╔═╡ ad1a5963-d120-4a8c-b5e1-9bd743a32670
begin
	φ_s 			= @bind φ Slider(0:1e-2:90, default = 15)
	ψ_s 			= @bind ψ Slider(0:1e-2:90, default = 30)
	aero_flag 		= @bind aero CheckBox(default = true)
	stab_flag 		= @bind stab CheckBox(default = true)
	weights_flag 	= @bind weights CheckBox(default = false)
	strm_flag 		= @bind streams CheckBox(default = false)
end;

# ╔═╡ 8af8885c-48d8-40cf-8584-45d89521d9a1
toggles = md"""
φ: $(φ_s)
ψ: $(ψ_s)

Panels: $(aero_flag)
Weights: $(weights_flag)
Stability: $(stab_flag)
Streamlines: $(strm_flag)
"""

# ╔═╡ 11e3c0e6-534c-4b01-a961-5429d28985d7
toggles

# ╔═╡ 620d9b28-dca9-4678-a50e-82af5176f558
begin
	# Plot meshes
	plt_vlm = plot(
	    # aspect_ratio = 1,
	    xaxis = "x", yaxis = "y", zaxis = "z",
	    zlim = (-0.5, 0.5) .* span(wing_mesh),
	    camera = (φ, ψ),
	)

	# Surfaces
	if aero
		plot!(fuse, label = "Fuselage", alpha = 0.6)
		plot!(wing_mesh, label = "Wing", mac = false)
		#plot!(htail_mesh, label = "Horizontal Tail", mac = false)
		#plot!(vtail_mesh, label = "Vertical Tail", mac = false)
	else
		plot!(fuse, alpha = 0.3, label = "Fuselage")
		plot!(wing, 0.4, label = "Wing MAC 40%") 			 
		#plot!(htail, 0.4, label = "Horizontal Tail MAC 40%") 
		#plot!(vtail, 0.4, label = "Vertical Tail MAC 40%")
	end

	# CG
	#scatter!(Tuple(r_cg), label = "Center of Gravity (CG)")
	
	# Streamlines
	if streams
		plot!(sys, wing_mesh, 
			span = 4, # Number of points over each spanwise panel
			dist = 40., # Distance of streamlines
			num = 50, # Number of points along streamline
		)
	end

	# Weights
	if weights
		# Iterate over the dictionary
		#[ scatter!(Tuple(pos), label = key) for (key, (W, pos)) in W_pos ]
	end

	# Stability
	if stab
		#scatter!(Tuple(r_np), label = "Neutral Point (SM = $(round(SM; digits = 2))%)")
		# scatter!(Tuple(r_np_lat), label = "Lat. Neutral Point)")
		#scatter!(Tuple(r_cp), label = "Center of Pressure")
	end
end

# ╔═╡ 62dd8881-9b07-465d-a83e-d93eafc7225a
plt_vlm

# ╔═╡ Cell order:
# ╟─316a98fa-f3e4-4b46-8c19-c5dbfa6a550f
# ╟─cf3ff4ea-03ed-4b53-982c-45d9d71a3ba2
# ╠═3d26ac1a-f679-4ff8-a6d5-e52fc83bcae1
# ╠═8802e233-9cfa-4ae6-b6bb-09f27215b5f4
# ╠═3602500f-cbd8-43a9-a9d5-001fda45aa6b
# ╠═87dfa675-cb8c-41e6-b03d-c5a983d99aa8
# ╠═3fc8039e-acb3-44eb-a7c3-176afe4ad6e0
# ╠═b1e81925-32b5-45c0-888c-4b38a34e27b6
# ╟─b81ca63b-46e9-4808-8225-c36132e70084
# ╟─6242fa28-1d3f-45d7-949a-646d2c7a9f52
# ╠═0badf910-ef0d-4f6a-99b0-9a1a5d8a7213
# ╠═11e3c0e6-534c-4b01-a961-5429d28985d7
# ╠═62dd8881-9b07-465d-a83e-d93eafc7225a
# ╠═d82a14c0-469e-42e6-abc2-f7b98173f92b
# ╟─165831ec-d5a5-4fa5-9e77-f808a296f09c
# ╠═7bb33068-efa5-40d2-9e63-0137a44181cb
# ╠═3413ada0-592f-4a37-b5d0-6ff88baad66c
# ╟─08420a59-34c1-4a29-a1d9-b8a6aa56ff1f
# ╠═6ef141f2-4655-431e-b064-1c82794c9bac
# ╟─9f776e2f-1fa9-48f5-b554-6bf5a5d91441
# ╠═ad1a5963-d120-4a8c-b5e1-9bd743a32670
# ╠═8af8885c-48d8-40cf-8584-45d89521d9a1
# ╠═620d9b28-dca9-4678-a50e-82af5176f558
# ╠═1aeef97f-112b-4d1c-b4b0-b176483a783b
