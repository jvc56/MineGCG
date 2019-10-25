#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

my $dir;

GetOptions (
            'directory=s'         => \$dir,
           );

chdir ( $dir );

system "./meta/maintenance/daily_cronjob.pl";

