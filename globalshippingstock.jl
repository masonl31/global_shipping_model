using JuMP
using Gurobi
using CSV
using DataFrames


#Data
Ship_types = ["oiltanker" "bulkcarrier" "generalcargo" "containership" "other"]
T = length(Ship_types)

include("Years.jl")

Y = length(Years)


include("emission_limit.jl")
include("ship_demands.jl")



#ship information
Ships = ["MDO_D", "MDO_C", "MDO_T", "LNG_D", "LNG_C", "LNG_T", "AMM_D", "AMM_C", "AMM_T", "MET_D", "MET_C", "MET_T"]
S = length(Ships)

include("existing_fleet.jl")
include("ship_inv.jl")
include("ship_var.jl")
include("ship_fuel.jl")
include("ship_emission.jl")
include("ship_eff.jl")
include("ship_fuel_relation.jl")
include("maxdemand.jl")
include("ship_lifetime.jl")

#testing information
ship_fuel_cost_test=
[
1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1
1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1
1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1	1
]

fuels = ["MFO", "Ammonia", "Methanol"]
F=length(fuels)

eff_test=
[
0	1	0	1	1	1	1	1	1	1	1	1
0	0	1	1	1	1	1	1	1	1	1	1
1	0	0	1	1	1	1	1	1	1	1	1
]

#end of testing




#Model
Shipping_stock = Model(with_optimizer(Gurobi.Optimizer,MIPGap=0.0,TimeLimit=300))

#variables
@variable(Shipping_stock, x[1:S,1:Y] >= 0, Int) #number of ships bought per year
@variable(Shipping_stock, q[1:S,1:Y] >= 0, Int) #ship stock at end of year Y
@variable(Shipping_stock, z[1:F,1:S,1:Y] >= 0) #amount of fuel per fueltype, ship, and year

#removed variable costs!
@objective(Shipping_stock, Min, sum(ship_inv[y,s]*x[s,y] for s=1:S, y=1:Y)+ sum(sum(z[f,s,y] for s=1:S)*ship_fuel_cost_test[f,y] for f=1:F, y=1:Y))

#ship stock in each year for each ship
@constraint(Shipping_stock, [s=1:S, y=1:Y], x[s,y] + preexisting_fleet[y,s] + (y>1 ? q[s,y-1] : 0) - (y>lifetime[s] ? x[s,y-lifetime[s]] : 0) == q[s,y])

#number of ships needed in a given year per type
@constraint(Shipping_stock, [t=1:T, y=1:Y], sum(q[s,y]*shipfuelrelation[t,s]*maxdemandpervessel[s] for s=1:S) >= Ship_Demands[y,t])

@constraint(Shipping_stock, [s=1:S, y=1:Y], sum(z[f,s,y]*eff_test[f,s] for f=1:F) >= q[s,y]*maxdemandpervessel[s])

#@constraint(Shipping_stock, [s=1:S, y=1:Y], sum(z[f,y]*eff_test[f,s]/maxdemandpervessel[s] for f=1:F) >= sum(fuel_matrix_test[f,s]*q[s,y] for f=1:F))

#emission constraint
#@constraint(Shipping_stock, [y=1:Y], sum(z[s,y]*ship_emissions[s] for s=1:S) <= emission_limit[y])


#These are the old ones
#=
#variables
@variable(Shipping_stock, x[1:S,1:Y] >= 0, Int) #number of ships bought per year
@variable(Shipping_stock, q[1:S,1:Y] >= 0, Int) #ship stock at end of year Y
@variable(Shipping_stock, z[1:S,1:Y] >= 0) #fuel used per ship and per year

@objective(Shipping_stock, Min, sum(ship_inv[y,s]*x[s,y] + ship_var[y,s]*z[s,y] + ship_fuel[y,s]*z[s,y] for s=1:S, y=1:Y))

#ship stock in each year for each ship
@constraint(Shipping_stock, [s=1:S, y=1:Y], x[s,y] + preexisting_fleet[y,s] + (y>1 ? q[s,y-1] : 0) - (y>lifetime[s] ? x[s,y-lifetime[s]] : 0) == q[s,y])

#demand constraint forcing ships to use fuel
@constraint(Shipping_stock, [t=1:T, y=1:Y], sum(shipfuelrelation[t,s]*z[s,y]*ship_eff[s] for s=1:S) >= Ship_Demands[y,t])

#only ships that have been invested in can supply the demand
@constraint(Shipping_stock, [s=1:S, y=1:Y], z[s,y]*ship_eff[s] <= q[s,y]*maxdemandpervessel[s])

#emission constraint
@constraint(Shipping_stock, [y=1:Y], sum(z[s,y]*ship_emissions[s] for s=1:S) <= emission_limit[y])

#redundant
#ship to fuel constraint
#@constraint(Shipping_stock, [t=1:T, y=1:Y],sum(q[s,y]*maxdemandpervessel[s]*shipfuelrelation[t,s] for s=1:S) >= Ship_Demands[y,t])
=#



#--------------------

# solve
optimize!(Shipping_stock)

#--------------------
#OUTPUTS
fuel_fueltype_year=zeros(F,Y)
for f=1:F
	for y=1:Y
		fuel_fueltype_year[f,y] = sum(JuMP.value.(z[f,s,y]) for s=1:S)
	end
end

fuel_ship_year=zeros(S,Y)
for s=1:S
	for y=1:Y
		fuel_ship_year[s,y] = sum(JuMP.value.(z[f,s,y]) for f=1:F)
	end
end



#creates dataframes
ships_bought = DataFrame(transpose(JuMP.value.(x)))
stock = DataFrame(transpose(JuMP.value.(q)))
fuel_f_y = DataFrame(transpose(fuel_fueltype_year))
fuel_s_y = DataFrame(transpose(fuel_ship_year))

#adds headers
rename!(ships_bought, Ships)
rename!(stock, Ships)
rename!(fuel_f_y, fuels)
rename!(fuel_s_y, Ships)

# write DataFrame out to CSV file
CSV.write("Results_ships_bought.csv", ships_bought)
CSV.write("Results_stock.csv", stock)
CSV.write("Results_fuels_f_y.csv", fuel_f_y)
CSV.write("Results_fuels_s_y.csv", fuel_s_y)


#=
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
=#
