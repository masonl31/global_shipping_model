using JuMP
using GLPK

#customise years of model
include("Years.jl")
Y= length(Years)

#includes types of ships
include("ship_types.jl")
S=length(Ship_types)

#Data

Fuels = ["HFO" "LNG" "LSFO" "Methanol" "Biodiesel" "Ammonia" "Electricity" "Liquifiedmethane" "Hydrogen"]


Ship_types = ["oiltanker" "bulkcarrier" "generalcargo" "containership" "other"]
T = length(Ship_types)

#emission limits
include("emission_limit.jl")

#shipping demands by type
include("shipping_demands.jl")


existing_fleet =
#"MDO_D" "MDO_C" "MDO_T" "LNG_D" "LNG_C" "LNG_T" "AMM_D" "AMM_C" "AMM_T" "MET_D" "MET_C" "MET_T"
[
#4        7       5       2       1       1       0       0       0       0       0       0
0        0       0       0       0       0       0       0       0       0       0       0
]

ship_inv =
#"MDO_D" "MDO_C" "MDO_T" "LNG_D" "LNG_C" "LNG_T" "AMM_D" "AMM_C" "AMM_T" "MET_D" "MET_C" "MET_T"
[
4       7       5       2       8       3       5       1       7       4       1       2   #inv costs
]

ship_var =
#"MDO_D" "MDO_C" "MDO_T" "LNG_D" "LNG_C" "LNG_T" "AMM_D" "AMM_C" "AMM_T" "MET_D" "MET_C" "MET_T"
[
1        2       4       8       2       8       2       7       6       1       2       3   #var costs
]

#=
ship_life =
#"MDO_D" "MDO_C" "MDO_T" "LNG_D" "LNG_C" "LNG_T" "AMM_D" "AMM_C" "AMM_T" "MET_D" "MET_C" "MET_T"
[
20      20      10      20      15      25      20      25      10      10      20      25  #lifetime
]
=#


ship_emissions =
#"MDO_D" "MDO_C" "MDO_T" "LNG_D" "LNG_C" "LNG_T" "AMM_D" "AMM_C" "AMM_T" "MET_D" "MET_C" "MET_T"
[
5        5       5       4       4       4       0       0       0       2       2       2
] #emissions/GJ


ship_eff =
#"MDO_D" "MDO_C" "MDO_T" "LNG_D" "LNG_C" "LNG_T" "AMM_D" "AMM_C" "AMM_T" "MET_D" "MET_C" "MET_T"
[
5        5       5       4       4       4       1       1       1       2       2       2
#1        2       4       8       2       8       2       7       6       1       2       3   #var costs
] #Mton*km/GJ

shipfuelrelation =
#"MDO_D" "MDO_C" "MDO_T" "LNG_D" "LNG_C" "LNG_T" "AMM_D" "AMM_C" "AMM_T" "MET_D" "MET_C" "MET_T"
[
1        0       0       1       0       0       1       0       0       1       0       0        #D
0        1       0       0       1       0       0       1       0       0       1       0        #C
0        0       1       0       0       1       0       0       1       0       0       1        #T
]

maxdemandpervessel =
[
#"MDO_D" "MDO_C" "MDO_T" "LNG_D" "LNG_C" "LNG_T" "AMM_D" "AMM_C" "AMM_T" "MET_D" "MET_C" "MET_T"
5e3      5e3     5e3     5e3     5e3     5e3     5e3     5e3     5e3     5e3     5e3     5e3
]





#Model
#Shipping_stock = Model(with_optimizer(Gurobi.Optimizer,MIPGap=0.0,TimeLimit=300))
Shipping_stock = Model(with_optimizer(GLPK.Optimizer, tm_lim = 60000, msg_lev = GLPK.OFF))
#variables
@variable(Shipping_stock, x[1:S,1:Y] >= 0) #ships bought per type and year
@variable(Shipping_stock, q[1:S,1:Y] >= 0) #ship stock
@variable(Shipping_stock, z[1:S,1:Y] >= 0) #fuel used per ship and per year

@objective(Shipping_stock, Min, sum(ship_inv[s]*x[s,y] for s=1:S, y=1:Y) + sum(ship_var[s]*z[s,y] for s=1:S, y=1:Y))


#demand constraint forcing ships to use fuel
@constraint(Shipping_stock, [t=1:T, y=1:Y], sum(shipfuelrelation[t,s]*z[s,y]*ship_eff[s] for s=1:S) >= Ship_Demands[y,t])

#ship stock in each year for each ship
@constraint(Shipping_stock, [s=1:S, y=1:Y], x[s,y]+(y>1 ? q[s,y-1] : existing_fleet[s]) == q[s,y])

#ship to fuel constraint
@constraint(Shipping_stock, [t=1:T, y=1:Y],sum(q[s,y]*maxdemandpervessel[s]*shipfuelrelation[t,s] for s=1:S) >= Ship_Demands[y,t])

#only ships that have been invested in can supply the demand
@constraint(Shipping_stock, [s=1:S, y=1:Y], z[s,y]*ship_eff[s] <= q[s,y]*maxdemandpervessel[s])

#emission constraint
@constraint(Shipping_stock, [y=1:Y], sum(z[s,y]*ship_emissions[s] for s=1:S) <= emission_limit[y])


# solve
optimize!(Shipping_stock)

if termination_status(Shipping_stock) == MOI.OPTIMAL
    println("Optimal objective value: $(objective_value(Shipping_stock))")
    println("Number of ships built in each year")
    for s=1:S
        for y=1:Y
            println(" $(Ships[s]) $(Years[y]) = $(value(x[s,y]))")
        end
    end

    println("Stock of ships in each year")
    for s=1:S
        for y=1:Y
            println(" $(Ships[s]) $(Years[y]) = $(value(q[s,y]))")
        end
    end

    println("Fuel used per ship in each year")
    for s=1:S
        for y=1:Y
            println(" $(Ships[s]) $(Years[y]) = $(value(z[s,y]))")
        end
    end
else
    println("No optimal solution available")
end
#************************************************************************
