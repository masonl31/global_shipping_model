
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
rename!(ships_bought, ships)
rename!(stock, ships)
rename!(fuel_f_y, fuels)
rename!(fuel_s_y, ships)

Results_folder = joinpath("","results")
# write DataFrame out to CSV file
CSV.write(joinpath(Results_folder,"Results_ships_bought.csv"), ships_bought)
CSV.write(joinpath(Results_folder,"Results_stock.csv"), stock)
CSV.write(joinpath(Results_folder,"Results_fuels_f_y.csv"), fuel_f_y)
CSV.write(joinpath(Results_folder,"Results_fuels_s_y.csv"), fuel_s_y)
