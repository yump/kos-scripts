//// Controlled altitude hovering.

declare parameter setpoint.
print "SETPOINT ARGUMENT WAS " + setpoint. // Fail early if called without arg.

// User input
lock hov_enabl to ag1.    // Enable/disable hovering.
//lock hor_enabl to ag2.    // Kill horizontal velocity. Not yet implemented.
declare oshoot_reset.      // Needed for "ON" statements, for some reason.
lock oshoot_reset to ag3. // Reset overshoot/undershoot peak detectors.

//tuning
set period to 0.01.
set ingain to 2.     // setpoint change at full translate deflection
set kd to 4.         // 
set kp to kd^2/4.
// Diagnostics
set infoprint_interval to 0.1.
set infoprint_at to 0.
set max_overshoot to 0.
set min_undershoot to 0.
on oshoot_reset { set max_overshoot to 0. set min_undershoot to 0. preserve. }
// Output
when hov_enabl then {
    lock throttle to thrott.
    preserve.
}
when not hov_enabl then {
    unlock throttle.
    preserve.
}
// Loop
until false {
    //// Vertical Hovering control
    // Change setpoint by user unput.
    set setpoint to setpoint*(1-ingain*period*ship:control:pilottranslation:z).
    set setpoint to max(0,setpoint).  // We are not a submarine.
    set height to alt:radar. // Sample exactly once, to prevent NaN.
    set v_vert to ship:velocity:surface * up:vector.
    set maxacc to max(1e-9,maxthrust * (facing:vector * up:vector) / mass).
    set grav_acc to ship:body:mu/(ship:body:radius + altitude)^2.
    // PD controller for use in deadband.
    set pdthrott to ((setpoint - height)*kp - v_vert*kd + grav_acc) / maxacc.
    // If the magnitude of the state vector is small enough that the PD 
    // controller will never need more than the maximum acceleration, 
    // we're controllable.
    set pd_mag to sqrt((setpoint-height)^2 + v_vert^2).
    if pd_mag*sqrt(2) < min(grav_acc, maxacc-grav_acc) {
        set thrott to pdthrott.
    // Otherwise, use sliding-mode.
    } else if height <= setpoint {
        if v_vert < sqrt(2*grav_acc*(setpoint-height)) {
            set thrott to 1.
        } else {
            set thrott to 0.
        }
    } else {
        if v_vert <= -(sqrt(2*max(0,maxacc-grav_acc)*(height-setpoint))) {
            set thrott to 1.
        } else {
            set thrott to 0.
        }
    }
    // Diagnostics
    set max_overshoot to max(max_overshoot, height - setpoint).
    set min_undershoot to min(min_undershoot, height - setpoint).
    // Infoprinting
    if time:seconds >= infoprint_at {
        print "                    " at(30,27).
        print "                    " at(30,28).
        print "                    " at(30,29).
        print "                    " at(30,30).
        print "                    " at(30,31).
        print "                    " at(30,32).
        print "                    " at(30,33).
        print "                    " at(30,34).
        print "Hover is " + hov_enabl at(30,27).
        print "sp     = " + round(setpoint,2) at(30,28).
        print "thrott = " + round(throttle,2) at(30,29).
        print "v_vert = " + round(v_vert,2) at(30,30).
        print "alt    = " + round(height,2) at(30,31).
        print "oshoot = " + round(max_overshoot,2) at(30,32).
        print "ushoot = " + round(min_undershoot,2) at(30,33).
        print "pd_mag = " + round(pd_mag,2) at(30,34).
        set infoprint_at to infoprint_at + infoprint_interval.
    }
    wait period.    
}
