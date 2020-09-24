emission1 = 1045
emissionY = 268

delta_emission = (emission1 - emissionY)/(Lastyear - Firstyear)

emission_limit = zeros(Y)

for e = 1:Y
    emission_limit[e]=1045-delta_emission*(e-1)
end
