
demand1 = [1400 12500 11500 8500 5500]
dummy=zeros(Y-1,T)
Ship_Demands = vcat(demand1, dummy)
growth1 = [1.03 1.043 1.043 1.024 1.024] #2010-2018 DNV GL
growth2 = [1.025 1.017 1.043 1.036 1.022] #2019-2030 DNV GL
growth3 = [0.999 0.999 0.999 1.015 1.006] #2031-2050 DNV GL

for i=1:T
        for j=2:8
                Ship_Demands[j,i]=growth1[i]*Ship_Demands[j-1,i]
        end
        for j=9:20
                Ship_Demands[j,i]=growth2[i]*Ship_Demands[j-1,i]
        end
        for j=21:Y
                Ship_Demands[j,i]=growth3[i]*Ship_Demands[j-1,i]
        end
end
