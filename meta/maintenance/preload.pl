#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

require "./scripts/retrieve_games.pl";
require "./scripts/sanitize.pl";

use lib './objects';
use Constants;

my @countries = ('BRB', 'IND', 'MYS', 'CAN', 'USA');

my $wget_flags = Constants::WGET_FLAGS;
my $players_by_country_prefix = Constants::CROSS_TABLES_COUNTRY_PREFIX;
my $html_page_prefix = './downloads/player_by_country_';

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

  my $num_names = scalar @player_names;
  print "Retrieving the games of $num_names people for $country\n";

  while (@player_names)
  {
    my $raw_name = shift @player_names;
    my $name = $raw_name;
    print "Retrieving games for $name\n";
    $name = sanitize($name);
    retrieve($name, $raw_name, "update", 0, 0, 0, 0, 1);
  }
  system "rm '$html_page_name'";
}
