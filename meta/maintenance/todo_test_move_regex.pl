#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use lib '.';
use Constants;

open(MOVES, '<', "todo_gcg_moves.txt");

while(<MOVES>)
{
  my $line = $_;
  if ($line =~ /^~/ || $line eq "\n")
  {
    # This a comment line, skip it
    next;
  }
  else
  {
    $line =~ s/^\s+|\s+$//g;
    my @items = split /\s+/, $line;
    print "The items:\n";
    print Dumper(\@items);

    # Possible plays:
    
    # Pass                  5
    # +5 Collins            5
    # Word challenged off   5
    # Word played           6
    # exchanged             5
    # 6 pass                5
    # outplay               4



    if ($line =~ /^\s*>([^:]+):\s+([\w\?]+)\s+([^\s\+]+)?\s+([^\s\+]+)?\s+([^\s]+)\s+([^\s\+]+)/)
    {
      my $name  = $1;
      my $rack  = $2;
      my $loc   = $3;
      my $play  = $4;
      my $score = $5;
      my $total = $6;
      print "The line: $_";
      printf "The vars: name: %s, rack: %s, loc: %s, play: %s, score: %s, total: %s\n", $name, $rack, $loc, $play, $score, $total;
    }
  }
}
