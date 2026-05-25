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

function emit_front_matter(        i, field, tag) {
    printf("%s", FRONTMATTER_PRE)
    # emit them in preference-order
    for (i=1; i<=length(expected_metadata_priorities); i++) {
        field = expected_metadata_priorities[i]
        if (field in metadata) {
            printf("%s%s%s%s%s%s", \
                METADATALABEL_PRE, field, METADATALABEL_POST, \
                METADATA_PRE, metadata[field], METADATA_POST)
        }
    }
    if (length(tags)) {
        printf("%s", TAGS_PRE)
        for (i=0; i<length(tags); i++) printf("%s%s%s", TAG_PRE, tags[i], TAG_POST)
        printf("%s", TAGS_POST)
    }

#    print "All tags:"
#    for (tag in all_tags) print " - ", tag
    printf("%s", FRONTMATTER_POST)
}

function emit_section(section_number, s) {
    printf("%s%s%s", SECTION_TEXT_PRE, s, SECTION_TEXT_POST)
}

function emit_note(s) {
    # TODO
    print "NOTE: ", s
}

function emit_ingredient(s, qty, units,        i, output, found) {
    printf("%s", INGREDIENT_INLINE_PRE)
    output = s
    if (qty != "") {
        output = output " (" qty
        if (units != "") output = output sprintf(" %s", units)
        output = output ")"
    }
    found = 0
    for (i in ingredients) {
        if (found = (ingredients[i] == output)) break
    }
    if (!found) ingredients[length(ingredients)] = output
    printf("%s", output)
    printf("%s", INGREDIENT_INLINE_POST)
}

function emit_timer(s, qty, units) {
    printf("%s", TIMER_PRE)
    if (s != "") {
        printf("%s (", s)
    }
    if (qty != "") {
        printf("%s", qty)
        if (units != "") printf(" %s", units)
    }
    if (s != "") {
        printf(")")
    }
    printf("%s", TIMER_POST)
}

function emit_cookware(s, qty, units,        i, output, found) {
    printf("%s", COOKWARE_ITEM_PRE)
    output = s
    if (qty != "") {
        output = output " (" qty
        if (units != "") output = output sprintf(" %s", units)
        output = output ")"
    }
    found = 0
    for (i in cookware) {
        if (found = (cookware[i] == output)) break
    }
    if (!found) cookware[length(cookware)] = output
    printf("%s", output)
    printf("%s", COOKWARE_ITEM_POST)
}

function emit_text(s) {
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
                match(rest, /{[^}]*}/) # this should always match^
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
            if (type == "@") emit_ingredient(item, qty, units)
            else if (type == "#") emit_cookware(item, qty, units)
            else if (type == "~") emit_timer(item, qty, units)
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
            step_number = 0 # reset step-number per section
        } else if (match(s, /^>[ \t*]/)) {
            emit_note(rest_of(s))
        } else {
            emit_step(++step_number, s)
        }
    }
    if (length(ingredients)) {
        printf("%s", INGREDIENT_LIST_PRE)
        for (i=0; i<length(ingredients); i++) {
            printf("%s%s%s", INGREDIENT_PRE, ingredients[i] , INGREDIENT_POST)
        }
        printf("%s", INGREDIENT_LIST_POST)
    }
    if (length(cookware)) {
        printf("%s", COOKWARE_LIST_PRE)
        for (i=0; i<length(cookware); i++) {
            printf("%s%s%s", COOKWARE_PRE, cookware[i], COOKWARE_POST)
        }
        printf("%s", COOKWARE_LIST_POST)
    }
    printf("%s", RECIPE_POST)
}

