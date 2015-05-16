run libprint.

local labels is list("shor lbl             ",
                     "a long label         ",
                     "another just for show").
local label_len is 21.
local data is list(0.2314, 12.1245412315, 564312).
local data_len is 8.
local decimals is 2.

local t_start is time:seconds.
infoprint(labels,label_len,data,data_len,decimals).
local elapsed is time:seconds - t_start.
print "Elapsed ms: " + elapsed * 1000.
