#gigaton-NM
average_transport_work = zeros(Y,S)

work_t = 8.62
work_b = 5.21
work_g = 0.37
work_c = 2.03
work_o = 0.82
work_sum = [work_t work_b work_g work_c work_o]
work_sum_sum = [work_sum work_sum work_sum work_sum work_sum work_sum work_sum]
for y=1:Y
    for s = 1:S
        average_transport_work[y,s] = work_sum_sum[s]
    end
end
