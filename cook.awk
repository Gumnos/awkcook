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
    printf("%s%s%s", TITLE_PRE, title, TITLE_POST)
    printf("%s%s%s", AUTHOR_PRE, author, AUTHOR_POST)
    if (length(tags)) {
        printf("%s", TAGS_PRE)
        for (i=0; i<length(tags); i++) printf("%s%s%s", TAG_PRE, tags[i], TAG_POST)
        printf("%s", TAGS_POST)
    }

#    print "All tags:"
#    for (tag in all_tags) print " - ", tag
}

function emit_section(section_number, s) {
    printf("%s%s%s", SECTION_TEXT_PRE, s, SECTION_TEXT_POST)
}

function emit_note(s) {
    # TODO
    print "NOTE: ", s
}

function emit_ingredient(s, qty, units) {
    printf("%s%s", INGREDIENT_PRE, s)
    if (qty != "") {
        printf(" (%s", qty)
        if (units != "") printf(" %s", units)
        printf(")")
    }
    printf("%s", INGREDIENT_POST)
}

function emit_timer(s, qty, units) {
    # TODO better deal with empty timer-names
    printf("%s%s", TIMER_PRE, s)
    if (qty != "") {
        printf(" (%s", qty)
        if (units != "") printf(" %s", units)
        printf(")")
    }
    printf("%s", TIMER_POST)
}

function emit_cookware(s, qty, units) {
    printf("%s%s", COOKWARE_PRE, s)
    if (qty != "") {
        printf(" (%s", qty)
        if (units != "") printf(" %s", units)
        printf(")")
    }
    printf("%s", COOKWARE_POST)
}

function emit_text(s) {
    # TODO
    printf("%s", s)
}

function emit_step(step_number, s,        left, type, rest, item, qty, units) {
    # TODO
    #print "STEP" step_number ": ", s
    rest = s
    printf("%s", STEP_PRE)
    while (match(rest, /[@#~]/)) {
        left = substr(rest, 1, RSTART-1)
        type = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART+RLENGTH)
        emit_text(left)
        qty = units = ""
        # where does it end?
        if (match(rest, /[@#~{]/)) {
            # if it terminates with a "{"
            # and there's a closing "}"
            if (substr(rest, RSTART, 1) == "{" && rest ~ /{.*}/) {
                item = substr(rest, 1, RSTART-1)
                match(rest, /{.*}/) # this should always match^
                # 2 = len("{") + len("}"):
                qty = substr(rest, RSTART+1, RLENGTH-2)
                if (qty ~ /%/) {
                    units = qty
                    sub(/^[^%]*%/, "", units)
                    sub(/%.*/, "", qty)
                }
                rest = substr(rest, RSTART+RLENGTH)
            } else { # it's just one item
                item = rest
                sub(/ .*/, "", item)
                rest = substr(rest, length(item)+1)
            }
            if (type == "@") emit_ingredient(item, qty, units)
            else if (type == "#") emit_cookware(item, qty, units)
            else if (type == "~") emit_timer(item, qty, units)
            else {
                err("unclosed {")
                break
            }
        } else {
            item = rest
            sub(/ .*/, "", item)
            rest = substr(rest, length(item)+1)
        }
    }
    emit_text(rest)
    printf("%s", STEP_POST)
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

function set_mode_plain() {
    OUTPUT_PRE = OUTPUT_POST = \
    RECIPE_PRE = RECIPE_POST = \
    FRONTMATTER_PRE = FRONTMATTER_POST = \
    TAG_POST = \
    ""

    TITLE_PRE = "Title: "
    AUTHOR_PRE = "Author: "
    TAGS_PRE = "Tags:"

    TITLE_POST = \
    AUTHOR_POST = \
    TAGS_POST = \
    "\n"
    SECTION_POST = \
    SECTION_TEXT_POST = \
    STEP_POST = \
    "\n\n"

    TAG_PRE = " "

    SECTION_PRE = \
    SECTION_TEXT_PRE = \
    STEP_PRE = \
    TEXT_PRE = \
    ""

    INGREDIENT_PRE = \
    TIMER_PRE = \
    COOKWARE_PRE = \
    "["

    INGREDIENT_POST = \
    TIMER_POST = \
    COOKWARE_POST = \
    "]"
}

function set_mode_ansi(      esc) {
    # TODO
    esc = sprintf("%c", 27)
    OUTPUT_PRE = OUTPUT_POST = \
    RECIPE_PRE = RECIPE_POST = \
    FRONTMATTER_PRE = FRONTMATTER_POST = \
    TITLE_PRE = TITLE_POST = \
    AUTHOR_PRE = AUTHOR_POST = \
    TAGS_PRE = TAGS_POST = \
    TAG_PRE = TAG_POST = \
    SECTION_PRE = SECTION_POST = \
    SECTION_TEXT_PRE = SECTION_TEXT_POST = \
    STEP_PRE = STEP_POST = \
    TEXT_PRE = TEXT_POST = \
    INGREDIENT_PRE = INGREDIENT_POST = \
    TIMER_PRE = TIMER_POST = \
    COOKWARE_PRE = COOKWARE_POST = \
    X_PRE = X_POST = \
    ""
}
function set_mode_html() {
    # TODO
    OUTPUT_PRE = OUTPUT_POST = \
    RECIPE_PRE = RECIPE_POST = \
    FRONTMATTER_PRE = FRONTMATTER_POST = \
    TITLE_PRE = TITLE_POST = \
    AUTHOR_PRE = AUTHOR_POST = \
    TAGS_PRE = TAGS_POST = \
    TAG_PRE = TAG_POST = \
    SECTION_PRE = SECTION_POST = \
    SECTION_TEXT_PRE = SECTION_TEXT_POST = \
    STEP_PRE = STEP_POST = \
    TEXT_PRE = TEXT_POST = \
    INGREDIENT_PRE = INGREDIENT_POST = \
    TIMER_PRE = TIMER_POST = \
    COOKWARE_PRE = COOKWARE_POST = \
    X_PRE = X_POST = \
    ""
}

function set_mode(mode) {
    if (mode == OUTPUT_PLAIN) set_mode_plain()
    else if (mode == OUTPUT_ANSI) set_mode_ansi()
    else if (mode == OUTPUT_HTML) set_mode_html()
}

function parse_options(options,        i) {
    for (i in options) {
        # print "Option", i, options[i]
    }
}

BEGIN {
    USER = ENVIRON["USER"]
    CMD_SHOW = cmd = "show"
    OUTPUT_PLAIN = "plain"
    OUTPUT_ANSI = "ansi"
    OUTPUT_HTML = "html"
    OUTPUT_DEFAULT = OUTPUT_PLAIN

    opt_mode = OUTPUT_DEFAULT
    for (i=1; i<ARGC; i++) {
        s = ARGV[i]
        if (s ~ /^-/) {
            options[length(options)] = s
        } else {
            if (i==1) cmd = s
            else actual_args[length(actual_args)] = s
        }
    }
    # reset the command-line arguments
    # to just the .cook files to process
    for (i=0; i<length(actual_args); i++) {
        ARGV[i+1] = actual_args[i]
    }
    ARGC = length(actual_args)+1
    parse_options(options)
    set_mode(opt_mode)
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
