#! /usr/bin/perl
use v5.14; use strict; use warnings; use utf8;
our (@b, @u, @x, $p, $nl); our $pos = 0; our $regex  = '';
our $ADR = qr#\d+|\$|\.|([/?]).*?(?:\1|$)#;
our $CMD = qr#[acdefijknpqQsuxXyz!]|w?[qQ]|[rw]!?#x;
our $ERR_SFX = "Invalid command suffix\n";
our $ERR_ADR = "Invalid adress!\n";
our $ERR_FLN = "No current filename!\n";
our $ERR_FND = "No match!\n";

sub re     { $regex = $_[0] || $regex; return qr/$regex/ }
sub invert { my %h = map { $_ => 1 } @_; return (0, grep !$h{$_}, 1..$#b) }
sub fndl   { my @i = ($pos+1..$#b,1..$pos); @i = reverse @i if $_[0] eq '?';
	     $b[$_] =~ re $_[1] and return $_ for @i; die $ERR_FND }
sub getl   { local $_ = shift // return;
	     /([\/?])([^\1]*?)(?:\1|$)/? fndl $1,$2 : /\./? $pos : /\$/? $#b : $_ }
sub gettxt { push @_, $_ while defined ($_ = <STDIN>) and chomp and not /^\.$/; @_ }
sub del    { @x = @b[@_]; @b = @b[invert @_]; $pos -= $pos<$#b ? $#_ : @_ }
sub insrt  { my $i = pop; @b = $i<$#b ? (@b[0..$i],@_,@b[$i+1..$#b]) : (@b,@_) }
sub insert { insrt @_, $pos; $pos += @_ }
sub splt   { my $i = shift; @_ = ($b[$i]);
	     push @_,$1 while $_[0] =~ s/^(.*)\n//; push @_, shift @_;
	     return 1 unless $#_; $b[$i] = shift; insrt @_, $i}
sub nsubst { my ($re, $rpl, $cnt, @i) = @_;
	     for(@i) { while ($b[$_] =~ /$re/gps) {
	       $b[$_] = $`.$rpl.$' and splt $_ and return unless --$cnt } }
	     die $ERR_FND }
sub gsubst { my ($re, $rpl, @i) = @_; my %m;
	     $b[$_] =~ s/$re/$rpl/gs and $m{$_} = 1 for @i; splt $_ for keys %m }
sub size   { use bytes; return length $_[0] }
sub name   { my $f = shift; return ($f =~ s/^\s+(?=\S)//) ? $f : $b[0] }
sub load   { my $f = shift; my $m = ($f =~ s/^\s*!//) ? "-|" : "<"; my $s = 0;
	     if (open my $h,$m,$f) {
	       while (<$h>) { $s+=size($_); $nl=chomp; push @_, $_ }
	       warn "Final newline missing\n" if -T $f && !$nl; say $s; close $h; return @_ }
	     die "$f: $!\n" }
sub wrt    { my $f = shift; my $m = ($f =~ s/^\s*!//) ? "|-" : ">";
	     if (open my $h,$m,$f)
	       { my $out = join "\n", map $b[$_], @_; $out .= "\n"x$nl; print { $h } $out;
		 say size $out; close $h; return }
	     die "Cannot open $f for write: $!\n" }
sub edit   { @b = ($_[0]); $nl=1; eval { push @b, load $b[0] } or warn $@; $pos = $#b }

while ($_ = shift) { if (!@b) { edit $_ } }
unless (@b) { @b = ('', '') and $nl=1 and $pos = $#b }
@u = @b; print $p = $pos.':';
while (<STDIN>) {
  chomp; eval {
    my $beg  = s#^$ADR##         ? $& : undef;
    my $dlm  = s#^[,;]##         ? $& : '';
    my $end  = s#^$ADR##         ? $& : undef;
    my $cmd  = s#^$CMD##         ? $& : '';
    my $sfx  = $_; exit if $cmd eq 'Q';
    $sfx .= $_ while $sfx =~ s/\\$/\n/ && defined ($_ = <STDIN>) && chomp;

    my $no_adr = 1 unless defined $beg or defined $end; $beg = getl $beg; $end = getl $end;
    $beg = ($dlm eq ',') ? 1 : $pos unless defined $beg; $pos = $beg;
    $end = ($dlm) ? $#b : $beg unless defined $end;
    0 <= $beg <= $end <= $#b or die $ERR_ADR;     my @i = $beg..$end; $pos = $i[-1];

    @u = @b if $cmd =~ /[aicedxrs]/;
    if ($cmd =~ /s/) {
      $sfx =~ s#(\S)(.*?)\1(.*?)(?:\z|\1([g\d]*)(?=[nlp]?\z))##s or die $ERR_SFX;
      my ($dlm, $re, $rpl, $flg) = ($1, $2, $3, $4 || 1 ); $re = re $re;
      if    ($flg =~ /g/ && $flg =~ /\d/) { die $ERR_SFX }
      elsif ($flg =~ /g/)                 { gsubst $re, $rpl, @i }
      else                                { nsubst $re, $rpl, $flg || 1, @i } }
    elsif ($cmd =~ /!$/) { system $sfx; say '!' }
    elsif ($cmd =~ /f/)  { say $b[0] = name $sfx; }
    elsif ($cmd =~ /e/)  { my $f = name $sfx or die $ERR_FLN; edit $f }
    elsif ($cmd =~ /r/)  { my $f = name $sfx or die $ERR_FLN; insert load $f }
    elsif ($cmd =~ /w/)  { my $f = name $sfx or die $ERR_FLN; wrt $f, ($no_adr ? 1..$#b : @i) }
    if    ($cmd =~ /q/)  { exit }
    $cmd !~ /[efrw!]/ and $sfx =~ s/([pn])$// and $cmd .= $1;
    if ($cmd =~ /[cdnpsy]|^$/ and grep /^0$/, @i)  { die $ERR_ADR }
    if ($cmd =~ /[adinpuxy=]/ and $sfx)           { die $ERR_SFX }
    if ($cmd =~ /u/) { @_ = @b; @b = @u; @u = @_; $pos = $#b if $pos > $#b }
    elsif ($cmd =~ /X/) { eval "$sfx;" }
    elsif ($cmd =~ /a/) { my @t = gettxt; insert @t if @t }
    elsif ($cmd =~ /i/) { my @t = gettxt; do { --$pos if $pos>0; insert @t } if @t }
    elsif ($cmd =~ /c/) { my @t = gettxt; do { del @i; --$pos if $pos>0; insert @t } if @t }
    elsif ($cmd =~ /d/) { del @i }
    elsif ($cmd =~ /y/) { @x = @b[@i] }
    elsif ($cmd =~ /x/) { insert @x }
    elsif ($cmd =~ /j/) { my $ins = join "$sfx", @b[@i]; del @i; $pos-- if $pos>1; insert $ins }
    if ($cmd =~ /p/)    { say for @b[@i] }
    elsif ($cmd =~ /n/) { say "$_\t$b[$_]" for @i }
    elsif (!$cmd) {$sfx && die "Unknown command\n"; say for @b[@i]; $pos==$#b or $pos++}
  };  print STDERR "? $@" if $@; print $p = $pos.':';
}
