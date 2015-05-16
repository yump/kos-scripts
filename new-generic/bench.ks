@lazyglobal off.

run libutil.
run liblaunch.
run libpilot.
run libprint.

atmopitch_init(0.5,   //Sqrt worked before
               10000, //45° at 10km
               3,     //3° aoa limit max 
               0.5).  //0.5°/s aoa limit shaping

goodsteer_init(0.100, 0.005, 0.050).

local win1 is infoprint_alloc("I have 5 lines",
                              list("a label",
                                   "another label",
                                   "what",
                                   "really",
                                   "more?"),
                              13,
                              8,
                              2).
local win2 is infoprint_alloc("I have 5 lines",
                              list("a label",
                                   "another label",
                                   "what",
                                   "really",
                                   "more?"),
                              13,
                              8,
                              2).
local win3 is infoprint_alloc("I have 5 lines",
                              list("a label",
                                   "another label",
                                   "what",
                                   "really",
                                   "more?"),
                              13,
                              8,
                              2).

local oldprint_labels is list("shit 1", "shit 2").

local ang is 123.
local out is 0.
local vec is v(0,0,0).
local somedir is ship:facing.
local mylist is list().

global n is 0.
global k is 0. //apparently, using i interferes with loops in fuctions using i.

set n to 100.
set k to n.   
local t_start is time:seconds.
until k <= 0 {
    //infoprint_update(win1, list(1,2,3,4,5)).
    //infoprint_redraw_labels().
    infoprint_redraw_data().
    //infoprint(oldprint_labels, 6, list(1,2), 8, 2).
    //nspaces(7).
    //wait 0.
    //set ship:control:rotation to goodsteer(somedir).
    set k to k - 1.
}
local elapsed is time:seconds - t_start.
local phys_tics_per_second is 50.
print "cycles: " + (elapsed / n * phys_tics_per_second * config:ipu - 12).
