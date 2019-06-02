@save "./trueresultsfortest.jld2" err dist stbar error

trueresult = @load "./trueresultsfortest.jld2"
err_true = eval(trueresult[1])
dist_true = eval(trueresult[2])
stbar_true = eval(trueresult[3])
error_true = eval(trueresult[4])

@test err_true == err_true