function set_mode_plain() {
    OUTPUT_PRE = OUTPUT_POST = \
    RECIPE_PRE = RECIPE_POST = \
    FRONTMATTER_PRE = \
    METADATALABEL_PRE = \
    METADATA_PRE = \
    TAG_POST = \
    ""

    TAGS_PRE = "TAGS:"
    INGREDIENT_LIST_PRE = "Ingredients:\n"
    COOKWARE_LIST_PRE = "Cookware:\n"
    METADATALABEL_POST = ": "

    FRONTMATTER_POST = \
    METADATA_POST = \
    TAGS_POST = \
    INGREDIENT_LIST_POST = \
    INGREDIENT_POST = \
    COOKWARE_LIST_POST = \
    COOKWARE_POST = \
    INGREDIENT_LIST_POST = \
    SECTION_POST = \
    SECTION_TEXT_POST = \
    STEP_POST = \
    "\n"

    TAG_PRE = " "

    SECTION_PRE = \
    SECTION_TEXT_PRE = \
    STEP_PRE = \
    TEXT_PRE = \
    ""

    COOKWARE_PRE = \
    INGREDIENT_PRE = \
    " - "

    INGREDIENT_INLINE_PRE = \
    TIMER_PRE = \
    COOKWARE_ITEM_PRE = \
    "["

    INGREDIENT_INLINE_POST = \
    TIMER_POST = \
    COOKWARE_ITEM_POST = \
    "]"
}

function set_mode_ansi(      CSI,\
        RED, GREEN, BLUE, \
        YELLOW, CYAN, MAGENTA, \
        BRIGHT_RED, BRIGHT_GREEN, BRIGHT_BLUE, \
        BRIGHT_YELLOW, BRIGHT_CYAN, BRIGHT_MAGENTA, \
        WHITE, BRIGHT_WHITE, NORMAL) {
    # define constants
    CSI = sprintf("%c[", 27)
    NORMAL = CSI "0m"
    RED = CSI "31m"     ; BRIGHT_RED = CSI "1;31m"
    GREEN = CSI "32m"   ; BRIGHT_GREEN = CSI "1;32m"
    YELLOW = CSI "33m"  ; BRIGHT_YELLOW = CSI "1;33m"
    BLUE = CSI "34m"    ; BRIGHT_BLUE = CSI "1;34m"
    MAGENTA = CSI "35m" ; BRIGHT_MAGENTA = CSI "1;35m"
    CYAN = CSI "36m"    ; BRIGHT_CYAN = CSI "1;36m"
    WHITE = CSI "37m"   ; BRIGHT_WHITE = CSI "1;37m"

    set_mode_plain() # get defaults
#    OUTPUT_PRE = WHITE OUTPUT_PRE
#    OUTPUT_POST = OUTPUT_POST NORMAL
#    RECIPE_PRE = WHITE RECIPE_PRE
#    RECIPE_POST = RECIPE_POST NORMAL
#    FRONTMATTER_PRE = WHITE FRONTMATTER_PRE
#    FRONTMATTER_POST = FRONTMATTER_POST NORMAL
    METADATALABEL_PRE = BRIGHT_BLUE METADATALABEL_PRE
    METADATALABEL_POST = METADATALABEL_POST NORMAL
    METADATA_PRE = WHITE METADATA_PRE
    METADATA_POST = METADATA_POST NORMAL
    TAGS_PRE = BRIGHT_BLUE TAGS_PRE NORMAL
#    TAGS_POST = TAGS_POST NORMAL
#    TAG_PRE = WHITE TAG_PRE
#    TAG_POST = TAG_POST NORMAL
#    SECTION_PRE = WHITE SECTION_PRE
#    SECTION_POST = SECTION_POST NORMAL
    SECTION_TEXT_PRE = BRIGHT_WHITE SECTION_TEXT_PRE
    SECTION_TEXT_POST = SECTION_TEXT_POST NORMAL
#    STEP_PRE = WHITE STEP_PRE
#    STEP_POST = STEP_POST NORMAL
#    TEXT_PRE = WHITE TEXT_PRE
#    TEXT_POST = TEXT_POST NORMAL
    INGREDIENT_LIST_PRE = BRIGHT_WHITE INGREDIENT_LIST_PRE NORMAL
#    INGREDIENT_LIST_POST = INGREDIENT_LIST_POST
    INGREDIENT_PRE = INGREDIENT_PRE CYAN
    INGREDIENT_POST = NORMAL INGREDIENT_POST
    INGREDIENT_INLINE_PRE = BRIGHT_CYAN
    INGREDIENT_INLINE_POST = NORMAL
    TIMER_PRE = BRIGHT_YELLOW
    TIMER_POST = NORMAL
    COOKWARE_ITEM_PRE = BRIGHT_GREEN
    COOKWARE_ITEM_POST = NORMAL
    COOKWARE_LIST_PRE = BRIGHT_WHITE COOKWARE_LIST_PRE NORMAL
    COOKWARE_PRE = COOKWARE_PRE BRIGHT_GREEN
    COOKWARE_POST = NORMAL COOKWARE_POST
#    COOKWARE_LIST_POST = COOKWARE_LIST_POST
}

