using JuMP
#using GLPK
using Gurobi
using CSV
#using Tables
using DataFrames
#using Plots

#Data
#Ship_types = ["oiltanker" "bulkcarrier" "generalcargo" "containership" "other"]
Ship_types = ["generalcargo", "containership", "other"]
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
include("ship_emission.jl")
include("ship_eff.jl")
include("ship_fuel_relation.jl")
include("maxdemand.jl")

#Model
Shipping_stock = Model(with_optimizer(Gurobi.Optimizer,MIPGap=0.0,TimeLimit=300))
#Shipping_stock = Model(with_optimizer(GLPK.Optimizer, tm_lim = 60000, msg_lev = GLPK.OFF))

#variables
@variable(Shipping_stock, x[1:S,1:Y] >= 0) #number of ships bought per year
@variable(Shipping_stock, q[1:S,1:Y] >= 0) #ship stock
@variable(Shipping_stock, z[1:S,1:Y] >= 0) #fuel used per ship and per year

@objective(Shipping_stock, Min, sum(ship_inv[s]*x[s,y] for s=1:S, y=1:Y) + sum(ship_var[s]*z[s,y] for s=1:S, y=1:Y))


#demand constraint forcing ships to use fuel
@constraint(Shipping_stock, [t=1:T, y=1:Y], sum(shipfuelrelation[t,s]*z[s,y]*ship_eff[s] for s=1:S) >= Ship_Demands[y,t])

#ship stock in each year for each ship
@constraint(Shipping_stock, [s=1:S, y=1:Y], x[s,y] + preexisting_fleet[y,s] == q[s,y])

#redundant
#ship to fuel constraint
#@constraint(Shipping_stock, [t=1:T, y=1:Y],sum(q[s,y]*maxdemandpervessel[s]*shipfuelrelation[t,s] for s=1:S) >= Ship_Demands[y,t])

#only ships that have been invested in can supply the demand
@constraint(Shipping_stock, [s=1:S, y=1:Y], z[s,y]*ship_eff[s] <= q[s,y]*maxdemandpervessel[s])

#emission constraint
@constraint(Shipping_stock, [y=1:Y], sum(z[s,y]*ship_emissions[s] for s=1:S) <= emission_limit[y])


# solve
optimize!(Shipping_stock)



#-------------------------------------------------------
#OUTPUTS

#primal_status(Shipping_stock)
#dual_status(Shipping_stock)

#creates dataframes
ships_bought = DataFrame(transpose(JuMP.value.(x)))
stock = DataFrame(transpose(JuMP.value.(q)))
fuel_use = DataFrame(transpose(JuMP.value.(z)))

#adds headers
rename!(ships_bought, Ships)
rename!(stock, Ships)
rename!(fuel_use, Ships)

# write DataFrame out to CSV file
CSV.write("ships_bought.csv", ships_bought)
CSV.write("stock.csv", stock)
CSV.write("fuel_use.csv", fuel_use)


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
