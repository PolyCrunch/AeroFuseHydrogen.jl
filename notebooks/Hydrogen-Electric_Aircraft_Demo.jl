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

# ╔═╡ 88b272f9-ad2c-4aab-b784-6907dc87ea2d
begin
	global CLmax = 1.9;
	global CLmax_TO = 2.5;
	global CLmax_LD = 2.7;

	global CD_0 = 0.0478; # Need confirming. Taken from some random person's thesis
	global CD0_TO = 0.0828; # Added 0.04 from Levis
	global CD0_LD = 0.1328; # Added 0.11 from Levis

	global e = 0.75;
	global e_TO = e - 0.05 - 0.05;
	global e_LD = e - 0.05 - 0.10;
end

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
    spans       = [9.5, 18.9] / 2,                # Span lengths TIP ACCURATE
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
	S_ref = projected_area(wing)					# Area, m^2
	c_w = mean_aerodynamic_chord(wing)				# Mean aerodynamic chord, m
	mac_w = mean_aerodynamic_center(wing, 0.25)		# Mean aerodynamic center (25%), m
	mac40_wing = mean_aerodynamic_center(wing, 0.40)# Mean aerodynamic center (40%), m
end;

# ╔═╡ bae8f6a4-a130-4c02-8dd4-1b7fc78fb104
AR = aspect_ratio(wing);

# ╔═╡ c84c5839-b215-4f5d-b89a-24da4a7241c2
md"""
## Power Requirements
Need weights to get constraint diagrams. Estimate empty weight, fuel weight, and GTOW."""

# ╔═╡ 45193a1b-732f-4d38-b417-a23c65c76ce4
md"""### Max L/D
Estimate from wetted aspect ratio (Raymer)."""

# ╔═╡ a4d378e7-40e5-467c-a126-6432076b32c1
K_LD = 15.5; # Factor — assume civil jet

# ╔═╡ 92b76c68-c68e-47ed-846b-9b7be027a438
md"""### Specific fuel consumption
Fuel mass flow rate / thrust

$$C = \frac{\text{Fuel mass flow rate}}{\text{Thrust}} = \frac{\dot{m}}{P} \cdot \frac{V}{\eta_{propeller}}$$
"""

# ╔═╡ dd5ca173-b70a-4bc7-9c13-78cece8269ed
md"Finding an appropriate $\dot{m}/P$"

# ╔═╡ 8790bead-dd8b-4ac4-843d-d264243fa7e6
C_power = psfc(200., 1.) # nb effective area 200 is approx 90% higher than the minimum. kg/W-s

# ╔═╡ a3036e50-f599-4614-a14b-2ec1ef4a7b4e
C_power * 1000 * 1000 # mg/W-s. N.B. 0.07-0.09 for piston-prop. Right order of magnitude, and hydrogen is energy rich!

# ╔═╡ b8db061e-3dfb-4883-85f9-455ce2bd4912
md"""
### Fuel Weight Fraction
"""

# ╔═╡ a9cf68ca-cf0c-481c-b88c-3f4cf222ee5b
h_cruise = 7500; # Similar to Dash 8 Q400

# ╔═╡ 95910c74-faa4-404f-b0a2-a642cc0f8093
a_cruise = sqrt(1.4 * 287 * T_air(h_cruise))

# ╔═╡ 2ff4b8a7-5985-4033-855e-8d169fe2d6fb
M_cruise = 0.5;

# ╔═╡ be1dfd57-dddb-4d83-8a4d-cdaa13323f2c
V_cruise = a_cruise * M_cruise

# ╔═╡ c6697863-76bd-4ead-8cd7-7b4818d5af6f
η_prop = 0.8;

# ╔═╡ eda958b2-a71c-41f3-9643-3b3eb130224d
Hjet_HH2 = 1/2.;

# ╔═╡ bb004a3a-40c3-4f13-975e-f0d6aa20612d
W1_W0 = 1 - (1 - 0.970) * Hjet_HH2; # Warmup and take-off [corrected from Raymer]. This could be lower as no warm up!

# ╔═╡ 60f4656e-b8fb-465a-bd3e-8647fbb785c8
W2_W0 = 1 - (1 - 0.985) * Hjet_HH2; # Climb [Raymer]

# ╔═╡ e86479c5-cbf6-42e1-8b7d-52684360f0b2
W4_W0 = 1 - (1 - 0.995) * Hjet_HH2; # Land

