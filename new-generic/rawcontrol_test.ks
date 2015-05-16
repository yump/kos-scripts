@lazyglobal off.

function dot_ypr_rate {
    local angularvel is ship:angularvel.
    return V(vdot(angularvel, ship:facing:topvector),
             vdot(angularvel, ship:facing:starvector),
             vdot(angularvel, ship:facing:forevector)).
}

function rot_att_rate {
    return -ship:facing * ship:angularvel.
}

function zero_facing {
    print "Aligning vessel with R(0,0,0)".
    set ship:control:neutralize to true.
    lock steering to R(0,0,0).
    wait 8.
    unlock steering.
    sas on.  //SAS has better damping than lock steering.
    wait 2.
    sas off.
    lock steering to R(0,0,0).
    wait 5.
    unlock steering.
}

function test_control {
    parameter rotvec.
    print "Initial facing is " + ship:facing.
    print "initial attitude rate is " + rot_att_rate().
    print "applying ship:control:rotation " + rotvec.
    set ship:control:rotation to rotvec.
    wait 1.
    print "After 1s, facing is " + ship:facing.
    print "After 1s, attitude rate is " + rot_att_rate().
}

zero_facing().
test_control(v(0.2,0,0)). //positive yaw
print " ".
zero_facing().
test_control(v(0,0.2,0)). //positive pitch
print " ".
zero_facing().
test_control(v(0,0,0.2)). //positive roll
print " ".
