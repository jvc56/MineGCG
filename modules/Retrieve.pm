#!/usr/bin/perl

package Retrieve;

use warnings;
use strict;
use Data::Dumper;

use lib './modules';
use Constants;
use Utils;
use Update;

use CSW07;
use CSW12;
use CSW15;
use CSW19;
use TWL98;
use TWL06;
use TWL15;
use NSW18;

unless (caller)
{
  retrieve(Constants::UPDATE_OPTION_STATS);
}

sub retrieve
{
  # Constants
  my $downloads_dir              = Constants::DOWNLOADS_DIRECTORY_NAME;
  my $cache_dir                  = Constants::CACHE_DIRECTORY_NAME;

  system "mkdir -p $downloads_dir";

  my $update            = shift;

  my $dbh = Utils::connect_to_database();

  my @every_annotated_game_info = Utils::get_all_annotated_game_info();
  my %updated_players = ();
  my %name_id_hash    = ();
  my %id_name_hash    = ();
  my %tournament_id_date_hash = ();

  my $games_to_update = scalar @every_annotated_game_info;
  my $games_updated   = 0;

  while (@every_annotated_game_info)
  {
    my $annotated_game_data = shift @every_annotated_game_info;
    
    Utils::prepare_anno_data($annotated_game_data, \%id_name_hash, \%tournament_id_date_hash);

    my $game_xt_id       = $annotated_game_data->[0];
    my $player_one_xt_id = $annotated_game_data->[1];
    my $player_two_xt_id = $annotated_game_data->[2];
    my $player_one_name  = $annotated_game_data->[3];
    my $player_two_name  = $annotated_game_data->[4];
    my $tournament_xt_id = $annotated_game_data->[5];
    my $round            = $annotated_game_data->[6];
    my $lexicon          = $annotated_game_data->[7];
    my $upload_date      = $annotated_game_data->[8];
    my $date             = $annotated_game_data->[10];

    if (!$lexicon)
    {
      next;
    }
    my $lexicon_ref = get_lexicon_ref(uc($lexicon));

    if (!$lexicon_ref)
    {
      next;
    }

    $annotated_game_data->[9] = $lexicon_ref;

    my @players_to_update = ([$player_one_xt_id, $player_one_name], [$player_two_xt_id, $player_two_name]);

    foreach my $item (@players_to_update)
    {
      my $id   = $item->[0];
      my $name = $item->[1];
      if (!$name)
      {
        print "Name undefined: " . $annotated_game_data->[0] . "\n";
      }
      if ($id && !$updated_players{$id})
      {
        $updated_players{$id} = 1;
        $name_id_hash{Utils::sanitize($name)} = $id;
        Utils::update_player_record($dbh, $id, $name, Utils::sanitize($name));
      }
    }

    my @game_query = @{Utils::query_table($dbh, Constants::GAMES_TABLE_NAME, Constants::GAME_CROSS_TABLES_ID_COLUMN_NAME, $game_xt_id)};
    if (!@game_query)
    {
      $games_updated++;
    }
    Utils::update_stats($dbh, $game_query[0], $annotated_game_data, $update);
  }
  print "\n\n$games_to_update games detected in API call\n";
  print "$games_updated new games retrieved\n";
  Update::update_name_id_hash(\%name_id_hash);
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
    $lexicon_ref = TWL15::TWL15_LEXICON;
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

1;
