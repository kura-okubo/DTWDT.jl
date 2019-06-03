# DTWDT Functions

These are fundamental functions to calculate DTW distance distance array and DTW error between two time series.

## Main function
`dtwdt` returns time shift, distance function and DTW error between two signals.

Example:
> stbarTime, stbar, dist, dtwerror = dtwdt(u0, u1, dt, dtwnorm="L2", maxLag=80, b=1, direction=1)

```@docs
dtwdt
```

## Sub functions
```@docs
computeErrorFunction
accumulateErrorFunction
backtrackDistanceFunction
computeDTWerror
```
