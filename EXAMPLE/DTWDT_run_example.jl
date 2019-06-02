# This script is the translation of run_example.m in
# Dylan Mikesell's DynamicWarping repo (https://github.com/dylanmikesell/DynamicWarping.)
# run this script in the terminal: '> julia DTWDT_run_example.jl'
# 2019/06 Kurama Okubo

using PlotlyJS, ORCA, FileIO, JLD2
# This script runs an example of dynamic time warping as an introduction to
# the method.
push!(LOAD_PATH,"../src")

include("../src/functions.jl")
using .DTWDTfunctions

example = 2; # shift function (1=step, 2=sine)
# you can try two test cases. Watch the 'maxLag' parameter. The two shift
# functions have different magnitudes so if you don't go to large enough
# lags in the sine model, you won't converge to the correction solution.

# in the case of the sine wave, you must have b=1 because the strains are
# on the order of dt!! Play with 'b' to see how you get stuck in the
# wrong minimum because you're not allowing large enough jumps.

# in the case of the step function, we break the DTW because the step shift
# is larger than dt. We would need a different step pattern to correctly
# solve for this step. It's possible, just not implemented in this version
# of the dynamic warping because don't expect strains > 100#.

# (you can also change the input examples using the scripts in exampleData/
# folder.)

maxLag = 80; # max nuber of points to search forward and backward (can be npts, just takes longer and is unrealistic)
b      = 1; # b-value to limit strain
# impose a strain limit: 1 dt is b=1, half dt is b=2, etc.
# if you mess with b you will see the results in the estimated shifts
# (kura) usually b=1

## load the data file and plot

if example == 1
    #@load "../exampledata/stepShiftData.jld2"; # data with constant shifts and step in the middle
    error("stepShiftData is not implemented.")
elseif example == 2
    @load "../exampledata/sineShiftData.jld2"; # data with sine wave shifts of one cycle
end

lvec   = (-maxLag:maxLag).*dt; # lag array for plotting below
npts   = length(u0);            # number of samples
tvec   = ( 0 : npts-1 ) .* dt; # make the time axis
stTime = st;               # shift vector in time

# plot shift function
#time shift curve

function lineplot1()
    tr = scatter(;x=tvec, y=stTime, mode="lines", name="Timeshift")
    layout = Layout(
        title="Shift applied to u_{0}(t)",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="τ [s]"),
    )
    plot(tr, layout)
end

function lineplot2()
    tr1 = scatter(;x=tvec, y=u0, mode="lines+markers", name="u<sub>0</sub>(t)")
    tr2 = scatter(;x=tvec, y=u1, mode="lines+markers", name="u(t)")
    layout = Layout(
        title = "Traces",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="Amplitude [a.u.]"),
    )
    plot([tr1, tr2], layout)
end

#p = [lineplot1(), lineplot2()]

## compute error function and plot

err = computeErrorFunction(u1, u0, npts, maxLag); # cpmpute error function over Lags
# note the error function is independent of strain limit 'b'.


function ploterrfunc()
    tr = heatmap(;x=tvec, y=lvec, z=log10.(err), colorscale="Greys",
    zauto=false, zmin=-4, zmax=0, colorbar=attr(title="L2 error", titleside="right",))
    layout = Layout(
        title = "Error function",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="Lag"),
    )
    plot(tr, layout)
end

#ploterrfunc()

## accumuluate error in FORWARD direction

direction = 1; # direction to accumulate errors (1=forward, -1=backward)
# it is instructive to flip the sign of +/-1 here to see how the function
# changes as we start the backtracking on different sides of the traces.
# Also change 'b' to see how this influences the solution for stbar. You
# want to make sure you're doing things in the proper directions in each
# step!!!

dist  = accumulateErrorFunction(direction, err, npts, maxLag, b); # forward accumulation to make distance function

function plotdistfunc()
    tr = heatmap(;x=tvec, y=lvec, z=dist, colorscale="Jet",
    zauto=true, colorbar=attr(title="Dist", titleside="right",))
    layout = Layout(
        title = "Distance function dir = +1",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="τ [s]"),
    )
    plot(tr, layout)
end
#plotdistfunc()

stbar = backtrackDistanceFunction( -1*direction, dist, err, -maxLag, b ); # find shifts

## plot the results

stbarTime = stbar .* dt;      # convert from samples to time
tvec2     = tvec + stbarTime; # make the warped time axis

# make figure
function lineplot3()
    tr1 = scatter(;x=tvec, y=stTime, mode="lines", name="Actual")
    tr2 = scatter(;x=tvec, y=stbarTime, mode="markers", name="Estimated")
    layout = Layout(
        title = "Estimated shifts",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="τ [s]"),
    )
    plot([tr1, tr2], layout)
