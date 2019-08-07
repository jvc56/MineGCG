#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use DBI;

use lib "./objects"; 
use lib "./lexicons";

use Constants;
use CSW07;
use CSW12;
use CSW15;
use CSW19;
use TWL98;
use TWL06;
use American;
use NSW18;

sub connect_to_database
{
  my $driver        = Constants::DATABASE_DRIVER;
  my $database_name = Constants::DATABASE_NAME;
  my $hostname      = Constants::DATABASE_HOSTNAME;
  my $username      = Constants::DATABASE_USERNAME;
  my $password      = Constants::DATABASE_PASSWORD;

  my $dbh = DBI->connect("DBI:$driver:dbname = $database_name;host=$hostname",
                         $username, $password) or die $DBI::errstr;

  $dbh->do("SET client_min_messages TO WARNING");

  my $tables_hashref = Constants::DATABASE_TABLES;
  my $creation_order = Constants::TABLE_CREATION_ORDER;

  for(my $i = 0; $i < scalar @{$creation_order}; $i++)
  {
    my $key = $creation_order->[$i];
    my @columns = @{$tables_hashref->{$key}};
    my $columns_string = join ", ", @columns;
    my $statement = "CREATE TABLE IF NOT EXISTS $key ($columns_string);";
    $dbh->do($statement);
  }   
  return $dbh;
}

sub query_table
{
  my $dbh       = shift;
  my $tablename = shift;
  my $fieldname = shift;
  my $value     = shift;

  my $arrayref =  $dbh->selectall_arrayref("SELECT * FROM $tablename WHERE $fieldname = '$value'", {Slice => {}}) or die DBI::errstr;
  return $arrayref;
}

sub get_player_cross_tables_id
{
  my $query_url_prefix           = Constants::QUERY_URL_PREFIX;
  my $downloads_dir              = Constants::DOWNLOADS_DIRECTORY_NAME;
  my $query_results_page_name    = Constants::QUERY_RESULTS_PAGE_NAME;
  my $wget_flags                 = Constants::WGET_FLAGS;

  my $player_name = shift;
  my $raw_name    = shift;

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
  if (!$player_cross_tables_id)
  {
    print "No player named $raw_name found\n";
  }
  return $player_cross_tables_id;
}

sub get_player_annotated_game_data
{
  my $annotated_games_url_prefix = Constants::ANNOTATED_GAMES_URL_PREFIX;
  my $wget_flags                 = Constants::WGET_FLAGS;
  my $downloads_dir              = Constants::DOWNLOADS_DIRECTORY_NAME;
  my $annotated_games_page_name  = Constants::ANNOTATED_GAMES_PAGE_NAME;

  my $player_cross_tables_id = shift;

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
    while (@matches)
    {
      my @item = ();
      for (my $i = 0; $i < 7; $i++)
      {
        push @item, shift @matches;
      }
      push @game_ids, \@item;
    }
  }
  return \@game_ids;
}

sub update_player_record
{
  my $dbh                    = shift;
  my $player_cross_tables_id = shift;
  my $raw_name               = shift;
  my $player_name            = shift;

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
}

sub download_gcg
{
  my $game_cross_tables_id = shift;
  
  my $wget_flags     = Constants::WGET_FLAGS;
  my $html_game_name = Constants::HTML_GAME_NAME;
  my $html_game_url  = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX . $game_cross_tables_id;
  my $downloads_dir  = Constants::DOWNLOADS_DIRECTORY_NAME;
  my $cross_tables_url           = Constants::CROSS_TABLES_URL;

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
  return [$player_one_name, $player_two_name, $gcgtext];
}

