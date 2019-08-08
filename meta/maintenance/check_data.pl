#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use lib './objects';
use Constants;

require './scripts/utils.pl';

print "Data integrity log file for check_data.pl on " . localtime() . "\n\n"; 


my $dbh = connect_to_database();
my $gamestable = Constants::GAMES_TABLE_NAME;
my $game_player1_cross_tables_id_column_name    = Constants::GAME_PLAYER_ONE_CROSS_TABLES_ID_COLUMN_NAME;
my $game_player2_cross_tables_id_column_name    = Constants::GAME_PLAYER_TWO_CROSS_TABLES_ID_COLUMN_NAME;


# Ensure that no one plays themselves

my $self_play_query =
  "
  SELECT *
  FROM $gamestable
  WHERE $game_player1_cross_tables_id_column_name = $game_player2_cross_tables_id_column_name
  ";

my @self_play_results = @{$dbh->selectall_arrayref($self_play_query, {Slice => {}, "RaiseError" => 1})};

if (@self_play_results)
{
  print "Games where players played themselves:\n\n";
  print Dumper(\@self_play_results);
  print "\n\n";
}


# Ensure that all games link to at least one players

my $no_player_query =
  "
  SELECT *
  FROM $gamestable
  WHERE $game_player1_cross_tables_id_column_name is NULL AND $game_player2_cross_tables_id_column_name is NULL
  ";

my @no_player_results = @{$dbh->selectall_arrayref($no_player_query, {Slice => {}, "RaiseError" => 1})};

if (@no_player_results)
{
  print "Games where there are no linked players:\n\n";
  print Dumper(\@no_player_results);
  print "\n\n";
}





 








