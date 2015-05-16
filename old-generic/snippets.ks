// Clocked background loop
set clock_period to 0.1.
set next_clock to 0.
when time:seconds >= next_clock then {
    //do stuff
    set next_clock to time:seconds + clock_period. preserve. //re-arm
}

//test if part "p" is a decoupler.
// **UNTESTED**
set is_decoupler to false.
for mod in p:modules {
    if getmodule(mod):hasevent("decouple") { 
        set is_decoupler to true.
        break. 
    }
}

//Find the Isp and mass loss rate for all the currently active engines.
set totfuel_Mg_s to 0.
set totthrust_kN to 0.
set g0 to 9.82.
list engines in engs.
for eng in engs {
    if eng:ignition and not eng:flameout { //engine will contribute
        set totthrust_kN to totthrust_kN + eng:maxthrust.
        set totfuel_Mg_s to totfuel_Mg_s + eng:maxthrust/(g0*eng:isp).
    }
}
set totisp_m_s to totthrust_kN/totfuel_Mg_s.


//PID

//gains
set ki to 0.1.
set kp to 1.
set kd to 0.
//info printing interval
set infoprint_interval to 1.
//state
set int to 1.
set diff to 0.
set lasttime to time:seconds - 0.1. //prevent divide-by-zero problems at start.
set lasterr to 0.
set infoprint_in to 0.
//Error and output signals
lock err to setpoint - current.
lock pidout to int + kp*err + kd*diff.
lock throttle to min(1,max(0, pidout )).
//sample rate gain invariance
lock dt to time:seconds - lasttime.
//loop
until endcondition {
    //math
    set int to int + ki*err*dt.
    set int to min(1.1,max(-0.1,int)).  //avoid saturation problems
    set diff to (err - lasterr)/dt.
    set lasterr to err.
    //infoprinting
    if infoprint_in <=0 {
        set errinfo to "err=" + round(err,2).
        set intinfo to " int=" + round(int,2).
        set dinfo to " d=" + round(kd*diff,2).
        print errinfo + intinfo + dinfo at(20,34).
        set infoprint_in to infoprint_interval.
    }
    set infoprint_in to infoprint_in - dt.
    set lasttime to time:seconds.
    wait 0.1.
}
