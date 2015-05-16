@lazyglobal off.

//Test the strange behavior of ship:control:rotation at launch.

lock throttle to 1.
stage.
set ship:control:rotation to v(0,1,0).
wait until maxthrust = 0. 