# ╔═╡ 8f7b0cf4-6d09-4d20-a130-90c7368dc39b
W5_W0 = 1 - (1 - 0.985) * Hjet_HH2; # Climb [Raymer]

# ╔═╡ 75af705e-6508-438d-8094-ffec993d0060
W7_W0 = exp((-5400 * 9.81 * psfc(200., 1.e6))/(η_prop)); # 45 min loiter — this seems unrealistic

# ╔═╡ 17a2f25a-964a-4a73-996a-a18484f82add
W8_W0 = 1 - (1 - 0.995) * Hjet_HH2; # Land

# ╔═╡ 3920cf3a-1144-4fe7-9a40-9b12a1a4ed9e
md"""### Passenger Weight
As fuel will be stored in the cabin, number of passengers will depend on size of tank."""


# ╔═╡ 22a540fa-0659-4eb9-9d73-fb9516e5f715
n_basepassengers = 80;

# ╔═╡ bb3a629d-b63f-42dc-a074-d5df13ca0aee
W0_base = 30481.;

# ╔═╡ ff947612-2f1e-49a7-9815-8dea097edc3c
md"""### Crew Weight
2 pilots, 1 flight attendant per 50 passengers (from FAR 25).

85kg * 2 + 75kg * 2. Assuming 15kg payload each
"""

# ╔═╡ 7115cdf4-632c-45be-a3bd-2aaf152e42c9
md"""### Empty Weight Fraction
Raymer, twin turboprop: We/W0 = 0.96 * W_0^{-0.05}

Correction factor for Hydrogen: 1.16x"""

# ╔═╡ e58f446a-88fe-430a-9598-d5bf2dc931ee
md"### $W_0$"

# ╔═╡ c7f6cae8-0116-4993-8aec-e1dc0a8a8e63
#print(L_tank)

# ╔═╡ df79508b-2df5-45c9-81be-bfa28398bba2
mass_motor = motor_mass(8.e6, Future)

# ╔═╡ a77fce1f-0574-4666-ba3b-631716384ae0
md"""
### Constraint Diagrams
"""

# ╔═╡ cea3ed96-73aa-44ee-bdc5-2becba65987f
W_S = LinRange(0, 10000, 100);

# ╔═╡ d037c253-032a-4a83-a246-5920cd8e57be
md"""
#### Take-Off
1500 m seems like a good target.

London City is 1508m — Inverness and Isle of Man are 1800-1900 m

Actual take-off distance: what is required AEO

Take-off distance required: 1.15x actual; or balanced field length

Actual landing distance: what the aircraft would ideally require

Landing distance required: 5/3 x actual landing distance


Lots of maths, but for propeller 50ft obstacle clearance,

$$TODA_{m} \geq 11.7 TOP_{SI}$$
"""

# ╔═╡ 50275134-8baa-48fe-be7b-93d17a029c85
md"""##### 50ft Obstacle"""

# ╔═╡ 91f05db8-972e-435e-aaf7-a207047e27e8
CL_TO = CLmax_TO * 0.88; # RANDOM GUESS FOR NOW

# ╔═╡ 4b738106-128e-4399-8edb-2c1b6e2a5512
σ_TO_LDG = 1.; # SEA LEVEL FOR NOW

# ╔═╡ 005399ec-fc82-445f-92a5-7172c2b4722d
TODA_min = 1500; # metres. Needs justifying

# ╔═╡ 9d98cc63-eec4-4294-8467-b1ca1117d243
PW_TO50 = 11.7 * W_S / (TODA_min * σ_TO_LDG * CL_TO);

# ╔═╡ c727ec57-02ad-443c-b8e1-0303ed101e5d
md"""##### BFL Estimate"""

# ╔═╡ 6881d47f-4fc6-4885-9e6c-ebbcbca31005
N_E = 2;

# ╔═╡ cc47266b-899d-4519-b159-915b3ae14a54
PW_TO_BFL = PW_TO50 * (0.297 - 0.019 * N_E) / 0.144;

# ╔═╡ 0726c8be-9699-4d05-ae2d-3a24db308ae4
md"""#### Landing Distance"""

# ╔═╡ bd40dd8a-8f7e-4f68-a052-be71620a1f9e
begin
	ALD = TODA_min / (5/3); # 5/3 is mandatory safety factor
	Sa = 305; # For a 3 degree glideslope
	KR = 0.66; # Assume thrust reversers

	global WS_ldg = (ALD - Sa) * σ_TO_LDG * CLmax_LD / (0.51 * KR);
