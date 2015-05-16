set target_alt to 75000.
set Rk to 600000. //kerbin radius
set GM to 3532000000000. //kerbin G*Mass

SAS off.
set ship:control:pilotmainthrottle to 0. //Don't piss away the fuel in orbit.

print "3".
wait 1.
print "2".
wait 1.
print "1".
wait 1.
print "Blast off!".
set t_launch to time:seconds.

// Clocked background loop for staging logic
set clock_period to 0.1.
set next_clock to 0.
when time:seconds >= next_clock then {
    // Handle basic engines and separable boosters
    list engines in engs.
    for eng in engs {
        if eng:flameout and eng:name <> "sepMotor1" { 
            print "Stage flameout at t= " + round(time:seconds-t_launch,1).
            stage.
            break.
        }
    }
    //Handle asparagus staging
    for line in ship:partsnamed("fuelLine") {
        //Fuel lines are children of the source tank
        if line:parent:mass = line:parent:drymass {
            set needstage to true.
            print "Stage asparagus at t= " + round(time:seconds-t_launch,1).
            stage.
            break.
        }
    }
    set next_clock to time:seconds + clock_period. preserve. //re-arm
}
stage. //Fire the first stage.

//ascent steering
lock steering to lookdirup(heading(90,90):vector,facing:topvector).
when altitude > 9000 and ship:verticalspeed > 240 then { 
    lock steering to lookdirup(heading(90,60):vector,facing:topvector).
    print "pitchover at t= " + round(time:seconds - t_launch,2). 
    when altitude > 15000 then {
        lock steering to lookdirup(prograde:vector, facing:topvector).
        print "gravity turn at t= " + round(time:seconds - t_launch,2). 
    }
}

//// Fancy throttle control
//gains
set ki to 0.1.
set kp to 1.
set kd to 0.
//info printing interval
set infoprint_interval to 1.
//state
set int_term to 1.
set diff to 0.
set lasttime to time:seconds - 0.1. //prevent divide-by-zero problems at start.
set lasterr to 0.
set infoprint_in to 0.
//automagic
lock err to min(1e6,ship:termvelocity) - ship:airspeed.
lock dt to time:seconds - lasttime.
lock throttle to min(1,max(0, (int_term + kp*err + kd*diff) )).
//loop
until apoapsis > target_alt { //upper atmospheric drag correction
    //math
    set int_term to int_term + ki*err*dt.
    set int_term to min(1.1,max(-0.1,int_term)).  //avoid saturation problems
    set diff to (err - lasterr)/dt.
    //infoprinting
    if infoprint_in <=0 {
        set errinfo to "err=" + round(err,2).
        set intinfo to " int=" + round(int_term,2).
        set dinfo to " d=" + round(kd*diff,2).
        print errinfo + intinfo + dinfo at(20,34).
        set infoprint_in to infoprint_interval.
    }
    set infoprint_in to infoprint_in - dt.
    set lasttime to time:seconds.
    wait 0.1.    
}

print "MECO at t= " + round(time:seconds - t_launch,2). 
print "Maintaining apoapsis through upper atmosphere...".
until altitude > 68000 {
    if apoapsis < target_alt {
        lock throttle to 0.2.
    } else {
        lock throttle to 0.
    }
}

//circularization burn calc
set circ_v to sqrt(GM/(apoapsis+Rk)).
set apo_v to sqrt( GM*( 2/(apoapsis+Rk) - 1/ship:obt:semimajoraxis ) ).
set circ_burn to node(time:seconds + eta:apoapsis, 0, 0, circ_v - apo_v).
add circ_burn.
print round(circ_burn:deltav:mag,2) + " m/s to circularize".
//circularize
run execute.
remove circ_burn.
print "ORBIT at t= " + round(time:seconds - t_launch,2). 
print "Remaining Fuel: " + stage:liquidfuel.

SAS on.
