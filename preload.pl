#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
require "./retrieve_games.pl";
use lib '.';
use Constants;

my @countries = ('BRB', 'IND', 'MYS', 'CAN', 'USA');


print "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
print "!!! WARNING: LONG-RUNNING JOB !!!\n";
print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
print "\n";
print "This script will download and index\n";
print "all of the games of all of the active\n";
print "players from the following countries:\n\n";

foreach my $country (@countries)
{
print "  $country\n";
}
print "\n";
print "Even with the lowest latencies, this is\n";
print "expected to take several days.\n";
print "Continue? [y/N] ";

my $response = <STDIN>;

if ($response =~ /^([yY][eE][sS]|[yY])+$/)
{
  my $wget_flags = Constants::WGET_FLAGS;
  my $players_by_country_prefix = 'https://www.cross-tables.com/bycountry.php?country=';
  my $html_page_prefix = 'player_by_country_';

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
      my $name = shift @player_names;
      print "Retrieving games for $name\n";
      $name =~ s/'//g;
      retrieve($name, "update", 0, 0, 1, 1);
    }
    system "rm '$html_page_name'";
  }
}