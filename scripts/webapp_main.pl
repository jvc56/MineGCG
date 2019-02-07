#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

chdir("/home/jvc/MineGCG");

require "./scripts/mine_games.pl";
require "./scripts/sanitize.pl";

my $name;
my $cort    = '';
my $game    = '';
my $tid     = '';
my $opp     = '';
my $start   = '';
my $end     = '';

GetOptions (
            'name=s'    => \$name,
            'cort:s'    => \$cort,
            'game:s'    => \$game,
            'tid:s'     => \$tid,
            'opp:s'     => \$opp,
            '$start:s'  => \$start,
            '$end:s'    => \$end
           );

mine(sanitize($name), $cort, $game, $opp, $start, $end, 1, $tid, 1);

