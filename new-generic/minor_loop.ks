@lazyglobal off.

run libpilot2.

function nullfun {
    parameter x.
    return true.
}

global cycles is 0.
global somerot is ship:facing.
when true then {
    rot_to_vec(somerot).
    set cycles to cycles + 1.
    preserve.
}

local t_print is time:seconds + 1.
until false {
    print cycles + " cycles per second".
    set cycles to 0.
    set t_print to t_print + 1.
    wait t_print - time:seconds.
}

