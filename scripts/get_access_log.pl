#!/usr/bin/perl

use warnings;
use strict;
use DateTime;

use lib './modules';
use Constants;

my $rr_host         = Constants::RR_IP_ADDRESS;
my $rr_username     = Constants::RR_USERNAME;
my $rr_logs_source  = Constants::RR_LOGS_SOURCE;
my $ssh_args        = Constants::SSH_ARGS;
my $logs            = Constants::LOGS_DIRECTORY_NAME;

my %known_users = 
(
  "67.249.88.136"   => "105 Bool Street",
  "141.222.36.215"  => "Matthew O'Connor", 
  "98.169.40.117"   => "9654 Scotch Haven Drive",  
);


my $log1 = "./downloads/log1.log";
my $log2 = "./downloads/log2.log";

system "scp $ssh_args $rr_username\@$rr_host:$rr_logs_source/access.log.1 $log1";
system "scp $ssh_args $rr_username\@$rr_host:$rr_logs_source/access.log   $log2";

my @log_names = ($log1, $log2);

my $final_access_log = "";

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =  gmtime(time);

my $now_time = DateTime->new(
    year       => $year + 1900,
    month      => $mon + 1,
    day        => $mday,
    hour       => $hour,
    minute     => $min,
    second     => $sec
);

my %abbr = (
  Jan => 1,
  Feb => 2,
  Mar => 3,
  Apr => 4,
  May => 5,
  Jun => 6,
  Jul => 7,
  Aug => 8,
  Sep => 9,
  Oct => 10,
  Nov => 11,
  Dec => 12,
);

my $num_accesses = 0;

my %cached_ipinfo;

for (my $i = 0; $i < scalar @log_names; $i++)
{
  my $log_name = $log_names[$i];

  # Attempting to capture:
  # 67.249.88.136 - - [25/Mar/2019:04:16:52 +0000] "GET /cache/NIGEL_RICHARDS.cache HTTP/1.1" 200 88760
  # 67.249.88.136 - - [25/Mar/2019:04:17:09 +0000] "GET /cgi-bin/mine_webapp.pl?name=nigel+richards&cort=t&tid=&lexicon=&gid=&opp=&start=&end= HTTP/1.1" 200 8737

  open(LOGFILE, '<', $log_name);
  while (<LOGFILE>)
  {
      $_ =~ /(\d+).(\w+).(\d+):(\d+):(\d+):(\d+)/;

      my $logline_time = DateTime->new(
            year       => $3,
            month      => $abbr{$2},
            day        => $1,
            hour       => $4,
            minute     => $5,
            second     => $6
        );

      my $now_gm_epoch = $now_time->epoch();
      my $then_gm_epoch = $logline_time->epoch();

      if ($now_gm_epoch - $then_gm_epoch < 86400)
      {
        $num_accesses++;
        $_ =~ /^(\S+)\s/;

        my $ip = $1;
        my $user = $known_users{$ip};
        my $is_known_user = $user;
        if (!$is_known_user)
        {
          $user = "Unknown User";
        }

        $user = (sprintf "%-20s", $user) . " - ";
        $_ = $user . $_;

        $final_access_log .= $_;

        if (!$is_known_user)
        {
          if (!$cached_ipinfo{$ip})
          {
            my $curlinfo = "";
            my $padding = " " x 20;
            my $curlcmd = "curl ipinfo.io/$ip?token=002cac0572fbd0 |"; 
            open (CURLCMDOUT, $curlcmd) or die "$!\n";
            while (<CURLCMDOUT>)
            {
              my $info_line = $padding . $_;
              $final_access_log .= $info_line;
              $cached_ipinfo{$ip} .= $info_line;
            }
          }
          else
          {
            $final_access_log .= $cached_ipinfo{$ip};
          }
        }

        $final_access_log .= "\n";
      }
    }
}

my $final_access_log_name = "$logs/access.log";
open(my $log, '>', $final_access_log_name);
print $log "Access log file for mine_games_test on " . localtime() . "\n\n"; 
print $log "$num_accesses requests logged\n\n"; 
print $log "\n\n$final_access_log\n\n";
close $log;