end

p = ([plotdistfunc(), lineplot3()])
display(p)
savefig(p, "./SINEdistance.png")

## An example of computing the residual misfit

error = computeDTWerror( err, stbar, maxLag );

## Apply dynamic time warping in the backward direction
direction = -1; # direction to accumulate errors (1=forward, -1=backward)

dist  = accumulateErrorFunction(direction, err, npts, maxLag, b ); # backward accumulation to make distance function
stbar = backtrackDistanceFunction( -1*direction, dist, err, -maxLag, b ); # find shifts

## plot the results
stbarTime = stbar .* dt;      # convert from samples to time
tvec2     = tvec + stbarTime; # make the warped time axis


function plotdistfunc2()
    tr = heatmap(;x=tvec, y=lvec, z=dist, colorscale="Jet",
    zauto=true, colorbar=attr(title="Dist", titleside="right",))
    layout = Layout(
        title = "Distance function dir = -1",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="τ [s]"),
    )
    plot(tr, layout)
end

function lineplot4()
    tr1 = scatter(;x=tvec, y=stTime, mode="lines", name="Actual")
    tr2 = scatter(;x=tvec, y=stbarTime, mode="markers", name="Estimated")
    layout = Layout(
        title = "Estimated shifts",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="τ [s]"),
    )
    plot([tr1, tr2], layout)
end

p = ([plotdistfunc2(), lineplot4()])
display(p)

# plot input traces
function lineplot5()
    tr1 = scatter(;x=tvec, y=u0, mode="lines", name="Raw")
    tr2 = scatter(;x=tvec, y=u1, mode="lines", name="Shifted",
    line = attr(dash="dash"))

    layout = Layout(
        title = "Input traces for dynamic time warping dir = -1",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="Amplitude (a.u.)"),
    )
    plot([tr1, tr2], layout)
end

function lineplot6()
    tr1 = scatter(;x=tvec, y=u0, mode="lines", name="Raw")
    tr2 = scatter(;x=tvec2, y=u1, mode="lines", name="Warped",
    line = attr(dash="dash"))

    layout = Layout(
        title = "Output traces for dynamic time warping",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="Amplitude (a.u.)"),
    )
    plot([tr1, tr2], layout)
end

p = ([lineplot5(), lineplot6()])
display(p)

## Apply dynamic time warping in both directions to smooth. (Follwoing example in Hale 2013)

dist1 = accumulateErrorFunction( -1, err, npts, maxLag, b ); # forward accumulation to make distance function
dist2 = accumulateErrorFunction( 1, err, npts, maxLag, b ); # backwward accumulation to make distance function

dist  = dist1 .+ dist2 .- err; # add them and remove 'err' to not count twice (see Hale's paper)

stbar = backtrackDistanceFunction( -1, dist, err, -maxLag, b ); # find shifts
# !! Notice now that you can backtrack in either direction and get the same
# result after you smooth the distance function in this way.

## plot the results

stbarTime = stbar .* dt;      # convert from samples to time
tvec2     = tvec + stbarTime; # make the warped time axis

# plot the distance function
function plotdistfunc_s()
    tr = heatmap(;x=tvec, y=lvec, z=dist, colorscale="Jet",
    zauto=true, colorbar=attr(title="Dist", titleside="right",))
    layout = Layout(
        title = "Distance function smoothed",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="τ [s]"),
    )
    plot(tr, layout)
end

function lineplot_s1()
    tr1 = scatter(;x=tvec, y=stTime, mode="lines", name="Actual")
    tr2 = scatter(;x=tvec, y=stbarTime, mode="markers", name="Estimated")
    layout = Layout(
        title = "Estimated shifts",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="τ [s]"),
    )
    plot([tr1, tr2], layout)
end

p = ([plotdistfunc_s(), lineplot_s1()])
display(p)

# plot input traces
function lineplot_s2()
    tr1 = scatter(;x=tvec, y=u0, mode="lines", name="Raw")
    tr2 = scatter(;x=tvec, y=u1, mode="lines", name="Shifted",
    line = attr(dash="dash"))

    layout = Layout(
        title = "Input traces for dynamic time warping smoothed",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="Amplitude (a.u.)"),
    )
    plot([tr1, tr2], layout)
end

function lineplot_s3()
    tr1 = scatter(;x=tvec, y=u0, mode="lines", name="Raw")
    tr2 = scatter(;x=tvec2, y=u1, mode="lines", name="Warped",
    line = attr(dash="dash"))

    layout = Layout(
        title = "Output traces for dynamic time warping",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="Amplitude (a.u.)"),
    )
    plot([tr1, tr2], layout)
end

p = ([lineplot_s2(), lineplot_s3()])
display(p)

println("Type something to exit this example.");
readline();
