@lazyglobal off.

function recurse {
    parameter n.
    if n > 0 {
        recurse(n - 1).
    }
}

local t_start is time:seconds.

recurse(200).

local elapsed is time:seconds - t_start.

print "Elapsed time: " + elapsed + " seconds".
print elapsed*50*config:ipu + " cycles.".
