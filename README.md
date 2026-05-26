# a cooklang formatter in `awk`

## What is cooklang?

The [cooklang spec](https://cooklang.org/docs/spec/)
defines a language for marking up plain-text recipes.

## What is this abomination?

This utility reformats the input files for display
in simple formatted plain-text, ANSI VT100 color,
and HTML output.

## How do I use this abomination?

Invoke the program with one or more `.cook` files:

    $ awk -f cook.awk my_recipe.cook my_sauce.cook

or, if you have marked it as executable,

    $ ./cook.awk my_recipe.cook my_sauce.cook

For ANSI colorized output:

    $ awk -f -- --ansi cook.awk my_recipe.cook other_recipe.cook

Note the `--` required to tell `awk`
that the following options are for the script,
not for `awk` itself.

If you want to page through the ANSI output,
you can use `less -R` as your `$PAGER`

    $ awk -f cook.awk -- --ansi my_recipe.cook | less -R

Alternatively, it can emit an HTML fragment suitable for inclusion in other HTML:

    $ awk -f -- --html cook.awk *.cook > recipes.html

## Why?

Why not?