sub insert_or_set_hash_into_table
{
  my $dbh       = shift;
  my $table     = shift;
  my $hashref   = shift;
  my $record_id = shift;

  if (!(keys %{$hashref}))
  {
    return $record_id;
  }

  my $stmt;

  if (!$record_id)
  {
    my $keys_string   = "("; 
    my $values_string = "("; 

    foreach my $key (keys %{$hashref})
    {
      $keys_string   .= "$key,";
      if (defined $hashref->{$key})
      {    
        $values_string .= "'$hashref->{$key}',";
      }
      else
      {
        $values_string .= "NULL,";
      }
    }

    chop($keys_string);
    chop($values_string);

    if (!$keys_string || !$values_string)
    {
      return undef;
    }

    $keys_string   .= ")"; 
    $values_string .= ")"; 

    $stmt = "INSERT INTO $table $keys_string VALUES $values_string;";
    $dbh->do($stmt) or die DBI::errstr;
    return $dbh->last_insert_id(undef, undef, $table, undef);
  }
  else
  {
    my $set_stmt   = ""; 
    foreach my $key (keys %{$hashref})
    {
      if ($key eq 'stats')
      {
      }
      my $value;
      if (defined $hashref->{$key})
      {    
        $value = "'$hashref->{$key}'";
      }
      else
      {
        $value = "NULL";
      }
      $set_stmt .= "$key = $value,";
    }
    chop($set_stmt);
    $stmt = "UPDATE $table SET $set_stmt WHERE id = '$record_id'";
    $dbh->do($stmt) or die DBI::errstr;
    return $record_id;
  }

}

sub is_valid_game
{
  my $blacklisted_tournaments = Constants::BLACKLISTED_TOURNAMENTS;

  my $player_name       = shift;
  my $tourney_id        = shift;
  my $tourney_or_casual = shift;
  my $single_game_id    = shift;
  my $opponent_name     = shift;
  my $startdate         = shift;
  my $enddate           = shift;
  my $lexicon           = shift;
  my $verbose           = shift;
  my $num_str           = shift;
  my $id                = shift;
  my $annotated_game_data = shift;

  my $game_opponent          = $annotated_game_data->[1];
  my $game_tournament_id     = $annotated_game_data->[2];
  my $game_date              = $annotated_game_data->[4];
  my $game_round_number      = $annotated_game_data->[5];
  my $game_lexicon           = $annotated_game_data->[6];

  if ($tourney_id && $tourney_id ne $game_tournament_id)
  {
    if ($verbose) {print "$num_str Game with ID $id was not played in the specified tournament\n";}
    return;
  }
  if ($single_game_id && $single_game_id ne $id)
  {
    if ($verbose) {print "$num_str Game with ID $id is not the specified game\n";}
    return;
  }
  if (!$tourney_id && uc $tourney_or_casual eq 'T')
  {
    if ($verbose) {print "$num_str Game with ID $id is not a tournament game\n";}
    return;
  }
  if ($tourney_id && uc $tourney_or_casual eq 'C')
  {
    if ($verbose) {print "$num_str Game with ID $id is a tournament game\n";}
    return;
  }
  if ($opponent_name && $game_opponent ne $opponent_name)
  {
    if ($verbose) {print "$num_str Game with ID $id is not against the specified opponent\n";}
    return;
  }
  if (($startdate && $game_date < $startdate) || ($enddate && $game_date > $enddate))
  {
    if ($verbose) {print "$num_str Game with ID $id is not in the specified timeframe\n";}
    return;  
  }
  if ($lexicon && $game_lexicon ne $lexicon)
  {
    if ($verbose) {print "$num_str Game with ID $id is not in the specified lexicon\n";}
    return;  
  }
  if ($blacklisted_tournaments->{$game_tournament_id})
  {
    if ($verbose) {print "$num_str Game with ID $id is from a blacklisted tournament\n";}
    return;
  }
  return 1;
}

