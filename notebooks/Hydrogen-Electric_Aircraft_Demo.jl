### A Pluto.jl notebook ###
# v0.20.8

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
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

# ╔═╡ b4a9024c-2c1e-4291-95c1-b9560ff94b6d
using LaTeXStrings;

# ╔═╡ 1aeef97f-112b-4d1c-b4b0-b176483a783b
begin
	using PlutoUI
	TableOfContents()
end

# ╔═╡ 316a98fa-f3e4-4b46-8c19-c5dbfa6a550f
md"""# AeroFuse: Hydrogen-Electric Aircraft Design Demo

**Author**: [Tom Gordon](https://github.com/PolyCrunch), Imperial College London.

Based on the work of [Arjit Seth and Rhea P. Liem](https://github.com/GodotMisogi/AeroFuse.jl)

---
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
The aircraft in this demo will be a De Havilland Canada *Dash 8 Q-400*, retrofitted to use hydrogen-electric propulsion.

It will use two electric motors (with propellers) under the wing, powered by PEM electric fuel cells which are fuelled by cryogenic liquid hydrogen.

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
    foils       = [foil_w_r, foil_w_m, foil_w_t], # Airfoils (root to tip)
    chords      = [3.31, 3.00, 1.20],             # Chord lengths (root to tip)
    spans       = [9.5, 18.9] / 2,                # Span lengths
    dihedrals   = fill(1, 2),                     # Dihedral angles (deg)
    sweeps      = fill(4.4, 2),                   # Sweep angles (deg)
    w_sweep     = 0.,                             # Leading-edge sweep
    symmetry    = true,                           # Symmetry

	# Orientation
    angle       = 3,       # Incidence angle (deg)
    axis        = [0, 1, 0], # Axis of rotation, x-axis
    position    = [0.44fuse.length, 0., 1.35]
);

# ╔═╡ d69b550d-1634-4f45-a660-3be009ddd19d
begin
	b_w = span(wing)								# Span length, m
	S_ref = projected_area(wing)					# Area, m^2
	c_w = mean_aerodynamic_chord(wing)				# Mean aerodynamic chord, m
	mac_w = mean_aerodynamic_center(wing, 0.25)		# Mean aerodynamic centre (25%), m
	mac40_wing = mean_aerodynamic_center(wing, 0.40)# Mean aerodynamic centre (40%), m
end;

# ╔═╡ bae8f6a4-a130-4c02-8dd4-1b7fc78fb104
AR = aspect_ratio(wing);

# ╔═╡ e44e5781-c689-463e-b0d3-1d4a434c287a
S_ref

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
C_power = psfc(200., 1.); # nb effective area 200 is approx 90% higher than the minimum. kg/W-s

# ╔═╡ a3036e50-f599-4614-a14b-2ec1ef4a7b4e
C_power * 1000 * 1000 # mg/W-s. N.B. 0.07-0.09 for piston-prop [Raymer]. Right order of magnitude, and hydrogen is energy rich!

# ╔═╡ b8db061e-3dfb-4883-85f9-455ce2bd4912
md"""
### Fuel Weight Fraction
"""

# ╔═╡ a9cf68ca-cf0c-481c-b88c-3f4cf222ee5b
h_cruise = 7500; # [m], Similar to Dash 8 Q400

# ╔═╡ 95910c74-faa4-404f-b0a2-a642cc0f8093
a_cruise = sqrt(1.4 * 287 * T_air(h_cruise));

# ╔═╡ 2ff4b8a7-5985-4033-855e-8d169fe2d6fb
M_cruise = 0.35;

# ╔═╡ be1dfd57-dddb-4d83-8a4d-cdaa13323f2c
V_cruise = a_cruise * M_cruise

# ╔═╡ c6697863-76bd-4ead-8cd7-7b4818d5af6f
η_prop = 0.8;

# ╔═╡ eda958b2-a71c-41f3-9643-3b3eb130224d
Hjet_HH2 = 1/2.8; # Rato of kerosene HHV to hydrogen

# ╔═╡ bb004a3a-40c3-4f13-975e-f0d6aa20612d
W1_W0 = 1 - (1 - 0.970) * Hjet_HH2; # Warmup and take-off [corrected from Raymer]. This could be lower as no warm up!

# ╔═╡ 60f4656e-b8fb-465a-bd3e-8647fbb785c8
W2_W0 = 1 - (1 - 0.985) * Hjet_HH2; # Climb [Raymer]

# ╔═╡ e86479c5-cbf6-42e1-8b7d-52684360f0b2
W4_W0 = 1 - (1 - 0.995) * Hjet_HH2; # Land

# ╔═╡ 8f7b0cf4-6d09-4d20-a130-90c7368dc39b
W5_W0 = 1 - (1 - 0.985) * Hjet_HH2; # Climb [Raymer]

# ╔═╡ 75af705e-6508-438d-8094-ffec993d0060
#W7_W0 = exp((-5400 * 9.81 * psfc(200., 1.e6))/(η_prop)); # 45 min loiter — this seems unrealistic

# ╔═╡ 17a2f25a-964a-4a73-996a-a18484f82add
W8_W0 = 1 - (1 - 0.995) * Hjet_HH2; # Land

# ╔═╡ 22a540fa-0659-4eb9-9d73-fb9516e5f715
n_basepassengers = 80; # Passengers in original Dash 8

# ╔═╡ 57fd1ec3-14be-4b64-8de7-c0f448df630d
W0_base = 30481.0; # MTOW of base Dash 8

# ╔═╡ a2eca0b9-730c-4be0-9e7e-d10d9f7ca664
md"""
### Constraint Diagrams Prep
"""

# ╔═╡ d037c253-032a-4a83-a246-5920cd8e57be
md"""
#### Take-Off
1500 m.

London City is 1508m — Inverness and Isle of Man are 1800-1900 m

Actual take-off distance: what is required AEO
Take-off distance required: 1.15x actual; or balanced field length

