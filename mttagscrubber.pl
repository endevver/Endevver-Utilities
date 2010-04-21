#!/usr/bin/perl

use strict;

local $/;
my $in = $_ . <>;
$in =~ s!<(/)?MT(.*?)\b((<[^>]+>|[^>]+) 
*)>!
my $close = $1 || '';
my $tag = lc $2;
my $attr = $3;
my @attr;
while ($attr =~ /(?: (?:(\w+)\s*=\s*(?:(["'])(.*?)\2|(\S+))) 
| ((["'])(.*?)\6 | \w+) )/gsx) {
my $tag = $1;
my $name = $6 ? $5 : '"' . lc $5 . '"' if $5;
my $attr;
if ($4) {
$attr = '"' . $4 . '"';
} else {
$attr = $3;
my $q = $2;
if ($q eq "'") {
$q = '"' unless $attr =~ m/"/;
}
$attr = $q . $attr . $q;
}
if ($name) {
push @attr, "name=" . $name;
} else {
push @attr, lc($tag) . '=' . $attr;
}
}
$attr = @attr ? " " . join " ", @attr : "";
$attr =~ s/\b(name|escape)="((?:[A-Z]+_?)+)"/$1="\L$2"/g;
"<$close\mt:$tag" . $attr . ">"
!igsex;
$in =~ s!<MT_TRANS\b!<__trans!ig;
$in =~ s!\b__(FIRST|LAST|ODD|EVEN|COUNTER)__\b!__\L$1__!g;
print $in;