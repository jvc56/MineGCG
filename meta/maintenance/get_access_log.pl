#!/usr/bin/perl

use warnings;
use strict;
use DateTime;

my %known_users = 
(
  "67.249.88.136"   => "Joshua Castellano",
  "46.229.168.146"  => "Crawler",
  "66.249.66.88"    => "Crawler",
  "66.249.66.89"    => "Crawler",
  "66.249.66.90"    => "Crawler",
  "66.249.66.150"   => "Crawler",
  "66.249.66.152"   => "Crawler",
  "66.249.66.148"   => "Crawler",
  "45.67.213.155"   => "Crawler",
  "89.191.228.29"   => "Crawler",
  "121.98.150.20"   => "Crawler",
  "46.229.168.152"  => "Crawler",
  "446.229.168.150" => "Crawler",
  "78.46.149.254"   => "Crawler",
  "46.229.168.130"  => "Crawler",
  "141.222.36.215"  => "Matthew O'Connor",
  "46.229.168.133"  => "Crawler",
  "46.229.168.161"  => "Crawler",
  "46.229.168.137"  => "Crawler",  
  "46.229.168.150"  => "Crawler",  
  "46.229.168.141"  => "Crawler"
);

# Get most recent weekly access log .gz from bitnami

my $dashi = "-i /home/jvc/.ssh/randomracer.pem";

my $cmd = "ssh -q $dashi -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jvc\@media.wgvc.com ls -ltr /opt/bitnami/apache2/logs |";
open (CMDOUT, $cmd) or die "$!\n";
my $last_week_log_name = "";
while (<CMDOUT>)
{
  if (/(access_log.*gz)/)
  {
      $last_week_log_name = $1;
  }
}

my $gz_log_file   = "./downloads/log1.gz";
my $log2 = "./downloads/log2.log";

system "scp $dashi jvc\@media.wgvc.com:/opt/bitnami/apache2/logs/$last_week_log_name $gz_log_file";
system "scp $dashi jvc\@media.wgvc.com:/opt/bitnami/apache2/logs/access_log $log2";

my $log1 = "./downloads/log1.log";

system "gunzip -c $gz_log_file > $log1";

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
  "Jan" => 1,
  "Feb" => 2,
  "Mar" => 3,
  "Apr" => 4,
  "May" => 5,
  "Jun" => 6,
  "Jul" => 7,
  "Aug" => 8,
  "Sep" => 9,
  "Oct" => 10,
  "Nov" => 11,
  "Dec" => 12,
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
    if (/(\/cache\/\w+\.cache)|(\/cgi-bin\/mine_webapp\.pl)|(leaderboard.html)/)
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
}

my $final_access_log_name = "./logs/access.log";
open(my $log, '>', $final_access_log_name);
print $log "Access log file for mine_games_test on " . localtime() . "\n\n"; 
print $log "$num_accesses requests logged\n\n"; 
print $log "\n\n$final_access_log\n\n";
close $log;