end

# ╔═╡ 8af17db4-6710-4e4d-8384-e3768d43e609
md"""#### Flight Phases
$$\bigg( \frac{P}{W} \bigg)_0 = \frac{V_\infty \alpha}{\eta_{prop} \beta} \bigg[ \frac{1}{V_\infty} \frac{dh}{dt} + \frac{1}{g} \frac{dV_\infty}{dt} + \frac{\frac{1}{2}\rho V_\infty^2 C_{D_0}}{\alpha W_0/S_{ref}} + \frac{\alpha n^2 W_0/S_{ref}}{\frac{1}{2}\rho V_\infty^2 \pi AR e} \bigg]$$


For climb:

$$\bigg( \frac{P}{W} \bigg)_0 = \frac{V_\infty \alpha}{\eta_{prop} \beta} \bigg[ G + \frac{C_{D_0}}{\alpha C_L} + \frac{\alpha C_L}{\pi AR e} \bigg]$$



For cruise:

$$\bigg( \frac{P}{W} \bigg)_0 = \frac{V_\infty \alpha}{\eta_{prop} \beta} \bigg[ 
\frac{\frac{1}{2}\rho V_\infty^2 C_{D_0}}{\alpha W_0/S_{ref}} + \frac{\alpha n^2 W_0/S_{ref}}{\frac{1}{2}\rho V_\infty^2 \pi AR e}
\bigg]$$
"""

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
i = LinRange(0., 1600, 100) / 1000;

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
polarization_coeffs = [LinearRegression.slope(E_fit); LinearRegression.bias(E_fit)]

# ╔═╡ 4d86e477-7a9e-4eed-8b8f-e007411b2898
md"""### Defining the Fuel Cell Stack"""

# ╔═╡ e2457cb1-8718-4175-b7a2-e5ad6e864a43
P_max = 4.e6 # Maximum power needed by the aircraft (W)

# ╔═╡ 4e23f46e-9253-4b3b-92fa-1efe7049899a
A_min = - 4 * polarization_coeffs[1] * P_max / polarization_coeffs[2]^2 / 10000;

# ╔═╡ 45f95a01-b50d-4f11-bc5c-412968c16dee
print("Minimum fuel cell area required for a real 'i': " * string(round(A_min, digits=1)) * " m^2");

# ╔═╡ cbeacb6e-f1ae-4152-aef5-426908cb5f6e
order_A = floor(Int, log10(A_min));

# ╔═╡ 479f80e3-8ab6-4f3d-bd47-a18f4671dfa9
md"Choose a fuel cell area for your aircraft, and observe the effect on fuel cell length and efficiency $η$ at max power:"

# ╔═╡ 040809ae-69cf-4445-8a6c-82c404b7dabd
@bind A_eff Slider(A_min*1.1:10^(order_A-0.5):5*A_min, default=A_min*1.2)

# ╔═╡ eea50a16-6798-4b53-8c36-ec647b592b23
PEMFC = PEMFCStack(
	area_effective=A_eff,
	power_max = P_max,
	height = 2.,
	width = 2.,
	layer_thickness=0.0043,
	position = [0., 0., 0.]
)

# ╔═╡ ec53c66a-9f14-4520-8d28-2f53a54bb447
print("Fuel cell area: " * string(round(A_eff, digits=0)) * " m^2")

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
j_PEMFC = j_cell(PEMFC, 1, polarization_coeffs) # Cell current density (A/cm^2)

# ╔═╡ e9ffaaed-b8b3-4825-8bb2-30a848a17abc
U_PEMFC = U_cell(j_PEMFC, polarization_coeffs); # Cell potential difference (V)

# ╔═╡ c6b9ea47-0dc5-42b9-a0b1-ff4158102d49
η_PEMFC = η_FC(U_PEMFC) # Fuel cell stack efficiency (w.r.t HHV)

# ╔═╡ 6895ed8b-acf4-4941-ada7-38ab54d77870
mdot_H2 = fflow_H2(PEMFC, 1., polarization_coeffs) # Hydrogen mass flow rate in (kg/s)

# ╔═╡ 1d624369-c08a-4c65-8ac4-46e8605cf905
PEMFC_length = length(PEMFC) # Fuel cell length (m)

# ╔═╡ 5270c8d4-4703-423b-89a5-805679a374ae
PEMFC_mass = mass(PEMFC) # Fuel cell mass (kg)

