#!/usr/bin/perl

use warnings;
use strict;

chdir("/home/jvc/MineGCG");

my $full_start_time =  "\nStarted: " . localtime() . "\n";

my $preload_start_time = time;

system "./meta/maintenance/preload.pl > ./logs/preload.log 2>&1";

my $preload_end_time = time;

my $check_start_time = time;

system "./meta/maintenance/check_data.pl > ./logs/check_data.log 2>&1";

my $check_end_time = time;

my $mine_start_time = time;

system "./meta/maintenance/mine_games_test.pl";

my $mine_end_time = time;

my $access_start_time = time;

system "./meta/maintenance/get_access_log.pl > /dev/null 2>&1";

my $access_end_time = time;

my $cache_start_time = time;

system "scp -i /home/jvc/.ssh/randomracer.pem -r ./cache jvc\@media.wgvc.com:/home/bitnami/htdocs/rracer/";

my $cache_end_time = time;

my $full_end_time = "Ended:   " . localtime() . "\n";


open(my $full_test_log, ">", "./logs/full_test.log");

print $full_test_log "Full Test Report\n\n";

print $full_test_log "Preload: " . format_time($preload_start_time, $preload_end_time);
print $full_test_log "Check:   " . format_time($check_start_time, $check_end_time);
print $full_test_log "Mine:    " . format_time($mine_start_time, $mine_end_time);
print $full_test_log "Access:  " . format_time($access_start_time, $access_end_time);
print $full_test_log "Cache:   " . format_time($cache_start_time, $cache_end_time);

print $full_test_log $full_start_time;
print $full_test_log $full_end_time;

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

  return "$h" . "h  " . "$m" . "m  $s". "s\n";
}




