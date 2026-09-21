#!/usr/bin/perl

use warnings;
use strict;

use Getopt::Long;

use lib './modules';

use Constants;
use Retrieve;

# --all forces a full fetch of every annotated game for this run only.
my $all = 0;
GetOptions('all' => \$all);

print "Log file for retrieve on " . localtime() . "\n\n";

Retrieve::retrieve(Constants::UPDATE_OPTION_GCG, $all);

print "\n\n\nFinished on " . localtime() . "\n\n"; 



1;