# ╔═╡ 429db1e1-071f-41de-a02f-7d0297353928
md"""Generate eta, m_dot versus Area plots (temporary)"""

# ╔═╡ e2848f51-2145-4d37-a2c3-d73a67cd525d
Areas = LinRange(523, 2000, 20);

# ╔═╡ 448e3477-6be6-41fb-8794-cd95c9ea56db
begin
	eta_fullpower = zeros(size(Areas));
	eta_thirdpower = zeros(size(Areas));

	mdot_fullpower = zeros(size(Areas));
	mdot_thirdpower = zeros(size(Areas));

	length_fullpower = zeros(size(Areas));

	mass_fullpower = zeros(size(Areas));
	
	for i in 1:length(Areas)
		PEMFC_AreaStudy = PEMFCStack(
			area_effective=Areas[i],
			power_max = P_max,
			height = 2.,
			width = 2.,
			layer_thickness=0.0043,
			position = [0., 0., 0.]
		)

		eta_fullpower[i] = η_FC(PEMFC_AreaStudy, 1.);
		eta_thirdpower[i] = η_FC(PEMFC_AreaStudy, 0.33);

		mdot_fullpower[i] = fflow_H2(PEMFC_AreaStudy, 1.);
		mdot_thirdpower[i] = fflow_H2(PEMFC_AreaStudy, 0.33);

		length_fullpower[i] = length(PEMFC_AreaStudy);
		mass_fullpower[i] = mass(PEMFC_AreaStudy);
	end
end

# ╔═╡ 92e4aa80-c9fd-4aa0-940a-7ca4765141f5
begin
	plot(
			Areas, eta_fullpower,
			label = "Full power",
			lw = 3.,
			ylabel = "η",
			xlabel = "Fuel Cell Area (m²)",
			title = "Fuel cell efficiency versus effective area"
		);
		plot!(
			Areas, eta_thirdpower,
			label = "1/3 power",
			lw = 3.,
		);
end

# ╔═╡ 373a8b16-b3a2-4cfb-ae50-bc9962a6cbe5
begin
	plot(
			Areas, mdot_fullpower,
			label = "Full power",
			lw = 3.,
			ylabel = "H2 mass flow rate (kg/s)",
			xlabel = "Fuel Cell Area (m²)",
			title = "Hydrogen mass flow rate versus PEMFC effective area"
		);
		plot!(
			Areas, mdot_thirdpower,
			label = "1/3 power",
			lw = 3.,
		);
end

# ╔═╡ 5bfe15dd-29db-4a48-af6f-f8a04bb495e7
begin
	plot(
			Areas, length_fullpower,
			lw = 3.,
			ylabel = "PEMFC Length (m)",
			xlabel = "Fuel Cell Area (m²)",
			title = "Fuel cell length versus effective area"
		);
end

# ╔═╡ ef8669ca-1897-4397-ae00-3da40b64b487
begin
	plot(
			Areas, mass_fullpower,
			lw = 3.,
			ylabel = "PEMFC mass (kg)",
			xlabel = "Fuel Cell Area (m²)",
			title = "Fuel cell mass versus effective area"
		);
end

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
V_h = S_h / S_ref * (mac_h.x - mac_w.x) / c_w;

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

# ╔═╡ 8a73957f-b08e-41e7-8fa4-410558da04e5
S_wet = (wetted_area(wing_mesh) + wetted_area(fuse, 0:0.1:1) + wetted_area(htail_mesh) + wetted_area(vtail_mesh)); # Approximate wetted area calculated from fuselage and flight surfaces. Doesn't account for intersection of surfaces and fuselage, nor does it account for engine nacelles

# ╔═╡ 24bc5967-b0ea-4081-b3de-d4c362670787
A_wetted = aspect_ratio(wing)/(S_wet/S_ref) # AR / (S_wet / S_ref)

# ╔═╡ 0a750cbd-0842-42d4-9a00-99c4c69672fc
LD_max = K_LD * sqrt(A_wetted) # Raymer

# ╔═╡ 34d83139-a0ce-4712-a884-a3c53a2df098
W3_W0 = exp((-2000e3 * 9.81 * psfc(200., 1.e6))/(η_prop * LD_max)); # Cruise

# ╔═╡ 50ebd56c-b6bc-4a0a-ad97-f9b8e94ac8bf
W6_W0 = exp((-300e3 * 9.81 * psfc(200., 1.e6))/(η_prop * LD_max)); # Diversion 300km

