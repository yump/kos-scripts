log "alt,temp,pres" to "atmodata.log".

set last to 70000.
set step to 10.
until altitude <10 {
	if altitude <= last {
		log altitude + ","  + ship:sensors:temp + "," + ship:sensors:pres to "atmodata.log".
		set last to last - step.
	}
}
