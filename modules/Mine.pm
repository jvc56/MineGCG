#!/usr/bin/perl

package Mine;

use warnings;
use strict;
use Data::Dumper;

use lib "./objects"; 
use lib "./modules";
use lib "./data";

use Constants;
use Stats;
use Utils;
use NameConversion;
use JSON::XS;

my $html_string = "";


sub mine
{
  my $stats_dir               = Constants::STATS_DIRECTORY_NAME;
  my $notable_dir             = Constants::NOTABLE_DIRECTORY_NAME;
  my $blacklisted_tournaments = Constants::BLACKLISTED_TOURNAMENTS;
  my $cache_dir               = Constants::CACHE_DIRECTORY_NAME;
  my $stats_note              = Constants::STATS_NOTE;
  my $names_to_ids_hashref    = NameConversion::NAMES_TO_IDS;

  my $dbh = Utils::connect_to_database();

  my $player_name       = shift;
  my $cort              = shift;
  my $single_game_id    = shift;
  my $opponent_name     = shift;
  my $startdate         = shift;
  my $enddate           = shift;
  my $lexicon           = shift;
  my $verbose           = shift;
  my $tourney_id        = shift;
  my $statsdump         = shift;
  my $html              = shift;
  my $missingracks      = shift;


  my $cache_filename = "$cache_dir/$player_name.html";
  my $cache_condition = !$cort &&
                        !$single_game_id &&
                        !$opponent_name &&
                        !$startdate &&
                        !$enddate &&
                        !$lexicon &&
                        !$tourney_id &&
                        $html;

  if (!$statsdump && $cache_condition && -e $cache_filename)
  {
    my $game_string = "";
    open(GAME, '<', $cache_filename);
    while (<GAME>)
    {
      $game_string .= $_;
    }
    print $game_string;
    return;
  }

  my $player_id = $names_to_ids_hashref->{$player_name};

  if (!$player_id)
  {
    print STDERR "Player ID not found for $player_name\n";
    return;
  }

  my $player_name_no_underscore = $player_name;
  $player_name_no_underscore =~ s/_/ /g;

  my $opponent_name_no_underscore = $opponent_name;
  $opponent_name_no_underscore =~ s/_/ /g;

  my $javascript = "";

  if ($html)
  {
    $javascript .= Constants::RESULTS_PAGE_JAVASCRIPT;
  }

  if (Utils::get_environment_name(""))
  {
    print_or_append( "\nDevelopment Version of RandomRacer\n\n\n", $html, 0);
  }

  print_or_append( "\nStatistics for $player_name_no_underscore\n\n\n", $html, 0);
  
  print_or_append( "\nSEARCH PARAMETERS: \n", $html, 0);
  
  print_or_append( "\n  Player:        $player_name_no_underscore", $html, 0);


  print_or_append( "\n  Game type:     ", $html, 0);

  if (!$cort) {print_or_append( "-", $html, 0);}
  else {print_or_append($cort, $html, 0);}

  print_or_append( "\n  Lexicon:       ", $html, 0);

  if (!$lexicon) {print_or_append( "-", $html, 0);}
  else {print_or_append( $lexicon, $html, 0);}

  print_or_append( "\n  Tournament ID: ", $html, 0);
  
  if ($tourney_id) {print_or_append( $tourney_id, $html, 0);}
  else {print_or_append( "-", $html, 0);}

  print_or_append( "\n  Game ID:       ", $html, 0);
  
  if ($single_game_id) {print_or_append( $single_game_id, $html, 0);}
  else {print_or_append( "-", $html, 0);}

  print_or_append( "\n  Opponent:      ", $html, 0);
  
  if ($opponent_name_no_underscore) {print_or_append( $opponent_name_no_underscore, $html, 0);}
  else {print_or_append( "-", $html, 0);}

  print_or_append( "\n  Start Date:    ", $html, 0);
  
  if ($startdate) {print_or_append( $startdate, $html, 0);}
  else {print_or_append( "-", $html, 0);}

  print_or_append( "\n  End Date:      ", $html, 0);
  
  if ($enddate) {print_or_append( $enddate, $html, 0);}
  else {print_or_append( "-", $html, 0);}
  

  print_or_append( "\n\n\n", $html, 0);

  if ($html)
  {

    my $tt_color    = Constants::TRIPLE_TRIPLE_COLOR;
    my $na_color    = Constants::NINE_OR_ABOVE_COLOR;
    my $im_color    = Constants::IMPROBABLE_COLOR;
    my $tt_na_color = Constants::TRIPLE_TRIPLE_NINE_COLOR;
    my $im_na_color = Constants::IMPROBABLE_NINE_OR_ABOVE_COLOR;
    my $im_tt_color = Constants::IMPROBABLE_TRIPLE_TRIPE_COLOR;
    my $at_color    = Constants::ALL_THREE_COLOR;

    my $opening_mark_tag = "<mark style='background-color: ";
    my $closing_mark_tag = "</mark>";  

    print_or_append( "COLOR KEY:\n\n", $html, 0);
    print_or_append( "  $opening_mark_tag $tt_color'>Triple Triple$closing_mark_tag\n\n", $html, 0);
    print_or_append( "  $opening_mark_tag $na_color'>Bingo Nine or Above$closing_mark_tag\n\n", $html, 0);
    print_or_append( "  $opening_mark_tag $im_color'>Improbable$closing_mark_tag\n\n", $html, 0);
    print_or_append( "  $opening_mark_tag $tt_na_color'>Triple Triple and Bingo Nine or Above$closing_mark_tag\n\n", $html, 0);
    print_or_append( "  $opening_mark_tag $im_na_color'>Improbable and Bingo Nine or Above$closing_mark_tag\n\n", $html, 0);
    print_or_append( "  $opening_mark_tag $im_tt_color'>Triple Triple and Improbable$closing_mark_tag\n\n", $html, 0);
    print_or_append( "  $opening_mark_tag $at_color'>Triple Triple and Bingo Nine or Above and Improbable$closing_mark_tag\n\n", $html, 0);
    
    print_or_append( "\n\n", $html, 0);

    print_or_append("<div id='" . Constants::ERROR_DIV_ID . "' style='display: none;'>", $html, 0);

  }

  my $all_stats = Stats->new(1);

  my %tourney_game_hash;
  my $at_least_one = 0;

  my $num_errors   = 0;
  my $num_warnings = 0;

  my $games_table   = Constants::GAMES_TABLE_NAME;
  my $players_table = Constants::PLAYERS_TABLE_NAME;

  my $player_sanitized_name_column_name           = Constants::PLAYER_SANITIZED_NAME_COLUMN_NAME;
  my $player_cross_tables_id_column_name          = Constants::PLAYER_CROSS_TABLES_ID_COLUMN_NAME;
  my $game_cross_tables_id_column_name            = Constants::GAME_CROSS_TABLES_ID_COLUMN_NAME;
  my $game_player1_cross_tables_id_column_name    = Constants::GAME_PLAYER_ONE_CROSS_TABLES_ID_COLUMN_NAME;
  my $game_player2_cross_tables_id_column_name    = Constants::GAME_PLAYER_TWO_CROSS_TABLES_ID_COLUMN_NAME;
  my $game_player1_name_column_name               = Constants::GAME_PLAYER_ONE_NAME_COLUMN_NAME;
  my $game_player2_name_column_name               = Constants::GAME_PLAYER_TWO_NAME_COLUMN_NAME;
  my $game_cross_tables_tournament_id_column_name = Constants::GAME_CROSS_TABLES_TOURNAMENT_ID_COLUMN_NAME;
  my $game_lexicon_column_name                    = Constants::GAME_LEXICON_COLUMN_NAME;
  my $game_round_column_name                      = Constants::GAME_ROUND_COLUMN_NAME;
  my $game_name_column_name                       = Constants::GAME_NAME_COLUMN_NAME;
  my $game_date_column_name                       = Constants::GAME_DATE_COLUMN_NAME;
  my $game_stats_column_name                      = Constants::GAME_STATS_COLUMN_NAME;
  my $game_error_column_name                      = Constants::GAME_ERROR_COLUMN_NAME;
  my $game_warning_column_name                    = Constants::GAME_WARNING_COLUMN_NAME;

  my $opp_table_statement = "";
  my $opp_query           = "";

  if ($opponent_name)
  {
    my $opp_id = $names_to_ids_hashref->{$opponent_name};
    $opp_query =
    "
      AND opp.$player_cross_tables_id_column_name = $opp_id
      AND
         (
          opp.$player_cross_tables_id_column_name = g.$game_player1_cross_tables_id_column_name OR
          opp.$player_cross_tables_id_column_name = g.$game_player2_cross_tables_id_column_name
         )
    ";

    $opp_table_statement = " , $players_table AS opp ";
  } 

  my $games_query =
  "
  SELECT 
       $game_player1_name_column_name,
       $game_player2_name_column_name,
       $game_error_column_name,
       $game_warning_column_name,
       $game_player1_cross_tables_id_column_name,
       $game_player2_cross_tables_id_column_name,
       $game_stats_column_name
  FROM $games_table AS g, $players_table AS p $opp_table_statement
  WHERE
        p.$player_cross_tables_id_column_name = $player_id AND
        (
         g.$game_player1_cross_tables_id_column_name =
         p.$player_cross_tables_id_column_name
         OR
         g.$game_player2_cross_tables_id_column_name =
         p.$player_cross_tables_id_column_name
        )
  $opp_query
  ";

  if ($single_game_id)
  {
    $games_query .= " AND g.$game_cross_tables_id_column_name = $single_game_id";
  }
  if ($tourney_id)
  {
    $games_query .= " AND g.$game_cross_tables_tournament_id_column_name = $tourney_id";
  }
  if ($startdate)
  {
    $games_query .= " AND g.$game_date_column_name >= '$startdate'";
  }
  if ($enddate)
  {
    $games_query .= " AND g.$game_date_column_name <= '$enddate'";
  }
  if ($lexicon)
  {
    $games_query .= " AND g.$game_lexicon_column_name = '$lexicon'";
  }
  if ($cort eq Constants::TOURNAMENT_OPTION)
  {
    $games_query .= " AND g.$game_cross_tables_tournament_id_column_name > 0";
  }
  elsif ($cort eq Constants::CASUAL_OPTION)
  {
    $games_query .= " AND g.$game_cross_tables_tournament_id_column_name = 0";
  }

  my @game_results = @{$dbh->selectall_arrayref($games_query, {Slice => {}, "RaiseError" => 1})};
  my $num_games = 0;

  while (@game_results)
  {
    my $game = shift @game_results;

    my $error   = $game->{$game_error_column_name};
    my $warning = $game->{$game_warning_column_name};

    my $game_opp_name = $game->{$game_player2_name_column_name};
    my $player_is_first = 1;
   
    my $player2_id = $game->{$game_player2_cross_tables_id_column_name};

    if ($player2_id && $player_id == $player2_id)
    {
      $player_is_first = 0;
      $game_opp_name = $game->{$game_player1_name_column_name};
    }
    
    my $game_id = $game->{$game_cross_tables_id_column_name};

    if ($error)
    {
      print_or_append( "\n$error", $html, 1);
      $num_errors++;
      next;
    }
    elsif ($warning)
    {
      print_or_append( "\n$warning", $html, 0);
      $num_warnings++;
    }

    my $game_stat = Stats->new($player_is_first, $game->{$game_stats_column_name});

    $all_stats->addStat($game_stat);
    $num_games++;
    $at_least_one = 1;
  }

  if ($statsdump && $at_least_one)
  {
    my $dump = JSON::XS::encode_json(Utils::prepare_stats($all_stats));
    Utils::update_player_record($dbh, 0, 0, $player_name, $dump, $num_games);
  }

  if ($html)
  {
      print_or_append("</div>\n", $html, 0);
      print_or_append( "\n", $html, 0);
      print_or_append( "Errors:   $num_errors\n", $html, 0);
      print_or_append( "Warnings: $num_warnings\n", $html, 0);
      print_or_append( "\n", $html, 0);
      print_or_append("<button onclick='toggle(\"" . Constants::ERROR_DIV_ID . "\")'>Toggle Error and Warning Report</button>\n", $html, 0);
  }

  print_or_append($stats_note, $html, 0);

  if ($at_least_one)
  {
    if ($html)
    {
      $html_string .= $all_stats->toString($html);
    }
    else
    {
      print $all_stats->toString($html);
    }
  }
  else
  {
    print_or_append( "\nNo valid games found\n", $html, 0);
  }
  print_or_append( "\n", $html, 0);
  print_or_append( "Errors:   $num_errors\n", $html, 0);
  print_or_append( "Warnings: $num_warnings\n", $html, 0);
  print_or_append( "\n", $html, 0);

  my $start_tags = "<!DOCTYPE HTML><html><body> $javascript <pre style='white-space: pre-wrap;' >";
  my $end_tags   = "</pre></body></html>";

  my $final_output = "$start_tags $html_string $end_tags\n";

  if ($cache_condition && $at_least_one && $statsdump)
  {
    my $lt = localtime();
    system "mkdir -p $cache_dir";
    open(my $fh, '>', $cache_filename);
    print $fh "$start_tags $html_string \n\nThis report was produced from a file cached on $lt\n$end_tags\n";
    close $fh;
  }

  if ($html)
  {
    print $final_output;
  }
}

sub print_or_append
{
  my $addition    = shift;
  my $html        = shift;
  my $error       = shift;

  if ($html)
  {
    $html_string .= $addition;
  }
  else
  {
    if ($error)
    {
      print STDERR $addition;
    }
    else
    {
      print $addition;
    }
  }
}

1;