Actual landing distance: what the aircraft would ideally require
Landing distance required: 5/3 x actual landing distance
"""

# ╔═╡ 88b272f9-ad2c-4aab-b784-6907dc87ea2d
begin
	# Assumed aerodynamic parameters
	global CLmax = 1.9;
	global CLmax_TO = 2.5;
	global CLmax_LD = 2.7;

	# https://www.researchgate.net/publication/305810138_Conceptual_design_of_a_twin-engine_turboprop_passenger_aircraft
	global CD_0 = 0.0478;
	global CD0_TO = 0.0828; # Added 0.04 from Levis
	global CD0_LD = 0.1328; # Added 0.11 from Levis

	global e = 0.75;
	global e_TO = e - 0.05 - 0.05;
	global e_LD = e - 0.05 - 0.10;
end;

# ╔═╡ cff8b71d-1870-486f-ad06-732813265742
ρ_gnd = 1.225;

# ╔═╡ 91f05db8-972e-435e-aaf7-a207047e27e8
CL_TO = CLmax_TO * 0.88; # Educated guess

# ╔═╡ 4b738106-128e-4399-8edb-2c1b6e2a5512
σ_TO_LDG = 1.; # Assume sea level

# ╔═╡ 005399ec-fc82-445f-92a5-7172c2b4722d
L_rwy = 1500; # [m]

# ╔═╡ 6881d47f-4fc6-4885-9e6c-ebbcbca31005
N_E = 2; # Number of engines

# ╔═╡ 7ba1e469-9442-462d-8164-0552000e1cb7
V_cl = 80.; # IAS during climb

# ╔═╡ c685a7e8-1cfd-4703-830f-9e4c78b19d8d
G_cl = 0.06; # Climb gradient during standard climb

# ╔═╡ f668c250-e709-44e8-b8b2-4bf7a43a0f3d
V_stall = 55.; # Similar to actual Dash 8

# ╔═╡ fcc34f42-2b64-4c4f-8b91-b5f95ddadfd0
ρ_cr = ρ_air(h_cruise);

# ╔═╡ 8af17db4-6710-4e4d-8384-e3768d43e609
md"""#### Specific Excess Power Equations
$$\bigg( \frac{P}{W} \bigg)_0 = \frac{V_\infty \alpha}{\eta_{prop} \beta} \bigg[ \frac{1}{V_\infty} \frac{dh}{dt} + \frac{1}{g} \frac{dV_\infty}{dt} + \frac{\frac{1}{2}\rho V_\infty^2 C_{D_0}}{\alpha W_0/S_{ref}} + \frac{\alpha n^2 W_0/S_{ref}}{\frac{1}{2}\rho V_\infty^2 \pi AR e} \bigg]$$


For climb:

$$\bigg( \frac{P}{W} \bigg)_0 = \frac{V_\infty \alpha}{\eta_{prop} \beta} \bigg[ G + \frac{C_{D_0}}{\alpha C_L} + \frac{\alpha C_L}{\pi AR e} \bigg]$$



For cruise:

$$\bigg( \frac{P}{W} \bigg)_0 = \frac{V_\infty \alpha}{\eta_{prop} \beta} \bigg[ 
\frac{\frac{1}{2}\rho V_\infty^2 C_{D_0}}{\alpha W_0/S_{ref}} + \frac{\alpha n^2 W_0/S_{ref}}{\frac{1}{2}\rho V_\infty^2 \pi AR e}
\bigg]$$
"""

# ╔═╡ 13be94f1-bfc7-44a0-9985-0a3783cd8265
β_OEI = 0.6; # Motor max power is generally above max continuous

# ╔═╡ e58f446a-88fe-430a-9598-d5bf2dc931ee
md"### $W_0$ Determination"

# ╔═╡ d7aebf1e-df3e-42ab-82ed-2080d552722b
t_w_weightloop = 0.001;

# ╔═╡ d5181a37-7a4a-4c34-a9db-de83af11112c
A_FC_factor = 1.0; # Area of FC compared to minimum area of FC

# ╔═╡ a77fce1f-0574-4666-ba3b-631716384ae0
md"""
### Constraint Diagrams
"""

# ╔═╡ cea3ed96-73aa-44ee-bdc5-2becba65987f
W_S = LinRange(0, 10000, 100);

# ╔═╡ b50bf2eb-3bbb-4ce8-b0af-063d69bbeb26
WS_ldg = WS_Landing(;
				    ALD = L_rwy / (5. / 3.),
					S_a = 305.,
					K_R = 0.66,
					σ = σ_TO_LDG
				   );

# ╔═╡ 1d60645e-6d85-4f14-8554-6a0383fe92ea
WS_stall = WS_Stall(;
				   V_stall = V_stall,
				   ρ = ρ_gnd,
				   CL_max = CLmax_LD);

# ╔═╡ aae8d9a3-aa33-4467-adbd-6a639221fbf5
PW_TO50 = PW_50ftTakeoff(W_S;
						TODA_min = L_rwy / 1.15,
						σ = σ_TO_LDG,
						CL_TO = CL_TO);

# ╔═╡ 4c948bb0-7399-4e0f-a9aa-c239aec74566
PW_TO_BFL = PW_BFLTakeoff(W_S;
						 N_E = N_E,
						 TODA_min = L_rwy,
						 σ = σ_TO_LDG,
						 CL_TO = CL_TO);

# ╔═╡ 29a1727c-6eea-4bf3-89c3-789ef8a4f7ac
PW_climb1 = PW_Climb(W_S;
			 α = W1_W0 * W2_W0,
			 β = 1.,
			 V = TAS(h_cruise, V_cl),
			 G = 0.06, # Climb gradient
			 ρ = ρ_cr
			);

# ╔═╡ 8b62eee7-6a6f-43d9-b0f2-e4e48d156a45
PW_cl_oei_gear = PW_Climb(W_S;
		     # OEI climb with gear, 0.5%. Assume one engine available results in 60%
		     # thrust, as often max power > continuous power.
			 α = W1_W0,
			 β = β_OEI,
			 V = V_cl, # Assume sea level
			 G = 0.005, # Regulatory requirement
			 ρ = ρ_gnd,
			 η_prop = η_prop,
			 CD_0 = CD0_TO,
			 AR = AR,
			 e = e_TO
			 );

# ╔═╡ 6a90d93d-246e-46e8-aab8-b604de989823
PW_cl_oei = PW_Climb(W_S;
			# OEI climb without gear, 3%. Assume one engine available results in 60%
			# thrust, as often max power > continuous power.
			α = W1_W0,
			β = β_OEI,
			V = V_cl,
			G = 0.03, # Regulatory requirement
			ρ = ρ_gnd,
			η_prop = η_prop,
			CD_0 = CD_0,
			AR = AR,
			e = e
			);

# ╔═╡ 9bf58181-6a29-4587-bec5-cf5999d0ca32
PW_cr = PW_Cruise(W_S;
			 # Cruise at 7500 m
			 α = W1_W0 * W2_W0, # Most constraining weight expected to be same as top of climb 1
			 β = 1.,
			 V = TAS(h_cruise, V_cruise),
			 η_prop = η_prop,
			 ρ = ρ_cr,
			 CD_0 = CD_0,
			 AR = AR,
			 e = e
		 	);

# ╔═╡ bf75995b-317b-4ade-a46a-51ed947240c3
# ╠═╡ disabled = true
#=╠═╡
PW_climb2 = PW_Climb(W_S;
 	# Disabled as similar to climb 1
	α = W1_W0 * W2_W0 * W3_W0 * W4_W0 * W5_W0,
	β = 1.,
	V = TAS(h_cruise, 80.),
	G = 0.06,
	ρ = ρ_cr);
  ╠═╡ =#

# ╔═╡ 848a3f87-f942-4691-832a-fe1883129e3d
md"""
## Simulation / Fuel Estimations
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
		xlabel = "Current density, i [mA/cm²]",
		ylabel = "Cell PD, E [V]"
	)

	plot!(
		i_extrem.*1000,
		LinearRegression.slope(E_fit) .* i_extrem .+ LinearRegression.bias(E_fit),
		lw=2,
		label="E = -0.213 i + 0.873",
		linestyle=:dash,
		linecolor = :gray50,
		size = (600,300)
	)
