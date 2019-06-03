__precompile__()
module DTWDT

include("functions.jl")
using .DTWDTfunctions

export dtwdt

"""
    dtwdt(u0::Array{Float64,1}, u1::Array{Float64,1}, dt::Float64; dtwnorm::String="L2"
        maxlag::Int64=80, b::Int64=1, direction::Int64=1)

returns minimum distance time lag and index in dist array, and dtw error between traces.

# Arguments
- `u0, u1::Array{Float64,1}`: Time series.
- `dt::Float64`: time step (dt of u0 and u1 should be same)
- `dtwnorm::String`: norm to calculate distance; effect on the unit of dtw error. (L2 or L1)
-  Note: L2 is not squard, thus distance is calculated as (u1[i]-u0[j])^2
- `maxlag::Int64`: number of maxLag id to search the distance.
- `b::Int64t`: b value to controll in distance calculation algorithm (see Mikesell et al. 2015).
- `direction::Int64`: length of noise data window, in seconds, to cross-correlate.

# Outputs
- `stbarTime::Array{Float64,1}`: series of time shift at t.
- `stbar::Array{Int64,1}`: series of minimum distance index in distance array.
- `dist::Array{Int64,2}`: distance array.
- `dtwerror::Float64`: dtw error (distance) between two time series.

"""
function dtwdt(u0::Array{Float64,1}, u1::Array{Float64,1}, dt::Float64;
    dtwnorm::String="L2",    #norm to calculate distance; effect on the unit of dtw error
    maxLag::Int64=80,         #number of maxLag id to search the distance
    b::Int64=1,               #b value to controll in distance calculation algorithm (see Mikesell et al. 2015)
    direction::Int64=1,       #direction to accumulate errors (1=forward, -1=backward, 0=double to smooth)
    )

    #prepare datasize and time vector
    lvec   = (-maxLag:maxLag).*dt; # lag array for plotting below
    npts   = length(u0);            # number of samples
    if length(u0) != length(u1) error("u0 and u1 must be same length.") end
    tvec   = ( 0 : npts-1 ) .* dt; # make the time axis

    #compute distance between traces
    err = computeErrorFunction(u1, u0, npts, maxLag, norm=dtwnorm);

    #compute distance array and backtrack index
    if direction == 1 || direction == -1
        dist  = accumulateErrorFunction(direction, err, npts, maxLag, b); # forward accumulation to make distance function
        stbar = backtrackDistanceFunction( -1*direction, dist, err, -maxLag, b ); # find shifts

    elseif direction == 0
        #calculate double time to smooth distance array
        dist1 = accumulateErrorFunction( -1, err, npts, maxLag, b ); # forward accumulation to make distance function
        dist2 = accumulateErrorFunction( 1, err, npts, maxLag, b ); # backwward accumulation to make distance function
        dist  = dist1 .+ dist2 .- err; # add them and remove 'err' to not count twice (see Hale's paper)
        stbar = backtrackDistanceFunction( -1, dist, err, -maxLag, b );
    else
        error("direction must be +1, -1 or 0(smoothing).")
    end

    stbarTime = stbar .* dt;      # convert from samples to time
    tvec2     = tvec + stbarTime; # make the warped time axis

    #accumulate distance in distance array to calculate dtw error
    error = computeDTWerror( err, stbar, maxLag );

    return (stbarTime, stbar, dist, error)
end

end # module