sub update_stats_or_create_record
{
  my $dbh                    = shift;
  my $player_name            = shift;
  my $player_cross_tables_id = shift;
  my $game_result            = shift;
  my $game_data              = shift;
  my $gcgtext                = shift;
  my $lexicon_ref            = shift;
  my $player_one_name        = shift;
  my $player_two_name        = shift;
  my $html                   = shift;
  my $missingracks           = shift;
  my $lexicon                = shift;
  my $game_cross_tables_id   = shift;
  my $annotated_game_data    = shift;

  my $game_opponent          = $annotated_game_data->[1];
  my $game_tournament_id     = $annotated_game_data->[2];
  my $game_date              = $annotated_game_data->[4];
  my $game_round_number      = $annotated_game_data->[5];
  my $game_lexicon           = $annotated_game_data->[6];

  my $player1_cross_tables_id = undef;
  my $player2_cross_tables_id = undef;

  my $readable_name;
  my $error = "";
  my $warning = "";

  my $game_record_id;

  if (!$gcgtext)
  {
    my $players_and_gcg = download_gcg($game_cross_tables_id);

    $player_one_name = $players_and_gcg->[0]; 
    $player_two_name = $players_and_gcg->[1]; 
    $gcgtext         = $players_and_gcg->[2];
  }

  if ($game_result)
  {
    $game_record_id = $game_result->{'id'};

    $player1_cross_tables_id = $game_result->{'player1_cross_tables_id'};
    $player2_cross_tables_id = $game_result->{'player2_cross_tables_id'};
    
    if (!$player1_cross_tables_id && !$player2_cross_tables_id)
    {
      my $game_record_dump = Dumper($game_result);
      die "Game with ID $game_record_id has no associated players: $game_record_dump\n"; 
    }
    if (
         $player1_cross_tables_id && $player2_cross_tables_id &&
         $player1_cross_tables_id == $player2_cross_tables_id
        )
    {
      my $game_record_dump = Dumper($game_result);
      die "Game with ID $game_record_id has a player playing themselves: $game_record_dump\n"; 
    }
    if (!$player1_cross_tables_id && $player2_cross_tables_id != $player_cross_tables_id)
    {
      $player1_cross_tables_id = $player_cross_tables_id;
    }
    elsif (!$player2_cross_tables_id && $player1_cross_tables_id != $player_cross_tables_id)
    {
      $player2_cross_tables_id = $player_cross_tables_id;
    }
  }
  else
  {
    $player1_cross_tables_id = $player_cross_tables_id;
    $player2_cross_tables_id = undef;
    if (sanitize($player_one_name) ne $player_name)
    {
      $player1_cross_tables_id = undef;
      $player2_cross_tables_id = $player_cross_tables_id;
      if (sanitize($player_two_name) ne $player_name)
      {
        die "matching player name not found\n";
      }
    }  
  }

  my $game = Game->new(
                        $gcgtext,
                        $lexicon_ref,
                        $player_one_name,
                        $player_two_name,
                        $html,
                        $missingracks,
                        $lexicon,
                        $game_cross_tables_id
                      );

  if (ref($game) ne "Game")
  {
    $error = $game;
  }
  elsif ($game->{'warnings'})
  {
    $warning = $game->{'warnings'};
  }

  my $stats = Stats->new(1);

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
      'stats' =>
      {
        'player1' => delete_function_from_statslist($stats->{'stats'}->{'player1'}),
        'player2' => delete_function_from_statslist($stats->{'stats'}->{'player2'}),
        'game'    => delete_function_from_statslist($stats->{'stats'}->{'game'}),
        'notable' => delete_function_from_statslist($stats->{'stats'}->{'notable'}),
      }
    };

  }

  my $game_record =
  {
    'player1_cross_tables_id'      => $player1_cross_tables_id,
    'player2_cross_tables_id'      => $player2_cross_tables_id,
    'player1_name'                 => $player_one_name,
    'player2_name'                 => $player_two_name,
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

  insert_or_set_hash_into_table($dbh, Constants::GAMES_TABLE_NAME, $game_record, $game_record_id);
}

