using JuMP
#using GLPK
using Gurobi
using CSV
using DataFrames
#using Plots
#using StatsPlots

#Data
include("ship_types.jl")
include("fuels.jl")
include("ships.jl")


include("Years.jl")
include("emission_limit.jl")
include("ship_demands.jl")


include("existing_fleet.jl")
include("ship_inv.jl")
#include("ship_var.jl")
include("ship_eff.jl")
include("ship_type_relation.jl")
include("averagetransportwork.jl")
include("ship_lifetime.jl")


include("fuel_emissions.jl")
include("fuel_cost.jl")

#constants
onemega = 1E6
onegiga = 1E9
onetera = 1E12
megatogiga = 1E9
dummy = 5E2


#Model
#Shipping_stock = Model(Gurobi.Optimizer)
Shipping_stock = Model(with_optimizer(Gurobi.Optimizer,MIPGap=0.0,TimeLimit=300))

#variables
@variable(Shipping_stock, x[1:S,1:Y] >= 0, Int) #number of ships bought per year
@variable(Shipping_stock, q[1:S,1:Y] >= 0, Int) #ship stock at end of year Y
@variable(Shipping_stock, z[1:F,1:S,1:Y] >= 0) #amount of fuel per fueltype, ship, and year

#removed variable costs!
@objective(Shipping_stock, Min, sum(ship_inv[y,s]*x[s,y] for s=1:S, y=1:Y) + sum(sum(z[f,s,y] for s=1:S)*fuel_cost[f,y] for f=1:F, y=1:Y))

#ship stock in each year for each ship
#@constraint(Shipping_stock, [s=1:S, y=1:Y], x[s,y] + preexisting_fleet[y,s] + (y>1 ? q[s,y-1] : 0) - (y>lifetime[s] ? x[s,y-lifetime[s]] : 0) == q[s,y])
@constraint(Shipping_stock, [s=1:S, y=1:Y], x[s,y] + preexisting_fleet[y,s] + (y>1 ? sum(x[s,y] for y=1:y-1) : 0) - (y>lifetime[s] ? sum(x[s,y] for y=1:y-lifetime[s]) : 0) == q[s,y])


#number of ships needed in a given year per type
@constraint(Shipping_stock, [t=1:T, y=1:Y], sum(q[s,y]*ship_type_relation[t,s]*average_transport_work[s] for s=1:S) >= Ship_Demands[y,t])

#fuel must be consumed by current ship stock
@constraint(Shipping_stock, [s=1:S, y=1:Y], sum(z[f,s,y]*ship_eff[f,s] for f=1:F) >= q[s,y]*average_transport_work[s] * onegiga)

#emission constraint
@constraint(Shipping_stock, [y=1:Y], sum(sum(z[f,s,y] for s=1:S) * fuel_emissions[f] for f=1:F) <= emission_limit[y] * onetera * dummy)



#--------------------

# solve
optimize!(Shipping_stock)

#--------------------
#OUTPUTS
include("output.jl")
