use strict; use warnings; use v5.10;   # v5.10 for say; use print in older perls
our @b = ( $ARGV[0] ); our (@x, @u);
while (<>) { chomp; push @b, $_ }
chomp and eval and print STDERR $@ while <STDIN>;
open F, '>', shift @b or die $!; say F for @b; close F;
