//circularization burn calc
set mu to ship:body:mu.
set rad to ship:body:radius.
set circ_v to sqrt(mu/(apoapsis+rad)).
set apo_v to sqrt( mu*( 2/(apoapsis+rad) - 1/ship:obt:semimajoraxis ) ).
set circ_burn to node(time:seconds + eta:apoapsis, 0, 0, circ_v - apo_v).
add circ_burn.
print round(circ_burn:deltav:mag,2) + " m/s to circularize".
//circularize
run execute.
//remove circ_burn
