#!/usr/bin/awk -f
function warn(s) {
    print "WARN:", s >> "/dev/stderr"
}
function err(s) {
    print "ERR:", s >> "/dev/stderr"
}

function rest_of(s) {
    # when match() finds a prefix-context
    # return the rest of the line, right-stripped
    sub(/[ \t][ \t]*$/, "", s)
    return substr(s, RLENGTH+1)
}

function emit_front_matter() {
    print "Title:", title
    print "Author:", author
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
    author = ENVIRON["USER"]
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
    if (match($0, /^title: */)) {
        title = rest_of($0)
        next
    } else if (match($0, /^author: */)) {
        author = rest_of($0)
        next
    } else if (match($0, /^tags:$/)) {
        reading_tags = 1
        next
    } else if (reading_tags) {
        if (match($0, /^[ \t][ \t]*-[ \t]*/)) {
            tags[length(tags)] = rest_of($0)
            next
        } else reading_tags = 0
    }
    warn("Unknown front-matter: " $0)
}
