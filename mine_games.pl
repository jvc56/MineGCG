#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use lib '.';
use Game;
use Constants;
use Stats;

use lib 'lexicons';
use CSW07;
use CSW12;
use CSW15;
use TWL98;
use TWL06;
use American;


use Cwd qw(abs_path);

sub mine($$$$)
{
  my $dir_name                = Constants::GAME_DIRECTORY_NAME;
  my $names_dir               = Constants::NAMES_DIRECTORY_NAME;
  my $blacklisted_tournaments = Constants::BLACKLISTED_TOURNAMENTS;

  my $player_name = shift;
  my $cort        = shift;
  my $verbose     = shift;
  my $tourney_id  = shift;
  my $html        = shift;

  print "\nProcessing game data...\n\n";

  my $all_stats = Stats->new();
  my $single_game_stats = Stats->new();
  my %tourney_game_hash;
  my $at_least_one = 0;

  my $sanitized_name = $player_name;
  $sanitized_name =~ s/ /_/g;
  $sanitized_name =~ s/'//g; # Name is now no longer raw
  my $player_indexes_filename = "$names_dir/$sanitized_name.txt";
  if (-e $player_indexes_filename)
  {
    open(PLAYER_INDEXES, '<', $player_indexes_filename);
    while (<PLAYER_INDEXES>)
    {
      chomp $_;
      my $game_file_name = $_;
      if (!$game_file_name){next;}

      my @meta_data = split /\./, $game_file_name;
      my $date            = $meta_data[0];
      my $game_tourney_id = $meta_data[1];
      my $round_number    = $meta_data[2];
      my $tourney_name    = $meta_data[3];
      my $lexicon         = $meta_data[4];
      my $id              = $meta_data[5];
      my $player_one_name = $meta_data[6];
      $player_one_name    =~ s/_/ /g;
      my $player_two_name = $meta_data[7];
      $player_two_name    =~ s/_/ /g;
      my $ext             = $meta_data[8];

      if (($tourney_id && $game_tourney_id ne $tourney_id) || !$ext || $ext ne "gcg"){next;}
      my $full_game_file_name = $dir_name . '/' . $game_file_name;
      if (!(-e $full_game_file_name))
      {
        print "No GCG found for $full_game_file_name, rerun with the -u option to correct\n";
        next;
      }

      if ($blacklisted_tournaments->{$game_tourney_id})
      {
        print "Game $full_game_file_name is from a blacklisted tournament\n";
        next;
      }

      my $is_tourney_game = $tourney_name ne Constants::NON_TOURNAMENT_GAME;

      # Check for casual/club or only tournament games
      if ( (uc $cort eq 'T' && !$is_tourney_game) || (uc $cort eq 'C' && $is_tourney_game))
      {
        next;
      }

      # Check for repeat tournament games
      if ($game_tourney_id && $round_number && $is_tourney_game)
      {
        my $key = $game_tourney_id.'+'.$round_number;
        if($tourney_game_hash{$key})
        {
          print "Repeat game $full_game_file_name found with tournament id $game_tourney_id and round number $round_number. Skipping...\n";
          next;
        }
        $tourney_game_hash{$key} = 1;
      }

      my $lexicon_ref;

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
      else
      {
        print "No lexicon found for game $full_game_file_name, using CSW15 as a default\n";
        $lexicon_ref = CSW15::CSW15_LEXICON;
      }
      my $player_is_first = 0;

      if ($player_one_name ne $player_name)
      {
        $player_is_first = 1;
        if ($player_two_name ne $player_name)
        {
          print "Didn't find a matching player name for $game_file_name\n";
          return;
        }
      }
      #print "$full_game_file_name\n";
      my $game = Game->new($full_game_file_name, $player_is_first, $lexicon_ref, $player_one_name, $player_two_name);
      if (!$game->{'valid'})
      {
        print "Skipping malformed gcg file: $full_game_file_name\n";
        next;
      }
      if ($verbose)
      {
        print "\nData structures for $full_game_file_name\n\n";
        print $game->toString();
        $single_game_stats->addGame($game);
        print $single_game_stats->toString();
        $single_game_stats->resetStats();
      }
      
      $all_stats->addGame($game);
      $at_least_one = 1;
    }
  }
  if ($at_least_one)
  {
    if (!$html)
    {
      print $all_stats->toString();
    }
    else
    {
      print $all_stats->toStringHTML();
    }
  }
  else
  {
    print "\nNo valid games found in " . abs_path($dir_name) . "\n";
    print "To update or reset this directory, use the -u or -r flags respectively\n";
    print "Invalid games are usually the result of malformed GCG files\n";
    print "Report a bug if you think valid GCG files are being marked as invalid\n\n";
  }
}

1;


