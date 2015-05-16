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
            print "Stage flameout at t=" + round(time:seconds-t_launch,1).
            stage.
            break.
        }
    }
    //Handle asparagus staging
    for line in ship:partsnamed("fuelLine") {
        //Fuel lines are children of the source tank
        if line:parent:mass = line:parent:drymass {
            set needstage to true.
            print "Stage asparagus at t=" + round(time:seconds-t_launch,1).
            stage.
            break.
        }
    }
    set next_clock to time:seconds + clock_period. preserve. //re-arm
}
stage. //Fire the first stage.

//ascent steering
set fixedrolltop to facing:topvector. //sample once to avoid roll drift.
//lock pitch to 10*(min(1000,altitude)/1000).
//lock steering to lookdirup(heading(90,90-pitch):vector, fixedrolltop).
//when altitude > 1500 then {
//    lock steering to lookdirup(ship:srfprograde:vector, fixedrolltop).
//    print "gravity turn at t= " + round(time:seconds - t_launch,2). 
//    when altitude > 25000 then {
//        lock steering to lookdirup(prograde:vector, fixedrolltop).
//        print "prograde at t= " + round(time:seconds - t_launch,2).
//    }
//}

// Fixed parabolic steering.
set aspect to 5. //tall aspect ratio half-parabola
lock elev to arctan(2*aspect*(sqrt(1 - altitude/target_alt))).
lock steering to lookdirup(heading(90,elev):vector, fixedrolltop).

// Simple throttle control
lock throttle to 1.
until apoapsis > target_alt {
    print "                    " at(30,29).
    print "elev = " + round(elev,2) at(30,29).
    wait 0.2.
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
//remove circ_burn.
print "ORBIT at t= " + round(time:seconds - t_launch,2). 
print "Remaining Fuel: " + stage:liquidfuel.

SAS on.
