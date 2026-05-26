# a cooklang formatter in `awk`

## what is cooklang?

The [cooklang spec](https://cooklang.org/docs/spec/)
defines a language for marking up plain-text recipes.

## what is this abomination?

This utility reformats the input files for display
in simple formatted plain-text, ANSI VT100 color,
and HTML output.

## how do I use this abomination?

Invoke the program with one or more `.cook` files:

    $ awk -f cook.awk my_recipe.cook my_sauce.cook

or, if you have marked it as executable,

    $ ./cook.awk my_recipe.cook my_sauce.cook

## why?

Why not?

## okay, how do I use it

You can either invoke it with `awk` using ANSI output

    $ awk -f cook.awk my_recipe.cook

or to get a plaintext version:

    $ awk -f -- --plain cook.awk my_recipe.cook other_recipe.cook

or it will emit an HTML fragment suitable for inclusion in other HTML:

    $ awk -f -- --html cook.awk *.cook > recipes.html

If you want to page through the ANSI output,
you can use `less -R` as your `$PAGER`

    $ awk -f cook.awk my_recipe.cook | less -R
