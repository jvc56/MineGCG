#!/usr/bin/perl

use warnings;
use strict;
use lib './objects';
use Constants;

require "./scripts/update_leaderboard.pl";
require "./scripts/update_notable.pl";
require "./scripts/utils.pl";

my $table = Constants::GAMES_TABLE_NAME;

my $dbh = connect_to_database();

my @names = map {$_->{'sanitized_name'}} @{$dbh->selectall_arrayref("SELECT sanitized_name FROM $table", {Slice => {}, "RaiseError" => 1})};

my $log_name = './logs/mine_games_test.log';

open(my $log, '>', $log_name);
print $log "Error log file for mine_games_test on " . localtime() . "\n\n"; 


my $count = scalar @names;
print $log "\n\n$count names tested\n\n";
close $log;

foreach my $name (@names)
{
  system "./scripts/main.pl --name '$name' -ski -stats -notable >/dev/null 2>> $log_name";
  system "./scripts/main.pl --name '$name' -ski --html >/dev/null 2>> $log_name";
}

update_leaderboard();
update_notable();


