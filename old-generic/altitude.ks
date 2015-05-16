//mode b: altitude mode
lock setpoint to 100*ship:control:pilotmainthrottle.

//tuning
set ki to 0.01.
set kp to 0.2.
set kd to 0.5.
set period to 0.02.
//info printing interval
set infoprint_interval to 0.1.
//state
set int to 0.
set diff to 0.
set lasttime to time:seconds - 0.1. //prevent divide-by-zero problems at start.
set lasterr to 0.
set infoprint_in to 0.
//Error and output signals
lock err to setpoint - alt:radar.
lock pidout to int + kp*err + kd*diff.
lock throttle to min(1,max(0, pidout )).
//sample rate gain invariance
lock dt to time:seconds - lasttime.
//loop
until ag1 {
    //math
    set int to int + ki*err*dt.
    set int to min(1.1,max(-0.1,int)).  //avoid saturation problems
    set diff to (err - lasterr)/dt.
    set lasterr to err.
    //infoprinting
    if infoprint_in <=0 {
        print "                    " at(30,21).
        print "                    " at(30,22).
        print "                    " at(30,23).
        print "                    " at(30,24).
        print "sp  =  " + round(setpoint,2) at(30,21).
        print "err =  " + round(err,2) at(30,22).
        print "int =  " + round(int,2) at(30,23).
        print "d   =  " + round(kd*diff,2) at(30,24).
        set infoprint_in to infoprint_interval.
    }
    set infoprint_in to infoprint_in - dt.
    set lasttime to time:seconds.
    wait period.    
}
