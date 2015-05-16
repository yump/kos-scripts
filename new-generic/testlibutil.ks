run libutil.

print "Fuel use: " + fuel_rate_Mgs().
print "100 m/s delta-v time: " + burn_time(100).

//local horiztonal prediction
print "Red vector is local horizontal now.".
print "Green vector is local horizontal in 10 minutes.".
set lochor_now to vecdrawargs(
    V(0,0,0),
    local_hor_at(ship,time:seconds),
    RGB(1,0,0),
    "Now",
    5.0,
    True).
set lochor_ten to vecdrawargs(
    V(0,0,0),
    local_hor_at(ship,time:seconds+eta:periapsis),
    RGB(0,1,0),
    "peri",
    5.0,
    True).
set vel_now to vecdrawargs(
    V(0,0,0),
    ship:velocity:orbit/ship:velocity:orbit:mag,
    RGB(0,0,1),
    "velocity",
    5.0,
    True).
set vel_ten to velocityat(ship,time:seconds+600):orbit.
set vel_ten_draw to vecdrawargs(
    V(0,0,0),
    vel_ten/vel_ten:mag,
    RGB(0,1,1),
    "velocity+10m",
    5.0,
    True).
