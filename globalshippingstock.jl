using JuMP
using Cbc, Gurobi

using CSV
using DataFrames
using DelimitedFiles

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
include("fuel_tax.jl")


#constants
onemega = 1E6
onegiga = 1E9
onetera = 1E12
megatogiga = 1E9
NMtokm = 1.852
petatogiga = 1E6

decommission_value = 0.5

#Model
Shipping_stock = Model(Gurobi.Optimizer)

#variables
@variable(Shipping_stock, x[1:S,1:Y] >= 0, Int) #number of ships bought per year [# of ships]
@variable(Shipping_stock, q[1:S,1:Y] >= 0, Int) #ship stock at year Y [# of ships]
@variable(Shipping_stock, z[1:F,1:S,1:Y] >= 0) #amount of fuel per fueltype, ship, and year [PJ]
@variable(Shipping_stock, d[1:S,1:Y] >= 0, Int) #ship stock to decomission [# of ships]

@objective(Shipping_stock, Min, sum(ship_inv[y,s]*x[s,y] for s=1:S, y=1:Y)*onemega
                              + sum((sum(z[f,s,y] for s=1:S)*petatogiga)*(fuel_cost[f,y]+fuel_tax[f,y]) for f=1:F, y=1:Y)
#                              - sum(d[s,y]*ship_inv[y,s]*decommission_value for s=1:S, y=1:Y)   not working yet
           )
           
#ship stock in each year for each ship
@constraint(Shipping_stock, [s=1:S, y=1:Y], x[s,y] + preexisting_fleet[y,s] + (y>1 ? sum(x[s,y] for y=1:y-1) : 0) - (y>lifetime[s] ? sum(x[s,y] for y=1:y-lifetime[s]) : 0) - d[s,y] == q[s,y])

#number of ships needed in a given year per type
#@constraint(Shipping_stock, [t=1:T, y=1:Y], sum(q[s,y]*ship_type_relation[t,s]*average_transport_work[s] for s=1:S) >= Ship_Demands[y,t])

#fuel must be consumed by current ship stock
@constraint(Shipping_stock, [s=1:S, y=1:Y], sum(z[f,s,y]*ship_eff[f,s] for f=1:F) <= q[s,y]*average_transport_work[y,s])

@constraint(Shipping_stock, [t=1:T, y=1:Y], sum(sum(z[f,s,y]*ship_eff[f,s] for f=1:F)*average_transport_work[s]*ship_type_relation[t,s] for s=1:S) >= Ship_Demands[y,t])

#emission constraint for year 2050 and onwards
@constraint(Shipping_stock, [y=2050-2007+1:Y], sum(sum(z[f,s,y] for s=1:S) * fuel_emissions[f] for f=1:F) <= emission_limit[2050-2007+1] * onemega)



#--------------------

# solve
optimize!(Shipping_stock)

#--------------------
#OUTPUTS
include("output.jl")
#new test