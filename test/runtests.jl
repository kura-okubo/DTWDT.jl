using DTWDT
using Test
using JLD2, Printf

include("../src/functions.jl")
using .DTWDTfunctions

@testset "functions.jl" begin
    #prepare dataset
    maxLag = 80;
    b      = 1;

    fi = @sprintf("%s/testdata.jld2", pwd())
    @eval @load $("$fi"); # data with sine wave shifts of one cycle
    lvec   = (-maxLag:maxLag).*dt; # lag array for plotting below
    npts   = length(u0);            # number of samples
    direction = 1;

    #load true results
    fi = @sprintf("%s/trueresultsfortest.jld2", pwd())
    trueresult = @eval @load $("$fi");
    err_true = eval(trueresult[1])
    dist_true = eval(trueresult[2])
    stbar_true = eval(trueresult[3])
    error_true = eval(trueresult[4])

    err   = computeErrorFunction(u1, u0, npts, maxLag); # cpmpute error function over Lags
    dist  = accumulateErrorFunction(direction, err, npts, maxLag, b); # forward accumulation to make distance function
    stbar = backtrackDistanceFunction( -1*direction, dist, err, -maxLag, b); # find shifts
    error = computeDTWerror(err, stbar, maxLag); #return DTWerror

    @test err == err_true
    @test dist == dist_true
    @test stbar == stbar_true
    @test error == error_true
end
