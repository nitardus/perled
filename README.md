PERLED
=====

This project tries to implement an clone of the UNIX standard text
editor in less than 150 lines of code, none of them exceeding 100
characters. It comes without any external dependencies (unless perl,
of course), can be copied as a file and run with only the interpreter
installed, or even typed in, if it must be. I'm planning to add
another version which is more human readable (but easily double in
size) in the near future.

There is also an version which adds support for GNU Readline using the
Term::ReadLine:GNU module, which enhances the usability of this program a lot.

Please note: This is an early untested version, so errors and glitches
will happen!

FEATURES
--------

perled tries to implement most features of GNU ed. There are, however, some differences:

  * Error printing is always on, and the short error messages are
    printed in the same line as the question mark.
  * You cannot toggle the promt interactively; you can, however, set a
    promt with the -p or -P*PROMT* command line switch. -pn or -Pn is
    special, because now the prefix of the promt gets reset to the current line.
  * Regular expressions accept the g and the I suffix, or a digit (as
    in GNU ed). But apart form that, the regular expressions
    themselves are handed as they are to perl's excellent regex
    engine, so... enjoy!
  * there is a new X command, which hands over all the remaining input
    to perl's eval and adds a semicolon, in other words: this way, you
    can execute arbitrary commands over your text data (which resides
    in the global @b array).
  * the l command accepts the O, X and D suffix, which causes all
    non-ascii characters to be printed as octal, hexadecimal or
    decimal values.
