#!/usr/bin/python
import sys
import numpy as np
import os.path
import math

def sqrt_interpo ( ub, lb, in_temp, in_concentration, isub):
  if isub == True :
    return in_concentration / (math.sqrt(ub) - math.sqrt(lb)) * (math.sqrt(in_temp) - math.sqrt(lb))
  else :
    return in_concentration / (math.sqrt(ub) - math.sqrt(lb)) * (math.sqrt(ub) - math.sqrt(in_temp))

###############################################################################
# Main Program
###############################################################################
if __debug__:
  print "Py: Temperature: %s, zzzaaa: %s, a/o: %s " %( sys.argv[1], sys.argv[2], sys.argv[3])
  print "Py:      CE map: %s, SAB map: %s"          %( sys.argv[4], sys.argv[5])
  print "Py:    new file:",                          sys.argv[6]


# read input
in_temp=float(sys.argv[1])
ub_temp=0
lb_temp=0
in_concentration=float(sys.argv[3])
CEt, CEname   = np.loadtxt( sys.argv[4],skiprows=0,usecols=(0, 1),unpack=True,dtype=float)
SABt, SABname = np.loadtxt( sys.argv[5],skiprows=0,usecols=(0, 1),unpack=True,dtype=float)
if __debug__:
  print "Py:      Origin a/o:", in_concentration
  
#/////////
# Detect if valid SAB or not
first = sys.argv[2]
if "6000" == sys.argv[2] :
  second = "6001"
elif "grph" == sys.argv[2] :
  second = "grpx"
else :
  second = sys.argv[2]

  
#//////////
# Find upper and lower bound for SAB
if in_concentration == 0 :
  if __debug__:
    print "Py:  interpolate SAB file:", in_concentration
  for i in range ( 0, SABt.size, 1) :
    if in_temp >= SABt[i] :
      lb_temp = SABt[i]                                                 # lower temperature
      lb_name = first + "." + str(int(SABname[i])) + "t"                # zzaaa.nnx format
    if in_temp <= SABt[SABt.size -1 -i] :
      ub_temp = SABt[SABt.size -1 -i]                                   # upper temperature
      ub_name = second + "." + str(int(SABname[SABt.size -1 -i])) + "t" # zzaaa.nnx format
#//////////
# Find upper and lower bound for CE
else :
  for i in range ( 0, CEt.size, 1) :
    if in_temp >= CEt[i] :
      lb_temp = CEt[i]                                                # lower temperature
      lb_name = first + "." + str(int(CEname[i])) + "c"               # zzaaa.nnx format
    if in_temp <= CEt[CEt.size -1 -i] :
      ub_temp = CEt[CEt.size -1 -i]                                   # upper temperature
      ub_name = second + "." + str(int(CEname[CEt.size -1 -i])) + "c" # zzaaa.nnx format

 
# Check Temperatures and output identical temperature
if ub_temp == 0 or lb_temp == 0 or lb_temp > ub_temp :
  print "Py: Error boundary temperature!"
  sys.exit(1)


#/////////
# Redefine Temperature doundary for CE in SAB relationship
if "6000" == sys.argv[2] :
  for i in range ( 0, SABt.size, 1) :
    if in_temp >= SABt[i] :
      lb_temp = SABt[i]                                                 # lower temperature
    if in_temp <= SABt[SABt.size -1 -i] :
      ub_temp = SABt[SABt.size -1 -i]                                   # upper temperature

# interpolate mCard for CE and mtCard for SAB
if in_temp == ub_temp and in_temp == lb_temp :
  ub_concentration=0
  lb_concentration=in_concentration
  if __debug__:
    print "%s: Temperature == Boundary." % ub_name
  ub_name=" "
else :
  ub_concentration = sqrt_interpo (ub_temp,lb_temp,in_temp,in_concentration,True)
  lb_concentration = sqrt_interpo (ub_temp,lb_temp,in_temp,in_concentration,False)

#//////////
# Output SAB
if in_concentration == 0 :
  if __debug__:
    print "Py:      SAB file:", in_concentration
  with open(sys.argv[6], 'w') as f:
    f.write("%-3s" %(sys.argv[6]) + "%11s" %(lb_name) + "%11s" %(ub_name) + "\n" )
  sys.exit(0)
  
#///////// 
# Output CE
if os.path.exists( sys.argv[6] + ".txt") :
  with open(sys.argv[6] + ".txt", 'a') as f:
    f.write("%16s" %(lb_name) + "%12.4E" %(lb_concentration) ) 
    f.write("%12s" %(ub_name) + "%12.4E" %(ub_concentration)  + "\n")
  with open(sys.argv[6], 'w') as f:
    f.write("%16s" %(lb_name) + "%12.4E" %(lb_concentration) ) 
    f.write("%12s" %(ub_name) + "%12.4E" %(ub_concentration)  + "\n")
else:
  with open(sys.argv[6] + ".txt", 'a') as f:
    f.write("%-4s" %(sys.argv[6]) + "%12s" %(lb_name) + "%12.4E" %(lb_concentration) ) 
    f.write("%12s" %(ub_name)     + "%12.4E" %(ub_concentration)  + "\n")
  with open(sys.argv[6], 'w') as f:
    f.write("%-4s" %(sys.argv[6]) + "%12s" %(lb_name) + "%12.4E" %(lb_concentration) ) 
    f.write("%12s" %(ub_name)     + "%12.4E" %(ub_concentration)  + "\n")


if __debug__:
  print "Py: upper bound a/o: %10.3E for %10s at %5d" %(ub_concentration, ub_name,ub_temp)
  print "Py: lower bound a/o: %10.3E for %10s at %5d" %(lb_concentration, lb_name,lb_temp)
  print "Py: End Python script"

sys.exit(0)

