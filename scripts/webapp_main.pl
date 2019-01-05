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

GetOptions (
            'name=s'    => \$name,
            'cort:s'    => \$cort,
            'game:s'    => \$game,
            'tid:s'     => \$tid,
           );

mine(sanitize($name), $cort, $game, 1, $tid, 1);