# ╔═╡ e00ea2c0-dee4-43e1-ab9d-6c8de1e0c2aa
begin
	Wi_W0 = 1; # Initial weight fraction
	Wi_W0 *= W1_W0;
	Wi_W0 *= W2_W0;
	Wi_W0 *= W3_W0;
	Wi_W0 *= W4_W0;
	Wi_W0 *= W5_W0;
	Wi_W0 *= W6_W0;
	Wi_W0 *= W7_W0;
	Wi_W0 *= W8_W0;
end

# ╔═╡ 16996cd1-b98a-4ab7-9674-e45b8548eda7
begin
	tol = 0.1;
	global W0_prev = 0.0;
	global curstep = 0;
	max_step = 10000;

	We_base = 17819. - 2*718.; # Mass of base Dash 8 Q400 without engines
	P_tot = 7562000.; # Total engine power of base Dash 8 Q400

	# Fixed
	global Wf_W0 = 1.12 * (1 - Wi_W0); # Allow extra fuel mass for excess boil-off. Justify this later.
	P_cabin = 38251.; # Cabin pressure, in Pa
	
	# Initial guesses
	global W0 = [30481.0]; # Based on Dash 8 Q400 MTOW

	while abs(W0[end] - W0_prev) > tol
		global curstep += 1;
		if curstep >= max_step
			print("Failed to iterate within max_step")
			push!(W0, -1.0)
			break
		end
		global W0_prev = W0[end];

		concept_tank = CryogenicFuelTank(
			radius=fuse.radius - fuse_t_w,
			length=volume_to_length(Wf_W0 * W0[end] / ρ_LH2, fuse.radius - fuse_t_w, t_insulation),
			insulation_thickness=0.05,
			insulation_density=35.3
		)

		concept_fc = PEMFCStack(
			area_effective=840.,
			power_max = P_tot,
			height=2*(fuse.radius - fuse_t_w),
			width=2*(fuse.radius - fuse_t_w)
		)
		
		global n_passengers = n_basepassengers - 4 * Int(ceil(concept_tank.length/0.762));
		W_crew = crew_weight(2, n_passengers);
		n_cc = n_cabincrew(n_passengers);
		W_payload = n_passengers * (84 + 23);

		global We = We_base;
		We += dry_mass(concept_tank); # Tank mass
		We += mass(concept_fc); # FC mass
		We += motor_mass(P_tot, Future); # Motor mass
		We -= furnishings_weight(2, n_basepassengers, 2, p_air(2200), W0_base, ShortHaul, Short); # Subtract the total weight of furnishings (base)
		We += furnishings_weight(2, n_passengers, n_cc, p_air(2200), W0[end], ShortHaul, Short); # Add the new total weight of the furnishings
		


		global drymass = dry_mass(concept_tank)
		W0_new = (W_crew + W_payload + We) / (1 - Wf_W0)
		push!(W0, W0_new)
	end
end

# ╔═╡ 913db9f9-850b-4fe9-b4c5-1c872fc7ebf9
W0[end]

# ╔═╡ 6c8ed38b-1b05-41ca-92f9-760501184e58
n_passengers

# ╔═╡ 077500bd-581a-46b0-a943-f05a036cf01a
curstep

# ╔═╡ a658e85d-1402-4b3f-a8b2-c4205572d2d3
Wf = Wf_W0 * W0[end]

# ╔═╡ 72ba560b-198f-457a-ba1e-3ddb3628864a
Vf = Wf / ρ_LH2

# ╔═╡ 82b332ac-5628-4b82-8735-f361dcdfc9b6
tank = CryogenicFuelTank(
	radius = fuse.radius - fuse_t_w,
	length = volume_to_length(Vf, fuse.radius - fuse_t_w, t_insulation),
	insulation_thickness = t_insulation,
	insulation_density = insulation_material.Density,
	position = [0.55fuse.length, 0, 0]
)

# ╔═╡ 63475bbf-6993-4f6c-86b8-f3b608b63a8e
tank_length = tank.length # Tank exterior length

# ╔═╡ b9fddbc4-a2d7-48cf-ace4-f092a3c38b11
tank_dry_mass = dry_mass(tank) # Calculate the dry mass of the tank (kg)

# ╔═╡ a0c931b1-e9a5-4bf3-af6d-a9e6d0009998
full_tank_mass = wet_mass(tank, 1) # Calculate the mass of a fuel tank. This function can also accept a vector of fractions

# ╔═╡ e36dc0e2-015e-4132-a105-d145e17cceb8
tank_capacity = internal_volume(tank) # Calculate the internal volume of the fuel tank