sub sanitize_game_data
{
  my $annotated_game_data = shift;

  my $game_cross_tables_id = $annotated_game_data->[0];
  my $game_opponent        = $annotated_game_data->[1];
  my $game_tournament_id   = $annotated_game_data->[2];
  my $is_tournament_game   = $annotated_game_data->[3];
  my $game_date            = $annotated_game_data->[4];
  my $game_round_number    = $annotated_game_data->[5];
  my $game_lexicon         = $annotated_game_data->[6];

  my $game_date_sanitized  = $game_date;

  $annotated_game_data->[1] = sanitize($game_opponent);
  $annotated_game_data->[4] =~ s/[^\d]//g;
  $annotated_game_data->[6] = uc $game_lexicon;

  if (!$game_date)
  {
    $annotated_game_data->[4] = '0000-00-00';
  }
  if (!$game_round_number || !($game_round_number =~ /^\d+$/))
  {
    $annotated_game_data->[5] = 0;
  }
  if (!$game_tournament_id || !($game_tournament_id =~ /^\d+$/))
  {
    $annotated_game_data->[2] = 0;
  }
}

sub update_foreign_keys
{
  my $dbh                    = shift;
  my $game_cross_tables_id   = shift;
  my $player_cross_tables_id = shift;

  my $table = Constants::GAMES_TABLE_NAME;

  my $set_stmt =
  "
  UPDATE $table
  SET
    player1_cross_tables_id = 
    CASE
      WHEN
              player1_cross_tables_id is NULL AND player2_cross_tables_id != $player_cross_tables_id THEN
                $player_cross_tables_id
              ELSE
                player1_cross_tables_id
      END
    ,
    player2_cross_tables_id = 
    CASE
      WHEN
              player2_cross_tables_id is NULL  AND player1_cross_tables_id != $player_cross_tables_id THEN
                $player_cross_tables_id
              ELSE
                player2_cross_tables_id
      END
  WHERE cross_tables_id = '$game_cross_tables_id'
  ";

  $dbh->do($set_stmt) or die DBI::errstr;
}

sub delete_function_from_statslist
{
  my $stats = shift;

  foreach my $stat (@{$stats})
  {
    delete $stat->{Constants::STAT_ADD_FUNCTION_NAME};
    delete $stat->{Constants::STAT_COMBINE_FUNCTION_NAME};
  }
  return $stats;
}

sub get_lexicon_ref
{
  my $lexicon = shift;
  my $lexicon_ref = undef;

  if ($lexicon eq 'TWL98')
  {
    $lexicon_ref = TWL98::TWL98_LEXICON;
  }
  elsif ($lexicon eq 'TWL06')
  {
    $lexicon_ref = TWL06::TWL06_LEXICON;
  }
  elsif ($lexicon eq 'TWL15')
  {
    $lexicon_ref = American::AMERICAN_LEXICON;
  }
  elsif ($lexicon eq 'NSW18')
  {
    $lexicon_ref = NSW18::NSW18_LEXICON;
  }
  elsif ($lexicon eq 'CSW07')
  {
    $lexicon_ref = CSW07::CSW07_LEXICON;
  }
  elsif ($lexicon eq 'CSW12')
  {
    $lexicon_ref = CSW12::CSW12_LEXICON;
  }
  elsif ($lexicon eq 'CSW15')
  {
    $lexicon_ref = CSW15::CSW15_LEXICON;
  }
  elsif ($lexicon eq 'CSW19')
  {
    $lexicon_ref = CSW19::CSW19_LEXICON;
  }
  return $lexicon_ref;
}

sub sanitize
{
  my $string = shift;

  # Remove trailing and leading whitespace
  $string =~ s/^\s+|\s+$//g;

  # Replace spaces with underscores
  $string =~ s/ /_/g;

  # Remove anything that is not an
  # underscore, dash, letter, or number
  $string =~ s/[^\w\-]//g;

  # Capitalize
  $string = uc $string;

  return $string;
}

sub database_sanitize
{
  my $s = shift;

  $s =~ s/'/''/g;

  return $s;
}

1;
