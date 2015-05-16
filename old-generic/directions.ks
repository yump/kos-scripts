set dir to lookdirup(heading(90,90):vector,facing:topvector).

set uparrow to vecdraw().
set uparrow:vec to dir:vector.
set uparrow:show to true.
set uparrow:color to RGB(255,0,0).
set uparrow:scale to 10.

set uptop to vecdraw().
set uptop:vec to dir:topvector.
set uptop:show to true.
set uptop:color to RGB(0,255,255).
set uptop:scale to 10.
