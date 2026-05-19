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
