@lazyglobal off.
run libprint.

global last_stage_time is 0.
global atmopitch_state is list(0.5,
                            10000,
                            3,
                            0.5,
                            time:seconds - 1,
                            3).

function extend_panels {
    //extend all extenable solar panels.
    for part in ship:parts {
        if part:modules:contains("ModuleDeployableSolarPanel") {
            local mod is part:getmodule("ModuleDeployableSolarPanel").
            if mod:hasevent("extend panels") {
                mod:doevent("extend panels").
            }
        }
    }
}

function activate_antennas {
    // Activate all RemoteTech antennas.
    for part in ship:parts {
        if part:modules:contains("ModuleRTAntenna") {
            local mod is part:getmodule("ModuleRTAntenna").
            if mod:hasevent("activate") {
                mod:doevent("activate").
            }
        }
    }
}

function jettison_fairings {
    for part in ship:parts {
        if part:modules:contains("ProceduralFairingDecoupler") {
            local mod is part:getmodule("ProceduralFairingDecoupler").
            if mod:hasevent("jettison") {
                mod:doevent("jettison").
            }
        }
    }
}

function simple_staging {
    // Simple function for staging, that should work most of the time.
    // Handle basic engines and separable boosters
    local needstage is false.
    local engs is 0.
    list engines in engs.
    for eng in engs {
        if eng:flameout and eng:name <> "sepMotor1" {
            print "Stage flameout at t=" + T.
            set needstage to true.
        }
    }
    //Handle asparagus staging
    for line in ship:partsnamed("fuelLine") {
        //Fuel lines are children of the source tank
        if line:parent:mass = line:parent:drymass {
            // Tanks that aren't attached by decouplers probably aren't 
            // part of an aspergas or drop tank scheme.
            if line:parent:parent:modules:contains("ModuleDecouple") {
                print "Stage asparagus at t=" + T.
                set needstage to true.
            }
        } 
    }
    if needstage {
        stage.
    }
    until maxthrust > 0 {
        stage.
    }
}
    

function jettison_expended_parts {
    // Jettison everything that ought to be jettisoned.
    // Really slow, do not use.
    subtree_empty_check(ship:rootpart).
}

function subtree_empty_check {
    // FOR INTERNAL USE ONLY
    // Turns out this is REALLY SLOW. Don't use it. O(n), but n is huge.  Like,
    // 335 cycles on a ship with 3 parts.
    // Recursively visit node in part tree, report if container and if empty, 
    // and jettison if applicable.
    parameter part.
    // Tag for indicating RO SRBs and propulsive landing boosters.
    local empty_frac is 0.
    if part:tag = "empty_at_5" {
        set empty_frac to 0.05.
    }
    local resource_mass is part:wetmass - part:drymass.
    local is_decoupler is part:modules:contains("ModuleDecouple").
    local is_container is part:wetmass <> part:drymass.
    // Part is empty if the current mass is less than the dry mass plus the
    // residual at burnout (usually zero, potentially nonzero for flyback
    // boosters or SRBs in realism overhaul). Decouplers are always "empty", so
    // we know they can safely be detached.
    local is_empty is is_decoupler 
        or (part:mass <= part:drymass + empty_frac*resource_mass).
    // Good old recursive traversal. Subtree is empty if the root and all its
    // child subtrees are empty. Subtree is a container if any of its subtrees
    // are containers.
    for child in part:children {
        local child_result is subtree_empty_check(child).
        set is_container to is_container or child_result[0].
        set is_empty to is_empty and child_result[1].
    }
    // Discard empty container subtrees.
    if is_container and is_empty and is_decoupler {
        local mod is part:getmodule("ModuleDecouple").
        if mod:hasevent("decouple") {
            print "Jettisoning " + part:children[0] + " and children.".
            set last_stage_time to time:seconds.
            mod:doevent("decouple").
        }
    }
    return list(is_container, is_empty).
}

function atmopitch_init {
    // Init for atmospheric pitch program. Pitchover angle from vertical is:
    //            45° * (altitude/forty_five_alt)^exponent
    // Commanded pitch is vertical below 50 m/s. Note that the commanded pitch
    // will be horizontal at forty_five_alt*2^(1/exponent). For the default
    // config, 0.5 and 10km, that's 40km.
    // aoa_limit and ramp control the system for limiting the angle of attack.
    // aoa_limit is the maximum limit, and ramp is the rate at which to decrease
    // or increase the limit in order to keep the amount of control authority
    // used in between 10 and 30 percent. Units are degrees/second.
    parameter exponent.
    parameter forty_five_alt.
    parameter aoa_limit.
    parameter ramp.
    local aoa_limit_max is aoa_limit.
    set atmopitch_state to list(exponent,
                                forty_five_alt,
                                aoa_limit_max,
                                ramp,
                                time:seconds - 1,
                                aoa_limit).
}

function atmopitch_update {
    // Update cycle for atmospheric pitch program.
    // Unpack state.
    local exponent is atmopitch_state[0].
    local forty_five_alt is atmopitch_state[1].
    local aoa_limit_max is atmopitch_state[2].
    local ramp_rate is atmopitch_state[3].
    local lastcycle_time is atmopitch_state[4].
    local aoa_limit is atmopitch_state[5].
    // Grab the time.
    local curtime is time:seconds.
    local elapsed is curtime - lastcycle_time.
    // Calculate ideal pitch and flight path angle.
    local targ_pitch is 45*(altitude/forty_five_alt)^exponent.
    local flight_path_angle is vang(ship:velocity:surface, up:vector).    
    // Update angle of attack / sideslip limit.
    local authority_used is abs(ship:control:pitch).
    local aoa is vang(facing:vector, srfprograde:vector).
    if abs(targ_pitch - flight_path_angle) >= 0.9*aoa_limit { //limit is in play
        if authority_used < 0.1 {
            set aoa_limit to aoa_limit + ramp_rate*elapsed.
        } else if authority_used > 0.3 { //Whoa, Nelly!
            set aoa_limit to aoa_limit - ramp_rate*elapsed.
        }
    }
    // Near staging events, we should be very fucking careful, because the new
    // configuration of the rocket might have less control authority.
    local time_to_stage is time_in_stage_now().
    if time_to_stage < 4 or abs(curtime - last_stage_time) < 2 {
        set aoa_limit to 0.
    }
    // Clamp the aoa_limit.
    set aoa_limit to min(aoa_limit_max, max(0, aoa_limit)).
    // Limit pitch.
    local limited is min(flight_path_angle + aoa_limit,
                         max(flight_path_angle - aoa_limit,
                         targ_pitch)).
    // Debug info
    infoprint(list("aoa_limit", "authority", "relpitch", "timeleft", "aoa"),
              9,
              list(aoa_limit,
                  authority_used,
                  flight_path_angle - limited,
                  time_to_stage,
                  aoa),
              8,
              3).
    // Update state.
    set atmopitch_state[4] to curtime.
    set atmopitch_state[5] to aoa_limit.
    // Convert to pitch above horizontal, as used by heading().
    return 90 - limited.
}
    
