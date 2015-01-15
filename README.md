# BASHsplitMAT
Stochastic Mixing Cross Section for MCNP using Pseudo Material Method

It has two version for now.
ratio6000: 
  interpolate all material using the relationship read from Nuclide reaction data.
  Noting that even data at 900K is separated into two parts using identical data.
  This separated entries are used for SAB interpolation.
ratioGRPH:
  This version interpolate all material using relationship read from Nuclide reaction data, 
  except the 6000 concerning the SAB data - grph.
  interpolation scheme for 6000 here employed the relationship read from SAB.

