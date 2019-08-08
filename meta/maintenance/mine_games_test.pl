#!/usr/bin/perl

use warnings;
use strict;
use lib './objects';
use Constants;

require "./scripts/utils.pl";

my $playerstable = Constants::PLAYERS_TABLE_NAME;
my $sanitized_name = Constants::PLAYER_SANITIZED_NAME_COLUMN_NAME;

my $dbh = connect_to_database();

my @names = map {$_->{$sanitized_name}} @{$dbh->selectall_arrayref("SELECT $sanitized_name FROM $playerstable", {Slice => {}, "RaiseError" => 1})};

my $log_name = './logs/mine_games_test.log';

open(my $log, '>', $log_name);
print $log "Error log file for mine_games_test on " . localtime() . "\n\n"; 


my $count = scalar @names;
print $log "\n\n$count names tested\n\n";
close $log;

foreach my $name (@names)
{
  # print $log "\n\n$name\n\n";
  system "./scripts/main.pl --name '$name' --html --statsdump >/dev/null 2>> $log_name";
}