end

# ╔═╡ a2e58e67-f7f1-444b-991f-442f304f86bf
polarization_coeffs = [LinearRegression.slope(E_fit); LinearRegression.bias(E_fit)]

# ╔═╡ 4d86e477-7a9e-4eed-8b8f-e007411b2898
md"""### Defining the Fuel Cell Stack"""

# ╔═╡ 479f80e3-8ab6-4f3d-bd47-a18f4671dfa9
md"Choose a fuel cell area for your aircraft, and observe the effect on fuel cell length and efficiency $η$ at max power:"

# ╔═╡ e81ab1c3-228c-4a32-9275-43d5f9b134db
md"""Calculate the cell current density $j$ (A/cm²) for the cell under max power.
Note:
- *j* must be lower than the previously-defined limiting current density *j_L*
- A real solution only exists for $b^2 - 4ac >= 0$, where:
  -  $a$ is the gradient of the linear fit of the polarization curve,
  -  $b$ is the y-intercept, and
  -  $c = P_{max}/A$
"""

# ╔═╡ 429db1e1-071f-41de-a02f-7d0297353928
md"""Generate eta, m_dot versus Area plots (temporary)"""

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
S_wet = (wetted_area(wing_mesh) + wetted_area(fuse, 0:0.1:1) + wetted_area(htail_mesh) + wetted_area(vtail_mesh)) # Approximate wetted area calculated from fuselage and flight surfaces. Doesn't account for intersection of surfaces and fuselage, nor does it account for engine nacelles

# ╔═╡ 24bc5967-b0ea-4081-b3de-d4c362670787
A_wetted = aspect_ratio(wing)/(S_wet/S_ref) # AR / (S_wet / S_ref)

# ╔═╡ 0a750cbd-0842-42d4-9a00-99c4c69672fc
LD_max = K_LD * sqrt(A_wetted) # Raymer

# ╔═╡ 34d83139-a0ce-4712-a884-a3c53a2df098
W3_W0 = exp((-2000e3 * 9.81 * psfc(200., 1.e6))/(η_prop * LD_max)); # Cruise 2000 km

# ╔═╡ 50ebd56c-b6bc-4a0a-ad97-f9b8e94ac8bf
W6_W0 = exp((-400e3 * 9.81 * psfc(200., 1.e6))/(η_prop * LD_max)); # Diversion 400 km

# ╔═╡ e3a6b351-3d6d-4707-9bd2-b36a2a6cab41
W7_W0 = exp(((-2700*V_cruise) * 9.81 * psfc(200., 1.e6))/(η_prop * LD_max)); # 45 min at cruise speed

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

# ╔═╡ 25f5ce08-02dc-4d9d-ae61-ae83f4c1dd13
Wf_W0 = 1.06 * (1 - Wi_W0) # 1.06 factor from Raymer

