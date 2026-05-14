#!/usr/bin/awk -f

# cook.awk: a rough processor for https://cooklang.org file
# author: Tim Chase
# copyright: 2026

function warn(s) {
    print "WARN:", s >> "/dev/stderr"
}
function err(s) {
    print "ERR:", s >> "/dev/stderr"
}

function rstrip(s) {
    sub(/[ \t][ \t]*$/, "", s)
    return s
}

function lstrip(s) {
    sub(/^[ \t][ \t]*/, "", s)
    return s
}

function rest_of(s) {
    # when match() finds a prefix-context
    # return the rest of the line, right-stripped
    return rstrip(substr(s, RLENGTH+1))
}

function emit_front_matter() {
    print "Title:", title
    print "Author:", author
    print "Tags:"
    for (i=0; i<length(tags); i++) print " - ", tags[i]

    print "All tags:"
    for (tag in all_tags) print " - ", tag
}

BEGIN {
    USER = ENVIRON["USER"]
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
    reading_multiline_comment = 0
    title = FILENAME
    sub(/.*\//, "", title)
    sub(/\.cook$/, "", title)
    author = USER
    delete tags
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

FNR == 1 {
    # there was no front-matter block
    # so emit the defaults
    emit_front_matter()   
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
            tag = rest_of($0)
            all_tags[tag]
            tags[length(tags)] = tag
            next
        } else reading_tags = 0
    }
    warn("Unknown front-matter: " $0)
}

match($0, /[ \t]*--/) {
    # an inline comment
    $0 = substr($0, 1, RSTART-1)
}

{
    # remove [- ... -] comments
    gsub(/\[-.*-\]/, "", $0)
}

reading_multiline_comment {

    if (match($0, /-\]/)) {
        $0 = substr($0, RSTART+RLENGTH)
        reading_multiline_comment = 0
    } else {
        next
    }
}

match($0, /\[-/) {
    # a comment
    $0 = substr($0, 1, RSTART-1)
    reading_multiline_comment = 1
}

1
