#!/usr/bin/perl

use warnings;
use strict;
use lib '.';
use Constants;

my $names_dir = Constants::NAMES_DIRECTORY_NAME;

opendir my $names, $names_dir or die "Cannot open directory: $!";
my @name_files = readdir $names;
closedir $names;

my $log_name = 'mine_games_test.log';

open(my $log, '>', $log_name);
print $log "Log file for mine_games_test on " . localtime() . "\n\n"; 
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
  open(my $write_log1, '>>', $log_name);
  print $write_log1 "$name\n";
  close $write_log1;
  system "./main.pl -n '$name' >/dev/null 2>> $log_name";
  open(my $write_log2, '>>', $log_name);
  print $write_log2 "Done\n\n";
  close $write_log2;
}
