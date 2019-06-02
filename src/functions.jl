module DTWDTfunctions
export test, computeErrorFunction, accumulateErrorFunction, backtrackDistanceFunction, computeDTWerror
using FFTW, LinearAlgebra, DSP

function test()
    println("test")
    return nothing
end

"""
 USAGE: err = computeErrorFunction( u1, u0, nSample, lag )

 INPUT:
   u1      = trace that we want to warp; size = (nsamp,1)
   u0      = reference trace to compare with: size = (nsamp,1)
   nSample = numer of points to compare in the traces
   lag     = maximum lag in sample number to search
   norm    = 'L2' or 'L1' (default is 'L2')
 OUTPUT:
    err = the 2D error function; size = (nsamp,2*lag+1)

 The error function is equation 1 in Hale, 2013. You could umcomment the
 L1 norm and comment the L2 norm if you want on Line 29

 Original by Di Yang
 Last modified by Dylan Mikesell (25 Feb. 2015)
"""
function computeErrorFunction(u1::Array{Float64, 1}, u0::Array{Float64, 1}, nSample::Int, lag::Int; norm::String="L2")

    if lag >= nSample
        error("computeErrorFunction:lagProblem ","lag must be smaller than nSample");
    end

    #using JLD2
    #@load "../exampledata/sineShiftData.jld2"
    #nSample = length(u0)
    #lag = 80
    #norm = "L2"

    # Allocate error function variable
    err = zeros(Float64, nSample, 2 * lag + 1 );

    #--------------------------------------------------------------------------
    # initial error calculation
    for ll = -lag:lag # loop over lags

        thisLag = ll + lag + 1;

        for ii = 1:nSample # loop over samples

            if ( ii + ll >= 1 && ii + ll <= nSample ) # skip corners for now, we will come back to these

                diff = u1[ii] - u0[ii + ll]; # sample difference

                if norm == "L2"
                        err[ii, thisLag] = diff^2; # difference squared error
                elseif norm == "L1"
                        err[ii, thisLag] = abs(diff); # absolute value errors
                else
                    error("norm type is not defined.")
                end

            end

        end

    end

    #--------------------------------------------------------------------------
    # Now fix corners with constant extrapolation
    for ll = -lag:lag # loop over lags

        thisLag = ll + lag + 1;

        for ii = 1:nSample # loop over samples

            if ( ii + ll < 1 ) # lower left corner (negative lag, early time)

                err[ii, thisLag] = err[-ll + 1, thisLag];

            elseif ( ii + ll > nSample ) # upper right corner (positive lag, late time)

                err[ii, thisLag] = err[nSample - ll, thisLag];

            end

        end

    end

    return err
end


"""

 USAGE: d = accumulation_diw_mod( dir, err, nSample, lag, b )

 INPUT:
   dir = accumulation direction ( dir > 0 = forward in time, dir <= 0 = backward in time)
   err = the 2D error function; size = (nsamp,2*lag+1)
   nSample = numer of points to compare in the traces
   lag = maximum lag in sample number to search
   b = strain limit (integer value >= 1)
 OUTPUT:
    d = the 2D distance function; size = (nsamp,2*lag+1)

 The function is equation 6 in Hale, 2013.

 Original by Di Yang
 Last modified by Dylan Mikesell (25 Feb. 2015)
"""
function accumulateErrorFunction(dir::Int, err::Array{Float64,2}, nSample::Int, lag::Int, b::Int)

    #nSample = length(u0)
    #lag = 80
    #dir = -1

    nLag = (2 * lag ) + 1; # number of lags from [ -lag : +lag ]

    # allocate distance matrix
    d = zeros(Float64, nSample, nLag);

    #--------------------------------------------------------------------------
    # Setup indices based on forward or backward accumulation direction
    #--------------------------------------------------------------------------
    if dir > 0            # FORWARD
        iBegin = 1;       # start index
        iEnd   = nSample; # end index
        iInc   = 1;       # increment
    else                  # BACKWARD
        iBegin = nSample; # start index
        iEnd   = 1;       # stop index
        iInc   = -1;      # increment
    end
    #--------------------------------------------------------------------------
    # Loop through all times ii in forward or backward direction

    for ii = iBegin:iInc:iEnd

        # min/max to account for the edges/boundaries
        ji = max(1, min(nSample, ii - iInc ));     # i-1 index
        jb = max(1, min(nSample, ii - iInc * b )); # i-b index

        # loop through all lags l
        for ll = 1:nLag

            # -----------------------------------------------------------------
            # check limits on lag indices
            lMinus1 = ll - 1; # lag at l-1

            if lMinus1 < 1  # check lag index is greater than 1
                lMinus1 = 1; # make lag = first lag
            end

            lPlus1 = ll + 1; # lag at l+1

            if lPlus1 > nLag # check lag index less than max lag
    #             lPlus1 = nLag - 1; # D.Y. version
                lPlus1 = nLag; # D.M. version
            end
            # -----------------------------------------------------------------

            # get distance at lags (ll-1, ll, ll+1)
            distLminus1 = d[jb, lMinus1]; # minus:  d( i-b, j-1 )
            distL       = d[ji, ll];      # actual: d( i-1, j   )
            distLplus1  = d[jb, lPlus1];  # plus:   d( i-b, j+1 )

            if ji != jb # equation 10 in Hale (2013)
                for kb = ji:-iInc:jb+iInc # sum errors over i-1:i-b+1
                    distLminus1 = distLminus1 + err[kb, lMinus1];
                    distLplus1  = distLplus1  + err[kb, lPlus1];
                end
            end

            # equation 6 (if b=1) or 10 (if b>1) in Hale (2013) after treating boundaries
            d[ii, ll] = err[ii, ll] + min(distLminus1, distL, distLplus1);
        end
    end
    return d
