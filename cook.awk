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

function emit_front_matter(        i, tag) {
    print "=============START OF RECIPE======================"
    print "Title:", title
    print "Author:", author
    print "Tags:"
    for (i=0; i<length(tags); i++) print " - ", tags[i]

    print "All tags:"
    for (tag in all_tags) print " - ", tag
}

function emit_section(section_number, s) {
    # TODO
    print "SECTION" section_number ": ", s
}

function emit_note(s) {
    # TODO
    print "NOTE: ", s
}

function emit_step(step_number, s) {
    # TODO
    print "STEP" step_number ": ", s
}

function end_recipe(        s, i, step_number, section_number) {
    for (i=1; i<=block_number; i++) {
        s = blocks[i]
        if (s ~ /^=/) {
            sub(/^==*[ \t]*/, "", s)
            sub(/[ \t*]=*$/, "", s)
            emit_section(++section_number, s)
        } else if (match(s, /^>[ \t*]/)) {
            emit_note(rest_of(s))
        } else {
            emit_step(++step_number, s)
        }
    }
    print "=============END OF RECIPE========================"
}

function parse_options(options) {
    # TODO
}

BEGIN {
    USER = ENVIRON["USER"]
    CMD_SHOW = cmd = "show"
    MODE_PLAIN = "plain"
    MODE_ANSI = "ansi"
    MODE_HTML = "html"
    MODE_DEFAULT = MODE_ANSI

    opt_mode = MODE_DEFAULT
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
    parse_options(options)
}

FNR == 1 {
    if (FNR != NR) end_recipe()
    # reset state for a new recipe
    reading_front_matter = 0
    reading_tags = 0
    reading_multiline_comment = 0
    block_number = 1
    reading_block = 1
    title = FILENAME
    sub(/.*\//, "", title)
    sub(/\.cook$/, "", title)
    author = USER
    delete cookware
    delete ingredients
    delete tags
    delete blocks # each block encountered, whether section or step
    delete section_indexes # [i] = blocks[n] for section blocks
    delete section_names # [i] = name for section blocks
    delete steps_indexes # [i] = blocks[n] for step blocks
    delete steps_content # [i] = content for step blocks
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
        $0 = substr($0, RSTART+RLENGTH+1)
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

/^$/ {
    if (blocks[block_number]) ++block_number
    next
}

{
    # convert a trailing backslash into a newline
    sub(/\\$/, "\n", $0)
    blocks[block_number] = blocks[block_number] ( \
        blocks[block_number] && !(blocks[block_number] ~ /\n$/) ? " " :"" \
        ) $0
}

END {
    end_recipe()
}
