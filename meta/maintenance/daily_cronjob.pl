#!/usr/bin/perl

use warnings;
use strict;

use constant FULLPATH => "/home/jvc/MineGCGDEV";

use lib FULLPATH . "/objects";
use lib FULLPATH . "/modules";
use lib FULLPATH . "/lexicons";

use Constants;
use Update;

chdir(FULLPATH);

my $rr_host         = Constants::RR_IP_ADDRESS;
my $rr_username     = Constants::RR_USERNAME;
my $rr_working_dir  = Constants::RR_WORKING_DIR;
my $ssh_args        = Constants::SSH_ARGS;

my @jobs =
(
  "Preload",     "./meta/maintenance/preload.pl         > ./logs/preload.log 2>&1   ",
  "Check",       "./meta/maintenance/check_data.pl      > ./logs/check_data.log 2>&1"  ,
  "Test",        "./meta/maintenance/mine_games_test.pl                             "  ,
  "Access",      "./meta/maintenance/get_access_log.pl  > /dev/null 2>&1            "  ,
  "Notable",     "",
  "Leaderboard", "",
  "Copy",        "./meta/maintenance/copy_to_remote.pl                              " 
);

my $full_start_time = time;

open(my $full_test_log, ">", "./logs/full_test.log");

print $full_test_log "Full Test Report\n\n";

while (@jobs)
{
  my $name = shift @jobs;
  my $cmd  = shift @jobs;
  printf "%s %s\n", $name, $cmd;
  my $start_time = time;
  if (!$cmd)
  {
    if ($name eq "Notable")
    {
      Update::update_notable();
    }
    elsif ($name eq "Leaderboard")
    {
      Update::update_leaderboard();
    }
  }
  else
  {
    system $cmd;
  }
  my $end_time = time;
  print $full_test_log sprintf "%-15s  %s", $name . ":",  format_time($start_time, $end_time);
}

my $full_end_time = time;

print $full_test_log "\n\nTotal: " . format_time($full_start_time, $full_end_time);

close $full_test_log;

my @t = localtime();
$t[5] += 1900;
$t[4]++;

my $log_name = sprintf "%04d_%02d_%02d", @t[5,4,3];

system "mkdir $log_name";
system "mv logs/*.log $log_name/";
system "mv $log_name logs/";

sub format_time
{
  my $start = shift;
  my $end   = shift;

  my $h = int (($end - $start) / 3600);
  my $m = int ((($end - $start) % 3600) / 60);
  my $s = ($end - $start) % 60;

  return sprintf "%-2sh %-2sm %-2ss\n", $h, $m, $s;
}




