#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

require "./retrieve_games.pl";
require "./mine_games.pl";


my $verbose = '';   # option variable with default value (false)
my $update  = '';
my $reset   = '';
my $dir;
my $name;
GetOptions (
            'verbose' => \$verbose,
            'update'  => \$update,
            'reset'   => \$reset,
            'dir=s'   => \$dir,
            'name=s'  => \$name 
           );

if (!$dir){die "Must specify a directory to download annotated game html files to using -d";}
if (!$name){die "Must the name of a player on cross-tables.com using -n";}

my $option = "";
if ($update)
{
  $option = "update";
}
if ($reset)
{
  $option = "reset"
}

retrieve($name, $dir, $option);
mine($name, $dir, $verbose);

