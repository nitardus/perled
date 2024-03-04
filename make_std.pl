#! /usr/bin/perl
use v5.16; use strict; use warnings; use utf8;

while (<>) {
  next if /^use Term::ReadLine/;
  s/use Term::ReadKey.*/our \$z = 22; # Terminal height for the z command/;
  s/defined \(\$_ = \$T->readline\(''\)\) and/defined (\$_ = <STDIN>) and chomp and/;
  s/&& defined \(\$_ = \$T->readline\(''\)\);/&& defined (\$_ = <STDIN>) && chomp;/;
  s/^while \( defined \(\$_.*/while (<STDIN>) {/;
  s/^(\s+)(eval \{\s*)$/$1chomp; $2/;
  s/\$pn = \$pos unless \$pn eq '';/$& print "\$pn\$p";/;
  print;
}
