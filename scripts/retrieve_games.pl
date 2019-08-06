#!/usr/bin/perl

use warnings;
use strict;

require "./scripts/utils.pl";

use lib './objects';
use Constants;
use Game;
use Stats;

use JSON;

sub retrieve
{
  # Constants
  my $wget_flags                 = Constants::WGET_FLAGS;
  my $cross_tables_url           = Constants::CROSS_TABLES_URL;
  my $query_url_prefix           = Constants::QUERY_URL_PREFIX;
  my $annotated_games_url_prefix = Constants::ANNOTATED_GAMES_URL_PREFIX;
  my $annotated_games_page_name  = Constants::ANNOTATED_GAMES_PAGE_NAME;
  my $query_results_page_name    = Constants::QUERY_RESULTS_PAGE_NAME;
  my $blacklisted_tournaments    = Constants::BLACKLISTED_TOURNAMENTS;
  my $downloads_dir              = Constants::DOWNLOADS_DIRECTORY_NAME;
  my $cache_dir                  = Constants::CACHE_DIRECTORY_NAME;
  my $blacklisted_tournaments    = Constants::BLACKLISTED_TOURNAMENTS;

  my $dbh = connect_to_database();

  my $player_name       = shift;
  my $raw_name          = shift;
  my $update            = shift;
  my $tourney_id        = shift;
  my $tourney_or_casual = shift;
  my $single_game_id    = shift;
  my $opponent_name     = shift;
  my $startdate         = shift;
  my $enddate           = shift;
  my $lexicon           = shift;
  my $verbose           = shift;
  my $html              = shift;
  my $missingracks      = shift;

  system "mkdir -p $downloads_dir";

  # Prepare name for cross-tables query
  # by replacing ' ' with '+'
  my $query_name = $player_name;
  $query_name =~ s/_/+/g;

  # Run a query using the name to get the player ID
  my $query_url = $query_url_prefix . $query_name;
  open (CMDOUT, "wget $wget_flags $query_url -O ./$downloads_dir/$query_results_page_name 2>&1 |");
  my $player_cross_tables_id;
  while (<CMDOUT>)
  {
  	if (/^Location: results\.php\?p=(\d+).*/)
  	{
      $player_cross_tables_id = $1;
  	  last;
  	}
  }
  if (!$player_cross_tables_id)
  {
    open(QUERY_RESULT, '<', "$downloads_dir/$query_results_page_name");
    while (<QUERY_RESULT>)
    {
      if (/href=.results.php.playerid=(\d+).>([^<]+)<.a>/)
      {
        my $captured_name = sanitize($2);
        if ($captured_name eq $player_name)
        {
          $player_cross_tables_id = $1;
        }
      }
    }
  }
  if (!$player_cross_tables_id){print "No player named $raw_name found\n"; return;}
  # Use the player ID to get the address of the annotated games page
  my $annotated_games_url = $annotated_games_url_prefix . $player_cross_tables_id;

  # Get the player's annotated games page
  system "wget $wget_flags $annotated_games_url -O ./$downloads_dir/$annotated_games_page_name  >/dev/null 2>&1";

  # Parse the annotated games page html to get the game IDs
  # of the player's annotated games
  my @game_ids = ();
  open(RESULTS, '<', $downloads_dir . '/' . $annotated_games_page_name);
  while (<RESULTS>)
  {
    my @matches = ($_ =~ /href=.annotated.php.u=(\d+).>\w+<.a><.td><td class=.nowrap.><a href=.results.php.p=\d+.>(.+?)<.a><.td><td><a href=.tourney.php.t=(.+?).>([^<]*)<.a><.td><td>([^<]*)<.td><td>([^<]*)<.td><td><.td><td>([^<]*)</g);
    #game_id, opponent, tourney_id, tourney_name, date, round_number, dictionary
    push @game_ids, @matches;
  }

  my @player_query = @{query_table($dbh, Constants::PLAYERS_TABLE_NAME, 'cross_tables_id', $player_cross_tables_id)};
  my $player_record_id;
  
  if (@player_query)
  {
    $player_record_id = $player_query[0]->{'id'};
  }

  my $player_record =
  {
    "cross_tables_id" => $player_cross_tables_id,
    "name"            => $raw_name,
    "sanitized_name"  => $player_name
  };

  $player_record_id = insert_or_set_hash_into_table($dbh, Constants::PLAYERS_TABLE_NAME, $player_record, $player_record_id);

  # Iterate through the annotated game IDs to fetch all of
  # the player's annotated games
  my $games_to_update = (scalar @game_ids) / 7;
  my $count           = 0;
  my $games_updated   = 0;

  while (@game_ids)
  {

    #game_id, tourney_id, tourney_name, date, round_number, dictionary
    my $game_cross_tables_id = shift @game_ids;
    my $game_opponent        = shift @game_ids;
    my $game_tournament_id   = shift @game_ids;
    my $is_tournament_game   = shift @game_ids;
    my $game_date            = shift @game_ids;
    my $game_round_number    = shift @game_ids;
    my $game_lexicon         = shift @game_ids;

    $count++;
    my $num_str = (sprintf "%-4s", $count) . " of $games_to_update:";

    if ($blacklisted_tournaments->{$game_tourney_id})
    {
      if ($verbose){"Game $full_game_file_name is from a blacklisted tournament\n"};
      next;
    }

    my @game_query = @{query_table($dbh, Constants::GAMES_TABLE_NAME, 'cross_tables_id', $game_cross_tables_id)};
    
    my $game_record_id;

    if (@game_query)
    {
      $game_record_id          = $game_query[0]->{'id'};
      my $player1_cross_tables_id = $game_query[0]->{'player1_cross_tables_id'};
      my $player2_cross_tables_id = $game_query[0]->{'player2_cross_tables_id'};
      
      my $update_record;
      if (!$player1_cross_tables_id && !$player2_cross_tables_id)
      {
        my $game_record_dump = Dumper($game_query[0]);
        die "Game with ID $game_record_id has no associated players: $game_record_dump\n"; 
      }
      if (
           $player1_cross_tables_id && $player2_cross_tables_id &&
           $player1_cross_tables_id == $player2_cross_tables_id
          )
      {
        my $game_record_dump = Dumper($game_query[0]);
        die "Game with ID $game_record_id has a player playing themselves: $game_record_dump\n"; 
      }
      if (!$player1_cross_tables_id && $player2_cross_tables_id != $player_cross_tables_id)
      {
        $update_record = {"player1_cross_tables_id" => $player_cross_tables_id};
      }
      elsif (!$player2_cross_tables_id && $player1_cross_tables_id != $player_cross_tables_id)
      {
        $update_record = {"player2_cross_tables_id" => $player_cross_tables_id};
      }

      if ($update_record)
      {
        insert_or_set_hash_into_table($dbh, Constants::GAMES_TABLE_NAME, $update_record, $game_record_id);
      }

      if (!$update)
      {
        if ($verbose){print "$num_str Game with ID $game_cross_tables_id already exists\n";}
        next;
      }
    }

    my $game_date_sanitized  = $game_date;

    $game_opponent      = sanitize($game_opponent);
    $game_date_sanitized     =~ s/[^\d]//g;
    $game_lexicon       = uc $game_lexicon;

    if (!$game_date)
    {
      $game_date = '0000-00-00';
    }
    if (!$game_round_number || !($game_round_number =~ /^\d+$/))
    {
      $game_round_number = 0;
    }
    if (!$game_tournament_id || !($game_tournament_id =~ /^\d+$/))
    {
      $game_tournament_id = 0;
    }

    # Check if game needs to be downloaded

    if (!$game_lexicon)
    {
      if ($verbose) {print "$num_str Game with ID $game_cross_tables_id does not have a specified lexicon\n";}
      next;
    }
    if ($tourney_id && $tourney_id ne $game_tournament_id)
    {
      if ($verbose) {print "$num_str Game with ID $game_cross_tables_id was not played in the specified tournament\n";}
      next;
    }
    if ($single_game_id && $single_game_id ne $game_cross_tables_id)
    {
      if ($verbose) {print "$num_str Game with ID $game_cross_tables_id is not the specified game\n";}
      next;
    }
    if (!$is_tournament_game && uc $tourney_or_casual eq 'T')
    {
      if ($verbose) {print "$num_str Game with ID $game_cross_tables_id is not a tournament game\n";}
      next;
    }
    if ($is_tournament_game && uc $tourney_or_casual eq 'C')
    {
      if ($verbose) {print "$num_str Game with ID $game_cross_tables_id is a tournament game\n";}
      next;
    }
    if ($opponent_name && $game_opponent ne $opponent_name)
    {
      if ($verbose) {print "$num_str Game with ID $game_cross_tables_id is not against the specified opponent\n";}
      next;
    }
    if (($startdate && $game_date_sanitized < $startdate) || ($enddate && $game_date_sanitized > $enddate))
    {
      if ($verbose) {print "$num_str Game with ID $game_cross_tables_id is not in the specified timeframe\n";}
      next;  
    }
    if ($lexicon && $game_lexicon ne $lexicon)
    {
      if ($verbose) {print "$num_str Game with ID $game_cross_tables_id is not in the specified lexicon\n";}
      next;  
    }
    if ($blacklisted_tournaments->{$game_tournament_id})
    {
      if ($verbose) {print "$num_str Game with ID $game_cross_tables_id is from a blacklisted tournament\n";}
      next;
    }
    # Check if game or game index already exists

    my $lexicon_ref = get_lexicon_ref($game_lexicon);

    if (!$lexicon_ref)
    {
        if ($verbose) {print "$num_str Game with ID $game_cross_tables_id has no valid lexicon\n";}
        next;
    }
    my $html_game_name = "annotated_game.html";

    my $html_game_url = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX . $game_cross_tables_id;

    # All this just to see who goes first
    system "wget $wget_flags $html_game_url -O '$downloads_dir/$html_game_name' >/dev/null 2>&1";
    my $gcg_url_suffix  = '';
    my $player_one_name = '';
    my $player_two_name = '';
    open(ANNOHTML, '<', "$downloads_dir/$html_game_name");
    while(<ANNOHTML>)
    {
      if (/href=.(annotated.selfgcg.\d+.anno\d+.gcg)./)
      {
        $gcg_url_suffix = $1;
      }
      if (/^([^<]*)(?:<a.*a>)?\s+vs\.\s+([^<]*)/) # How bout ^([^<]*)<a.*a>\s+vs.([^<]*)<a
      {
        $player_one_name = $1;
        $player_two_name = $2;
      }
    }

    $player_one_name =~ s/^\s+|\s+$//g;
    $player_two_name =~ s/^\s+|\s+$//g;

    my $gcg_name = "annotated_game.gcg";
    my $gcg_fullname = "$downloads_dir/$gcg_name";

    my $gcg_url = $cross_tables_url . $gcg_url_suffix;
    system "wget $wget_flags $gcg_url -O '$gcg_fullname' >/dev/null 2>&1";

    my $gcgtext = "";

    open(GCG, '<',  $gcg_fullname);
    while(<GCG>)
    {
      $gcgtext .= $_;
    }

    my $player_is_first = 0;
    my $player1_cross_tables_id = $player_cross_tables_id;
    my $player2_cross_tables_id = undef;

    if (sanitize($player_one_name) ne $player_name)
    {
      $player_is_first = 1;
      $player1_cross_tables_id = undef;
      $player2_cross_tables_id = $player_cross_tables_id;

      if (sanitize($player_two_name) ne $player_name)
      {
        print "\nERROR:  Matching player name not found\n";
        next;
      }
    }

    my $game = Game->new(
                          $gcg_fullname,
                          $player_is_first,
                          $lexicon_ref,
                          $player_one_name,
                          $player_two_name,
                          $html,
                          $missingracks,
                          $lexicon,
                          $game_cross_tables_id
                        );

    my $error   = undef;
    my $warning = undef;

    if (ref($game) ne "Game")
    {
      $error = $game;
    }
    elsif ($game->{'warnings'})
    {
      $warning = $game->{'warnings'};
    }

    my $stats = Stats->new($player_is_first);

    my $stat_warnings = $stats->addGame($game);

    if ($stat_warnings)
    {
      $warning .= $stat_warnings;
    }

    my $unblessed_stat = {};

    if (!$error)
    {
      $unblessed_stat =
      {
        'player1' => delete_function_from_statslist($stats->{'stats'}->{'player1'}),
        'player2' => delete_function_from_statslist($stats->{'stats'}->{'player2'}),
        'game'    => delete_function_from_statslist($stats->{'stats'}->{'game'}),
        'notable' => delete_function_from_statslist($stats->{'stats'}->{'notable'}),
      };
    }

    my $game_record =
    {
      'player1_cross_tables_id'      => $player1_cross_tables_id,
      'player2_cross_tables_id'      => $player2_cross_tables_id,
      'player1_name'                 => $player_one_name;
      'player2_name'                 => $player_two_name;
      'cross_tables_id'              => $game_cross_tables_id,
      'gcg'                          => database_sanitize($gcgtext),
      'stats'                        => database_sanitize(encode_json($unblessed_stat)),
      'cross_tables_tournament_id'   => $game_tournament_id,
      'date'                         => $game_date,
      'lexicon'                      => $game_lexicon,
      'round'                        => $game_round_number,
      'name'                         => database_sanitize($game->{'readable_name'}),
      'error'                        => $error,
      'warning'                      => $warning
    };

    if ($verbose)
    {
      if ($game_record_id)
      {
        print "$num_str Updating game $game_cross_tables_id\n";
      }
      else
      {
        print "$num_str Creating game $game_cross_tables_id\n";
      }
    }

    $game_record_id = insert_or_set_hash_into_table($dbh, Constants::GAMES_TABLE_NAME, $game_record, $game_record_id);
    $games_updated++;
  }
  if ($update)
  {
    print ((sprintf "%-30s", $player_name . ":") . "$games_updated games updated or created\n");
  }
}

1;
