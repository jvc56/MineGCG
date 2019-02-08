#!/usr/bin/perl

use warnings;
use strict;
use lib './objects';
use Constants;

my $names_dir = Constants::NAMES_DIRECTORY_NAME;

opendir my $names, $names_dir or die "Cannot open directory: $!";
my @name_files = readdir $names;
closedir $names;

my $log_name = './logs/mine_games_test.log';

open(my $log, '>', $log_name);
print $log "Log file for mine_games_test on " . localtime() . "\n\n"; 


my $count = 0;

foreach my $name_file (@name_files)
{
  if ($name_file eq '.' || $name_file eq '..')
  {
    next;
  }
  $name_file =~ /(.*)\.txt/;
  my $name = $1;
  $name =~ s/_/ /g;
  system "./scripts/main.pl -n '$name' -ski --html >/dev/null 2>> $log_name";
  $count++;
}

print $log "\n\n$count names mined\n\n";
close $log;
