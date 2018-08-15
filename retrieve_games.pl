#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

sub retrieve($$)
{
  my $name = shift;
  my $dir = shift;
  
  # Constants
  my $query_url_prefix = "http://www.cross-tables.com/players.php?query=";
  my $annotated_games_url_prefix = "http://www.cross-tables.com/anno.php?p=";
  my $annotated_games_page_name = "anno_page.html";
  my $query_results_page_name = "query_results.html";

  # Prepare name for cross-tables query
  # by replacing ' ' with '+'
  my $user_name = $name;
  $name =~ s/ /+/g;
  $name =~ s/'//g;

  # Run a query using the name to get the player id
  my $query_url = $query_url_prefix . $name;
  open (CMDOUT, "wget $query_url -O ./$query_results_page_name 2>&1 |");
  my $player_id;
  while (<CMDOUT>)
  {
  	/^Location: results\.php\?p=(\d+).*/;
  	$player_id = $1;
  	if ($player_id)
  	{
  	  last;
  	}
  }
  if (!$player_id){die "No player named $user_name found";}
  # Use the player id to get the address of the annotated games page
  my $annotated_games_url = $annotated_games_url_prefix . $player_id;

  # Get the player's annotated games page
  system "wget $annotated_games_url -O ./$annotated_games_page_name";

  # Parse the annotated games page html to get the game ids
  # of the player's annotated games
  my @game_ids = ();
  open(RESULTS, '<', $annotated_games_page_name);
  while (<RESULTS>)
  {
    my @matches = ($_ =~ /<a href='annotated\.php\?u=(\d+)'>/g);
    push @game_ids, @matches;
  }

  # Create the directory to store the game page htmls
  # if one doesn't already exist
  if (!(-e $dir and -d $dir))
  {
  	mkdir $dir;
  }

  # Iterate through the annotated game ids to fetch all of
  # the player's annotated games
  while (@game_ids)
  {
  	my $id = shift @game_ids;
  	my $game_url = "http://www.cross-tables.com/annotated.php?u=$id";
  	my $game_name = "$id.html";
  	system "wget $game_url -O $dir/$game_name";
  }
}
1;