# ╔═╡ 16996cd1-b98a-4ab7-9674-e45b8548eda7
begin
	tol = 0.1;
	global W0_prev = 0.0;
	global curstep = 0;
	max_step = 10000;

	global We_base = 17819. - 2*718.; # Mass of base Dash 8 Q400 without engines

	P_cabin = 38251.; # Cabin pressure, in Pa
	
	# Initial guesses
	global W0 = [W0_base]; # Based on Dash 8 Q400 MTOW
	global Wmot_hist = [];
	global Wfc_hist = [];
	global Wf_hist = [];
	global Wft_hist = [];
	global Wcrew_hist = [];
	global Wpayload_hist = [];
	global Wfurnishinglost_hist = []


	# !=========================== START OF LOOP ================================!
	while abs(W0[end] - W0_prev) > tol
		global curstep += 1;
		if curstep >= max_step
			print("Failed to iterate within max_step")
			push!(W0, -1.0)
			break
		end
		global W0_prev = W0[end];

		# !====================== CONSTRAINT DIAGRAMS ============================!
		# Use constraint diagrams to estimate total power required
		
		# This will assume that the wing loading is within the stall and landing limits. Recalculate the constraints after the final iteration to verify this.
		
		global WS_req = W0_prev * 9.81 / S_ref;
		global PW_max = 0.;

		local PW_TO50 = PW_50ftTakeoff(WS_req;
			 TODA_min = L_rwy / 1.15,
			 σ = σ_TO_LDG,
			 CL_TO = CL_TO
		);

		PW_max = max(PW_max, PW_TO50)

		local PW_TO_BFL = PW_BFLTakeoff(WS_req;
			 N_E = N_E,
			 TODA_min = L_rwy,
			 σ = σ_TO_LDG,
			 CL_TO = CL_TO
	    );

		PW_max = max(PW_max, PW_TO_BFL)	

		local PW_climb1 = PW_Climb(WS_req;
			 α = W1_W0 * W2_W0,
			 β = 1.,
			 V = TAS(h_cruise, V_cl),
			 G = G_cl, # Climb gradient
			 ρ = ρ_cr
			);

		PW_max = max(PW_max, PW_climb1)

		local PW_cl_oei_gear = PW_Climb(WS_req;
		     # OEI climb with gear, 0.5%. Assume one engine available results in 60%
		     # thrust, as often max power > continuous power.
			 α = W1_W0,
			 β = β_OEI,
			 V = V_cl, # Assume sea level
			 G = 0.005, # Regulatory requirement
			 ρ = ρ_gnd,
			 η_prop = η_prop,
			 CD_0 = CD0_TO,
			 AR = AR,
			 e = e_TO
			 );

		PW_max = max(PW_max, PW_cl_oei_gear)

		local PW_cl_oei = PW_Climb(WS_req;
			# OEI climb without gear, 3%. Assume one engine available results in 60%
			# thrust, as often max power > continuous power.
			α = W1_W0,
			β = β_OEI,
			V = V_cl,
			G = 0.03, # Regulatory requirement
			ρ = ρ_gnd,
			η_prop = η_prop,
			CD_0 = CD_0,
			AR = AR,
			e = e
			);

		PW_max = max(PW_max, PW_cl_oei)

		local PW_cr = PW_Cruise(WS_req;
			 # Cruise at 7500 m
			 α = W1_W0 * W2_W0, # Most constraining weight expected to be same as top of climb 1
			 β = 1.,
			 V = TAS(h_cruise, V_cruise),
			 η_prop = η_prop,
			 ρ = ρ_cr,
			 CD_0 = CD_0,
			 AR = AR,
			 e = e
		 	);

		PW_max = max(PW_max, PW_cr)

		global P_tot = PW_max * W0_prev * 9.81;

		# !=======================================================================!

		global concept_tank = CryogenicFuelTank(
			radius=fuse.radius - fuse_t_w,
			length=volume_to_length(Wf_W0 * W0[end] / ρ_LH2, fuse.radius - fuse_t_w, t_insulation),
			insulation_thickness=t_w_weightloop,
			insulation_density=35.3
		)

		global Wf = Wf_W0 * W0[end];
		push!(Wf_hist, Wf_W0 * W0[end]); # Store each fuel mass

		global n_passengers = n_basepassengers - 4 * Int(ceil(concept_tank.length/0.762));

		# Add estimated power for air conditioning, hydraulic pumps, avionics, etc to total power required
		global P_misc = P_Misc(n_passengers);
		global P_tot += P_misc;

		local minA = - 4 * polarization_coeffs[1] * P_tot / polarization_coeffs[2]^2 / 10000;
		
		global concept_fc = PEMFCStack(
			area_effective=A_FC_factor * minA,
			power_max = P_tot,
			height=2*(fuse.radius - fuse_t_w),
			width=2*(fuse.radius - fuse_t_w)
		)
		
		
		W_crew = crew_weight(2, n_passengers);		
		global n_cc = n_cabincrew(n_passengers);
		W_payload = n_passengers * (84 + 23);

		push!(Wcrew_hist, W_crew); # Store each crew and payload mass
		push!(Wpayload_hist, W_payload);

		global We = We_base;

		global drymass = dry_mass(concept_tank)
		We += drymass; # Tank mass
		push!(Wft_hist, drymass); # Store each tank mass
		
		We += mass(concept_fc); # FC mass
		push!(Wfc_hist, mass(concept_fc)); # Store each FC mass
		
		We += motor_mass(P_tot, Current); # Motor mass
		push!(Wmot_hist, motor_mass(P_tot, Current)); # Store each motor mass

		local furnishingslost = -furnishings_weight(2, n_basepassengers, 2, p_air(h_cruise), W0_base, ShortHaul, Short) + furnishings_weight(2, n_passengers, n_cc, p_air(h_cruise), W0[end], ShortHaul, Short);
		
		We += furnishingslost;
		push!(Wfurnishinglost_hist, furnishingslost)
		
		W0_new = (W_crew + W_payload + We) / (1 - Wf_W0)
		push!(W0, W0_new)
	end
end

# ╔═╡ 60912178-17b6-42d8-971d-17184aa1d8d9
P_tot

# ╔═╡ 913db9f9-850b-4fe9-b4c5-1c872fc7ebf9
W0[end]

# ╔═╡ 8c38ccc1-fbc6-4531-89fb-a10b11805433
Wf

# ╔═╡ 6c8ed38b-1b05-41ca-92f9-760501184e58
n_passengers

# ╔═╡ 72ba560b-198f-457a-ba1e-3ddb3628864a
Vf = Wf / ρ_LH2

# ╔═╡ 852baaab-ce24-48cc-8393-1a8ee7554874
begin
	W0plot = plot(
		1:curstep+1,
		W0,
		label = "W₀",
		xlabel = "Step",
		ylabel = "Weight (kg)",
		marker = :x,
		lw=2
	)
	
	plot!(
		1:curstep+1,
		fill(We_base, curstep+1),
		label = "Dash 8 base weight",
		xlims = (1, 7),
		ylims = (-2500, 30000) ,
		minorgrid = true,
		marker = :x,
		lw=2
	)

	plot!(
		2:curstep+1,
		Wcrew_hist + Wpayload_hist,
		label = "Crew + payload",
		marker = :x,
		lw=2
	)
	[We_base, We_base]
	plot!(
		2:curstep+1,
		Wmot_hist + Wfc_hist,
		label = "Motor + fuel cell",
		marker = :x,
		lw=2
	)

	plot!(
		2:curstep+1,
		Wf_hist + Wft_hist,
		label = "Fuel + fuel tank",
		marker = :x,
		lw=2
	)

	plot!(
		2:curstep+1,
		Wfurnishinglost_hist,
		label = "Furnishings lost",
		marker = :x,
		lw=2,
		size = (800, 500)
	)
end

# ╔═╡ 8ce1c30e-b602-4411-b671-1cc5f267e646
We

# ╔═╡ 94eaf8be-b197-4606-9908-bc8317b1c6d0
begin
	# Curves
	plot(
		W_S,
		[PW_TO50 PW_TO_BFL PW_climb1 PW_cl_oei_gear PW_cl_oei PW_cr],
		label = ["Take-off: 50ft obstacle" "Take-off: BFL" "6.0% Top of Climb 1" "0.5% Climb, Gear Down, OEI" "3.0% Climb, OEI" "Cruise"],
		xlabel = "Wing Loading (W₀/S) (N/m²)",
		ylabel = "Power Loading (P/W)₀ (W/N)",
		xlims = (0, 10000),
		ylims = (0, 100)
	);

	# Vertical lines
	plot!(
		[[WS_ldg; WS_ldg] [WS_stall; WS_stall]],
		[0; 100],
		label = ["Landing 1500 m" "Stall"]
	);

	plot!(
		[30481 * 9.81 / S_ref],
		[3781 * 1000 * 2 / (30481 * 9.81)],
		label = "Dash 8 Q400 Design Point",
		marker = :circle
	)

	plot!(
		[[WS_req; WS_req]],
		[0; 100],
		label = "Wing loading required for unmodified wing",
		color = :gray,
		line = :dashdot
	)

	plot!(
		[WS_req],
		[PW_max],
		label = "Fuel Cell Dash 8 Q400 Design Point",
		marker = :star,
		size = (800, 600)
	)
end