function set_mode_html() {
    # TODO
    OUTPUT_PRE = OUTPUT_POST = \
    RECIPE_PRE = RECIPE_POST = \
    FRONTMATTER_PRE = FRONTMATTER_POST = \
    METADATALABEL_PRE = METADATALABEL_POST = \
    METADATA_PRE = METADATA_POST = \
    TAGS_PRE = TAGS_POST = \
    TAG_PRE = TAG_POST = \
    SECTION_PRE = SECTION_POST = \
    SECTION_TEXT_PRE = SECTION_TEXT_POST = \
    STEP_PRE = STEP_POST = \
    TEXT_PRE = TEXT_POST = \
    INGREDIENT_LIST_PRE = INGREDIENT_LIST_POST = \
    INGREDIENT_PRE = INGREDIENT_POST = \
    INGREDIENT_INLINE_PRE = INGREDIENT_INLINE_POST = \
    COOKWARE_ITEM_PRE = COOKWARE_ITEM_POST = \
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
    OUTPUT_DEFAULT = OUTPUT_ANSI

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

    # known metadata
    split( \
        "TITLE AUTHOR SERVINGS SERVES YIELD "\
        "COURSE TIME DURATION PREP COOK "\
        "DIFFICULTY CUISINE CATEGORY DIET IMAGE "\
        "LOCALE SOURCE INTRODUCTION DESCRIPTION "\
        , expected_metadata_priorities)
    for (i=1; i<length(expected_metadata_priorities); i++) {
        expected_metadata[expected_metadata_priorities[i]]
    }
}

FNR == 1 {
    if (FILENAME in seen) nextfile
    seen[FILENAME]
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
    delete metadata
    metadata["TITLE"] = title
    metadata["AUTHOR"] = USER

    delete cookware # [i] = cookware
    delete cookware_qty # [cookware, cookware_qty[cookware, 0]] = qty
    delete cookware_units # [cookware, cookware[cookware, 0]] = units

    delete ingredients # [i] = ingredient
    delete ingredients_qty # [ingredient, ingredient_qty[ingredient, 0]] = qty
    delete ingredients_units # [ingredient, ingredient[ingredient, 0]] = units

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
    uc = toupper($0)
    if (match(uc, /^TAGS:$/)) {
        reading_tags = 1
        next
    } else if (reading_tags) {
        if (match(uc, /^[ \t][ \t]*-[ \t]*/)) {
            tag = rest_of($0)
            all_tags[tag]
            tags[length(tags)] = tag
            next
        } else reading_tags = 0
    } else {
        if (match(uc, /^[A-Z][A-Z]*: */)) {
            field = substr(uc, 1, RLENGTH-2)
            if (field in expected_metadata) {
                metadata[field] = rest_of($0)
            }
            next
        } else warn("Unknown front-matter: " $0)
    }
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

/@\.*\/[^@#~{]*{.*}/ {
    # we have an included file
    s = $0
    while (match(s, /@\.*\/[^@#~{]*{/)) {
        path = substr(s, RSTART+1, RLENGTH-2)
        s = substr(s, RSTART+RLENGTH+1)
        # have we already enqueued this sub-recipe?
        found = 0
        for (i=1; i<ARGC; i++) {
            if (found = (ARGV[i] == path)) break
        }
        if (!found) {
            ARGV[ARGC++] = path
        }
    }
}

END {
    end_recipe()
}
