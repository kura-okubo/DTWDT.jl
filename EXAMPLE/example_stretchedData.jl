# This script is the translation of run_example.m in
# Dylan Mikesell's DynamicWarping repo (https://github.com/dylanmikesell/DynamicWarping.)
# run this script in the terminal: '> julia DTWDT_run_example.jl'
# 2019/06 Kurama Okubo

using PlotlyJS, ORCA, FileIO, JLD2, Printf, DTWDT
#for dv/v analysis
using DataFrames, GLM

fodir = "./EXAMPLE/fig/stretched"
mkpath(fodir)

## load the data file and plot
@load "./exampledata/StretchedData.jld2"; # data with sine wave shifts of one cycle

# plot shift function
maxLag = 80; # max nuber of points to search forward and backward (can be npts, just takes longer and is unrealistic)
b      = 1; # b-value to limit strain

lvec   = (-maxLag:maxLag).*dt; # lag array for plotting below
npts   = length(u0);            # number of samples
tvec   = ( 0 : npts-1 ) .* dt; # make the time axis
stTime = st;

## compute timeshift
stbarTime, stbar, dist, dtwerror = dtwdt(u0, u1, dt,
                    dtwnorm="L2",
                    maxLag=80, #number of maxLag id to search the distance
                    b=1, # b value to controll distance calculation algorithm
                    direction=1, #direction to accumulate errors (1=forward, -1=backward, 0=double to smooth)
                    )

tvec2 = tvec + stbarTime; # make the warped time axis

# plot the distance function
function plotdistfunc()
    tr = heatmap(;x=tvec, y=lvec, z=dist, colorscale="Jet",
    zauto=true, colorbar=attr(title="Dist", titleside="right",))
    layout = Layout(
        title = "Distance function",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="τ [s]"),
        width=800,
        height=400,
    )
    plot(tr, layout)
end

p = (plotdistfunc())
display(p)

savefig(p, fodir*"/distance_array.png")

function lineplot1()
    tr1 = scatter(;x=tvec, y=stTime, mode="lines", name="Actual")
    tr2 = scatter(;x=tvec, y=stbarTime, mode="markers", name="Estimated")
    layout = Layout(
        title = "Estimated shifts",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="τ [s]"),
        width=800,
        height=400,
    )
    plot([tr1, tr2], layout)
end

p = (lineplot1())
display(p)
savefig(p, fodir*"/inputsignal.png")

# plot input traces
function lineplot_s1()
    tr1 = scatter(;x=tvec, y=u0, mode="lines", name="Raw")
    tr2 = scatter(;x=tvec, y=u1, mode="lines", name="Shifted",
    line = attr(dash="dot"))

    layout = Layout(
        title = "Input traces for dynamic time warping",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="Amplitude (a.u.)"),
    )
    plot([tr1, tr2], layout)
end

function lineplot_s2()
    tr1 = scatter(;x=tvec, y=u0, mode="lines", name="Raw")
    tr2 = scatter(;x=tvec2, y=u1, mode="lines", name="Warped",
    line = attr(dash="dot"))

    layout = Layout(
        title = "Output traces for dynamic time warping",
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="Amplitude (a.u.)"),
    )
    plot([tr1, tr2], layout)
end

p = ([lineplot_s1(), lineplot_s2()])
display(p)
savefig(p, fodir*"/traces.png")

# dv/v analysis
#linear regression of stbarTime (=estimated time shift)

data = DataFrame(X=tvec, Y=stbarTime)
ols = lm(@formula(Y ~ X), data)

dtt = GLM.coef(ols)[2]
dvv = dtt # assume dt/T = dv/V

linstTime = collect(tvec) .* dtt .+ GLM.coef(ols)[1]
#plot line
# plot input traces

function lineplot_ln()
    tr1 = scatter(;x=tvec, y=stTime, mode="lines", name="Actual")
    tr2 = scatter(;x=tvec, y=stbarTime, mode="markers", name="Estimated")
    tr3 = scatter(;x=tvec, y=linstTime, mode="lines", name="Linear regression",
                    line=attr(width=5.0, color="red"))
    layout = Layout(
        title = @sprintf("true dv/v: -0.01, estimated dv/v = %4.8f", dvv),
        xaxis=attr(title="Time [s]"),
        yaxis=attr(title="τ [s]"),
        width = 800,
        height = 400,
    )
    plot([tr1, tr2, tr3], layout)
end

p = (lineplot_ln())
display(p)
savefig(p, fodir*"/linregression.png")

# plot schematic of dynamic warping
yshift0 = maximum(abs.(u0))
yshift1 = maximum(abs.(u1))

u0s = u0 .+ yshift0
u1s = u1 .- yshift1

layout = Layout(width=800, height=600,
				xaxis=attr(title="Time [s]", dtick=10.0),
				yaxis=attr(title="Amplitude (a.u.)"),
                font =attr(size=18),
                title = "Schematic of dynamic time warping")
p = plot([NaN], layout)

#plot connection
linespan = 5
for i = 1:linespan:npts
    x0 = tvec[i]
    y0 = u0s[i]
    x1 = tvec[stbar[i]+i]
    y1 = u1s[stbar[i]+i]

    trace1 = scatter(;x=[x0, x1], y=[y0, y1], mode="lines",
        line_color="rgb(200, 200, 200)",
        line=attr(dash = false,),
        showlegend=false,
        )
    addtraces!(p, trace1)
end

#plot two traces
tr1 = scatter(;x=tvec, y=u0s, mode="lines", name="Raw",)
tr2 = scatter(;x=tvec, y=u1s, mode="lines", name="Shifted",)
addtraces!(p, tr1)
addtraces!(p, tr2)

deletetraces!(p, 1)
savefig(p, fodir*"/schematic.png")

println("Type something to exit this example.");
readline();
