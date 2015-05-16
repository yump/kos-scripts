run libpilot2.

goodsteer_init(0, 0, 0.15).
wait 0.1.

local t_print is time:seconds + 1.

global cycles is 0.
global steer is ship:facing.
global steer_enbl is true.
when true then {
    if steer_enbl {
        set ship:control:rotation to goodsteer(steer).
    } else {
        set ship:control:neutralize to true.
    }
    set cycles to cycles + 1.
    preserve.
}

until false {
    if ship:control:pilotrotation:mag > 0 {
        set steer_enbl to false.
    } else {
        set steer to ship:facing.
        set steer_enbl to true.
    }
    if time:seconds > t_print {
        print cycles + " cycles per second".
        set cycles to 0.
        set t_print to t_print + 1.
    }
    wait 0.
}
