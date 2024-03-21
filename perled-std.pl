#! /usr/bin/perl
use v5.14; use strict; use warnings; use utf8;
our $z = 22; # Terminal height for the z command

our (@b, @u, @x, $p, $P, $mod, $nl); our $pos = 0; our $regex  = ''; our $pn = '';
our $ADR = qr#\d+|\$|\.|'[A-z]|([/?]).*?(?:\1I?|$)#;
our $OFS = qr#(?:[+-]\d*)+#;
our $GLB = qr#([GgVv])([/?])(.*?)($|\2I?)#;
our $CMD = qr#[acdefijkmnpqQstuxXyz=!]|PN?|N|l[DOX]?|w?[qQ]|[rw]!?#x;
our $ERR_SFX = "Invalid command suffix\n";
our $ERR_ADR = "Invalid adress!\n";
our $ERR_FLN = "No current filename!\n";
our $ERR_FND = "No match!\n";
our $O = "\\%03o"; our $X = ":%02X"; our $D = "(%d)";
sub raw    { my $r; $r .= /[ -~]/a ? $_ : sprintf( $_[1], ord ) for split '', $_[0]; $r.='$' }
sub save   { @u = @b; $mod = 1; }
sub dsave  { save; $u[$_] = { %{ $b[$_] } } for @_ }
sub undo   { @_ = @b; @b = @u; @u = @_; $pos = $#b if $pos > $#b }
sub sum    { my $s = 0;
	     $s += $_ for map /\d/ ? $_ : $_.'1', split /(?=[-+])/, shift;
	     $s }
sub valid  { die $ERR_ADR if grep { not 0<=$_<=$#b } @_; @_ }
sub re     { $regex = $_[0] || $regex; return ( $_[1]) ? qr/$regex/i : qr/$regex/ }
sub invert { my %h = map { $_ => 1 } @_; return (0, grep !$h{$_}, 1..$#b) }
sub setk   { delete $b[$_]{ $_[1] } for 1..$#b; $b[$_[0]]{ $_[1] } = 1 }
sub getk   { exists $b[$_]{ $_[0] } and return $_ for 1..$#b;
	     die "No shortcut defined for $_[0]!\n" }
sub fndl   { my @i = ($pos+1..$#b,1..$pos);
	     @i = reverse @i if $_[0] eq '?';
	     $b[$_]{_} =~ re($_[1], $_[2]) and return $_ for @i;
	     die $ERR_FND }
sub getl   { local $_ = shift // return;
	     /([\/?])([^\1]*?)(?:\1(I)?|$)/ ? fndl $1, $2, $3 :
	       /'([A-z])/         ? getk $1     :
	       /\./               ? $pos        :
	       /\$/               ? $#b         : $_; }
sub filt   { local $_ = shift; /^$GLB/ or die "Invalid regular expression\n";
	     my ($cmd,$dlm,$re) = ($1,$2,$3); $re = re $re;
	     @_ = grep { $b[$_]{_} =~ /$re/ } $dlm eq '?' ? reverse @_ : @_;
	     @_ = grep !/^0$/, invert @_ if $cmd=~/v/i;  @_ or die $ERR_FND; @_ }
sub gettxt { push @_, $_ while defined ($_ = <STDIN>) and chomp and not /^\.$/;
	     map { _ => $_ }, @_ }
sub copy   { my @c; push @c, { _ => $_->{_} } for @_; @c }
sub del    { @x = copy @b[@_]; @b = @b[invert @_]; $pos -= $pos<$#b ? $#_ : @_ }
sub insrt  { my $i = pop; @b = $i<$#b ? (@b[0..$i],@_,@b[$i+1..$#b]) : (@b,@_) }
sub insert { insrt @_, $pos; $pos += @_ }
sub splt   { my $i = shift; @_ = ($b[$i]{_});
	     push @_,$1 while $_[0] =~ s/^(.*)\n//; push @_, shift @_; return 1 unless $#_;
	     $b[$i]{_} = shift; @_ = map { _ => $_ }, @_; insrt @_, $i}
sub nsubst { my ($re, $rpl, $cnt, @i) = @_; dsave @i;
	     for(@i) { while ($b[$_]{_} =~ /$re/gps) {
	       $b[$_]{_} = $`.$rpl.$' and splt $_ and return unless --$cnt; }}
	     die $ERR_FND }
sub gsubst { my ($re, $rpl, @i) = @_; dsave @i; my %m;
	     $b[$_]{_} =~ s/$re/$rpl/gs and $m{$_} = 1 for @i; splt $_ for keys %m }
sub size   { use bytes; return length $_[0] }
sub name   { my $f = shift; return ($f =~ s/^\s+(?=\S)//) ? $f : $b[0] }
sub load   { my $f = shift; my $m = ($f =~ s/^\s*!//) ? "-|" : "<"; my $s = 0;
	     if (open my $h,$m,$f) {
	       while (<$h>) { $s+=size($_); $nl = chomp; push @_, {_=>$_} }
	       warn "Final newline missing\n" if -T $f && !$nl; say $s; close $h; return @_ }
	     die "$f: $!\n" }
sub wrt   { my $f = shift; my $m = ($f =~ s/^\s*!//) ? "|-" : ">";
	     if (open my $h,$m,$f) { my $out = join "\n", map $b[$_]{_}, @_; $out .= "\n"x$nl;
				     $mod=0; print { $h } $out; say size $out; close $h; return size $out }
	     die "Cannot open $f for write: $!\n" }
sub edit   { @b = ($_[0]); $nl=1; eval { push @b, load $b[0] } or warn $@; $pos = $#b }

while ($_ = shift) { if (s/^-//) { $p   = /^p$/ ? '*' : /^P(.)$/ ? $1 : ''; /^pn/ and $pn = 0 }
		     elsif (!@b) { edit $_ } }
unless (@b)        { @b = ('', { _ => '' }) and $nl=1 and $pos = $#b }
@u = @b; $P = $p = $p // ''; $pn = $pos unless $pn eq ''; print "$pn$p";

while (<STDIN>) {
  chomp; eval {
    my $beg  = s#^$ADR##         ? $& : undef;
    my $b_of = s#^$OFS##         ? sum $& : 0;
    my $dlm  = s#^[,;]##         ? $& : '';
    my $end  = s#^$ADR##         ? $& : undef;
    my $e_of = s#^(?:[+-]\d*)+## ? sum $& : 0;
    my $glob = s#^$GLB##         ? $& : undef;
    my $cmd  = s#^$CMD##         ? $& : '';
    my $sfx  = $_; exit if $cmd eq 'Q';
    $sfx .= $_ while $sfx =~ s/\\$/\n/ && defined ($_ = <STDIN>) && chomp;

    my $no_adr = 1 unless defined $beg or $b_of or defined $end or $e_of;
    $beg = getl $beg; $end = getl $end;
    $beg  = ($dlm eq ',') ? 1 : $pos unless defined $beg or $b_of;
    $beg  = $pos unless defined $beg;
    $beg += $b_of; $pos = $beg if $dlm eq ';';
    $end  = ($dlm) ? $#b  : $beg unless defined $end or $e_of;
    $end  = $pos unless defined $end;
    $end += $e_of;
    0 <= $beg <= $end <= $#b or die $ERR_ADR; my @i = $beg..$end;

    @i = filt $glob, ($no_adr ? ($pos+1..$#b,1..$pos) : @i) if $glob; $pos = $i[-1];

    save if $cmd =~ /[aicedkmrtx]/;
    if ($cmd =~ /k/) { die $ERR_ADR if $#i || !$i[0];
		       die $ERR_SFX unless $sfx =~ s/^([A-z])(?=[pnl]?$)//; setk $i[0], $1 }
    elsif ($cmd =~ /s/) {
      $sfx =~ s#(\S)(.*?)\1(.*?)(?:\z|\1([Ig\d]*)(?=[nlp]?\z))##s or die $ERR_SFX;
      my ($dlm, $re, $rpl, $flg) = ($1, $2, $3, $4 || 1 );
      $re = ($flg =~ s/(I)//g) ? re( $re,'I' ) : re( $re );
      if    ($flg =~ /g/ && $flg =~ /\d/) { die $ERR_SFX }
      elsif ($flg =~ /g/)                 { gsubst $re, $rpl, @i }
      else                                { nsubst $re, $rpl, $flg || 1, @i } }
    if ($cmd =~ /[efrw]/ and $sfx and not $sfx =~ /^\s+/) { die $ERR_SFX }
    if ($cmd =~ /[eEf]/  and not $no_adr )                { die "Unexpected adress\n" }
    if ($cmd =~ /!$/) { system $sfx; say '!' }
    elsif ($cmd =~ /f/)  { say $b[0] = name $sfx; }
    elsif ($cmd =~ /e/)  { my $f = name $sfx or die $ERR_FLN; edit $f }
    elsif ($cmd =~ /r/)  { my $f = name $sfx or die $ERR_FLN; insert load $f }
    elsif ($cmd =~ /w/)  { my $f = name $sfx or die $ERR_FLN; wrt $f, ($no_adr ? 1..$#b : @i) }
    if    ($cmd =~ /q/)  { if ($mod) {$mod = 0; die "Warning: buffer modifed\n" } else { exit }  }
    $cmd !~ /[efrw!]/ and $sfx =~ s/([pn]|l[xod]?)$// and $cmd .= $1;
    if ($cmd =~ /[cdnpsy]|^$/ and grep /^0$/, @i)  { die $ERR_ADR }
    if ($cmd =~ /[=acdilnpuxy]/ and $sfx)          { die $ERR_SFX }
    if ($cmd =~ /[tm]/) { die $ERR_SFX unless $sfx ne '' and $sfx =~ /^($ADR?)($OFS?)?$/;
			  $sfx  = $1 ne '' ? getl $1 : $pos;
			  $sfx += $3 ne '' ? sum $3 : 0;
			  die $ERR_ADR unless valid $sfx }
    if ($cmd =~ /P/) { $p = $p eq '' ? $P : '' }
    if ($cmd =~ /N/) { $pn = $pn eq '' ? $pos : ''; }
    if ($cmd =~ /u/) { undo }
    elsif ($cmd =~ /X/) { eval "$sfx;" }
    elsif ($cmd =~ /a/) { my @t = gettxt; insert @t if @t }
    elsif ($cmd =~ /i/) { my @t = gettxt; do { --$pos if $pos>0; insert @t } if @t }
    elsif ($cmd =~ /c/) { my @t = gettxt; do { del @i; --$pos if $pos>0; insert @t } if @t }
    elsif ($cmd =~ /d/) { del @i }
    elsif ($cmd =~ /y/) { @x = copy @b[@i] }
    elsif ($cmd =~ /x/) { insert @x }
    elsif ($cmd =~ /t/) { $pos = $sfx; @x = copy @b[@i]; insert @x; }
    elsif ($cmd =~ /m/) { die $ERR_ADR if grep /^$sfx$/, @i; del @i; $pos = $sfx;
			  $_<$pos and --$pos for @i; insert @x; }
    elsif ($cmd =~ /j/) { my %o; %o = ( %o, %{ $b[$_] } ) for @i; 
			  $o{_} = join "$sfx", map $b[$_]{_}, @i;
			  del @i; $pos-- if $pos>1; insert \%o }
    elsif ($cmd =~ /=/) { say $pos }
    if ($cmd =~ /p/) { say $b[$_]{_} for @i }
    elsif ($cmd =~ /n/) { say "$_\t", $b[$_]{_} for @i }
    elsif ($cmd =~ /z/) { $sfx =~ /\D/ and die $ERR_SFX; $z = $sfx||$z; $beg = $end;
			  die $ERR_ADR if $beg>$#b; $end = $beg+$z-1; $end = $end<$#b ? $end : $#b;
			  say $b[$_]{_} for $beg..$end; $pos = $end<$#b ? $end + 1 : $#b }
    elsif ($cmd =~ /l([DOX]?)/) { say raw $b[$_]{_}, ($1 eq 'X'? $X : $1 eq 'D'? $D : $O) for @i }
    elsif (!$cmd) {$sfx && die "Unknown command\n"; say $b[$_]{_} for @i;
		   $pos==$#b or $pos++ if $no_adr and not $glob }
  };  print STDERR "? $@" if $@; $pn = $pos unless $pn eq ''; print "$pn$p";
}
