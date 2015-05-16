@lazyglobal off.

global infoprint_windows is list().  // List of lists containing state.

//Rate lmiting.
global infoprint_next_print is 0.

function nspaces {
    //get a string containing n spaces.  Probably O(n^2).
    parameter n.
    local str is "".
    until n = 0 {
        set str to str + " ".
        set n to n - 1.
    }
    return str.
}

function infoprint_alloc {
    // Get an integer handle to use with infoprint_update().
    parameter title.       // Title
    parameter labels.      // List of labels
    parameter label_width. // Lenghth of the longest label
    parameter data_width.  // Space to use for the data
    parameter decimals.    // Number of decimal points to round to
    // Cached string for erasing.
    local erase_str is nspaces(data_width).
    // Initial data values.
    local data is list().
    local i is 0.
    until i >= labels:length {
        data:add(0).
        set i to i+1.
    }
    // Create and store the window object.
    local win is list(true,          // 0 Window visible
                      title,         // 1 Window title
                      labels,        // 2 List of labels
                      label_width,   // 3 Width of longest label
                      data,          // 4 List of data values
                      data_width,    // 5 Width of data column
                      decimals,      // 6 Number of places to round
                      erase_str).    // 7 Data erasing string
    infoprint_windows:add(win).
    infoprint_redraw_labels().
    return infoprint_windows:length - 1.  //index of the end.
}

function infoprint_redraw_labels {
    // INTERNAL.  Draw the window titles and labels in the terminal
    // Find the maximum width.
    local maxwidth is 0.
    for win in infoprint_windows {
        set maxwidth to max(maxwidth, win[3] + win[5] + 3).
    }
    // Blank the whole column
    local blanker is nspaces(maxwidth-1).
    local colbegin is terminal:width - maxwidth.
    local i is 0.
    until i >= terminal:height {
        print blanker at(colbegin, i).
        set i to i + 1.
    }
    // Draw the windows and labels.
    local cursor is 1.  //start 1 from the top.
    for win in infoprint_windows {
        if win[0] {  //if window visible
            //print the title
            print win[1] at(colbegin + 3, cursor).
            set cursor to cursor + 1.
            //print the labels and " = " symbols.
            for label in win[2] {
                print label at(colbegin, cursor).
                print " = " at(terminal:width - win[5] - 3, cursor).
                set cursor to cursor + 1.
            }
            set cursor to cursor + 1.  //Blank line seperator
        }
    }
    if cursor >= terminal:height {
        print "WARNING: TERMINAL TOO SMALL FOR INFOPRINT WINDOWS".
    }
}

function infoprint_redraw_data {
    // Redraw the data for all windows.  Should be called in major cycle.
    local cursor is 1.
    for win in infoprint_windows {
        if win[0] { //if window visible
            set cursor to cursor + 1. //title line
            for datum in win[4] {
                local datastart is terminal:width - win[5].
                print win[7] at(datastart, cursor). //blank data area
                print round(datum, win[6]) at(datastart, cursor).
                set cursor to cursor + 1.
            }
            set cursor to cursor + 1. //blank line seperator
        }
    }
}
            

function infoprint_update {
    // Send data to your infoprint window
    parameter win_handle.
    parameter data.
    set infoprint_windows[win_handle][4] to data.
}
    
function infoprint_hide {
    // Hide your infoprint window
    parameter win_handle.
    set infoprint_windows[0] to false.
}

function infoprint_show {
    // Show your infoprint window
    parameter win_handle.
    set infoprint_windows[0] to true.
}    
    

function infoprint {
    //print an info box in the top right.
    parameter labels.     //list of field names, padded to same length.
    parameter label_len.  //label length, without padding.
    parameter data.       //list of numeric data
    parameter data_len.   //amount of space to use for data
    parameter decimals.   //number of decimal places to keep.
    if time:seconds > infoprint_next_print {
        if labels:length <> data:length {
            print "INFOPRINT ERROR: labels and data must be same length".
        }
        local xbegin is terminal:width - data_len - label_len - 3.
        local ybegin is 3.
        local i is 0.
        until i = labels:length {
            print labels[i] + " = " + nspaces(data_len) at(xbegin, ybegin + i).
            print round(data[i],decimals) at(xbegin+label_len + 3, ybegin + i).
            set i to i + 1.
        }
        set infoprint_next_print to time:seconds + 0.2.
    }
}
        

