#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

use lib "./objects"; 
use lib "./lexicons";

use Game;
use Constants;
use Stats;

use CSW07;
use CSW12;
use CSW15;
use TWL98;
use TWL06;
use American;

my $html_string = "";


sub mine
{
  my $dir_name                = Constants::GAME_DIRECTORY_NAME;
  my $names_dir               = Constants::NAMES_DIRECTORY_NAME;
  my $blacklisted_tournaments = Constants::BLACKLISTED_TOURNAMENTS;

  my $player_name    = shift;
  my $cort           = shift;
  my $single_game_id = shift;
  my $verbose        = shift;
  my $tourney_id     = shift;
  my $html           = shift;

  print_or_append( "\nProcessing game data...\n\n", $html, 0);

  print_or_append( "\nStatistics for $player_name\n\n", $html, 0);

  print_or_append( "\nThe two numbers after each bingo are the probability and the game number, respectively.\n", $html, 0);
  print_or_append( "\nFor example, the bingo:\n\n", $html, 0);
  print_or_append( "TETrODE 3294 [30361]\n\n", $html, 0);
  print_or_append( "Has a probability of 3294 and appears in game 30361.\n", $html, 0);
  
  print_or_append( "\nPhonies and challenged plays don't have probabilities listed and are followed only by the game number.\n", $html, 0);  

  print_or_append( "\nYou can access games by their game number by using this address:\n", $html, 0);
  print_or_append( "https://www.cross-tables.com/annotated.php?u=<game_number>\n", $html, 0);
  print_or_append( "\nFor example, the TETrODE bingo appears in the game at this address:\n", $html, 0);
  print_or_append( "https://www.cross-tables.com/annotated.php?u=30361\n\n", $html, 0);


  my $all_stats = Stats->new();
  my $single_game_stats = Stats->new();
  my %tourney_game_hash;
  my $at_least_one = 0;

  my $num_errors   = 0;
  my $num_warnings = 0;

  my $player_indexes_filename = "$names_dir/$player_name.txt";
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
      my $player_two_name = $meta_data[7];
      my $ext             = $meta_data[8];

      my $player_is_first = 0;

      if ($player_one_name ne $player_name)
      {
        $player_is_first = 1;
        if ($player_two_name ne $player_name)
        {
          print_or_append( "Didn't find a matching player name for $game_file_name\n", $html, 0);
          return;
        }
      }

      if (!$ext || $ext ne "gcg")
      {
        print_or_append( "\nERROR:  invalid file extension\nFILE:   $game_file_name", $html, 1);
        $num_errors++;
        next;
      }

      my $full_game_file_name = $dir_name . '/' . $game_file_name;
      
      if (!(-e $full_game_file_name))
      {
        print_or_append( "\nERROR: No GCG found for index $full_game_file_name\n", $html, 1);
        $num_errors++;
        next;
      }

      if ($single_game_id && $single_game_id ne $id)
      {
        if ($verbose) {print_or_append( "Game $full_game_file_name is not the specified game\n", $html, 0);}
        next;
      }
      if ($tourney_id && $game_tourney_id ne $tourney_id)
      {
        if ($verbose) {print_or_append( "Game $full_game_file_name is not in the specified tournament\n", $html, 0);}
        next;
      }
      if ($blacklisted_tournaments->{$game_tourney_id})
      {
        if ($verbose) {print_or_append( "Game $full_game_file_name is from a blacklisted tournament\n", $html, 0);}
        next;
      }

      my $is_tourney_game = $tourney_name ne Constants::NON_TOURNAMENT_GAME;

      # Check for casual/club or only tournament games
      if ( (uc $cort eq 'T' && !$is_tourney_game) || (uc $cort eq 'C' && $is_tourney_game))
      {
        if ($verbose) {print_or_append( "Game $full_game_file_name is not the specified type\n", $html, 0);}
        next;
      }

      # Check for repeat tournament games
      if ($game_tourney_id && $round_number && $is_tourney_game)
      {
        my $key = $game_tourney_id.'+'.$round_number;
        if($tourney_game_hash{$key})
        {
          if ($verbose) {print_or_append( "Repeat game $full_game_file_name found with tournament id $game_tourney_id and round number $round_number\n", $html, 0);}
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
        if ($verbose) {print_or_append( "No lexicon found for game $full_game_file_name, using CSW15 as a default\n", $html, 0);}
        $lexicon_ref = CSW15::CSW15_LEXICON;
      }

      my $game = Game->new($full_game_file_name, $player_is_first, $lexicon_ref, $player_one_name, $player_two_name);
      
      if (ref($game) ne "Game")
      {
        print_or_append( "\nERROR:  $game", $html, 1);
        $num_errors++;
        next;
      }
      elsif ($game->{'warnings'})
      {
        print_or_append( "\n" . $game->{'warnings'}, $html, 0);
        $num_warnings++;
      }

      if ($verbose)
      {
       print_or_append( "\nData structures for $full_game_file_name\n\n", $html, 0);
       print_or_append( $game->toString(), $html, 0);
       $single_game_stats->addGame($game);
       print_or_append( $single_game_stats->toString(), $html, 0);
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
      print_or_append( $all_stats->toString(), $html, 0);
    }
    else
    {
      print_or_append( $all_stats->toStringHTML(), $html, 0);
    }
  }
  else
  {
    print_or_append( "\nNo valid games found\n", $html, 0);
    print_or_append( "To update or reset the games directory, use the --update or --reset flags respectively\n", $html, 0);
    print_or_append( "To attempt to resolve inconsistencies, use the --resolve flag\n", $html, 0);
  }
  print_or_append( "\n", $html, 0);
  print_or_append( "Errors:   $num_errors\n", $html, 0);
  print_or_append( "Warnings: $num_warnings\n", $html, 0);
  print_or_append( "\n", $html, 0);

  if ($html)
  {
    print "<pre style='white-space: pre-wrap;' > $html_string </pre>";
  }
}


sub print_or_append
{
  my $addition    = shift;
  my $append      = shift;
  my $error       = shift;
  if ($append)
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


