ship_inv = zeros(Y,S)

#million euro
ship_cost =
[
7.4198709	5.550891164	1.1427213	15.73175703	2.4055	12.60448792	9.41136018	1.8800589	26.80523803	4.0375	17.3165487	12.91996353	2.55019125	36.86941738	5.52075	999	999	999	999	999	11.10580956	8.295443355	1.66692225	23.60430993	3.56575	17.3165487	12.91996353	2.55019125	36.86941738	5.52075	999	999	999	999	6.393132665
]

for y=1:Y
    for s = 1:S
        ship_inv[y,s] = ship_cost[s]
    end
end
