using JuMP
using Gurobi

#Data
Fuels = ["MDO" "LNG" "Ammonia" "Methanol"]
Ship_types = ["Dry bulk" "Container" "Tanker"]
T = length(Ship_types)
Years = ["2020" "2021" "2022" "2023" "2024"]
Y = length(Years)


emission_limit =
[
7e5 #2020
7e5 #2021
7e5 #2022
7e5 #2023
7e5 #2024
]

Ship_Demands =
#D  #C  #T
[
1e6 4e6 9e5 #2020
1e6 4e6 9e5 #2021
1e6 4e6 9e5 #2022
1e6 4e6 9e5 #2023
1e6 4e6 9e5 #2024
] #Mtonkm


#ship information
Ships =
["MDO_D" "MDO_C" "MDO_T" "LNG_D" "LNG_C" "LNG_T" "AMM_D" "AMM_C" "AMM_T" "MET_D" "MET_C" "MET_T"]
S = length(Ships)

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
Shipping_stock = Model(with_optimizer(Gurobi.Optimizer,MIPGap=0.0,TimeLimit=300))

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
