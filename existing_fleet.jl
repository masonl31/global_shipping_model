#total ships from IMO statistics database
IMO_total =
[
#T      B        G      C       O
10609	8228	21090	4966	38390 #2011
8838	9001	20309	5096	41465
9033	9568	20282	5107	42494
9241	10162	19664	5101	43786
9695	10509	19566	5111	45589
9935	10747	19698	5227	46467
10216	10892	19716	5158	47280
10420	11125	19613	5164	47847
10766	11373	18993	5269	49894 #2019
]


#https://afi.dnvgl.com/Statistics
DNVGL_shiptypes = ["Bulk carrier" "Container ships" "Crude oil tankers" "Oil/Chemical tankers" "Cruise ships" "Ro-Ro cargo ships" "Gas tankers" "general cargo ships" "RoPax" "Car carriers" "Car/passenger ferries" "Other activities" "Fishing vessels" "Other offshore vessels" "Offshore supply ships" "Tugs"]
DNVGL_altfuels = ["Scrubber" "LNG" "ELC" "LNG ready" "Methanol" "LPG" "Hydrogen"]
#=
1 - "tanker"
2 - "bulk carrier"
3 - "generalcargo"
4 - "containership"
5 - "other"
=#
#this table comes directly from the above link from DNV GL
#represents the number of ships in operation and on order
#first column is type of ship and the other columns are the alternative fuels
DNVGL_total =
[
2   1568    19  6   42  0   0   0
4   938     47  2   45  0   0   0
1   621     55  6   8   0   0   0
5   571     49  5   29  21  0   0
5   220     32  18  0   0   0   0
3   195     13  16  8   0   0   0
1   115     7   0   0   2   34  0
3   103     15  3   0   0   0   0
3   93      22  3   12  1   0   0
3   60      10  0   0   0   0   0
5   12      53  194 4   0   0   2
5   6       20  89  1   0   0   0
5   1       3   18  0   0   0   0
5   1       0   13  0   0   0   0
5   0       37  59  0   0   0   0
5   0       18  16  0   0   0   1
]

DNVGL_total_sort = [a == 1 ? t : sum(DNVGL_total[findall(DNVGL_total[:,1].==t),a]) for t in 1:5, a in 1:8]



DNVGL_scrubberships =
[
11 #2011
20
39
107
243
313
388
732
3156
4341
4489
4502
4504 #2023
]

DNVGL_LNGships =
[
#operation #order #LNGready
22      0       0
32      0       0
43      0       0
53      0       1
70      0       13
88      0       34
105     0       53
130     0       80
162     0       114
172     58      126
172     131     142
172     196     144
172     219     144
172     223     144
172     226     144
172     227     144
]

DNVGL_elcships =
[
#operation #underconstruction
22      0 #2011
31      0
55      0
70      0
81      0
104     0
132     0
168     2
237     71
246     156
246     195
246     197
246     201
246     202 #2026
]


###############################################################################
#existing methanol ship calculations
existing_fleet_met = zeros(Y,5)
#methanol ships for year 2021
#assuming total ships are operational in 2021 that are stated by DNV GL
for y=(2021-2011+1):(2021-2011+1+25)
    for s = 1:5
        existing_fleet_met[y,s] = DNVGL_total_sort[s,6]
    end
end

###############################################################################
#existing lpg ship calculations
existing_fleet_lpg = zeros(Y,5)
#LPG ships for year 2021
#assuming total ships are operational in 2021 that are stated by DNV GL
for y=(2021-2011+1):(2021-2011+1+25)
    for s = 1:5
        existing_fleet_lpg[y,s] = DNVGL_total_sort[s,7]
    end
end

###############################################################################
#existing hyd ship calculations
existing_fleet_hyd = zeros(Y,5)
#HYD ships for year 2021
#assuming total ships are operational in 2021 that are stated by DNV GL
for y=(2021-2011+1):(2021-2011+1+25)
    for s = 1:5
        existing_fleet_hyd[y,s] = DNVGL_total_sort[s,8]
    end
end


###############################################################################
#existing elc ship calculations
#calculates the existing and orders from 2011 to 2026 based on DNV GL data
existing_fleet_elc = zeros(Y,5)
for y=1:size(DNVGL_elcships,1)
    for s=1:5
        existing_fleet_elc[y,s] = round(sum(DNVGL_elcships[y,i] for i=1:2)*(DNVGL_total_sort[s,4]/sum(DNVGL_total_sort[i,4] for i = 1:5)))
    end
