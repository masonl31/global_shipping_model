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


#existing_fleet
include("existing_fleet.jl")

#ship investments
include("ship_investments.jl")

#ship_variable
include("ship_variable.jl")


#ship emissions/GJ
include("ship_emissions.jl")

#ship eff
include("ship_efficiency.jl")

#ship type relation
include("ship_type_relation.jl")

#max demand
include("ship_maxdemand.jl")


#Model
#Shipping_stock = Model(with_optimizer(Gurobi.Optimizer,MIPGap=0.0,TimeLimit=300))
Shipping_stock = Model(with_optimizer(GLPK.Optimizer, tm_lim = 60000, msg_lev = GLPK.OFF))
#variables
@variable(Shipping_stock, x[1:S,1:Y] >= 0) #ships bought per type and year
@variable(Shipping_stock, q[1:S,1:Y] >= 0) #ship stock
@variable(Shipping_stock, z[1:S,1:Y] >= 0) #fuel used per ship and per year

@objective(Shipping_stock, Min, sum(ship_inv[s]*x[s,y] for s=1:S, y=1:Y) + sum(ship_var[s]*z[s,y] for s=1:S, y=1:Y))


#demand constraint forcing ships to use fuel
@constraint(Shipping_stock, [t=1:T, y=1:Y], sum(shiptyperelation[t,s]*z[s,y]*ship_eff[s] for s=1:S) >= Ship_Demands[y,t])

#ship stock in each year for each ship
@constraint(Shipping_stock, [s=1:S, y=1:Y], x[s,y]+(y>1 ? q[s,y-1] : existing_fleet[s]) == q[s,y])

#ship to fuel constraint
@constraint(Shipping_stock, [t=1:T, y=1:Y],sum(q[s,y]*maxdemandpervessel[s]*shiptyperelation[t,s] for s=1:S) >= Ship_Demands[y,t])

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
