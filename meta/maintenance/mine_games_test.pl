#!/usr/bin/perl

use warnings;
use strict;
use lib './objects';
use Constants;

require "./scripts/update_leaderboard.pl";
require "./scripts/update_notable.pl";

my $names_dir = Constants::NAMES_DIRECTORY_NAME;

opendir my $names, $names_dir or die "Cannot open directory: $!";
my @name_files = readdir $names;
closedir $names;

my $log_name = './logs/mine_games_test.log';

open(my $log, '>', $log_name);
print $log "Error log file for mine_games_test on " . localtime() . "\n\n"; 


my $count = (scalar @name_files) - 2;
print $log "\n\n$count names tested\n\n";
close $log;

foreach my $name_file (@name_files)
{
  if ($name_file eq '.' || $name_file eq '..')
  {
    next;
  }
  $name_file =~ /(.*)\.txt/;
  my $name = $1;
  $name =~ s/_/ /g;
  system "./scripts/main.pl --name '$name' -ski -stats -notable >/dev/null 2>> $log_name";
  system "./scripts/main.pl --name '$name' -ski --html >/dev/null 2>> /dev/null";
}

update_leaderboard();
update_notable();