# ╔═╡ 87b0e21b-c75d-4b81-a7b8-34012ac92de7
begin
	global segment_t = []; # Cumulative sum of time, given after each segment. Assumed zero for take-off
	global segment_burn = []; # Cumulative sum of fuel burnt, given after each segment. Follow Raymer assumption for take-off.
	global E_used = []; # Energy use at each timestep
	
	global resolution = 1; # Duration of each step, seconds
	global h = 0.; # Current height
	global t = 0; # Current time
	global m_burnt = 0.; # Current mass of fuel burnt
	global dist = 0.; # Current distance travelled

	# !========================= START UP / T-O ==============================!
	# Assume 60 mins of boil-off on ground at 30 degrees C
	dm = boil_off(concept_tank, 9.6e-3, 150, 303, 20);
	m_burnt += dm * 60 * 60;
	push!(segment_burn, m_burnt);

	# Standard start up / T-O
	m_burnt = W0[end] * (1 - W1_W0);
	push!(segment_burn, m_burnt);

	# !============================== CLIMB 1 ================================!
	
	while h < h_cruise
		global t += resolution;
	
		# Find climb rate, altitude
		global V_TAS = TAS(h, V_cl)
	
		global V_vert = V_TAS * sin(G_cl * pi / 2)
		

		# Power requirements
		P_prop = (W0[end] - m_burnt) * 9.81 * PW_Climb(WS_req;
				     α = (W0[end] - m_burnt) / W0[end],
					 β = 1.,
					 V = TAS(h, V_cl),
					 G = G_cl, # Climb gradient
					 ρ = ρ_air(h)
					);

		global P = P_prop + P_misc;
		push!(E_used, P * resolution)

		# Mass flow rate of Hydrogen required
		dm = fflow_H2(concept_fc, P/P_tot); # Mass of fuel burnt in the second
		dm = max(dm, boil_off(concept_tank)); # Use boil-off rate if higher

		global m_burnt += dm * resolution;
		
		global h += V_vert * resolution;
	end

	push!(segment_t, t);
	push!(segment_burn, m_burnt);

	# !=========================== CRUISE 1 ==================================!

	while dist < 2000e3
		global t += resolution;
	
		global V_TAS = TAS(h, V_cruise)		

		# Power requirements
		P_prop = (W0[end] - m_burnt) * 9.81 * PW_Cruise(WS_req;
			 # Cruise at 7500 m
			 α = (W0[end] - m_burnt) / W0[end],
			 β = 1.,
			 V = V_TAS,
			 η_prop = η_prop,
			 ρ = ρ_cr,
			 CD_0 = CD_0,
			 AR = AR,
			 e = e
		 	);

		global P = P_prop + P_misc;
		push!(E_used, P * resolution);

		# Mass flow rate of Hydrogen required
		dm = fflow_H2(concept_fc, P/P_tot); # Mass of fuel burnt in the second
		dm = max(dm, boil_off(concept_tank)); # Use boil-off rate if higher

		global m_burnt += resolution * dm;
		global dist += resolution * V_TAS;
	
	end

	push!(segment_t, t);
	push!(segment_burn, m_burnt);

	# !========================== DESCENT 1 ==================================!

	local descenttime = 15 * 60
	while t < (segment_t[end] + descenttime)
		# Assume no propulsive power requirement, just systems
		global P = P_misc;
		push!(E_used, P * resolution);

		# Mass flow rate of hydrogen required
		dm = fflow_H2(concept_fc, P/P_tot); # Mass of fuel burnt during \Delta t
		dm = max(dm, boil_off(concept_tank));

		global m_burnt += resolution * dm;
		global t += resolution;
	end

	push!(segment_t, t);
	push!(segment_burn, m_burnt);

	# !========================== LAND 1 =====================================!

	push!(segment_t, t);
	m_burnt += (1 - W4_W0) * W0[end]
	push!(segment_burn, m_burnt);

	# !========================== CLIMB 2 ====================================!

	global h = 0;

	while h < h_cruise
		global t += resolution;
	
		# Find climb rate, altitude
		global V_TAS = TAS(h, V_cl)
	
		global V_vert = V_TAS * sin(G_cl * pi / 2)
		

		# Power requirements
		P_prop = (W0[end] - m_burnt) * 9.81 * PW_Climb(WS_req;
				     α = (W0[end] - m_burnt) / W0[end],
					 β = 1.,
					 V = TAS(h, V_cl),
					 G = G_cl, # Climb gradient
					 ρ = ρ_air(h)
					);

		global P = P_prop + P_misc;
		push!(E_used, P * resolution)

		# Mass flow rate of Hydrogen required
		dm = fflow_H2(concept_fc, P/P_tot); # Mass of fuel burnt in the second
		dm = max(dm, boil_off(concept_tank)); # Use boil-off rate if higher

		global m_burnt += dm * resolution;
		
		global h += V_vert * resolution;
	end

	push!(segment_t, t);
	push!(segment_burn, m_burnt);

	# !========================== CRUISE 2 ===================================!

	global dist = 0;

	while dist < 400e3
		global t += resolution;
	
		global V_TAS = TAS(h, V_cruise)		

		# Power requirements
		P_prop = (W0[end] - m_burnt) * 9.81 * PW_Cruise(WS_req;
			 # Cruise at 7500 m
			 α = (W0[end] - m_burnt) / W0[end],
			 β = 1.,
			 V = V_TAS,
			 η_prop = η_prop,
			 ρ = ρ_cr,
			 CD_0 = CD_0,
			 AR = AR,
			 e = e
		 	);

		global P = P_prop + P_misc;
		push!(E_used, P * resolution);

		# Mass flow rate of Hydrogen required
		dm = fflow_H2(concept_fc, P/P_tot); # Mass of fuel burnt in the second
		dm = max(dm, boil_off(concept_tank)); # Use boil-off rate if higher

		global m_burnt += resolution * dm;
		global dist += resolution * V_TAS;
	
	end

	push!(segment_t, t);
	push!(segment_burn, m_burnt);

	# !========================== DESCENT 2 ==================================!

	local descenttime = 7.5 * 30
	while t < (segment_t[end] + descenttime)
		# Assume no propulsive power requirement, just systems
		global P = P_misc;
		push!(E_used, P * resolution);

		# Mass flow rate of hydrogen required
		dm = fflow_H2(concept_fc, P/P_tot); # Mass of fuel burnt during \Delta t
		dm = max(dm, boil_off(concept_tank));

		global m_burnt += resolution * dm;
		global t += resolution;
	end

	push!(segment_t, t);
	push!(segment_burn, m_burnt);
	

	# !========================== LOITER =====================================!

	# 45 minute flight at cruise speed
	# assume cruise level
	h = h_cruise/2;
	global t_loiter = 0;

	while t_loiter < 45 * 60 # 45 min loiter
		global t += resolution;
		global t_loiter += resolution;
	
		global V_TAS = TAS(h, V_cruise)		

		# Power requirements
		P_prop = (W0[end] - m_burnt) * 9.81 * PW_Cruise(WS_req;
			 # Cruise at 0 m
			 α = (W0[end] - m_burnt) / W0[end],
			 β = 1.,
			 V = V_TAS,
			 η_prop = η_prop,
			 ρ = ρ_cr,
			 CD_0 = CD_0,
			 AR = AR,
			 e = e
		 	);

		global P = P_prop + P_misc;
		push!(E_used, P * resolution);

		# Mass flow rate of Hydrogen required
		dm = fflow_H2(concept_fc, P/P_tot); # Mass of fuel burnt in a second
		dm = max(dm, boil_off(concept_tank)); # Use boil-off rate if higher

		global m_burnt += resolution * dm;
	
	end

	push!(segment_t, t);
	push!(segment_burn, m_burnt);

	# !========================== DESCENT 2 ==================================!

	local descenttime = 7.5 * 60
	while t < (segment_t[end] + descenttime)
		# Assume no propulsive power requirement, just systems
		global P = P_misc;
		push!(E_used, P * resolution);

		# Mass flow rate of hydrogen required
		dm = fflow_H2(concept_fc, P/P_tot); # Mass of fuel burnt during \Delta t
		dm = max(dm, boil_off(concept_tank));

		global m_burnt += resolution * dm;
		global t += resolution;
	end

	push!(segment_t, t);
	push!(segment_burn, m_burnt);

	# !========================== LAND 2 =====================================!

	push!(segment_t, t);
	m_burnt += (1 - W4_W0) * W0[end]
	push!(segment_burn, m_burnt);
	
