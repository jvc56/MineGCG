#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

use lib './objects';
use lib './modules';

use Constants;
use Retrieve;
use Utils;

my @countries = Constants::PRELOAD_COUNTRIES;

my $wget_flags = Constants::WGET_FLAGS;
my $players_by_country_prefix = Constants::CROSS_TABLES_COUNTRY_PREFIX;
my $download_dir              = Constants::DOWNLOADS_DIRECTORY_NAME;
my $html_page_prefix = "$download_dir/player_by_country_";

print "Log file for retrieve on " . localtime() . "\n\n"; 

foreach my $country (@countries)
{
  my $url = $players_by_country_prefix . $country;
  my $html_page_name = $html_page_prefix . $country . '.html';

  system "wget $wget_flags $url -O '$html_page_name' >/dev/null 2>&1";

  my @player_names = ();
  open(PLAYERS, '<', $html_page_name);

  while (<PLAYERS>)
  {
    my @matches = ($_ =~ /href=.results.php.playerid=\d+.>([^<]*)</g);
    push @player_names, @matches;
  }
  while (@player_names)
  {
    my $raw_name = shift @player_names;
    my $name = $raw_name;
    $name = Utils::sanitize($name);
    
    Retrieve::retrieve(
      $name,
      $raw_name,
      Constants::UPDATE_OPTION_STATS,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    );
  }
}
