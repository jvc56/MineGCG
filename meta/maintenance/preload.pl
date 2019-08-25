#!/usr/bin/perl

use warnings;
use strict;

use lib './modules';

use Constants;
use Retrieve;

print "Log file for retrieve on " . localtime() . "\n\n"; 

Retrieve::retrieve(Constants::UPDATE_OPTION_STATS);

print "\n\n\nFinished on " . localtime() . "\n\n"; 



1;
