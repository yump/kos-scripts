@lazyglobal off.

run libprint.
run libpilot.

function fuel_rate_Mgs {
    //Get the full-throttle fuel consumption in Mg/s (metric tons per second).
    //constants
    local g0 is 9.82.
    //engines    
    local engs is list().
    list engines in engs.
    //sum fuel consumption of active engines
    local tot is 0.
    for eng in engs {
        if eng:ignition and not (eng:flameout) {
            set tot to tot + eng:thrustlimit/100*eng:maxthrust/(g0*eng:isp).
        }
    }
    return tot.
}

function time_in_stage_now {
    //get the burn time left in the current stage at the current throttle.
    local engs is 0.
    list engines in engs.
    local tot is 0.
    for eng in engs {
        set tot to tot + eng:fuelflow.
    }
    return 0.005 * (stage:liquidfuel + stage:oxidizer) / (tot + 1e-24).
}

function burn_time {
    //Find burn time for given Δv at some throttle with the current vessel.
    parameter delta_v.
    parameter throt.
    local fuel_use is fuel_rate_Mgs(). //call once, because iterates engines.
    local v_exhaust is ship:availablethrust / fuel_use.
    local delta_mass is ship:mass * (1 - constant():e^(-delta_v/v_exhaust)).
    return delta_mass/(fuel_use*throt).
}

function calc_dv {
    //Calculate delta-v for a mass change.
    parameter mass_initial.
    parameter mass_final.
    local v_exhaust is ship:availablethrust / fuel_rate_Mgs().
    return v_exhaust * ln(mass_initial/mass_final).
}

function circ_speed {
    //Find horizontal speed for a circular orbit around a body at some altitude
    parameter body.
    parameter orb_alt.
    local obt_radius is body:radius + orb_alt.
    return sqrt(body:mu / obt_radius).
}


function circ_vel_here {
    //Find circular orbit velocity vector for the current position
    return circ_speed(body,altitude) * local_hor_here().
}

function circularize_at {
    //Circularize the orbit at some time.  Blocking.
    parameter circ_time.
    //Estimate the Δv needed.
    local target_vel is circ_speed(body,apoapsis)*local_hor_at(ship,circ_time).
    local delta_v is target_vel - velocityat(ship,circ_time):orbit.
    print "Circularization delta-v: " + round(delta_v:mag,2) + " m/s".
    //Estimate the time to start the burn as the burn time for half the Δv
    //before the target cirularization time.
    global circ_burn_start is circ_time - burn_time(delta_v:mag / 2, 1).
    //Info printing config.
    local labels is list("Time to burn         ",
                         "Time to cutoff       ",
                         "Velocity to be gained").
    local label_len is 21.
    local data_len is 8.
    local decimals is 2.
    //Variables for use in loop.
    local time_to_go is 0.
    global circ_burn_stop is 0.  //Time to stop the burn, global for trigger.
    local vel_tbg is V(0,0,0). //velocity to be gained
    local interval is min(0.5, burn_time(delta_v:mag, 1)). //possible runt burn
    local next_loop is time:seconds.  //time for next loop
    local phase is "coast".
    until phase = "finished" {
        set next_loop to next_loop + interval.
        set vel_tbg to circ_vel_here() - velocity:orbit.
        lock steering to roll_up(vel_tbg).
        if phase = "coast" {
            if circ_burn_start < next_loop {
                when time:seconds >= circ_burn_start then {
                    lock throttle to 1.
                }
                set phase to "burn".
            }
        } else if phase = "burn" {
            set time_to_go to burn_time(vel_tbg:mag, throttle).
            if time_to_go < interval*10 {
                lock throttle to 0.6. // Throttle depth for muggle engine.
            }
            if time_to_go < interval {
                set circ_burn_stop to time:seconds + time_to_go.
                when time:seconds >= circ_burn_stop then {
                    lock throttle to 0.
                }
                set phase to "finished".
            }
        }
        //Informative output.
        infoprint(labels, label_len,
                  list(circ_burn_start-time:seconds, time_to_go, vel_tbg:mag),
                  data_len, decimals).
        //Sleep as necessary.
        wait until time:seconds >= next_loop.
    }
    set vel_tbg to circ_vel_here() - velocity:orbit.
    print "Final velocity error: " + vel_tbg:mag + " m/s".
}

        

