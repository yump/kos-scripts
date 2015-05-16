run libutil.

SAS off.

lock steering to srfprograde.
wait until altitude > 65000.

local initial_mass is ship:mass.
circularize_at(time:seconds + eta:apoapsis).
local final_mass is ship:mass.
print "Delta-V used: " + round(calc_dv(initial_mass,final_mass),2) + " m/s".
