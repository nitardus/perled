PERLED
=====
This project tries to implement an clone of the UNIX standard text
editor in less than 150 lines of code, none of them exceeding 100
characters. It comes without any external dependencies (unless perl,
of course), can be copied as a file and run with only the interpreter
installed, or even typed in, if it must be (but on this see below!).
I'm planning to add another version which is more human readable (but
easily double in size) in the near future.

Please note: This is an early beta version, so errors and glitches
will happen!

Features
--------
perled tries to implement most features of GNU ed. There are, however,
some differences:

  * Error printing is always on, and the short error messages are
    printed in the same line as the question mark.
  * Additional to the P command, the N command toggles line number
    printing before the prompt. Use the -pn to switch this on the
    command line.
  * Regular expressions accept the g and the I suffix, or a digit (as
    in GNU ed). But apart form that, the regular expressions
    themselves are handed as they are to perl's excellent regex
    engine, so... enjoy!
  * The interactive global commands G and V are not implemented, only
    the normal g and v commands.
  * The j command now accepts a suffix which gets inserted between
    each joined line: So now, you can easily join lines in a sensible
    way.
  * The l command accepts the O, X and D suffix, which causes all
    non-ascii characters to be printed as octal, hexadecimal or
    decimal values.
  * There is a new X command, which hands over all the remaining input
    to perl's eval and adds a semicolon, in other words: this way, you
    can execute arbitrary commands over your text data (which resides
    in the global @b array).


Versions
--------
There are three versions of perled included in this repository: 
  * perled-std strives to be a fairly complete implementation of
    GNU ed without any dependencies but perl itself.
  * perled-rl adds support of the GNU Readline library via the
    Term::ReadLine::GNU module, and automatically detects your screen
    height via the Term::ReadKey module. Both modulea have to be
    installed, e.g. from cpan, in order for this version to work, but
    that should be worth it (and please note: when using
    Term::ReadLine, you have to make sure that Term::ReadLine:GNU is
    loaded. Other backends to Term::ReadLine can have some issues).
    Having readline in ed is like an old dream come true.
  * perled-light gets rid of 60 lines of code by skipping some
    commamds (ktl=, the use of offsets in line adressing, the global
    command, case insensitive searches). Getting rid of the bookmark
    system made it possible to simplify the buffer model: the content
    of the lines is now directly stored in @b (in perled, @b is an
    array of hashes): so $b[1] now holds the text of the first line
    instead of $b[1]{\_}.

makeshifted
==========
If you really are desparate and are stuck on a system whitout anything
but a shell and perl, then you can use makeshifted. The idea is quite
simple: you write a short perl script which loads a file into an
array, gives you control over it through an eval-loop and finally
prints it back to a file. A minimal version could be implemented thus:

	$ perl -pe '' > makeshifted    # or: cat > makeshifted
	use strict; use warnings; use v5.10;   # v5.10 for say
	our @b = ( $ARGV[0] ); our (@x, @u);
	while (<>) { chomp; push @b, $_ }
	chomp and eval and print STDERR $@ while <STDIN>;
	open F, '>', shift @b or die $!; print F $_ for @b; close F;
	
Now execute this script upon itself (or better, a copy of itself):

	$ cp makeshifted makeshifted_copy
	$ perl makeshifted makeshifted_copy

This script now loads the file given in the argument into the @b array
($b[0] is the filename, $b[1] line 1, etc.) and awaits user input;
upon recieveing EOF (Control-D on Unix) it writes the contents back to
the filename residing in $b[0]. Abort all edits with Contol-C.
Printing the buffer contents is as easy as writing

	say for @b   # or in older perls: print $_ for @b 
	
or with the linenumbers included

	say "$_\t$b[$_] for 1..$#b
	
you want that to have as a function to call with n. Add this line
to the file:

	push @b, 'sub n { say "$_\t$b[$_]" for 1..$#b }'
	
Correcting errors is just as easy

	$b[7] =~ s/say/print/
	$b[7] =~ s/\]/$&\n/
	
but surely, you want that also to be a easy to use function

	push @b, 'sub subst { my ($i, $re) = @_; eval "\$b[$i] =~ s$re" }'
	
you now can change a line by calling
 
	subst 6, '/print/say'
	
If you do not like the line order, change it:

	@x = @b[4..6]
	@b = ( @b[0-3], @x, @b[7] )

And to finally save it to another file, just change $b[0]

	$b[0] = 'makeshifted_new'
	
The makeshifted script of this repository: usage
---------------------------
	
The makeshifted file included in this repository is an example of a
practical makeshifted editor: There are functions for all common tasks
(e for loading, w for writing, g and v commands for filtering, a for
adding teyt interactively, etc.). You can always call them in the
normal fashion, but the three substitutions in the main loop make it
also possible to use some commands in ed-style, e.g.

	1,3p
	3n
	3s/say/print/
	g/open/n
	
This usage is, however, is rather limited: You must always specify one
or two adresses and you cannot use the g command on substitutions. In
other cases, use a for loop

	subst $_ '/^/#/' for g '/eval/'
	n $_ for v 5, 50, '/^#/'
