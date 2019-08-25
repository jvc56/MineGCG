#!/usr/bin/perl

use warnings;
use strict;
use Perl::Critic;

my $critic = Perl::Critic->new( -severity => 'brutal');

my $cmd = "find html cgi-bin meta/maintenance objects scripts -name \"*.p[lm]\" | ";

open (CMDOUT, $cmd) or die "$!\n";
while (<CMDOUT>)
{
  chomp $_;
  print "\n\n\n$_\n";
  print $critic->critique($_);
}