# ╔═╡ 5fb06c72-03e3-4e10-b14c-2aa55413d675
mdot = boil_off(tank, K_insulation, T_s_0, T∞, T_LH2, ϵ)

# ╔═╡ 852baaab-ce24-48cc-8393-1a8ee7554874
W0plot = plot(
		1:curstep+1,
		W0,
		title = "Design MTOW Convergence",
		xlabel = "Step",
		ylabel = "Design MTOW (kg)",
		legend = false
	)

# ╔═╡ 8ce1c30e-b602-4411-b671-1cc5f267e646
We

# ╔═╡ aab531a1-910a-4ef3-b161-5cef662a2c38
begin
	# Top of initial climb: 7500 m (25,000 ft)
	W_cl1 = W0[end] * W1_W0 * W2_W0;
	α_cl1 = W_cl1 / W0[end];
	β = 1;
	V_cl1 = TAS(h_cruise, 80);
	G_cl = 0.05;
	ρ_cr = ρ_air(h_cruise);
	
	CL_cl1 = α_cl1 * W_S / (0.5 * ρ_cr * V_cl1^2);
	global PW_climb1 = (V_cl1 * α_cl1)/(η_prop * β) .* ( G_cl .+ (CD_0)./(α_cl1 .* CL_cl1) .+ (α_cl1 .* CL_cl1)./(π * AR * e) );
end;

# ╔═╡ bf75995b-317b-4ade-a46a-51ed947240c3
# ╠═╡ disabled = true
#=╠═╡
begin
	# Disabled as similar to climb 1
	# Top of second climb: 7500 m (25,000 ft)
	W_cl2 = W0[end] * W1_W0 * W2_W0 * W3_W0 * W4_W0 * W5_W0;
	α_cl2 = W_cl2 / W0[end];
	V_cl2 = V_cl1;

	CL_cl2 = α_cl2 * W_S / (0.5 * ρ_cr * V_cl2^2);
	global PW_climb2 = (V_cl2 * α_cl2)/(η_prop * β) .* ( G_cl .+ (CD_0)./(α_cl2 .* CL_cl2) .+ (α_cl2 .* CL_cl2)./(π * AR * e) );
end;
  ╠═╡ =#

# ╔═╡ 013f96c8-441d-49cb-b8f5-aa3c138aaedd
begin
	# OEI climb with gear, 0.5%. Assume one engine available results in 60% thrust as before, as often max power > continuous power
	W_cl_oei_gear = W0[end] * W1_W0;
	α_cl_oei_gear = W_cl_oei_gear / W0[end];
	β_oei = 0.6;
	V_cl_oei_gear = 80; # 80 m/s; ground level
	G_cl_oei_gear = 0.005;
	ρ_gnd = 1.225;

	CL_cl_oei_gear = α_cl_oei_gear * W_S / (0.5 * ρ_gnd * V_cl_oei_gear^2);
	global PW_cl_oei_gear = (V_cl_oei_gear * α_cl_oei_gear)/(η_prop * β_oei) .* ( G_cl_oei_gear .+ (CD0_TO)./(α_cl_oei_gear .* CL_cl_oei_gear) .+ (α_cl_oei_gear .* CL_cl_oei_gear)./(π * AR * e_TO));
end;

# ╔═╡ bae57b19-402e-4169-9ae6-c2d86248e798
begin
	# OEI climb without gear, 3%. Assume one engine available results in 60% thrust as before, as often max power > continuous power
	W_cl_oei = W0[end] * W1_W0;
	α_cl_oei = W_cl_oei_gear / W0[end];
	V_cl_oei = 80; # 80 m/s; ground level
	G_cl_oei = 0.03;

	CL_cl_oei = α_cl_oei * W_S / (0.5 * ρ_gnd * V_cl_oei^2);
	global PW_cl_oei = (V_cl_oei * α_cl_oei)/(η_prop * β_oei) .* ( G_cl_oei .+ (CD_0)./(α_cl_oei .* CL_cl_oei) .+ (α_cl_oei .* CL_cl_oei)./(π * AR * e));
end;