end


"""

 USAGE: stbar = backtrackDistanceFunction( dir, d, err, lmin, b )

 INPUT:
   dir   = side to start minimization ( dir > 0 = front, dir <= 0 =  back)
   d     = the 2D distance function; size = (nsamp,2*lag+1)
   err   = the 2D error function; size = (nsamp,2*lag+1)
   lmin  = minimum lag to search over
   b     = strain limit (integer value >= 1)
 OUTPUT:
   stbar = vector of integer shifts subject to |u(i)-u(i-1)| <= 1/b

 The function is equation 2 in Hale, 2013.

 Original by Di Yang
 Last modified by Dylan Mikesell (19 Dec. 2014)

"""

function backtrackDistanceFunction(dir::Int, d::Array{Float64,2}, err::Array{Float64,2}, lmin::Int, b::Int)

    #d = dist
    #dir = -1
    #lmin = -maxLag
    #b = 1

    nSample = size(d,1); # number of samples
    nLag    = size(d,2); # number of lags
    stbar   = zeros(Int64, nSample); # allocate

    #--------------------------------------------------------------------------
    # Setup indices based on forward or backward accumulation direction
    #--------------------------------------------------------------------------
    if dir > 0            # FORWARD
        iBegin = 1;       # start index
        iEnd   = nSample; # end index
        iInc   = 1;       # increment
    else                  # BACKWARD
        iBegin = nSample; # start index
        iEnd   = 1;       # stop index
        iInc   = -1;      # increment
    end
    #--------------------------------------------------------------------------
    # start from the end (front or back)
    ll0 = argmin(d[iBegin,:]); # find minimum accumulated distance at front or back depending on 'dir'
    stbar[iBegin] = ll0 + lmin - 1; # absolute value of integer shift
    #--------------------------------------------------------------------------
    # move through all time samples in forward or backward direction
    ii = iBegin;

    while ii != iEnd
        if ii == iBegin
            ll = ll0;
        else
            ll = ll_next
        end

        # min/max for edges/boundaries
        ji = max( 1, min(nSample, ii + iInc) );
        jb = max( 1, min(nSample, ii + iInc * b) );

        # -----------------------------------------------------------------
        # check limits on lag indices

        lMinus1 = ll - 1; # lag at l-1

        if lMinus1 < 1 # check lag index is greater than 1
            lMinus1 = 1; # make lag = first lag
        end

        lPlus1 = ll + 1; # lag at l+1

        if lPlus1 > nLag # check lag index less than max lag
            lPlus1 = nLag; # D.M. and D.Y. version
        end
        # -----------------------------------------------------------------
        # get distance at lags (ll-1, ll, ll+1)
        distLminus1 = d[jb, lMinus1]; # minus:  d( i-b, j-1 )
        distL       = d[ji, ll];      # actual: d( i-1, j   )
        distLplus1  = d[jb, lPlus1];  # plus:   d( i-b, j+1 )

        if ji != jb # equation 10 in Hale (2013)
            for kb = ji:iInc:jb-iInc # sum errors over i-1:i-b+1
                distLminus1 = distLminus1 + err[kb, lMinus1];
                distLplus1  = distLplus1  + err[kb, lPlus1];
            end
        end

        dl = min(distLminus1, distL, distLplus1); # update minimum distance to previous sample

        if ( dl != distL ) # then ll != ll and we check forward and backward
            if ( dl == distLminus1 )
                global ll_next = lMinus1;
            else # ( dl == lPlus1 )
                global ll_next = lPlus1;
            end
        end

        # assume ii = ii - 1
        ii += iInc; # previous time sample

        stbar[ii] = ll_next + lmin - 1; # absolute integer of lag
        # now move to correct time index, if smoothing difference over many
        # time samples using 'b'

        if ( ll_next == lMinus1 || ll_next == lPlus1 ) # check edges to see about b values
            if ( ji != jb ) # if b>1 then need to move more steps
                for kb = ji:iInc:jb - iInc
                    ii = ii + iInc; # move from i-1:i-b-1
                    stbar[ii] = ll_next + lmin - 1; # constant lag over that time
                end
            end
        end
    end

    return stbar

    #------------------------#
    # while loop is tricky with Julia
    # we modified ll to ll_next
    # this is the original source from dylanmikesell
    #------------------------#
    # ii = iBegin;
    # while (ii ~= iEnd)
    #
    #     % min/max for edges/boundaries
    #     ji = max( 1, min( [ nSample, ii + iInc ] ) );
    #     jb = max( 1, min( [ nSample, ii + iInc * b ] ) );
    #
    #     % -----------------------------------------------------------------
    #     % check limits on lag indices
    #     lMinus1 = ll - 1; % lag at l-1
    #
    #     if lMinus1 < 1 % check lag index is greater than 1
    #         lMinus1 = 1; % make lag = first lag
    #     end
    #
    #     lPlus1 = ll + 1; % lag at l+1
    #
    #     if lPlus1 > nLag % check lag index less than max lag
    #         lPlus1 = nLag; % D.M. and D.Y. version
    #     end
    #     % -----------------------------------------------------------------
    #
    #     % get distance at lags (ll-1, ll, ll+1)
    #     distLminus1 = d( jb, lMinus1 ); % minus:  d( i-b, j-1 )
    #     distL       = d( ji, ll );      % actual: d( i-1, j   )
    #     distLplus1  = d( jb, lPlus1 );  % plus:   d( i-b, j+1 )
    #
    #     if (ji ~= jb) % equation 10 in Hale (2013)
    #         for kb = ji : iInc : jb - iInc % sum errors over i-1:i-b+1
    #             distLminus1 = distLminus1 + err( kb, lMinus1 );
    #             distLplus1  = distLplus1  + err( kb, lPlus1  );
    #         end
    #     end
    #
    #     dl = min( [ distLminus1, distL, distLplus1 ] ); % update minimum distance to previous sample
    #
    #     if ( dl ~= distL ) % then ll ~= ll and we check forward and backward
    #         if ( dl == distLminus1 )
    #             ll = lMinus1;
    #         else % ( dl == lPlus1 )
    #             ll = lPlus1;
    #         end
    #     end
    #
    #     % assume ii = ii - 1
    #     ii = ii + iInc; % previous time sample
    #
    #     stbar(ii) = ll + lmin - 1; % absolute integer of lag
    #
    #     % now move to correct time index, if smoothing difference over many
    #     % time samples using 'b'
    #     if ( ll == lMinus1 || ll == lPlus1 ) % check edges to see about b values
    #         if ( ji ~= jb ) % if b>1 then need to move more steps
    #             for kb = ji : iInc : jb - iInc
    #                 ii = ii + iInc; % move from i-1:i-b-1
    #                 stbar(ii) = ll + lmin - 1; % constant lag over that time
    #             end
    #         end
    #     end
    # end

end


"""

 Compute the accumulated error along the warping path for Dynamic
 Time Warping.

 USAGE: function error = computeDTWerror( Aerr, u, lag0 )

 INPUT:
   Aerr = error MATRIX (equation 13 in Hale, 2013)
   u    = warping function (samples) VECTOR
   lag0 = value of maximum lag (samples) SCALAR

 Written by Dylan Mikesell
 Last modified: 25 February 2015
"""
function computeDTWerror(Aerr::Array{Float64,2}, u::Array{Int64,1}, lag0::Int)

    npts = length(u);

    if size(Aerr,1) != npts
        #println("Funny things with dimensions of error matrix: check inputs.");
        #Aerr = transpose(Aerr);
        error("Funny things with dimensions of error matrix: check inputs.")
    end

    error = 0; # initialize

    # accumulate error
    for ii = 1:npts
        idx = lag0 + 1 + u[ii]; # index of lag
        error += Aerr[ii,idx]; # sum error
    end

    return error

end


end
