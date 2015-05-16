run libpilot.

goodsteer_init(0, 0, 0.05).
wait 0.1.

global cycles is 0.
local t_print is time:seconds + 1.

local fb_control is v(0,0,0).

until false {
    set fb_control to goodsteer(ship:facing).
    set cycles to cycles + 1.
    if ship:control:pilotrotation:mag > 0 {
        set ship:control:rotation to ship:control:pilotrotation.
    } else {
        set ship:control:rotation to fb_control.
    }
    if time:seconds > t_print {
        print cycles + " cycles per second".
        set cycles to 0.
        set t_print to t_print + 1.
    }
    wait 0.
}
