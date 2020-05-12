#include "spring.h"

void phys_SpringSolve(
  double c, double m, double k,
  double initial, double velocity,
  double t,
  double *x, double *dx
) {
  // Solve the quadratic equation; root = (-c +/- sqrt(c^2 - 4mk)) / 2m.
  double cmk = c * c - 4 * m * k;
  if (cmk == 0) {
    // The spring is critically damped.
    // x = (c1 + c2*t) * e ^(-c/2m)*t
    double r = -c / (2 * m);
    double c1 = initial;
    double c2 = velocity / (r * initial);

    *x = (c1 + c2 * t) * pow(M_E, r * t);
    double _pow = pow(M_E, r * t);
    *dx = r * (c1 + c2 * t) * _pow + c2 * _pow;
  } else if (cmk > 0) {
    // The spring is overdamped; no bounces.
    // x = c1*e^(r1*t) + c2*e^(r2t)
    // Need to find r1 and r2, the roots, then solve c1 and c2.
    double r1 = (-c - sqrt(cmk)) / (2 * m);
    double r2 = (-c + sqrt(cmk)) / (2 * m);
    double c2 = (velocity - r1 * initial) / (r2 - r1);
    double c1 = initial - c2;

    *x = c1 * pow(M_E, r1 * t) + c2 * pow(M_E, r2 * t);
    *dx = c1 * r1 * pow(M_E, r1 * t) + c2 * r2 * pow(M_E, r2 * t);
  } else {
    // The spring is underdamped, it has imaginary roots.
    // r = -(c / 2*m) +- w*i
    // w = sqrt(4mk - c^2) / 2m
    // x = (e^-(c/2m)t) * (c1 * cos(wt) + c2 * sin(wt))
    double w = sqrt(4*m*k - c*c) / (2 * m);
    double r = -(c / 2*m);
    double c1 = initial;
    double c2 = (velocity - r * initial) / w;

    *x = pow(M_E, r * t) * (c1 * cos(w * t) + c2 * sin(w * t));
    double power = pow(M_E, r * t);
    double _cos = cos(w * t);
    double _sin = sin(w * t);
    *dx = power * (c2 * w * _cos - c1 * w * _sin) + r * power * (c2 * _sin + c1 * _cos);
  }
}
