#!/usr/bin/awk -f
function err(s) {
    print s >> "/dev/stderr"
}

function emit_front_matter() {
    print "Title:", title
    for (i=0; i<length(tags); i++) print "Tag:", tags[i]
}

BEGIN {
    CMD_SHOW = cmd = "show"
    for (i=1; i<ARGC; i++) {
        s = ARGV[i]
        if (i==1) cmd = s
        else if (s ~ /^-/) {
            options[length(options)] = s
        } else {
            actual_args[length(actual_args)] = s
        }
    }
    # reset the command-line arguments
    # to just the .cook files to process
    for (i=0; i<length(actual_args); i++) {
        ARGV[i+1] = actual_args[i]
    }
    ARGC = length(actual_args)+1
}

FNR == 1 {
    # reset state for a new recipe
    reading_front_matter = 0
    reading_tags = 0
    title = FILENAME
    sub(/.*\//, "", title)
    sub(/\.cook$/, "", title)
}

/^---$/ {
    if (reading_front_matter) {
        # done reading front-matter
        reading_front_matter = 0
        emit_front_matter()
        next
    } else if (FNR == 1) {
        reading_front_matter = 1
        next
    } else {
        err("Unexpected '---' in " FILENAME " line " FNR)
        nextfile
    }
}

reading_front_matter {
    # TODO: parse the front-matter into known notes
    if (match($0, /^title: */)) {
        title = substr($0, RLENGTH+1)
    } else if (match($0, /^tags:$/)) {
        reading_tags = 1
    } else if (reading_tags) {
        if (match($0, /^[ \t][ \t]*-[ \t]*/)) {
            tags[length(tags)] = substr($0, RLENGTH+1)
        } else reading_tags = 0
    }
}
