# This script is to run DTWDT for developping purpose.

# This script runs an example of dynamic time warping as an introduction to
# the method.
addpath('src');

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

switch example
    case 1
        load('exampleData/stepShiftData.mat'); # data with constant shifts and step in the middle
    case 2
        load('exampleData/sineShiftData.mat'); # data with sine wave shifts of one cycle
end

lvec   = (-maxLag:maxLag).*dt; # lag array for plotting below
npts   = numel(u0);            # number of samples
tvec   = ( 0 : npts-1 ) .* dt; # make the time axis
stTime = st.*dt;               # shift vector in time

figure;
# plot shift function
subplot(2,1,1)
plot(tvec,stTime);
xlabel('Time [s]'); ylabel('\tau [s]'); title('Shift applied to u_{0}(t)');
# plot original and shifted traces
subplot(2,1,2)
plot(tvec,u0); hold on;
plot(tvec,u1); grid on;
xlabel('Time [s]'); ylabel('Amplitude [a.u.]'); title('Traces');
legend('u_{0}(t)','u(t)','Location','Best'); legend boxoff;

## compute error function and plot

err = computeErrorFunction( u1, u0, npts, maxLag ); # cpmpute error function over lages
# note the error function is independent of strain limit 'b'.

figure;
imagesc(tvec,lvec,log10(err')); axis xy; colormap('gray'); c = colorbar;
xlabel('Time [s]'); ylabel('Lag'); title('Error function');

## accumuluate error in FORWARD direction

direction = 1; # direction to accumulate errors (1=forward, -1=backward)
# it is instructive to flip the sign of +/-1 here to see how the function
# changes as we start the backtracking on different sides of the traces.
# Also change 'b' to see how this influences the solution for stbar. You
# want to make sure you're doing things in the proper directions in each
# step!!!

dist  = accumulateErrorFunction( direction, err, npts, maxLag, b ); # forward accumulation to make distance function
stbar = backtrackDistanceFunction( -1*direction, dist, err, -maxLag, b ); # find shifts

## plot the results

stbarTime = stbar .* dt;      # convert from samples to time
tvec2     = tvec + stbarTime; # make the warped time axis

# make figure
h = figure('Color','White'); set(h,'PaperUnits','Inches');
set(h, 'PaperPositionMode','Auto');
set(h, 'Units', 'Inches','Position',[1 1 10 10]);

# plot the distance function
subplot(2,1,1);
imagesc(tvec,lvec,dist');
haxes1 = gca;
title('Distance function'); c=colorbar; axis('tight'); axis xy;
xlabel('Time [s]'); ylabel('\tau [s]');
# plot real shifts against estimated shifts
subplot(2,1,2);
plot(tvec,stTime,'ko'); hold on;
plot(tvec,stbarTime,'r+');
haxes2 = gca;
legend('Actual','Estimated'); legend boxoff;
title('Estimated shifts');
xlabel('Time [s]'); ylabel('\tau [s]');

pos1 = haxes1.Position;
pos2 = haxes2.Position;
set(haxes2,'Position',[pos2(1) pos2(2) pos1(3) pos1(4)]);
print(h,'-dpng','SINEdistance.png');

figure;
# plot input traces
subplot(2,1,1);
plot(tvec,u0,'b',tvec,u1,'r--'); legend('Raw','Shifted'); legend boxoff;
title('Input traces for dynamic time warping')
xlabel('Time (s)'); ylabel('Amplitude (a.u.)');
# plot warped trace to compare
subplot(2,1,2);
plot(tvec,u0,'b'); hold on;
plot(tvec2,u1,'r--'); axis('tight');
legend('Raw','Warped'); legend boxoff;
title('Output traces for dynamic time warping')
xlabel('Time (s)'); ylabel('Amplitude (a.u.)');

## An example of computing the residual misfit

error = computeDTWerror( err, stbar, maxLag );

## Apply dynamic time warping in the backward direction

direction = -1; # direction to accumulate errors (1=forward, -1=backward)

dist  = accumulateErrorFunction( direction, err, npts, maxLag, b ); # backward accumulation to make distance function
stbar = backtrackDistanceFunction( -1*direction, dist, err, -maxLag, b ); # find shifts

## plot the results

stbarTime = stbar .* dt;      # convert from samples to time
tvec2     = tvec + stbarTime; # make the warped time axis

figure;
# plot the distance function
subplot(2,1,1);
imagesc(tvec,lvec,dist');
title('Distance function'); c=colorbar; axis('tight'); axis xy;
xlabel('Time [s]'); ylabel('\tau [s]');
# plot real shifts against estimated shifts
subplot(2,1,2);
plot(tvec,stTime,'ko'); hold on;
plot(tvec,stbarTime,'r+'); legend('Actual','Estimated'); legend boxoff;
title('Estimated shifts');
xlabel('Time [s]'); ylabel('\tau [s]');

figure;
# plot input traces
subplot(2,1,1);
plot(tvec,u0,'b',tvec,u1,'r--'); legend('Raw','Shifted'); legend boxoff;
title('Input traces for dynamic time warping')
xlabel('Time (s)'); ylabel('Amplitude (a.u.)');
# plot warped trace to compare
subplot(2,1,2);
plot(tvec,u0,'b'); hold on;
plot(tvec2,u1,'r--'); axis('tight');
legend('Raw','Warped'); legend boxoff;
title('Output traces for dynamic time warping')
xlabel('Time (s)'); ylabel('Amplitude (a.u.)');

## Apply dynamic time warping in both directions to smooth. (Follwoing example in Hale 2013)

dist1 = accumulateErrorFunction( -1, err, npts, maxLag, b ); # forward accumulation to make distance function
dist2 = accumulateErrorFunction( 1, err, npts, maxLag, b ); # backwward accumulation to make distance function

dist  = dist1 + dist2 - err; # add them and remove 'err' to not count twice (see Hale's paper)

stbar = backtrackDistanceFunction( -1, dist, err, -maxLag, b ); # find shifts
# !! Notice now that you can backtrack in either direction and get the same
# result after you smooth the distance function in this way.

## plot the results

stbarTime = stbar .* dt;      # convert from samples to time
tvec2     = tvec + stbarTime; # make the warped time axis

figure;
# plot the distance function
subplot(2,1,1);
imagesc(tvec,lvec,dist');
title('Distance function'); c=colorbar; axis('tight'); axis xy;
xlabel('Time [s]'); ylabel('\tau [s]');
# plot real shifts against estimated shifts
subplot(2,1,2);
plot(tvec,stTime,'ko'); hold on;
plot(tvec,stbarTime,'r+'); legend('Actual','Estimated'); legend boxoff;
title('Estimated shifts');
xlabel('Time [s]'); ylabel('\tau [s]');

figure;
# plot input traces
subplot(2,1,1);
plot(tvec,u0,'b',tvec,u1,'r--'); legend('Raw','Shifted'); legend boxoff;
title('Input traces for dynamic time warping')
xlabel('Time (s)'); ylabel('Amplitude (a.u.)');
# plot warped trace to compare
subplot(2,1,2);
plot(tvec,u0,'b'); hold on;
plot(tvec2,u1,'r--'); axis('tight');
legend('Raw','Warped'); legend boxoff;
title('Output traces for dynamic time warping')
xlabel('Time (s)'); ylabel('Amplitude (a.u.)');
