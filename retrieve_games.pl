#!/usr/bin/perl

use warnings;
use strict;
use lib '.';
use Constants;

sub retrieve($$$$$$)
{
  # Constants
  my $cross_tables_url           = Constants::CROSS_TABLES_URL;
  my $query_url_prefix           = Constants::QUERY_URL_PREFIX;
  my $annotated_games_url_prefix = Constants::ANNOTATED_GAMES_URL_PREFIX;
  my $annotated_games_page_name  = Constants::ANNOTATED_GAMES_PAGE_NAME;
  my $query_results_page_name    = Constants::QUERY_RESULTS_PAGE_NAME;

  my $name              = shift;
  my $dir               = shift;
  my $option            = shift;
  my $tourney_id        = shift;
  my $tourney_or_casual = shift;
  my $verbose           = shift;

  if (!$option && -e $dir)
  {
    return;
  }
  print "Retrieving games...\n";
  if ($option eq "reset" && -e $dir)
  {
    system "rm -r $dir";
    if ($verbose) {print "Deleted $dir\n";}
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
  	if (/^Location: results\.php\?p=(\d+).*/)
  	{
      $player_id = $1;
  	  last;
  	}
  }
  if (!$player_id){print "No player named $user_name found\n"; return;}
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
    if ($verbose) {print "Created $dir\n";}
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

    if (!$tourney_name)
    {
      $tourney_name = Constants::NON_TOURNAMENT_GAME;
    }
    if (!$date)
    {
      $date = 0;
    }
    if (!$round_number)
    {
      $round_number = 0;
    }

    # Check if game needs to be downloaded
    $count++;
    my $num_str = "$count of $games_to_download:";

    if ($tourney_id && $tourney_id ne $game_tourney_id)
    {
      if ($verbose) {print "$num_str Game $id wasn't played in the specified tournament\n";}
      next;
    }
    if ($tourney_name eq Constants::NON_TOURNAMENT_GAME && uc $tourney_or_casual eq 'T')
    {
      if ($verbose) {print "$num_str Game $id is not a tournament game\n";}
      next;
    }
    if ($tourney_name ne Constants::NON_TOURNAMENT_GAME && uc $tourney_or_casual eq 'C')
    {
      if ($verbose) {print "$num_str Game $id is a tournament game\n";}
      next;
    }

    my $html_game_name = "$id.html";

  	my $html_game_url = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX . $id;

  	system "wget $html_game_url -O $dir/$html_game_name >/dev/null 2>&1";
    my $gcg_url_suffix  = '';
    my $player_one_name = '';
    my $player_two_name = '';
    open(ANNOHTML, '<', "$dir/$html_game_name");
    while(<ANNOHTML>)
    {
      if (/href=.(annotated.selfgcg.\d+.anno\d+.gcg)./)
      {
        $gcg_url_suffix = $1;
      }
      if (/(.*)<a.*vs.([^<]*)</)
      {
        $player_one_name = $1;
        $player_two_name = $2;
        $player_one_name =~ s/^\s+|\s+$//g;
        $player_two_name =~ s/^\s+|\s+$//g;
        $player_one_name =~ s/ /_/g;
        $player_two_name =~ s/ /_/g;
        $player_one_name =~ s/'//g;
        $player_two_name =~ s/'//g;
      }
    }
    system "rm $dir/$html_game_name";

    my $gcg_name = join ".", ($date, $game_tourney_id, $round_number, $tourney_name, $lexicon, $id, $player_one_name, $player_two_name, "gcg");
    # Move this check to before downloading
    if ($option eq "update" && -e $dir . "/" . $gcg_name)
    {
      if ($verbose) {print "$num_str Game $gcg_name already exists in the directory\n";}
      next;
    }
    my $gcg_url = $cross_tables_url . $gcg_url_suffix;
    system "wget $gcg_url -O $dir/$gcg_name >/dev/null 2>&1";
    if ($verbose) {print "$num_str Downloaded game $gcg_name to $dir\n";}
  }
}
1;
