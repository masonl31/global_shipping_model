fuelcost1 =
[
0.75
1.25
0.8
0.9
1.2
1.3
1.3
1.3
1.3
]

fuel_cost = zeros(F,Y)

for f=1:F
        for y=1:Y
                fuel_cost[f,y] = fuelcost1[f]
        end
end
