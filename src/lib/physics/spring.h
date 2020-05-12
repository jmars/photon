#include <stdbool.h>
#include <math.h>

void phys_SpringSolve(
  double c, double m, double k,
  double initial, double velocity,
  double t,
  double *x, double *dx
);