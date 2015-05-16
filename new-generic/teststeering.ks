run libpilot.

SAS off.

print "Initializing facing to heading(80,0).".
lock steering to heading(80,0).
wait 10.
unlock steering.

goodsteer_init(0.03, 0.00, 0.02).
wait 0.1.
local cycles is 0.
local t_print is time:seconds + 1.
print "Steering to up".
until false {
    set ship:control:rotation to goodsteer(up).
    set cycles to cycles + 1.
    if time:seconds > t_print {
        print cycles + " cycles per second" at(20,20).
        set cycles to 0.
        set t_print to t_print + 1.
    }
    wait 0.
}

