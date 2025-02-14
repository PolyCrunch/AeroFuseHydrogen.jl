### A Pluto.jl notebook ###
# v0.19.46

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

# ╔═╡ dacf3264-b291-49b1-8588-4cb691a753b6
Pkg.develop(url="https://github.com/PolyCrunch/AeroFuse.jl");

# ╔═╡ 3602500f-cbd8-43a9-a9d5-001fda45aa6b
Pkg.develop(url="https://github.com/PolyCrunch/AeroFuseHydrogen.jl");

# ╔═╡ 8758139a-3b2f-458f-b7a9-d64ed8613871
using AeroFuse;

# ╔═╡ f0aadce8-3424-47f2-a549-43a499385e80
using AeroFuseHydrogen;

# ╔═╡ 87dfa675-cb8c-41e6-b03d-c5a983d99aa8
using Plots;

# ╔═╡ 3fc8039e-acb3-44eb-a7c3-176afe4ad6e0
using DataFrames;

# ╔═╡ 559bcd99-f43f-4228-9632-2aa5cd93a1fb
using LinearRegression;

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

Note: If you haven't already you will need to add the packages AeroFuse, Plots, DataFrames, LinearRegression, and PlutoUI to your Julia installation.
"""

# ╔═╡ 25cfde65-2b81-4edf-b0db-8d525a81edc2
md"Run AeroFuseHydrogen tests"

# ╔═╡ 83238510-db03-4f25-84ce-49207b4a6e44
Pkg.test("AeroFuseHydrogen");

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

![Three-perspective of a De Havilland Canada Dash 8 Q-400](https://www.aviastar.org/pictures/canada/bombardier_dash-8-400.gif)
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

# ╔═╡ 87bca1cb-5e2f-4e2e-a1ff-a433507807da
# Get coordinates of rear end
fuse_end = fuse.affine.translation + [ fuse.length, 0., 0. ];

# ╔═╡ 9cd71ed3-c323-4500-92fa-43cb3f9b98e3
fuse_t_w = 0.05; # Thickness of the fuselage wall, used for calculating space available for fuel tank

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
    position    = [0.44fuse.length, 0., 1.35]
);

# ╔═╡ d69b550d-1634-4f45-a660-3be009ddd19d
begin
	b_w = span(wing)								# Span length, m
	S_w = projected_area(wing)						# Area, m^2
	c_w = mean_aerodynamic_chord(wing)				# Mean aerodynamic chord, m
	mac_w = mean_aerodynamic_center(wing, 0.25)		# Mean aerodynamic center (25%), m
	mac40_wing = mean_aerodynamic_center(wing, 0.40)# Mean aerodynamic center (40%), m
end;

# ╔═╡ 2b8ec21c-d8da-4e16-91c0-244857483463
md"## Defining the fuel tank"

# ╔═╡ a017efa0-cf08-4302-80f7-fae1ef55651c
md"""
We will assume the fuel tank will be to the rear of the fuselage, taking up the entire radius available, with a given internal volume.
"""

# ╔═╡ b69a9c96-c979-4ced-bc85-fbe47ada1c9e
md"""
#### Firstly, inspect the included data on insulation materials and choose one.
Source: [NASA](https://ntrs.nasa.gov/api/citations/20020085127/downloads/20020085127.pdf).
"""

# ╔═╡ a234a45e-c25f-4248-9c9f-3fce481cd281
tank_data = read_data("Data/tank_insulation_properties.csv")

# ╔═╡ a9df29fc-7f0a-409c-a34a-3a0fbcaa94e2
md"Which tank material may be best to use?"

# ╔═╡ 5dc43298-f815-4087-9a60-03717d20fd8e
merit_indices = 1 ./ tank_data.Density ./ tank_data.Thermal_conductivity # Merit index to minimize density and thermal conductivity

# ╔═╡ 48b7e573-ecf4-4d4c-a733-369ae06bbae5
begin
	(~, id_max) = findmax(merit_indices)
	println("Material with lowest ρ * K: " * tank_data.Insulation_type[id_max])
end

# ╔═╡ 631cfc20-058a-4574-8d81-b10c49fd2036
md"Use the slider to choose an insulation material of your choice:"

# ╔═╡ 89530c07-b538-4875-b67b-c916963d9ab8
@bind insulation_index Slider(1:nrow(tank_data))

# ╔═╡ 6fffa62e-48c1-48aa-a048-4e78048fb309
insulation_material = tank_data[insulation_index, :]

# ╔═╡ f4158708-4c5b-44d2-80bd-22334c19b319
begin
	t_w = [0.001 0.002 0.003 0.004 0.005 0.006 0.008 0.01 0.015 0.02 0.03 0.04 0.05 0.1 0.15 0.2]'
	K_insulation = insulation_material.Thermal_conductivity
	T_s_0 = 100
	T∞ = 293
	T_LH2 = 20
	ϵ = 0.1
	M = zeros(Float64, size(t_w))
	T_s = zeros(Float64, size(t_w))

	local i = 1
	for v in t_w
		temp_tank = CryogenicFuelTank(
			radius = fuse.radius - fuse_t_w,
			length = 5,
			insulation_thickness = v,
			insulation_density = insulation_material.Density,
			position = [0.5fuse.length, 0, 0]
		)	
		M[i] = boil_off(temp_tank, K_insulation, T_s_0, T∞, T_LH2, ϵ)
		T_s[i] = tank_surface_temperature(temp_tank, T_s_0, T∞, T_LH2, ϵ)
		i += 1
	end
end

# ╔═╡ c829759c-914e-4d1d-a037-9c59bf0f97c9
begin
	ρ_LH2 = 70.8; # Density of Hydrogen, kg /m^3
	boiloffplot = plot(
		100 * t_w,
		360 * M,
		title = "Mass boil-off rate versus insulation thickness",
		xlabel = "Insulation thickness (cm)",
		ylabel = "Mass boil-off (kg /hr)",
		legend = false
	);

	volboioloffplot = plot(
		100 * t_w,
		360 * M / ρ_LH2,
		title = "Volume boil-off rate versus insulation thickness",
		xlabel = "Insulation thickness (cm)",
		ylabel = "Volume boil-off (m³ /hr)",
		legend = false
	);

	Tsplot = plot(
		100 * t_w,
		T_s,
		title = "Tank surface temperature versus insulation thickness",
		xlabel = "Insulation thickness (cm)",
		ylabel = "Tank surface temperature (K)",
		label = "Theoretical value"
	)
	
	plot!([0; 20], [T∞; T∞], linestyle = :dash, linecolor = :gray, linewidth = 1, label = "T∞")

	plot(boiloffplot, volboioloffplot, Tsplot, layout = @layout [a; b; c])
end

# ╔═╡ 25b42e5d-2053-4687-bc8a-a5a145c42e53
md"""
#### Define the fuel tank using your desired insulation material
"""

# ╔═╡ 7fa4e010-4ae8-4b77-9bc2-f12437adb7b3
t_insulation = 0.05;

# ╔═╡ 82b332ac-5628-4b82-8735-f361dcdfc9b6
tank = CryogenicFuelTank(
	radius = fuse.radius - fuse_t_w,
	length = volume_to_length(50., fuse.radius - fuse_t_w, t_insulation),
	insulation_thickness = t_insulation,
	insulation_density = insulation_material.Density,
	position = [0.4fuse.length, 0, 0]
)

# ╔═╡ 63475bbf-6993-4f6c-86b8-f3b608b63a8e
tank_length = tank.length # Tank exterior length

# ╔═╡ b9fddbc4-a2d7-48cf-ace4-f092a3c38b11
tank_dry_mass = dry_mass(tank) # Calculate the dry mass of the tank (kg)

# ╔═╡ a0c931b1-e9a5-4bf3-af6d-a9e6d0009998
full_tank_mass = wet_mass(tank, 1) # Calculate the mass of a fuel tank. This function can also accept a vector of fractions

# ╔═╡ e36dc0e2-015e-4132-a105-d145e17cceb8
tank_capacity = internal_volume(tank) # Calculate the internal volume of the fuel tank

# ╔═╡ 5446afd1-4326-41ab-94ec-199587c1411b
md"""
## Propulsion
Electric motor and propeller combination
"""

# ╔═╡ f21b48c0-8e0c-4b67-9145-52a1480003ed
wing_coords = AeroFuse.coordinates(wing); # Get leading and trailing edge coordinates

# ╔═╡ c82d7f29-08f4-4268-881f-e422864ab789
begin
	eng_L = wing_coords[1, 2] - [1, 0., 0.] # Left engine at mid-section leading edge
	eng_R = wing_coords[1, 4] - [1, 0., 0.] # Right engine at mid-section leading edge
end

# ╔═╡ 9816aa83-4f98-4ea6-b149-749eacf833e6
md"### Fuel Cell Setup"

# ╔═╡ ebf91bfe-01e2-4975-93fe-b6c7ad03846f
md"""#### PEM Fuel Cell Polarization Curve
Generate the PEMFC polarization curve for a range of **i** using *pemfc\_polarization(i, T, α, n, i\_loss, i\_0, i\_L, R\_i)*."""

# ╔═╡ 1e80cb97-f238-43f7-b082-6ab2deacd701
i = collect(LinRange(0., 1600, 100) / 1000);

# ╔═╡ 911a3b54-10f4-4ddb-bb89-f380c79b4476
i_extrem = [i[1] i[end]]';

# ╔═╡ 22043683-a69f-4394-b872-4be6eb4b5dc9
E_cell = pemfc_polarization.(i);

# ╔═╡ 218c8ebb-414e-40f8-ad7a-ad5b6a0a44f3
md"""Observe that the curve seems approximately linear for 200 ≤ i ≤ 1500 mA/cm²

Choose a range of **i** for the linear fit:"""

# ╔═╡ d0433ace-dcfa-4adf-8df1-f7e0784afb5a
i_fitRange = [200., 1500.]/1000; # [minimum i, maximum i]

# ╔═╡ 7c48582c-3493-4c80-aab3-019aef3da65c
idx_iRangeMin = findfirst(x -> x >= i_fitRange[1], i);

# ╔═╡ 192ea8d5-df83-4944-9998-7b3006b32d68
idx_iRangeMax = findfirst(x -> x >= i_fitRange[2], i) - 1;

# ╔═╡ 541a4049-d17d-4ec8-8fd7-fe934ca53230
md"Create vectors of the linear portions of the curve, and perform a linear fit"

# ╔═╡ 5d7f3f13-eded-4e01-bb4e-925d24f2d883
i_linear = i[idx_iRangeMin:idx_iRangeMax];

# ╔═╡ ae560365-dddf-4aff-aff9-0dcd4227e1c4
E_linear = E_cell[idx_iRangeMin:idx_iRangeMax];

# ╔═╡ e17a3e03-88bf-4b9d-b3fb-5e20b4541c36
E_fit = linregress(i_linear, E_linear);

# ╔═╡ f0f28c3a-aa3c-4111-b676-5fd22fb3238c
begin
	plot(
		i*1000, E_cell,
		lw=3,
		label="Model Curve",
		ylims = (0, 1.2),
		xlims = (0, 2000),
		xlabel = "Current density, i (mA/cm²)",
		ylabel = "Cell PD, E (V)"
	)

	plot!(
		i_extrem.*1000,
		LinearRegression.slope(E_fit) .* i_extrem .+ LinearRegression.bias(E_fit),
		lw=2,
		label="Linear Fit",
		linestyle=:dash,
		linecolor = :gray50
	)
end

# ╔═╡ a2e58e67-f7f1-444b-991f-442f304f86bf
polarization_coeffs = [LinearRegression.slope(E_fit); LinearRegression.bias(E_fit)];

# ╔═╡ 4d86e477-7a9e-4eed-8b8f-e007411b2898
md"""### Defining the Fuel Cell Stack"""

# ╔═╡ eea50a16-6798-4b53-8c36-ec647b592b23
PEMFC = PEMFCStack(
	area_effective=5.e6,
	power_max = 4.e6,
	height = 2.,
	width = 2.,
	layer_thickness=0.0043,
	position = [0., 0., 0.]
)

# ╔═╡ e81ab1c3-228c-4a32-9275-43d5f9b134db
md"""Calculate the cell current density $j$ (A/cm²) for the cell under max power.
Note:
- *j* must be lower than the previously-defined limiting current density *j_L*
- A real solution only exists for $b^2 - 4ac >= 0$, where:
  -  $a$ is the gradient of the linear fit of the polarization curve,
  -  $b$ is the y-intercept, and
  -  $c = P_{max}/A$
"""

# ╔═╡ df7431fe-dcde-4456-a548-1ffafccb84b8
j_PEMFC = j_cell(PEMFC, 1, polarization_coeffs)

# ╔═╡ e9ffaaed-b8b3-4825-8bb2-30a848a17abc
U_PEMFC = U_cell(j_PEMFC, polarization_coeffs)

# ╔═╡ c6b9ea47-0dc5-42b9-a0b1-ff4158102d49
η_PEMFC = η_FC(U_PEMFC)

# ╔═╡ 6895ed8b-acf4-4941-ada7-38ab54d77870
mdot_H2 = fflow_H2(PEMFC, 1., polarization_coeffs)

# ╔═╡ f02237a0-b9d2-4486-8608-cf99a5ea42bd
md"## Stabilizers"

# ╔═╡ 36431db2-ac86-48ce-8a91-16d9cca57dad
md"#### Vertical stabilizer"

# ╔═╡ cf33519f-4b3e-4d84-9f48-1e76f4e8be47
vtail = WingSection(
    area        = 14.92, 			# Area (m²). # HOW DO YOU DETERMINE THIS?
    aspect      = 1.58,  			# Aspect ratio
    taper       = 0.78,  			# Taper ratio
    sweep       = 30.2, 			# Sweep angle (deg)
    w_sweep     = 0.,   			# Leading-edge sweep
    root_foil   = naca4(0,0,0,9), 	# Root airfoil
	tip_foil    = naca4(0,0,0,9), 	# Tip airfoil

    # Orientation
    angle       = 90.,       # To make it vertical
    axis        = [1, 0, 0], # Axis of rotation, x-axis
    position    = fuse_end - [3.4, 0., -fuse.d_rear] # HOW DO YOU DETERMINE THIS?
); # Not a symmetric surface

# ╔═╡ 0f131ff8-d956-4d46-a7f0-a89f9c647dc7
md"#### Horizontal stabilizer"

# ╔═╡ 49134949-ea48-468b-934e-8101c6424ded
con_foil = control_surface(naca4(0, 0, 1, 2), hinge = 0.75, angle = -10.) # Assumption

# ╔═╡ a8cd9c4d-9afe-4656-9142-6525d9181ecf
htail = WingSection(
    area        = 13.4,  		# Area (m²). Determined via scale drawing
	aspect      = 4.75,  		# Aspect ratio
	taper       = 0.82,  		# Taper ratio
	dihedral    = 0.,   		# Dihedral angle (deg)
    sweep       = 0.,  			# Sweep angle (deg)
    w_sweep     = 1.,   		# Leading-edge sweep
    root_foil   = con_foil, 	# Root airfoil
	tip_foil    = con_foil, 	# Tip airfoil
    symmetry    = true,

    # Orientation
    angle       = 0,  # Incidence angle (deg). HOW DO YOU DETERMINE THIS?
    axis        = [0., 1., 0.], # Axis of rotation, y-axis
    position    = vtail.affine.translation + [ 3.2, 0., span(vtail)],
);

# ╔═╡ 73fddb34-3e63-43bf-8912-98ce180127e4
b_h = span(htail);

# ╔═╡ c49e01f1-4a58-49af-8c9b-2f4d5baa1d97
S_h = projected_area(htail);

# ╔═╡ 4579294d-d33a-4469-859e-985eeac3108d
c_h = mean_aerodynamic_chord(htail);

# ╔═╡ 24a66024-4213-4c6f-833b-d364fd9f1a87
mac_h = mean_aerodynamic_center(htail);

# ╔═╡ d9cc17ce-2c3c-4320-a93e-2e6db054470d
V_h = S_h / S_w * (mac_h.x - mac_w.x) / c_w;

# ╔═╡ 08420a59-34c1-4a29-a1d9-b8a6aa56ff1f
md"### Meshing"

# ╔═╡ 6ef141f2-4655-431e-b064-1c82794c9bac
wing_mesh = WingMesh(wing, 
	[8,16], # Number of spanwise panels
	10,     # Number of chordwise panels
    span_spacing = Uniform() # Spacing: Uniform() or Cosine()
);

# ╔═╡ 1aed0dcb-3fa8-4c50-ac25-78e60c0ab99d
vtail_mesh = WingMesh(vtail, [8], 6);

# ╔═╡ 55a3b368-843e-47f1-a804-c5d3f582b1b9
htail_mesh = WingMesh(htail, [10], 8);

# ╔═╡ 9f776e2f-1fa9-48f5-b554-6bf5a5d91441
md"## Plot definition"

# ╔═╡ ad1a5963-d120-4a8c-b5e1-9bd743a32670
begin
	φ_s 			= @bind φ Slider(-180:1e-2:180, default = 15)
	ψ_s 			= @bind ψ Slider(-180:1e-2:180, default = 30)
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

# ╔═╡ 9b8ce85f-2cb8-43a9-a536-0d44681b5dfa
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
		plot!(htail_mesh, label = "Horizontal Tail", mac = false)
		plot!(vtail_mesh, label = "Vertical Tail", mac = false)
		plot!(tank, label = "Fuel Tank", n_secs = 3, n_circ = 10)
	else
		plot!(fuse, alpha = 0.3, label = "Fuselage")
		plot!(wing, 0.4, label = "Wing MAC 40%") 			 
		plot!(htail, 0.4, label = "Horizontal Tail MAC 40%") 
		plot!(vtail, 0.4, label = "Vertical Tail MAC 40%")
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

# ╔═╡ 50e128f3-72d9-42b1-b987-540bf6e7e6d0
plt_vlm

# ╔═╡ f03893b1-7518-47d3-ae88-da688aff9591
plt_vlm

# ╔═╡ Cell order:
# ╟─316a98fa-f3e4-4b46-8c19-c5dbfa6a550f
# ╟─cf3ff4ea-03ed-4b53-982c-45d9d71a3ba2
# ╠═3d26ac1a-f679-4ff8-a6d5-e52fc83bcae1
# ╠═dacf3264-b291-49b1-8588-4cb691a753b6
# ╠═8758139a-3b2f-458f-b7a9-d64ed8613871
# ╠═3602500f-cbd8-43a9-a9d5-001fda45aa6b
# ╟─25cfde65-2b81-4edf-b0db-8d525a81edc2
# ╠═83238510-db03-4f25-84ce-49207b4a6e44
# ╠═f0aadce8-3424-47f2-a549-43a499385e80
# ╠═87dfa675-cb8c-41e6-b03d-c5a983d99aa8
# ╠═3fc8039e-acb3-44eb-a7c3-176afe4ad6e0
# ╠═559bcd99-f43f-4228-9632-2aa5cd93a1fb
# ╟─b1e81925-32b5-45c0-888c-4b38a34e27b6
# ╟─b81ca63b-46e9-4808-8225-c36132e70084
# ╟─6242fa28-1d3f-45d7-949a-646d2c7a9f52
# ╠═0badf910-ef0d-4f6a-99b0-9a1a5d8a7213
# ╠═62dd8881-9b07-465d-a83e-d93eafc7225a
# ╟─11e3c0e6-534c-4b01-a961-5429d28985d7
# ╠═d82a14c0-469e-42e6-abc2-f7b98173f92b
# ╠═87bca1cb-5e2f-4e2e-a1ff-a433507807da
# ╠═9cd71ed3-c323-4500-92fa-43cb3f9b98e3
# ╟─165831ec-d5a5-4fa5-9e77-f808a296f09c
# ╠═7bb33068-efa5-40d2-9e63-0137a44181cb
# ╠═3413ada0-592f-4a37-b5d0-6ff88baad66c
# ╠═d69b550d-1634-4f45-a660-3be009ddd19d
# ╟─2b8ec21c-d8da-4e16-91c0-244857483463
# ╟─a017efa0-cf08-4302-80f7-fae1ef55651c
# ╟─b69a9c96-c979-4ced-bc85-fbe47ada1c9e
# ╠═a234a45e-c25f-4248-9c9f-3fce481cd281
# ╟─a9df29fc-7f0a-409c-a34a-3a0fbcaa94e2
# ╠═5dc43298-f815-4087-9a60-03717d20fd8e
# ╟─48b7e573-ecf4-4d4c-a733-369ae06bbae5
# ╟─631cfc20-058a-4574-8d81-b10c49fd2036
# ╟─89530c07-b538-4875-b67b-c916963d9ab8
# ╟─6fffa62e-48c1-48aa-a048-4e78048fb309
# ╟─f4158708-4c5b-44d2-80bd-22334c19b319
# ╟─c829759c-914e-4d1d-a037-9c59bf0f97c9
# ╟─25b42e5d-2053-4687-bc8a-a5a145c42e53
# ╠═7fa4e010-4ae8-4b77-9bc2-f12437adb7b3
# ╠═82b332ac-5628-4b82-8735-f361dcdfc9b6
# ╠═63475bbf-6993-4f6c-86b8-f3b608b63a8e
# ╠═b9fddbc4-a2d7-48cf-ace4-f092a3c38b11
# ╠═a0c931b1-e9a5-4bf3-af6d-a9e6d0009998
# ╠═e36dc0e2-015e-4132-a105-d145e17cceb8
# ╠═50e128f3-72d9-42b1-b987-540bf6e7e6d0
# ╟─5446afd1-4326-41ab-94ec-199587c1411b
# ╠═f21b48c0-8e0c-4b67-9145-52a1480003ed
# ╠═c82d7f29-08f4-4268-881f-e422864ab789
# ╟─9816aa83-4f98-4ea6-b149-749eacf833e6
# ╟─ebf91bfe-01e2-4975-93fe-b6c7ad03846f
# ╠═1e80cb97-f238-43f7-b082-6ab2deacd701
# ╠═911a3b54-10f4-4ddb-bb89-f380c79b4476
# ╠═22043683-a69f-4394-b872-4be6eb4b5dc9
# ╠═f0f28c3a-aa3c-4111-b676-5fd22fb3238c
# ╟─218c8ebb-414e-40f8-ad7a-ad5b6a0a44f3
# ╠═d0433ace-dcfa-4adf-8df1-f7e0784afb5a
# ╠═7c48582c-3493-4c80-aab3-019aef3da65c
# ╠═192ea8d5-df83-4944-9998-7b3006b32d68
# ╟─541a4049-d17d-4ec8-8fd7-fe934ca53230
# ╠═5d7f3f13-eded-4e01-bb4e-925d24f2d883
# ╠═ae560365-dddf-4aff-aff9-0dcd4227e1c4
# ╠═e17a3e03-88bf-4b9d-b3fb-5e20b4541c36
# ╠═a2e58e67-f7f1-444b-991f-442f304f86bf
# ╟─4d86e477-7a9e-4eed-8b8f-e007411b2898
# ╠═eea50a16-6798-4b53-8c36-ec647b592b23
# ╟─e81ab1c3-228c-4a32-9275-43d5f9b134db
# ╠═df7431fe-dcde-4456-a548-1ffafccb84b8
# ╠═e9ffaaed-b8b3-4825-8bb2-30a848a17abc
# ╠═c6b9ea47-0dc5-42b9-a0b1-ff4158102d49
# ╠═6895ed8b-acf4-4941-ada7-38ab54d77870
# ╟─f02237a0-b9d2-4486-8608-cf99a5ea42bd
# ╟─36431db2-ac86-48ce-8a91-16d9cca57dad
# ╠═cf33519f-4b3e-4d84-9f48-1e76f4e8be47
# ╟─0f131ff8-d956-4d46-a7f0-a89f9c647dc7
# ╠═49134949-ea48-468b-934e-8101c6424ded
# ╠═a8cd9c4d-9afe-4656-9142-6525d9181ecf
# ╠═9b8ce85f-2cb8-43a9-a536-0d44681b5dfa
# ╠═f03893b1-7518-47d3-ae88-da688aff9591
# ╠═73fddb34-3e63-43bf-8912-98ce180127e4
# ╠═c49e01f1-4a58-49af-8c9b-2f4d5baa1d97
# ╠═4579294d-d33a-4469-859e-985eeac3108d
# ╠═24a66024-4213-4c6f-833b-d364fd9f1a87
# ╠═d9cc17ce-2c3c-4320-a93e-2e6db054470d
# ╟─08420a59-34c1-4a29-a1d9-b8a6aa56ff1f
# ╠═6ef141f2-4655-431e-b064-1c82794c9bac
# ╠═1aed0dcb-3fa8-4c50-ac25-78e60c0ab99d
# ╠═55a3b368-843e-47f1-a804-c5d3f582b1b9
# ╟─9f776e2f-1fa9-48f5-b554-6bf5a5d91441
# ╠═ad1a5963-d120-4a8c-b5e1-9bd743a32670
# ╠═8af8885c-48d8-40cf-8584-45d89521d9a1
# ╠═620d9b28-dca9-4678-a50e-82af5176f558
# ╠═1aeef97f-112b-4d1c-b4b0-b176483a783b
