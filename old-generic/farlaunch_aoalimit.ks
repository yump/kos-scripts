set target_alt to 80000.
set head to 90.          // launch due east
//set head to 0.           // launch due north, for those polar mapping orbits.

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

//ascent steering
set elev to 90.
set fixedrolltop to facing:topvector. //sample once to avoid roll drift.
lock steering to lookdirup(heading(head,elev):vector, fixedrolltop).

// Profile
set ap_alt_ratio to 1.8. // target apoapsis/altitude ratio
set turn_start to 10.    // Turn enable speed
when altitude > 20000 then {
    set ap_alt_ratio to 1.6.
}
when altitude > 30000 then {
    lock steering to lookdirup(prograde:vector, fixedrolltop).
}

// Maximum angle of attack management
lock maxaoa to max(5,24-airspeed/20).


// Simple throttle control
lock throttle to 1.

// Build some initial velocity
wait until airspeed > turn_start.

// Control loop on apoapsis/altitude ratio
// tuning
set kp to 300.
set kd to 0.
set loop_per to 0.1.
// Diagnostics
set infoprint_interval to 0.2.
set infoprint_at to 0.
//internal
set prev_err to 0.
lock prog_vec to ship:srfprograde:vector. // Might want to use orbital later.
lock prog_elev to 90 - vang(up:vector, prog_vec).
lock err to ap_alt_ratio - apoapsis/altitude.
until apoapsis > target_alt {
    // Control function
    set prop to kp*err.
    set diff to kd*(err-prev_err)/loop_per.
    set raw_elev to prog_elev+prop+diff.
    set elev to min(prog_elev+maxaoa,max(prog_elev-maxaoa, raw_elev)).
    set elev to min(90,max(0,elev)).
    // State update
    set prev_err to err.
    // Diagnostics
    if time:seconds >= infoprint_at {
        print "                    " at(30,29).
        print "                    " at(30,30).
        print "                    " at(30,31).
        print "                    " at(30,32).
        print "                    " at(30,33).
        print "apo/alt   = " + round(apoapsis/altitude,2) at(30,29).
        print "prop     = " + round(prop,2) at(30,30).
        print "diff     = " + round(diff,2) at(30,31).
        print "raw_elev = " + round(raw_elev,2) at(30,32).
        print "elev     = " + round(elev,2) at(30,33).
        set infoprint_at to infoprint_at + infoprint_interval.
    }
    // Timing
    set next_loop to time:seconds + loop_per.
    wait until time:seconds >= next_loop.
}


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