end

# ╔═╡ dd05da5f-b206-41a8-88c7-ebfde1a871ef
segment_burn[end]

# ╔═╡ 26d249ff-9ac0-4559-9f43-4321429217a3
plot(1:resolution:t, E_used / resolution,
	xlabel = "Time (seconds)",
	ylabel = "Power consumption (W)",
	ylims = (0, 10e6)
)

# ╔═╡ 224e8310-30ac-4be9-9831-bcc1a41f48ff
segment_t

# ╔═╡ 20388f96-d158-46b3-b62e-80915e77f20b
segment_burn

# ╔═╡ e5269547-4785-4239-97ee-88c2fa3a0f9f
Vf_post_sim = segment_burn[end] / ρ_LH2 * 1.06

# ╔═╡ 9d1c4841-09fc-4d3a-9229-79bf9addba01
print("New Wf_W0: ", segment_burn[end] / W0[end])

# ╔═╡ e2457cb1-8718-4175-b7a2-e5ad6e864a43
P_max = P_tot # Maximum power needed by the aircraft (W)

# ╔═╡ 4e23f46e-9253-4b3b-92fa-1efe7049899a
A_min = - 4 * polarization_coeffs[1] * P_max / polarization_coeffs[2]^2 / 10000;

# ╔═╡ 45f95a01-b50d-4f11-bc5c-412968c16dee
print("Minimum fuel cell area required for a real 'i': " * string(round(A_min, digits=1)) * " m^2");

# ╔═╡ cbeacb6e-f1ae-4152-aef5-426908cb5f6e
order_A = floor(Int, log10(A_min));

# ╔═╡ 040809ae-69cf-4445-8a6c-82c404b7dabd
@bind A_eff Slider(A_min*1.1:10^(order_A-0.5):5*A_min, default=A_min*1.2)

# ╔═╡ ec53c66a-9f14-4520-8d28-2f53a54bb447
print("Fuel cell area: " * string(round(A_eff, digits=0)) * " m^2")

# ╔═╡ e2848f51-2145-4d37-a2c3-d73a67cd525d
Areas = LinRange(A_min*1.1, 2000, 20);

# ╔═╡ eea50a16-6798-4b53-8c36-ec647b592b23
PEMFC = PEMFCStack(
	area_effective=A_eff,
	power_max = P_max,
	height = 2.,
	width = 2.,
	layer_thickness=0.0043,
	position = [0., 0., 0.]
)

# ╔═╡ df7431fe-dcde-4456-a548-1ffafccb84b8
j_PEMFC = j_cell(PEMFC, 1, polarization_coeffs) # Cell current density at full power (A/cm^2)

# ╔═╡ e9ffaaed-b8b3-4825-8bb2-30a848a17abc
U_PEMFC = U_cell(j_PEMFC, polarization_coeffs); # Cell potential difference (V)

# ╔═╡ c6b9ea47-0dc5-42b9-a0b1-ff4158102d49
η_PEMFC = η_FC(U_PEMFC) # Fuel cell stack efficiency at full power (w.r.t HHV)

# ╔═╡ 6895ed8b-acf4-4941-ada7-38ab54d77870
mdot_H2 = fflow_H2(PEMFC, 1., polarization_coeffs) # Hydrogen mass flow rate in at full power (kg/s)

# ╔═╡ 1d624369-c08a-4c65-8ac4-46e8605cf905
PEMFC_length = length(PEMFC) # Fuel cell length (m)

# ╔═╡ 5270c8d4-4703-423b-89a5-805679a374ae
PEMFC_mass = mass(PEMFC) # Fuel cell mass (kg)

# ╔═╡ 448e3477-6be6-41fb-8794-cd95c9ea56db
begin
	eta_climbpower = zeros(size(Areas));
	eta_cruisepower = zeros(size(Areas));

	mdot_climbpower = zeros(size(Areas));
	mdot_cruisepower = zeros(size(Areas));

	length_fullpower = zeros(size(Areas));

	mass_fullpower = zeros(size(Areas));

	local PW_begclimb1 = PW_Climb(WS_req;
			 α = W1_W0,
			 β = 1.,
			 V = TAS(0, V_cl),
			 G = G_cl, # Climb gradient
			 ρ = ρ_cr
			);

	local PW_cr = PW_Cruise(WS_req;
			 # Cruise at 7500 m
			 α = W1_W0 * W2_W0, # Most constraining weight expected to be same as top of climb 1
			 β = 1.,
			 V = TAS(h_cruise, V_cruise),
			 η_prop = η_prop,
			 ρ = ρ_cr,
			 CD_0 = CD_0,
			 AR = AR,
			 e = e
		 	);
	
	global climb_throttle = ((PW_begclimb1 * W0[end] * 9.8) + P_misc) / P_max;
	global cruise_throttle = ((PW_cr * W0[end] * 9.8) + P_misc) / P_max;
	
	for i in 1:length(Areas)
		PEMFC_AreaStudy = PEMFCStack(
			area_effective=Areas[i],
			power_max = P_max,
			height = 2.,
			width = 2.,
			layer_thickness=0.0043,
			position = [0., 0., 0.]
		)

		eta_climbpower[i] = η_FC(PEMFC_AreaStudy, climb_throttle);
		eta_cruisepower[i] = η_FC(PEMFC_AreaStudy, cruise_throttle);

		mdot_climbpower[i] = fflow_H2(PEMFC_AreaStudy, climb_throttle);
		mdot_cruisepower[i] = fflow_H2(PEMFC_AreaStudy, cruise_throttle);

		length_fullpower[i] = length(PEMFC_AreaStudy);
		mass_fullpower[i] = mass(PEMFC_AreaStudy);
	end
