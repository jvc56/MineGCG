#!/usr/bin/perl

package Mine;

use warnings;
use strict;
use Data::Dumper;

use lib "./objects"; 
use lib "./lexicons";

use Game;
use Constants;
use Stats;
use Utils;

use CSW07;
use CSW12;
use CSW15;
use CSW19;
use TWL98;
use TWL06;
use American;
use NSW18;

my $html_string = "";


sub mine
{
  my $stats_dir               = Constants::STATS_DIRECTORY_NAME;
  my $notable_dir             = Constants::NOTABLE_DIRECTORY_NAME;
  my $blacklisted_tournaments = Constants::BLACKLISTED_TOURNAMENTS;
  my $cache_dir               = Constants::CACHE_DIRECTORY_NAME;
  my $stats_note              = Constants::STATS_NOTE;

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

  if ($cache_condition && -e $cache_filename)
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

  my $player_name_no_underscore = $player_name;
  $player_name_no_underscore =~ s/_/ /g;

  my $opponent_name_no_underscore = $opponent_name;
  $opponent_name_no_underscore =~ s/_/ /g;

  my $javascript = "";

  if ($html)
  {
    $javascript .= Constants::RESULTS_PAGE_JAVASCRIPT;
  }

  print_or_append( "\nStatistics for $player_name_no_underscore\n\n\n", $html, 0);
  
  print_or_append( "\nSEARCH PARAMETERS: \n", $html, 0);
  
  print_or_append( "\n  Player:        $player_name_no_underscore", $html, 0);


  print_or_append( "\n  Game type:     ", $html, 0);

  if (uc $cort eq 'C') {print_or_append( "CLUB OR CASUAL", $html, 0);}
  elsif (uc $cort eq 'T') {print_or_append( "TOURNAMENT", $html, 0);}
  else {print_or_append( "-", $html, 0);}

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

  my $games_query =
  "
  SELECT *
  FROM $games_table AS g, $players_table AS p, $players_table AS opp
  WHERE
        p.$player_sanitized_name_column_name = '$player_name' AND
        (
         g.$game_player1_cross_tables_id_column_name =
         p.$player_cross_tables_id_column_name
         OR
         g.$game_player2_cross_tables_id_column_name =
         p.$player_cross_tables_id_column_name
        )
  ";

  if ($single_game_id)
  {
    $games_query .= " AND g.$game_cross_tables_id_column_name = '$single_game_id'";
  }
  if ($tourney_id)
  {
    $games_query .= " AND g.$game_cross_tables_tournament_id_column_name = '$tourney_id'";
  }
  if ($opponent_name)
  {
    $games_query .=
    "
      AND opp.$player_sanitized_name_column_name = '$opponent_name'
      AND
         (
          opp.$player_cross_tables_id_column_name = g.$game_player1_cross_tables_id_column_name OR
          opp.$player_cross_tables_id_column_name = g.$game_player2_cross_tables_id_column_name
         )
    ";
  }
  if ($startdate)
  {
    $games_query .= " AND g.$game_date_column_name > '$startdate'";
  }
  if ($enddate)
  {
    $games_query .= " AND g.$game_date_column_name < '$enddate'";
  }
  if ($lexicon)
  {
    $games_query .= " AND g.$game_lexicon_column_name = 'lexicon'";
  }
  if ($cort eq 'T')
  {
    $games_query .= " AND g.$game_cross_tables_tournament_id_column_name > 0";
  }
  elsif ($cort eq 'C')
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

    my $game_opp_name = $game->{game_player1_cross_tables_id_column_name};
    my $player_is_first = 0;
    
    my $player1_name = $game->{game_player1_name_column_name};
    if ($player1_name && sanitize($player1_name) eq $player_name)
    {
      $player_is_first = 1;
      $game_opp_name = $game->{$game_player2_name_column_name};
    }
    
    my $game_id = $game->{$game_cross_tables_id_column_name};

    if ($error)
    {
      print_or_append( "\nERROR:  $error", $html, 1, $game_opp_name, $game_id);
      $num_errors++;
      next;
    }
    elsif ($warning)
    {
      print_or_append( "\n$warning", $html, 0, $game_opp_name, $game_id);
      $num_warnings++;
    }

    my $game_stat = Stats->new($player_is_first, $game->{$game_stats_column_name});

    $all_stats->addStat($game_stat);
    $num_games++;
    $at_least_one = 1;
  }

  if ($statsdump)
  {
    Utils::update_player_record($dbh, 0, 0, $player_name, prepare_stats($all_stats), $num_games);
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

  if ($cache_condition && $at_least_one)
  {
    if (!(-e $cache_filename))
    {
      my $lt = localtime();
      system "mkdir -p $cache_dir";
      open(my $fh, '>', $cache_filename);
      print $fh "$start_tags $html_string \n\nThis report was produced from a file cached on $lt\n$end_tags\n";
      close $fh;
    }
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
  my $opp         = shift;
  my $id          = shift;

  if ($html)
  {
    if ($opp)
    {
      my $url = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX;
      my $link = "<a href='$url$id' target='_blank'>against $opp</a>";
      $addition =~ s/\.\/.*\/\d+\.html/$link/g;
    }
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