end

#gives existing fleet the lifetime of 25 assuming 2011 is the earliest starting year for these ships
for y=(2026-2011):25
    for s=1:5
        existing_fleet_elc[y,s] = existing_fleet_elc[14,s]
    end
end

#these two loops extend the lifetime of the ships from DNV GL to the lifetime that they should have
for y = 26
    for s=1:5
        existing_fleet_elc[y,s] = existing_fleet_elc[y-1,s]-existing_fleet_elc[y-25,s]
    end
end

for y = 27:50
    for s=1:5
        existing_fleet_elc[y,s] = existing_fleet_elc[y-1,s] - (existing_fleet_elc[y-25,s] - existing_fleet_elc[y-26,s])
    end
end



###############################################################################
#existing lng ship calculations
#calculates the existing and orders from 2011 to 2026 based on DNV GL data
existing_fleet_lng = zeros(Y,5)
for y=1:size(DNVGL_LNGships,1)
    for s=1:5
        existing_fleet_lng[y,s] = round(sum(DNVGL_LNGships[y,i] for i=1:3)*((DNVGL_total_sort[s,3]+DNVGL_total_sort[s,5])/(sum(DNVGL_total_sort[i,3] for i = 1:5) + (sum(DNVGL_total_sort[i,5] for i = 1:5)))))
    end
end

#gives existing fleet the lifetime of 25 assuming 2011 is the earliest starting year for these ships
for y=(size(DNVGL_LNGships,1)+1):25
    for s=1:5
        existing_fleet_lng[y,s] = existing_fleet_lng[size(DNVGL_LNGships,1),s]
    end
end

#these two loops extend the lifetime of the ships from DNV GL to the lifetime that they should have
for y = 26
    for s=1:5
        existing_fleet_lng[y,s] = existing_fleet_lng[y-1,s]-existing_fleet_lng[y-25,s]
    end
end

for y = 27:50
    for s=1:5
        existing_fleet_lng[y,s] = existing_fleet_lng[y-1,s] - (existing_fleet_lng[y-25,s] - existing_fleet_lng[y-26,s])
    end
end


###############################################################################
#existing scrubber ship calculations
#calculates the existing and orders from 2011 to 2026 based on DNV GL data
existing_fleet_scrubber = zeros(Y,5)
for y=1:size(DNVGL_scrubberships,1)
    for s=1:5
        existing_fleet_scrubber[y,s] = round(DNVGL_scrubberships[y]*(DNVGL_total_sort[s,2]/sum(DNVGL_total_sort[i,2] for i = 1:5)))
    end
end

#gives existing fleet the lifetime of 25 assuming 2011 is the earliest starting year for these ships
for y=(size(DNVGL_scrubberships,1)+1):25
    for s=1:5
        existing_fleet_scrubber[y,s] = existing_fleet_scrubber[size(DNVGL_scrubberships,1),s]
    end
end

#these two loops extend the lifetime of the ships from DNV GL to the lifetime that they should have
for y = 26
    for s=1:5
        existing_fleet_scrubber[y,s] = existing_fleet_scrubber[y-1,s]-existing_fleet_scrubber[y-25,s]
    end
end

for y = 27:50
    for s=1:5
        existing_fleet_scrubber[y,s] = existing_fleet_scrubber[y-1,s] - (existing_fleet_scrubber[y-25,s] - existing_fleet_scrubber[y-26,s])
    end
end


###############################################################################
#existing MFO ship calculations assuming average lifetime of 15 years left and all gone in 20 years
existing_fleet_MFO = zeros(Y,5)
for y=1:size(IMO_total,1)
    for s=1:5
        existing_fleet_MFO[y,s] = IMO_total[y,s] - existing_fleet_scrubber[y,s] - existing_fleet_lng[y,s] - existing_fleet_elc[y,s] - existing_fleet_met[y,s] - existing_fleet_lpg[y,s] - existing_fleet_hyd[y,s]
    end
end

for y=size(IMO_total,1)+1:size(IMO_total,1)+15
    for s=1:5
        existing_fleet_MFO[y,s] = existing_fleet_MFO[size(IMO_total,1),s]
    end
end




preexisting_fleet = hcat(existing_fleet_MFO, existing_fleet_scrubber, existing_fleet_lng, existing_fleet_elc, existing_fleet_met, existing_fleet_lpg, existing_fleet_hyd)
preexisting_fleet = zeros(Y,S)
