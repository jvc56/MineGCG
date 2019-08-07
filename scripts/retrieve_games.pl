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
  my $downloads_dir              = Constants::DOWNLOADS_DIRECTORY_NAME;

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

  my $update_stats = $update eq "stats";
  my $update_gcg   = $update eq "gcg";

  my $player_cross_tables_id = get_player_cross_tables_id($player_name, $raw_name);

  if (!$player_cross_tables_id)
  {
    return;
  }

  my @game_info = @{get_player_annotated_game_data($player_cross_tables_id)};

  my $player_record_id = update_player_record($dbh, $player_cross_tables_id, $raw_name, $player_name);

  my $games_to_update = scalar @game_info;
  my $count           = 0;
  my $games_updated   = 0;

  while (@game_info)
  {
    my $annotated_game_data = shift @game_info;

    sanitize_game_data($annotated_game_data);

    my $game_cross_tables_id = $annotated_game_data->[0];

    my $game_lexicon         = $annotated_game_data->[6];

    my $lexicon_ref          = get_lexicon_ref($game_lexicon);

    $count++;
    my $num_str = (sprintf "%-4s", $count) . " of $games_to_update:";
    
    if (!$lexicon_ref)
    {
      if ($verbose) {print "$num_str Game with ID $game_cross_tables_id is not a tournament game\n";}
      next;
    }

    my @game_query = @{query_table($dbh, Constants::GAMES_TABLE_NAME, 'cross_tables_id', $game_cross_tables_id)};
    
    if (@game_query)
    {
      my $foreign_keys_missing = !$game_query[0]->{'player1_cross_tables_id'} || !$game_query[0]->{'player2_cross_tables_id'};

      if (!$update_gcg && $update_stats)
      {
        if ($verbose){print "$num_str Updating stats for $game_cross_tables_id\n";}
        update_stats_or_create_record
        (
          $dbh,
          $player_name,
          $player_cross_tables_id,
          $game_query[0],
          $annotated_game_data,
          $game_query[0]->{'gcgtext'},
          $lexicon_ref,
          $game_query[0]->{'player1_name'},
          $game_query[0]->{'player2_name'},
          $html,
          $missingracks,
          $game_lexicon,
          $game_cross_tables_id,
          $annotated_game_data
        );
        $games_updated++;
      }
      elsif ($update_gcg)
      {
        if ($verbose){print "$num_str Updating gcg for $game_cross_tables_id\n";}
        update_stats_or_create_record
        (
          $dbh,
          $player_name,
          $player_cross_tables_id,
          $game_query[0],
          $annotated_game_data,
          0,
          $lexicon_ref,
          0,
          0,
          $html,
          $missingracks,
          $game_lexicon,
          $game_cross_tables_id,
          $annotated_game_data
        );
        $games_updated++;
      }
      else
      {
        if ($foreign_keys_missing)
        {
          if ($verbose){print "$num_str Updating foreign keys for $game_cross_tables_id\n";}
          update_foreign_keys
          (
            $dbh,
            $game_cross_tables_id,
            $player_cross_tables_id
          );
        }
        else
        {
          if ($verbose){print "$num_str Game $game_cross_tables_id is up to date\n";}
        }
      }
    }
    else
    {
      my $is_valid =
      is_valid_game
      (
        $player_name         ,
        $tourney_id          ,
        $tourney_or_casual   ,
        $single_game_id      ,
        $opponent_name       ,
        $startdate           ,
        $enddate             ,
        $lexicon             ,
        $verbose             ,
        $num_str             ,
        $game_cross_tables_id,
        $annotated_game_data
      );

      if (!$is_valid)
      {
        next;
      }
      if ($verbose){print "$num_str Creating game $game_cross_tables_id\n";}

      update_stats_or_create_record
      (
        $dbh,
        $player_name,
        $player_cross_tables_id,
        0,
        $annotated_game_data,
        0,
        $lexicon_ref,
        0,
        0,
        $html,
        $missingracks,
        $game_lexicon,
        $game_cross_tables_id,
        $annotated_game_data
      );
      $games_updated++;
    }
  }
  if ($games_updated)
  {
    print ((sprintf "%-30s", $player_name . ":") . "$games_updated games updated or created\n");
  }
}

1;
