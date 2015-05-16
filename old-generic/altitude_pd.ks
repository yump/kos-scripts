//mode b: altitude mode
lock setpoint to 100*ship:control:pilotmainthrottle.

//tuning
set kd to 1.
set kp to kd^2/4.
set period to 0.02.
//info printing interval
set infoprint_interval to 0.1.
//state
set diff to 0.
set lasttime to time:seconds - 0.1. //prevent divide-by-zero problems at start.
set lasterr to 0.
set infoprint_in to 0.
//Gravitational acceleration. Replaces integral term.
lock grav_acc to ship:body:mu/(ship:body:radius + altitude)^2.
//Error and output signals
lock err to setpoint - alt:radar.
lock pidout to grav_acc + kp*err + kd*diff.
// Convert acceleration to throttle level
lock throttle to pidout*mass/(up:vector * facing:vector * max(maxthrust,0.1)).
//sample rate gain invariance
lock dt to time:seconds - lasttime.
//loop
until ag1 {
    //math
    set diff to (err - lasterr)/dt.
    set lasterr to err.
    //infoprinting
    if infoprint_in <=0 {
        print "                    " at(30,20).
        print "                    " at(30,21).
        print "                    " at(30,22).
        print "                    " at(30,23).
        print "                    " at(30,24).
        print "sp  =  " + round(setpoint,2) at(30,20).
        print "err =  " + round(err,2) at(30,21).
        print "p   =  " + round(kp*err,2) at(30,22).
        print "d   =  " + round(kd*diff,2) at(30,23).
        print "g   =  " + round(grav_acc,2) at(30,24).
        set infoprint_in to infoprint_interval.
    }
    set infoprint_in to infoprint_in - dt.
    set lasttime to time:seconds.
    wait period.    
}
