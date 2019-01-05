#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

chdir("~/MineGCG");

require "./scripts/mine_games.pl";
require "./scripts/sanitize.pl";

my $name    = '';
my $cort    = '';
my $game    = '';
my $tid     = '';

GetOptions (
            'name'    => \$name,
            'cort'    => \$cort,
            'game'    => \$game,
            'tid'     => \$tid,
           );

mine(sanitize($name), $cort, $game, 0, $tid, 1);

