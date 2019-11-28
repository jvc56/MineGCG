#!/usr/bin/perl

use warnings;
use strict;

my $cmd = "find lexicons scripts objects modules -name \"*.p[lm]\" | ";

open (CMDOUT, $cmd) or die "$!\n";
while (<CMDOUT>)
{
  chomp $_;
  system "perl -cw $_";
}