# ╔═╡ 94eaf8be-b197-4606-9908-bc8317b1c6d0
begin
	# Curves
	plot(
		W_S,
		[PW_TO50 PW_TO_BFL PW_climb1 PW_cl_oei_gear PW_cl_oei],
		label = ["Take-off: 50ft obstacle" "Take-off: BFL" "5.0% Top of Climb 1" "0.5% Climb, Gear Down, OEI" "3.0% Climb, OEI"],
	);

	# Vertical lines
	plot!(
		[WS_ldg; WS_ldg],
		[0; 100],
		label = "Landing 1500 m",
		xlabel = "Wing loading (N/m^2)",
		ylabel = "Power to weight (W/N)"
	);

	plot!(
		[30481 * 9.81 / S_ref],
		[3781 * 1000 * 2 / (30481 * 9.81)],
		label = "Dash 8 Q400 Design Point",
		marker = :circle,
		xlims = (0, 10000),
		ylims = (0, 100)
	)
end

# ╔═╡ 4cab2aca-0379-4f36-aec7-3bac193143d4
begin
	# Cruise at 7500 m
	α_cr = W_cl1 / W0[end]; # Same as top of climb 1
	V_cr = TAS(h_cruise, V_cruise);

	
end;

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

# ╔═╡ f001804d-1bad-4800-8ab0-09717d605dfd
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
# ╠═88b272f9-ad2c-4aab-b784-6907dc87ea2d
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
# ╠═bae8f6a4-a130-4c02-8dd4-1b7fc78fb104
# ╟─c84c5839-b215-4f5d-b89a-24da4a7241c2
# ╟─45193a1b-732f-4d38-b417-a23c65c76ce4
# ╠═a4d378e7-40e5-467c-a126-6432076b32c1
# ╠═8a73957f-b08e-41e7-8fa4-410558da04e5
# ╠═24bc5967-b0ea-4081-b3de-d4c362670787
# ╠═0a750cbd-0842-42d4-9a00-99c4c69672fc
# ╟─92b76c68-c68e-47ed-846b-9b7be027a438
# ╟─dd5ca173-b70a-4bc7-9c13-78cece8269ed
# ╠═8790bead-dd8b-4ac4-843d-d264243fa7e6
# ╠═a3036e50-f599-4614-a14b-2ec1ef4a7b4e
# ╟─b8db061e-3dfb-4883-85f9-455ce2bd4912
# ╠═a9cf68ca-cf0c-481c-b88c-3f4cf222ee5b
# ╠═95910c74-faa4-404f-b0a2-a642cc0f8093
# ╠═2ff4b8a7-5985-4033-855e-8d169fe2d6fb
# ╠═be1dfd57-dddb-4d83-8a4d-cdaa13323f2c
# ╠═c6697863-76bd-4ead-8cd7-7b4818d5af6f
# ╠═eda958b2-a71c-41f3-9643-3b3eb130224d
# ╠═bb004a3a-40c3-4f13-975e-f0d6aa20612d
# ╠═60f4656e-b8fb-465a-bd3e-8647fbb785c8
# ╠═34d83139-a0ce-4712-a884-a3c53a2df098
# ╠═e86479c5-cbf6-42e1-8b7d-52684360f0b2
# ╠═8f7b0cf4-6d09-4d20-a130-90c7368dc39b
# ╠═50ebd56c-b6bc-4a0a-ad97-f9b8e94ac8bf
# ╠═75af705e-6508-438d-8094-ffec993d0060
# ╠═17a2f25a-964a-4a73-996a-a18484f82add
# ╠═e00ea2c0-dee4-43e1-ab9d-6c8de1e0c2aa
# ╟─3920cf3a-1144-4fe7-9a40-9b12a1a4ed9e
# ╠═22a540fa-0659-4eb9-9d73-fb9516e5f715
# ╠═bb3a629d-b63f-42dc-a074-d5df13ca0aee
# ╟─ff947612-2f1e-49a7-9815-8dea097edc3c
# ╟─7115cdf4-632c-45be-a3bd-2aaf152e42c9
# ╟─e58f446a-88fe-430a-9598-d5bf2dc931ee
# ╠═16996cd1-b98a-4ab7-9674-e45b8548eda7
# ╠═913db9f9-850b-4fe9-b4c5-1c872fc7ebf9
# ╠═c7f6cae8-0116-4993-8aec-e1dc0a8a8e63
# ╠═6c8ed38b-1b05-41ca-92f9-760501184e58
# ╠═077500bd-581a-46b0-a943-f05a036cf01a
# ╠═a658e85d-1402-4b3f-a8b2-c4205572d2d3
# ╠═72ba560b-198f-457a-ba1e-3ddb3628864a
# ╟─852baaab-ce24-48cc-8393-1a8ee7554874
# ╠═df79508b-2df5-45c9-81be-bfa28398bba2
# ╠═8ce1c30e-b602-4411-b671-1cc5f267e646
# ╟─a77fce1f-0574-4666-ba3b-631716384ae0
# ╠═cea3ed96-73aa-44ee-bdc5-2becba65987f
# ╟─d037c253-032a-4a83-a246-5920cd8e57be
# ╟─50275134-8baa-48fe-be7b-93d17a029c85
# ╠═91f05db8-972e-435e-aaf7-a207047e27e8
# ╠═4b738106-128e-4399-8edb-2c1b6e2a5512
# ╠═005399ec-fc82-445f-92a5-7172c2b4722d
# ╠═9d98cc63-eec4-4294-8467-b1ca1117d243
# ╟─c727ec57-02ad-443c-b8e1-0303ed101e5d
# ╠═6881d47f-4fc6-4885-9e6c-ebbcbca31005
# ╠═cc47266b-899d-4519-b159-915b3ae14a54
# ╟─0726c8be-9699-4d05-ae2d-3a24db308ae4
# ╟─bd40dd8a-8f7e-4f68-a052-be71620a1f9e
# ╠═8af17db4-6710-4e4d-8384-e3768d43e609
# ╠═aab531a1-910a-4ef3-b161-5cef662a2c38
# ╠═bf75995b-317b-4ade-a46a-51ed947240c3
# ╠═013f96c8-441d-49cb-b8f5-aa3c138aaedd
# ╠═bae57b19-402e-4169-9ae6-c2d86248e798
# ╠═4cab2aca-0379-4f36-aec7-3bac193143d4
# ╠═94eaf8be-b197-4606-9908-bc8317b1c6d0
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
# ╠═5fb06c72-03e3-4e10-b14c-2aa55413d675
# ╠═50e128f3-72d9-42b1-b987-540bf6e7e6d0
# ╠═f001804d-1bad-4800-8ab0-09717d605dfd
# ╟─5446afd1-4326-41ab-94ec-199587c1411b
# ╠═f21b48c0-8e0c-4b67-9145-52a1480003ed
# ╠═c82d7f29-08f4-4268-881f-e422864ab789
# ╟─9816aa83-4f98-4ea6-b149-749eacf833e6
# ╟─ebf91bfe-01e2-4975-93fe-b6c7ad03846f
# ╠═1e80cb97-f238-43f7-b082-6ab2deacd701
# ╟─911a3b54-10f4-4ddb-bb89-f380c79b4476
# ╠═22043683-a69f-4394-b872-4be6eb4b5dc9
# ╟─f0f28c3a-aa3c-4111-b676-5fd22fb3238c
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
# ╠═e2457cb1-8718-4175-b7a2-e5ad6e864a43
# ╠═eea50a16-6798-4b53-8c36-ec647b592b23
# ╟─4e23f46e-9253-4b3b-92fa-1efe7049899a
# ╟─45f95a01-b50d-4f11-bc5c-412968c16dee
# ╠═cbeacb6e-f1ae-4152-aef5-426908cb5f6e
# ╠═479f80e3-8ab6-4f3d-bd47-a18f4671dfa9
# ╠═040809ae-69cf-4445-8a6c-82c404b7dabd
# ╠═ec53c66a-9f14-4520-8d28-2f53a54bb447
# ╟─e81ab1c3-228c-4a32-9275-43d5f9b134db
# ╠═df7431fe-dcde-4456-a548-1ffafccb84b8
# ╠═e9ffaaed-b8b3-4825-8bb2-30a848a17abc
# ╠═c6b9ea47-0dc5-42b9-a0b1-ff4158102d49
# ╠═6895ed8b-acf4-4941-ada7-38ab54d77870
# ╠═1d624369-c08a-4c65-8ac4-46e8605cf905
# ╠═5270c8d4-4703-423b-89a5-805679a374ae
# ╟─429db1e1-071f-41de-a02f-7d0297353928
# ╠═e2848f51-2145-4d37-a2c3-d73a67cd525d
# ╟─448e3477-6be6-41fb-8794-cd95c9ea56db
# ╟─92e4aa80-c9fd-4aa0-940a-7ca4765141f5
# ╟─373a8b16-b3a2-4cfb-ae50-bc9962a6cbe5
# ╟─5bfe15dd-29db-4a48-af6f-f8a04bb495e7
# ╟─ef8669ca-1897-4397-ae00-3da40b64b487
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
