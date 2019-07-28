#!/usr/bin/perl

use warnings;
use strict;

chdir("/home/jvc/MineGCG");

my $cmd = "find . -name \"*.pl\" | ";

open (CMDOUT, $cmd) or die "$!\n";
while (<CMDOUT>)
{
  chomp $_;
  system "perl -cw $_";
}
