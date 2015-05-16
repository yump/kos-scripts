run liblaunch.
run libutil.
run libpilot.

//Initialization
global target_alt is 75000.
local azimuth is 90.
set ship:control:pilotmainthrottle to 0.
goodsteer_init(0.100, 0.000, 0.080).
local steer is heading(azimuth,90).
atmopitch_init(0.5,   //Sqrt worked before
               10000, //45° at 10km
               3,     //3° aoa limit max 
               0.5).  //0.5°/s aoa limit shaping
local major_cycle_time is 0.5.
wait 0.

local phase is "pre-launch".
local next_major_cycle is time:seconds.
until altitude > 65000 {
    //every cycle
    wait 0.
    set ship:control:rotation to goodsteer(steer).
    //major cycles only
    if time:seconds >= next_major_cycle {
        // Re-arm.
        set next_major_cycle to next_major_cycle + major_cycle_time.
        // Do phase-dependent stuff.
        if phase = "pre-launch" {
            when apoapsis > target_alt then {
                lock throttle to 0.
            }
            local t_start is time:seconds.
            //Global time lock for reports.
            lock T to round(time:seconds - t_start,2).  
            lock throttle to 1.
            stage.
            set phase to "ascent".
        } else if phase = "ascent" {
            if ship:velocity:surface:mag < 50 {
                set steer to heading(azimuth,90).
            } else if altitude < 30000 {
                set steer to heading(azimuth,atmopitch_update()).
            } else {
                set steer to roll_up(prograde:vector).
            }
            if apoapsis > target_alt {
                set phase to "coast".
            }
        } else if phase = "coast" {
            set steer to srfprograde. //minimize drag
        }
        // Do phase-independent stuff.
        simple_staging().
    }
}

jettison_fairings().
extend_panels().
activate_antennas().
release_steering().

circularize_at(time:seconds + eta:apoapsis).
