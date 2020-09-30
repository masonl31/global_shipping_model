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
#existing MFO ship calculations
existing_fleet_MFO = zeros(Y,5)
for y=1:size(IMO_total,1)
    for s=1:5
        existing_fleet_MFO[y,s] = IMO_total[y,s] - existing_fleet_scrubber[y,s] - existing_fleet_lng[y,s] - existing_fleet_elc[y,s] - existing_fleet_met[y,s] - existing_fleet_lpg[y,s] - existing_fleet_hyd[y,s]
    end
end






preexisting_fleet = hcat(existing_fleet_MFO, existing_fleet_scrubber, existing_fleet_lng, existing_fleet_elc, existing_fleet_met, existing_fleet_lpg, existing_fleet_hyd)


#=
preexisting_fleet =
[
10603	8223	21085	4963	38352	2	4	1	2	2	4	1	3	1	15	0	0	1	0	21	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
8828	8993	20302	5090	41410	4	7	2	4	4	6	1	4	2	22	0	0	1	0	29	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
9017	9550	20271	5096	42404	7	15	4	9	9	9	2	6	2	29	0	1	1	0	52	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
9210	10120	19644	5074	43659	19	39	11	24	24	11	2	7	3	36	1	1	2	0	67	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
9639	10421	19530	5055	45413	41	85	25	52	52	14	2	9	4	47	1	1	2	0	77	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
9864	10634	19652	5155	46242	53	109	32	67	67	17	3	11	5	59	1	1	3	0	99	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
10129	10752	19660	5069	47001	65	134	39	82	82	21	4	14	6	71	1	2	3	1	126	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
10274	10872	19520	5006	47450	119	246	72	150	150	26	5	17	7	87	1	2	4	1	160	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
10226	10318	18659	4618	48919	506	1046	307	641	641	32	6	21	9	109	2	3	6	1	225	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	688	1421	417	871	871	51	8	32	19	141	2	3	6	1	236	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	709	1466	430	898	898	72	11	44	32	173	3	4	12	1	297	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	712	1471	431	901	901	88	13	53	41	198	5	5	18	2	371	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	94	14	57	45	208	6	6	21	2	406	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	96	14	57	46	210	6	6	22	2	408	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	96	14	58	47	211	6	6	22	2	411	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	97	14	58	47	212	6	6	22	2	412	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	97	14	58	47	212	6	6	22	2	412	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	97	14	58	47	212	6	6	22	2	412	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	97	14	58	47	212	6	6	22	2	412	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	97	14	58	47	212	6	6	22	2	412	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	97	14	58	47	212	6	6	22	2	412	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	97	14	58	47	212	6	6	22	2	412	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	97	14	58	47	212	6	6	22	2	412	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	97	14	58	47	212	6	6	22	2	412	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	97	14	58	47	212	6	6	22	2	412	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	97	14	58	47	212	6	6	22	2	412	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	95	14	57	46	205	6	6	22	2	404	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	92	13	55	46	198	6	5	22	2	381	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	90	13	54	45	191	5	5	21	2	366	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	87	13	52	44	180	5	5	21	2	356	2	0	1	0	21	34	0	0	0	0	0	0	0	0	3
0	0	0	0	0	733	1515	444	928	928	84	12	50	43	168	5	5	20	2	334	0	0	0	0	0	0	0	0	0	0	0	0	0	0	3
0	0	0	0	0	731	1512	443	926	926	80	11	47	42	156	5	4	20	1	307	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	728	1504	441	921	921	75	10	44	41	140	5	4	19	1	273	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	716	1480	434	906	906	69	9	40	39	118	4	3	17	1	208	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	694	1434	420	878	878	63	8	36	38	97	4	3	17	1	199	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	682	1410	413	863	863	46	6	26	28	71	3	2	10	1	117	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	670	1385	406	848	848	25	3	14	15	39	1	1	4	0	43	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	616	1273	373	780	780	9	1	5	6	14	0	0	1	0	8	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	229	473	138	289	289	3	0	1	2	4	0	0	0	0	6	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	47	98	28	59	59	1	0	1	1	2	0	0	0	0	3	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	26	53	15	32	32	1	0	0	0	1	0	0	0	0	2	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	23	48	14	29	29	0	0	0	0	0	0	0	0	0	2	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	2	4	1	2	2	0	0	0	0	0	0	0	0	0	2	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0
]
=#
