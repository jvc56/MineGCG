#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

use lib "./objects"; 
use lib "./lexicons";
require "./scripts/utils.pl";

use Game;
use Constants;
use Stats;

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

  my $dbh = connect_to_database();

  my $player_name       = shift;
  my $cort              = shift;
  my $single_game_id    = shift;
  my $opponent_name     = shift;
  my $startdate         = shift;
  my $enddate           = shift;
  my $lexicon           = shift;
  my $verbose           = shift;
  my $tourney_id        = shift;
  my $html              = shift;
  my $statsdump         = shift;
  my $notabledump       = shift;
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

  my $games_query =
  "
  SELECT *
  FROM $games_table AS g, $players_table AS p, $players_table AS opp
  WHERE
        p.sanitized_name = '$player_name' AND
        (g.player1_cross_tables_id = p.cross_tables_id OR g.player2_cross_tables_id = p.cross_tables_id)
  ";

  if ($single_game_id)
  {
    $games_query .= " AND g.cross_tables_id = '$single_game_id'";
  }
  if ($tourney_id)
  {
    $games_query .= " AND g.cross_tables_tournament_id = '$tourney_id'";
  }
  if ($opponent_name)
  {
    $games_query .=
    "
      AND opp.sanitized_name = '$opponent_name'
      AND
         (
          opp.cross_tables_id = g.player1_cross_tables_id OR
          opp.cross_tables_id = g.player2_cross_tables_id
         )
    ";
  }
  if ($startdate)
  {
    $games_query .= " AND g.date > '$startdate'";
  }
  if ($enddate)
  {
    $games_query .= " AND g.date < '$enddate'";
  }
  if ($lexicon)
  {
    $games_query .= " AND g.lexicon = 'lexicon'";
  }
  if ($cort eq 'T')
  {
    $games_query .= " AND g.cross_tables_tournament_id > 0";
  }
  elsif ($cort eq 'C')
  {
    $games_query .= " AND g.cross_tables_tournament_id = 0";
  }

  my @game_results = @{$dbh->selectall_arrayref($games_query, {Slice => {}, "RaiseError" => 1})};

  while (@game_results)
  {
    my $game = shift @game_results;

    my $error   = $game->{'error'};
    my $warning = $game->{'warning'};

    my $game_opp_name = $game->{'player1_name'};
    my $player_is_first = 0;
    
    if (sanitize($game->{'player1_name'}) eq $player_name)
    {
      $player_is_first = 1;
      $game_opp_name = $game->{'player2_name'};
    }
    
    my $game_id = $game->{'cross_table_id'};

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

    my $game_stat = Stats->new($player_is_first, $game->{'stats'});

    $all_stats->addStat($game_stat);

    $at_least_one = 1;
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