end

# ╔═╡ 52f0d3d0-8fd0-44dc-8991-0f0244572a03
climb_throttle

# ╔═╡ 6a9c0657-f496-4efb-8113-b4a2b89604fe
cruise_throttle

# ╔═╡ 92e4aa80-c9fd-4aa0-940a-7ca4765141f5
begin
	plot(
		Areas, eta_cruisepower,
		label = "Cruise power",
		lw = 3.,
		ylabel = "Fuel Cell Efficiency",
		xlabel = "Fuel Cell Area (m²)",
		#title = "Fuel cell efficiency versus effective area",
		ylims = (0., 1.0),
		xlims = (800, 2000),
		size = (600, 400),
		grid = true
	);
	plot!(
		Areas, eta_climbpower,
		label = "Start of climb power",
		lw = 3.,
	);
	plot!(
		[Areas[1], Areas[1]], [0., 1.],
		color = :black,
		linestyle = :dash,
		label = "Minimum viable area"
	)
end

# ╔═╡ 373a8b16-b3a2-4cfb-ae50-bc9962a6cbe5
begin
	plot(
		mass_fullpower, mdot_cruisepower,
		label = "Cruise power",
		lw = 3.,
		ylabel = "H₂ mass flow rate (kg/s)",
		xlabel = "Fuel cell mass (kg)",
		#title = "Hydrogen fuel flow rate versus PEMFC mass",
		xlims = (2000, 5000),
		ylims = (0.0, 0.15),
		size = (600, 400),
	);
	plot!(
		mass_fullpower, mdot_climbpower,
		label = "Start of climb power",
		lw = 3.,
	);
	plot!(
		[mass_fullpower[1], mass_fullpower[1]], [0., 0.15],
		color = :black,
		linestyle = :dash,
		label = "Minimum viable area"
	)
end

# ╔═╡ 5bfe15dd-29db-4a48-af6f-f8a04bb495e7
begin
	plot(
		Areas, length_fullpower*2*2,
		lw = 3.,
		ylabel = "Fuel Cell Volume (m³)",
		xlabel = "Fuel Cell Area (m²)",
		#title = "Fuel cell volume versus effective area",
		xlims = (600, 2000),
		ylims = (3, 10),
		label = "FC volume",
		size = (600, 300)
	);
	plot!(
		[Areas[1], Areas[1]], [0, 10],
		color = :black,
		linestyle = :dash,
		label = "Minimum viable area"
	)
end

# ╔═╡ ef8669ca-1897-4397-ae00-3da40b64b487
begin
	plot(
		Areas, mass_fullpower,
		lw = 3.,
		ylabel = "Fuel Cell Mass (kg)",
		xlabel = "Fuel Cell Area (m²)",
		#title = "Fuel cell mass versus effective area",
		xlims = (600, 2000),
		ylims = (1000, 5000),
		label = "FC mass",
		size = (600, 300)
	);

	plot!(
		[Areas[1], Areas[1]], [0, 5000],
		color = :black,
		linestyle = :dash,
		label = "Minimum viable area"
	)
end

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
			length = volume_to_length(Wf_W0 * W0[end] / ρ_LH2, fuse.radius - fuse_t_w, v),
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
	boiloffplot = plot(
		100 * t_w,
		360 * M,
		xlabel = "Insulation thickness (cm)",
		ylabel = "Mass boil-off (kg /hr)",
		legend = false,
		lw = 3,
		ylims = (0, 70)
	);

	volboioloffplot = plot(
		100 * t_w,
		360 * M / ρ_LH2,
		xlabel = "Insulation thickness (cm)",
		ylabel = "Volume boil-off (m³ /hr)",
		legend = false,
		lw = 3,
		ylims = (0., 1.)
	);

	Tsplot = plot(
		100 * t_w,
		T_s,
		xlabel = "Insulation thickness (cm)",
		ylabel = "Tank surface temperature (K)",
		label = "Theoretical value",
		lw = 3,
		ylims = (220., 300.)
	)
	
	plot!([0; 20], [T∞; T∞], linestyle = :dash, linecolor = :gray, linewidth = 2, label = "T∞")

	plot(boiloffplot, volboioloffplot, Tsplot, layout = @layout [a; b; c])
end

# ╔═╡ bffea698-1450-4cac-96fc-717ba609a5c1
# ╠═╡ disabled = true
#=╠═╡
boiloffplt = plot(
	100 * t_w,
	360 * M,
	title = "Mass boil-off rate versus insulation thickness",
	xlabel = "Insulation thickness (cm)",
	ylabel = "Mass boil-off (kg /hr)",
	legend = false,
	xlims = (0., 20.),
	size = (1000, 400)
)
  ╠═╡ =#

# ╔═╡ 7081ef25-8769-4a62-be19-c87168ac9135
# ╠═╡ disabled = true
#=╠═╡
volboioloffplt = plot(
	100 * t_w,
	360 * M / ρ_LH2,
	title = "Volume boil-off rate versus insulation thickness",
	xlabel = "Insulation thickness (cm)",
	ylabel = "Volume boil-off (m³ /hr)",
	legend = false
)
  ╠═╡ =#

# ╔═╡ 66c1cc45-913d-44f8-bf55-dc4a47d5dca6
# ╠═╡ disabled = true
#=╠═╡
begin
	Tsplt = plot(
		100 * t_w,
		T_s,
		title = "Tank surface temperature versus insulation thickness",
		xlabel = "Insulation thickness (cm)",
		ylabel = "Tank surface temperature (K)",
		label = "Theoretical value"
	);
	plot!([0; 20], [T∞; T∞], linestyle = :dash, linecolor = :gray, linewidth = 1, label = "T∞")
end
  ╠═╡ =#

