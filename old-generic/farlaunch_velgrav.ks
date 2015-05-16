set target_alt to 80000.
set head to 90.  //launch due east
//set head to 0.  //launch due north, for those polar mapping orbits.
set g0 to 9.82.  //gravitational acceleration at Kerbin sea level.

SAS off.
set ship:control:pilotmainthrottle to 0. //Don't piss away the fuel in orbit.

clearscreen. //make room for status displays.

print "3".
wait 1.
print "2".
wait 1.
print "1".
wait 1.
print "Blast off!".
set t_launch to time:seconds.
lock t to round(time:seconds - t_launch, 2).

// Clocked background loop for staging logic
set clock_period to 0.1.
set next_clock to 0.
when time:seconds >= next_clock then {
    // Handle basic engines and separable boosters
    list engines in engs.
    for eng in engs {
        if eng:flameout and eng:name <> "sepMotor1" { 
            print "Stage flameout at t=" + t.
            stage.
            break.
        }
    }
    //Handle asparagus staging
    for line in ship:partsnamed("fuelLine") {
        //Fuel lines are children of the source tank
        if line:parent:mass = line:parent:drymass {
            set needstage to true.
            print "Stage asparagus at t=" + t.
            stage.
            break.
        }
    }
    set next_clock to time:seconds + clock_period. preserve. //re-arm
}
stage. //Fire the first stage.

//ascent profile
set turnstart to 80.  // m/s
set slewrate to 0.17. // degrees per m/s
//set pitch to 17.
set pitch to 24.      // For large solid-type lifters
set twr_target to 2.4.
set fixedrolltop to facing:topvector. //sample once to avoid roll drift.
lock steering to lookdirup(heading(head,90):vector, fixedrolltop).
when velocity:surface:mag > turnstart then {
    lock pslew to min(pitch,(velocity:surface:mag - turnstart) * slewrate).
    lock steering to lookdirup(heading(head,90-pslew):vector, fixedrolltop).
    print "gravity turn at t=" + t. 
    when vang(ship:srfprograde:vector,up:vector) > (pitch - 0.5) then {
        lock steering to lookdirup(ship:srfprograde:vector, fixedrolltop).
        print "steering srfprograde at t=" + t.
        when altitude > 23000 then {
            lock steering to lookdirup(prograde:vector, fixedrolltop).
            print "steering obtprograde at t=" + t.
        }
    }
}

// Simple throttle control
lock throttle to 1.
wait until apoapsis > target_alt.

// TWR throttle control.
//when altitude > 25000 then { set twr_target to 10. }
//until apoapsis > target_alt {
//    // Figure out how much of our thrust can't be throttled.
//    set srb_thrust to 0.
//    list engines in twr_engs.
//    for twr_eng in twr_engs {
//        if twr_eng:throttlelock { //is an SRB
//            if twr_eng:ignition and not (twr_eng:flameout) { //is runnning
//                set srb_thrust to srb_thrust + twr_eng:thrust.
//            }
//        }
//    }
//    set throtthrust to max(0.01, maxthrust-srb_thrust). // Avoid /0.
//    lock throttle to (twr_target*g0*mass-srb_thrust)/throtthrust.    
//    wait 0.1.
//}


print "MECO at t= " + t. 
print "Maintaining apoapsis through upper atmosphere...".
until altitude > 50000 {
    if apoapsis < target_alt {
        lock throttle to 0.2.
    } else {
        lock throttle to 0.
    }
}

run circularize.

print "ORBIT at t= " + t. 
print "Remaining Fuel: " + stage:liquidfuel.

SAS on.
