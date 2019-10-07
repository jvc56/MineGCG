#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

use lib './objects';
use lib './modules';

use Constants;
use Utils;

my $testing;

GetOptions
(
  'testing' => \$testing
);

my $playerstable   = Constants::PLAYERS_TABLE_NAME;
my $sanitized_name = Constants::PLAYER_SANITIZED_NAME_COLUMN_NAME;
my $logs           = Constants::LOGS_DIRECTORY_NAME;

my $dbh = Utils::connect_to_database();

my @names = map {$_->{$sanitized_name}} @{$dbh->selectall_arrayref("SELECT $sanitized_name FROM $playerstable", {Slice => {}, "RaiseError" => 1})};

my $log_name = "$logs/mine_games_test.log";

open(my $log, '>', $log_name);
print $log "Error log file for mine_games_test on " . localtime() . "\n\n"; 


my $count = scalar @names;
print $log "\n\n$count names tested\n\n";

if ($testing)
{
  system "./scripts/main.pl --name 'joshua castellano' --statsdump >/dev/null 2>> $log_name";
}
else
{
  foreach my $name (@names)
  {
    system "./scripts/main.pl --name '$name' --statsdump >/dev/null 2>> $log_name";
  }
}

print $log "Finished at " . localtime() . "\n\n"; 

close $log;
