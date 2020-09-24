
average_transport_work = zeros(Y,S)

work_t = 5.6
work_b = 13
work_g = 0.9
work_c = 7.4
work_o = 0.6
work_sum = [work_t work_b work_g work_c work_o]
work_sum_sum = [work_sum work_sum work_sum work_sum work_sum work_sum work_sum]
for y=1:Y
    for s = 1:S
        average_transport_work[y,s] = work_sum_sum[s]
    end
end 
