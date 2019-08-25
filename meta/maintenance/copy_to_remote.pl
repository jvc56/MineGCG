#!/usr/bin/perl

use warnings;
use strict;

use lib "./modules";

use Utils;
use Constants;

my $cache_dir       = Constants::CACHE_DIRECTORY_NAME;

my $rr_host         = Constants::RR_IP_ADDRESS;
my $rr_username     = Constants::RR_USERNAME;
my $scp_args        = Constants::SSH_ARGS;

my $source_html = Constants::HTML_DIRECTORY_NAME;
my $source_cgi  = Constants::CGIBIN_DIRECTORY_NAME;

my $dest_html = Utils::get_environment_name($source_html);
my $dest_cgi  = Utils::get_environment_name($source_cgi);

$dest_html = Constants::RR_WORKING_DIR . $dest_html;
$dest_cgi  = Constants::RR_WORKING_DIR . $dest_cgi;

my $final_dest_html = Constants::RR_REAL_DIR;
my $final_dest_cgi  = Constants::RR_REAL_DIR;


my @commands =
(
  "cp -r $cache_dir $source_html",
  "ssh $scp_args $rr_username\@$rr_host 'sudo rm -rf  $dest_html'",
  "ssh $scp_args $rr_username\@$rr_host 'sudo rm -rf  $dest_cgi '",
  "scp -r $scp_args $source_html $rr_username\@$rr_host:$dest_html",
  "scp -r $scp_args $source_cgi  $rr_username\@$rr_host:$dest_cgi ",
  "ssh $scp_args $rr_username\@$rr_host 'sudo cp -r  $dest_html $final_dest_html'",
  "ssh $scp_args $rr_username\@$rr_host 'sudo cp -r  $dest_cgi  $final_dest_cgi '",
);

my $log_name = "./logs/copy_to_remote.log";
open(my $log, '>', $log_name);
print $log "Copy to Remote log file on " . localtime() . "\n\n";

while (@commands)
{
  my $cmd = shift @commands;
  print $log "$cmd\n";
  system $cmd;
}

close $log;



