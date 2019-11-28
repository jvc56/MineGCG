#!/usr/bin/perl

use warnings;
use strict;

use lib './objects';
use lib './modules';

use Constants;
use Update;

system "mkdir -p " . Constants::CACHE_DIRECTORY_NAME;
system "mkdir -p " . Constants::HTML_DIRECTORY_NAME;
system "mkdir -p " . Constants::CGIBIN_DIRECTORY_NAME;
system "mkdir -p " . Constants::LEGACY_DIRECTORY_NAME;

my $rr_host         = Constants::RR_IP_ADDRESS;
my $rr_username     = Constants::RR_USERNAME;
my $rr_working_dir  = Constants::RR_WORKING_DIR;
my $ssh_args        = Constants::SSH_ARGS;
my $logs            = Constants::LOGS_DIRECTORY_NAME;

system "mkdir -p $logs";

my @jobs =
(
  "Preload",     "./scripts/preload.pl         > $logs/preload.log 2>&1   ",
  "Check",       "./scripts/check_data.pl      > $logs/check_data.log 2>&1"  ,
  "Test",        "./scripts/mine_games_test.pl",
  "Access",      "./scripts/get_access_log.pl  > $logs/access_retrieval.log 2>&1",
  "Update",      "./modules/Update.pm          > $logs/update_html.log 2>&1",
  "Copy",        "./scripts/copy_to_remote.pl" 
);

my $full_start_time = time;

open(my $full_test_log, ">", "$logs/full_test.log");

print $full_test_log "Full Test Report\n\n";

while (@jobs)
{
  my $name = shift @jobs;
  my $cmd  = shift @jobs;
  printf "%s %s\n", $name, $cmd;
  my $start_time = time;
  system $cmd;
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
system "mv $logs/*.log $log_name/";
system "mv $log_name $logs";

sub format_time
{
  my $start = shift;
  my $end   = shift;

  my $h = int (($end - $start) / 3600);
  my $m = int ((($end - $start) % 3600) / 60);
  my $s = ($end - $start) % 60;

  return sprintf "%-2sh %-2sm %-2ss\n", $h, $m, $s;
}




