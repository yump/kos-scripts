@lazyglobal off.

run libprint.

//clearscreen.

local win1 is infoprint_alloc("I have 2 lines",
                              list("a label", "another label"),
                              13,
                              8,
                              2).

local win2 is infoprint_alloc("I have 3 lines",
                              list("a label", "another label", "wait more?"),
                              13,
                              8,
                              2).

print infoprint_windows.

local next_major_cycle is time:seconds.

until false {
    infoprint_update(win1, list(random(), random())).
    infoprint_update(win2, list(random(), random(), random())).
    if time:seconds >= next_major_cycle {
        set next_major_cycle to next_major_cycle + 1.
        infoprint_redraw_data().
    }
    wait 0.
}
