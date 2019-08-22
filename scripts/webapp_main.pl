#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

use lib './modules';

use Mine;
use Utils;

my $name;
my $cort      = '';
my $game      = '';
my $tid       = '';
my $opponent  = '';
my $startdate = '';
my $enddate   = '';
my $lexicon   = '';

GetOptions (
            'name=s'      => \$name,
            'cort:s'      => \$cort,
            'game:s'      => \$game,
            'tid:s'       => \$tid,
            'opponent:s'  => \$opponent,
            'startdate:s' => \$startdate,
            'enddate:s'   => \$enddate,
            'lexicon:s'   => \$lexicon
           );

Mine::mine
(
  Utils::sanitize($name),
  $cort,
  $game,
  $opponent,
  $startdate,
  $enddate,
  $lexicon,
  0,
  $tid,
  0,
  1,
  0
);

