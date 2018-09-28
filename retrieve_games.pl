#!/usr/bin/perl

use warnings;
use strict;
use lib '.';
use Constants;

sub retrieve($$$)
{
  # Constants
  my $query_url_prefix           = Constants::QUERY_URL_PREFIX;
  my $annotated_games_url_prefix = Constants::ANNOTATED_GAMES_URL_PREFIX;
  my $annotated_games_page_name  = Constants::ANNOTATED_GAMES_PAGE_NAME;
  my $query_results_page_name    = Constants::QUERY_RESULTS_PAGE_NAME;

  my $name = shift;
  my $dir = shift;
  my $option = shift;
  my $tourney_id = shift;
  my $tourney_or_casual = shift;

  if (!$option && -e $dir)
  {
    return;
  }
  print "Retrieving games...\n";
  if ($option eq "reset" && -e $dir)
  {
    system "rm -r $dir";
    print "Deleted $dir\n";
  }

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
  system "wget $annotated_games_url -O ./$annotated_games_page_name  >/dev/null 2>&1";

  # Parse the annotated games page html to get the game ids
  # of the player's annotated games
  my @game_ids = ();
  open(RESULTS, '<', $annotated_games_page_name);
  while (<RESULTS>)
  {
    my @matches = ($_ =~ /href=.annotated.php.u=(\d+).>.*?href=.tourney.php.t=(.+?).>([^<]*)<.a><.td><td>([^<]*)<.td><td>([^<]*)<.td><td><.td><td>([^<]*)</g);
    #game_id, tourney_id, tourney_name, date, round_number, dictionary
    push @game_ids, @matches;
  }
  # Create the directory to store the game page htmls
  # if one doesn't already exist
  if (!(-e $dir && -d $dir))
  {
  	system "mkdir $dir";
    print "Created $dir\n";
  }

  # Iterate through the annotated game ids to fetch all of
  # the player's annotated games
  my $games_to_download = (scalar @game_ids) / 6;
  my $count = 0;
  while (@game_ids)
  {
    #game_id, tourney_id, tourney_name, date, round_number, dictionary
  	my $id              = shift @game_ids;
    my $game_tourney_id = shift @game_ids;
    my $tourney_name    = shift @game_ids;
    $tourney_name =~ s/ /_/g;
    my $date            = shift @game_ids;
    my $round_number    = shift @game_ids;
    my $lexicon         = shift @game_ids;

    if (!$game_tourney_id)
    {
      $game_tourney_id = Constants::NON_TOURNAMENT_GAME;
    }
    if (!$tourney_name)
    {
      $tourney_name = "noname";
    }
    if (!$date)
    {
      $date = 0;
    }
    if (!$round_number)
    {
      $round_number = 0;
    }

    my $game_name = join ".", ($date, $game_tourney_id, $round_number, $tourney_name, $lexicon, $id, "html");
    
  	my $game_url = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX . $id;
    $count++;
    my $num_str = "$count of $games_to_download:";
    if ($option eq "update" && -e $dir . "/" . $game_name)
    {
      print "$num_str Game $game_url already exists in the directory\n";
      next;
    }
    if ($tourney_id && $tourney_id ne $game_tourney_id)
    {
      print "$num_str Game $game_url wasn't played in the specified tournament\n";
      next;
    }
    if ($tourney_name eq "noname" && uc $tourney_or_casual eq 'T')
    {
      print "$num_str Game $game_url is not a tournament game\n";
      next;
    }
    if ($tourney_name ne "noname" && uc $tourney_or_casual eq 'C')
    {
      print "$num_str Game $game_url is a tournament game\n";
      next;
    }
  	system "wget $game_url -O $dir/$game_name >/dev/null 2>&1";
    print "$num_str Downloaded game $game_url as $game_name to $dir\n";
  }
}
1;