# ╔═╡ 82b332ac-5628-4b82-8735-f361dcdfc9b6
tank = CryogenicFuelTank(
	radius = fuse.radius - fuse_t_w,
	length = volume_to_length(Wf_W0 * W0[end] / ρ_LH2, fuse.radius - fuse_t_w, t_insulation),
	insulation_thickness = t_insulation,
	insulation_density = insulation_material.Density,
	position = [0.5fuse.length, 0, 0]
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
		grid = false
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
# ╠═b4a9024c-2c1e-4291-95c1-b9560ff94b6d
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
# ╠═bae8f6a4-a130-4c02-8dd4-1b7fc78fb104
# ╠═e44e5781-c689-463e-b0d3-1d4a434c287a
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
# ╠═e3a6b351-3d6d-4707-9bd2-b36a2a6cab41
# ╠═17a2f25a-964a-4a73-996a-a18484f82add
# ╠═e00ea2c0-dee4-43e1-ab9d-6c8de1e0c2aa
# ╠═22a540fa-0659-4eb9-9d73-fb9516e5f715
# ╠═57fd1ec3-14be-4b64-8de7-c0f448df630d
# ╟─a2eca0b9-730c-4be0-9e7e-d10d9f7ca664
# ╟─d037c253-032a-4a83-a246-5920cd8e57be
# ╠═88b272f9-ad2c-4aab-b784-6907dc87ea2d
# ╠═cff8b71d-1870-486f-ad06-732813265742
# ╠═91f05db8-972e-435e-aaf7-a207047e27e8
# ╠═4b738106-128e-4399-8edb-2c1b6e2a5512
# ╠═005399ec-fc82-445f-92a5-7172c2b4722d
# ╠═6881d47f-4fc6-4885-9e6c-ebbcbca31005
# ╠═7ba1e469-9442-462d-8164-0552000e1cb7
# ╠═c685a7e8-1cfd-4703-830f-9e4c78b19d8d
# ╠═f668c250-e709-44e8-b8b2-4bf7a43a0f3d
# ╠═fcc34f42-2b64-4c4f-8b91-b5f95ddadfd0
# ╟─8af17db4-6710-4e4d-8384-e3768d43e609
# ╠═13be94f1-bfc7-44a0-9985-0a3783cd8265
# ╟─e58f446a-88fe-430a-9598-d5bf2dc931ee
# ╠═25f5ce08-02dc-4d9d-ae61-ae83f4c1dd13
# ╠═16996cd1-b98a-4ab7-9674-e45b8548eda7
# ╠═d7aebf1e-df3e-42ab-82ed-2080d552722b
# ╠═d5181a37-7a4a-4c34-a9db-de83af11112c
# ╠═60912178-17b6-42d8-971d-17184aa1d8d9
# ╠═913db9f9-850b-4fe9-b4c5-1c872fc7ebf9
# ╠═dd05da5f-b206-41a8-88c7-ebfde1a871ef
# ╠═8c38ccc1-fbc6-4531-89fb-a10b11805433
# ╠═6c8ed38b-1b05-41ca-92f9-760501184e58
# ╠═72ba560b-198f-457a-ba1e-3ddb3628864a
# ╟─852baaab-ce24-48cc-8393-1a8ee7554874
# ╠═8ce1c30e-b602-4411-b671-1cc5f267e646
# ╟─a77fce1f-0574-4666-ba3b-631716384ae0
# ╠═cea3ed96-73aa-44ee-bdc5-2becba65987f
# ╠═b50bf2eb-3bbb-4ce8-b0af-063d69bbeb26
# ╠═1d60645e-6d85-4f14-8554-6a0383fe92ea
# ╠═aae8d9a3-aa33-4467-adbd-6a639221fbf5
# ╠═4c948bb0-7399-4e0f-a9aa-c239aec74566
# ╠═29a1727c-6eea-4bf3-89c3-789ef8a4f7ac
# ╠═8b62eee7-6a6f-43d9-b0f2-e4e48d156a45
# ╠═6a90d93d-246e-46e8-aab8-b604de989823
# ╠═9bf58181-6a29-4587-bec5-cf5999d0ca32
# ╠═bf75995b-317b-4ade-a46a-51ed947240c3
# ╠═94eaf8be-b197-4606-9908-bc8317b1c6d0
# ╟─848a3f87-f942-4691-832a-fe1883129e3d
# ╠═87b0e21b-c75d-4b81-a7b8-34012ac92de7
# ╠═26d249ff-9ac0-4559-9f43-4321429217a3
# ╠═224e8310-30ac-4be9-9831-bcc1a41f48ff
# ╠═20388f96-d158-46b3-b62e-80915e77f20b
# ╟─9d1c4841-09fc-4d3a-9229-79bf9addba01
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
# ╟─bffea698-1450-4cac-96fc-717ba609a5c1
# ╟─7081ef25-8769-4a62-be19-c87168ac9135
# ╟─66c1cc45-913d-44f8-bf55-dc4a47d5dca6
# ╟─25b42e5d-2053-4687-bc8a-a5a145c42e53
# ╠═e5269547-4785-4239-97ee-88c2fa3a0f9f
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
# ╟─4e23f46e-9253-4b3b-92fa-1efe7049899a
# ╟─45f95a01-b50d-4f11-bc5c-412968c16dee
# ╟─cbeacb6e-f1ae-4152-aef5-426908cb5f6e
# ╟─479f80e3-8ab6-4f3d-bd47-a18f4671dfa9
# ╟─040809ae-69cf-4445-8a6c-82c404b7dabd
# ╟─ec53c66a-9f14-4520-8d28-2f53a54bb447
# ╠═eea50a16-6798-4b53-8c36-ec647b592b23
# ╟─e81ab1c3-228c-4a32-9275-43d5f9b134db
# ╠═df7431fe-dcde-4456-a548-1ffafccb84b8
# ╠═e9ffaaed-b8b3-4825-8bb2-30a848a17abc
# ╠═c6b9ea47-0dc5-42b9-a0b1-ff4158102d49
# ╠═6895ed8b-acf4-4941-ada7-38ab54d77870
# ╠═1d624369-c08a-4c65-8ac4-46e8605cf905
# ╠═5270c8d4-4703-423b-89a5-805679a374ae
# ╟─429db1e1-071f-41de-a02f-7d0297353928
# ╠═e2848f51-2145-4d37-a2c3-d73a67cd525d
# ╠═448e3477-6be6-41fb-8794-cd95c9ea56db
# ╠═52f0d3d0-8fd0-44dc-8991-0f0244572a03
# ╠═6a9c0657-f496-4efb-8113-b4a2b89604fe
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
