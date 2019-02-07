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
my $oppopnent     = '';
my $startdate   = '';
my $enddate     = '';

GetOptions (
            'name=s'    => \$name,
            'cort:s'    => \$cort,
            'game:s'    => \$game,
            'tid:s'     => \$tid,
            'opponent:s'     => \$opp,
            'startdate:s'   => \$start,
            'enddate:s'     => \$end
           );

mine(sanitize($name), $cort, $game, $opponent, $startdate, $enddate, 1, $tid, 1);

