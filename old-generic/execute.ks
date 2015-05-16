SAS off.

lock safemaxthrust to max(maxthrust, 0.001). // No dividing by zero.

// Moving average for maneuver node. Used for direction only, not burn timing,
// because we don't want to overshoot.
// Create and fill the moving average buffer
set navg to 50.
set filt_buf to list().
set i to 0.
until i >= navg {
    set i to i+1.
    filt_buf:add(v(0,0,0)).
}
// Actual filtering loop
set filt_period to 0.1.
set filt_clock to 0.
set deltav_avg to v(0,0,0).
when time:seconds >= filt_clock then {
    set newsample to nextnode:deltav. //sample
    set deltav_avg to deltav_avg - filt_buf[0]/navg + newsample/navg. //update
    filt_buf:remove(0). filt_buf:add(newsample). //shift buffer
    set filt_clock to time:seconds + filt_period. preserve. //re-arm
}

print "Orienting vessel for burn.".
//lock steering to lookdirup(nextnode:deltav, facing:topvector).
//try with filtered vector...
lock steering to lookdirup(deltav_avg, facing:topvector).

//Guesstimate start of burn.
//set preburn_offset to nextnode:deltav:mag * mass / safemaxthrust / 2.

//Better guesstimate
//Find the Isp and mass loss rate for all the currently active engines
set totfuel_Mg_s to 0.
set totthrust_kN to 0.
set g0 to 9.82.
set e to constant():e.
list engines in ex_engs.
for ex_eng in ex_engs {
    if ex_eng:ignition and not (ex_eng:flameout) { //engine will contribute
        set totthrust_kN to totthrust_kN + ex_eng:maxthrust.
        set totfuel_Mg_s to totfuel_Mg_s + ex_eng:maxthrust/(g0*ex_eng:isp).
    }
}
set totisp_m_s to totthrust_kN/totfuel_Mg_s.
// Find the mass we want to have at the node, so that half the ΔV happens
// before the node.
set mass_at_node to mass/e^(nextnode:deltav:mag/(2*totisp_m_s)).
set preburn_offset to (mass - mass_at_node)/totfuel_Mg_s.
print "Burn will start at T -" + round(preburn_offset,2).

//acceleration: burns should be at least 1 s
set ex_accel to nextnode:deltav:mag/1.
when nextnode:deltav:mag < 5 then {
    print "Reducing throttle at T " + round(-(nextnode:eta),2) + " s.".
    lock ex_accel to max(0.001, nextnode:deltav:mag/2).
}

//Use the filtered deltav vector, cause it's noisy as hell.
lock angleerr to vectorangle(deltav_avg, facing:vector).
until nextnode:deltav:mag < 0.1 {
    //Thrust only after the burn starts, when we're pointed the right way.
    if angleerr < 3 and nextnode:eta < preburn_offset {
        lock throttle to max(0,min(1, ex_accel*mass/safemaxthrust )).
    } else {
        lock throttle to 0.
    }
    print "                         " at(25,30).
    print "angle err = " + round(angleerr,3) at(25,30).
    print "                         " at(25,31).
    print "throttle  = " + round(throttle,6) at(25,31).
    print "                         " at(25,32).
    print "dv err    = " + round(nextnode:deltav:mag,3) at(25,32).
    print "                         " at(25,33).
    print "node in T = " + -(round(nextnode:eta,3)) at(25,33).
    print "                         " at(25,34).
    print "burn in T = " + -(round(nextnode:eta-preburn_offset,3)) at(25,34).
    wait 0.01.
}

print "Burn complete at T " + round(-(nextnode:eta),2) + " s.".
lock throttle to 0.
