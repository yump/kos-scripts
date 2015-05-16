@lazyglobal off.
run libprint.

function no_roll {
    //Convert a vector to a direction so that it won't roll the ship.
    parameter vec.
    return lookdirup(vec, ship:facing:topvector).
}

function roll_up {
    //Convert a vector to a direction so that it will level the "wings".
    parameter vec.
    return lookdirup(vec, up:vector).
}

function local_hor_at {
    //Find unit vector of local horizontal for orbitable at time.
    parameter orbitable.
    parameter time.
    local vel is velocityat(orbitable, time):orbit.
    local rad is positionat(orbitable,time) - orbitable:body:position.
    local horvec is vcrs(vcrs(rad,vel),rad).
    return horvec / horvec:mag.
}

function local_hor_here {
    //Find the local horizontal.
    local horvec is vcrs(vcrs(body:position, velocity:orbit),body:position).
    return horvec / horvec:mag.
}

function wrap_ang_neg {
    //Convert an angle such that angles > 180° are negative.
    parameter ang.
    set ang to mod(ang,360).
    if ang > 180 {
        return ang - 360.
    } else {
        return ang.
    }
}

function rot_to_vec {
    // Convert a rotation to V(yaw, pitch, roll) with angles > 180 represented
    // as negative.
    parameter rot.
    return V(wrap_ang_neg(rot:yaw), 
             wrap_ang_neg(rot:pitch),
             wrap_ang_neg(rot:roll)).
}

global vector_template is v(0,0,0).
function fast_rot_to_vec {
    // The same, but faster.
    parameter rot.
    if rot:yaw > 180 {
        set vector_template:x to rot:yaw - 360.
    } else {
        set vector_template:x to rot:yaw.
    }
    if rot:pitch > 180 {
        set vector_template:y to rot:pitch - 360.
    } else {
        set vector_template:y to rot:pitch.
    }
    if rot:roll > 180 {
        set vector_template:z to rot:roll - 360.
    } else {
        set vector_template:z to rot:roll.
    }
    return vector_template:vec.
}
    
global goodsteer_state is 0.
global gs_kp is 0.
global gs_ki is 0.
global gs_kd is 0.
global gs_integral is 0.
global gs_lastfacing is 0.
global gs_lasttime is 0.
function goodsteer_init {
    // Configure the steering control
    parameter kp.
    parameter ki.
    parameter kd.
    set gs_kp to kp.
    set gs_ki to ki.
    set gs_kd to kd.
    set gs_integral to V(0,0,0).
    set gs_lastfacing to ship:facing.
    set gs_lasttime to time:seconds - 1. //In the past to avoid divide by zero.
    sas off.
}

global goodsteer_debug_labels is list("pitch control",
                                      "yaw control",
                                      "roll control",
                                      "prop:pitch",
                                      "prop:yaw",
                                      "prop:roll",
                                      "der:pitch",
                                      "der:yaw",
                                      "der:roll",
                                      "int:pitch",
                                      "int:yaw",
                                      "int:roll").

function goodsteer {
    // Run steering control cycle with setpoint direction steer_to.
    parameter steer_to.
    // Sample the current facing and time.
    local curfacing is ship:facing.
    local curtime is time:seconds.
    // Control calculations.
    local errvec is fast_rot_to_vec(-curfacing * steer_to).
    // Proportional
    local prop is gs_kp * errvec.
    //timing
    local elapsed is curtime-gs_lasttime.
    //integral
    if prop:mag < 1 {
        // Avoid windup. If the proportional is already satruated, we don't
        // need to be integrating.
        set gs_integral to gs_integral + gs_ki * errvec * elapsed.
    }
    //derivative
    local der is -gs_kd * fast_rot_to_vec(-gs_lastfacing * curfacing)/elapsed.
    // update state.
    set gs_lastfacing to curfacing.
    set gs_lasttime to curtime.
    // Command
    local sum is prop + der + gs_integral.
    // Invert pitch and roll because who knows.
    set sum:x to -sum:x.
    // Debug printing
//    infoprint(goodsteer_debug_labels,
//              13,
//              list(sum:y,
//                   sum:x,
//                   sum:z,
//                   prop:y,
//                   prop:x,
//                   prop:z,
//                   der:y,
//                   der:x,
//                   der:z,
//                   integral:y,
//                   integral:x,
//                   integral:z),
//              8,
//              3).
    //return
    return -sum.
}

function release_steering {
    // Release control of the steering.
    set ship:control:neutralize to True.
}

