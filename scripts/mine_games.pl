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
use NSW18;

my $html_string = "";


sub mine
{
  my $dir_name                = Constants::GAME_DIRECTORY_NAME;
  my $names_dir               = Constants::NAMES_DIRECTORY_NAME;
  my $stats_dir               = Constants::STATS_DIRECTORY_NAME;
  my $blacklisted_tournaments = Constants::BLACKLISTED_TOURNAMENTS;
  my $stats_note = Constants::STATS_NOTE;

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


  my $player_name_no_underscore = $player_name;
  $player_name_no_underscore =~ s/_/ /g;

  my $opponent_name_no_underscore = $opponent_name;
  $opponent_name_no_underscore =~ s/_/ /g;

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
  }

  my $all_stats = Stats->new();
  my $single_game_stats = Stats->new();
  my %tourney_game_hash;
  my $at_least_one = 0;

  my $num_errors   = 0;
  my $num_warnings = 0;

  my $player_indexes_filename = "$names_dir/$player_name.txt";
  if (-e $player_indexes_filename && $player_name ne $opponent_name)
  {
    open(PLAYER_INDEXES, '<', $player_indexes_filename);
    while (<PLAYER_INDEXES>)
    {
      chomp $_;
      my $game_file_name = $_;
      if (!$game_file_name){next;}

      my @meta_data = split /\./, $game_file_name;
      my $date            = $meta_data[0];
      my $date_sanitized  = $date;
      $date_sanitized =~ s/[^\d]//g;
      my $game_tourney_id = $meta_data[1];
      my $round_number    = $meta_data[2];
      my $tourney_name    = $meta_data[3];
      my $this_lexicon    = $meta_data[4];
      my $id              = $meta_data[5];
      my $player_one_name = $meta_data[6];
      my $player_two_name = $meta_data[7];
      my $ext             = $meta_data[8];

      my $player_is_first = 0;

      my $full_game_file_name = $dir_name . '/' . $game_file_name;

      if ($player_one_name ne $player_name)
      {
        $player_is_first = 1;
        if ($player_two_name ne $player_name)
        {
          print_or_append( "\nERROR:  Matching player name not found\nFILE:   $full_game_file_name\n", $html, 1, $player_name);
          return;
        }
      }

      if ($single_game_id && $single_game_id ne $id)
      {
        if ($verbose) {print_or_append( "Game $full_game_file_name is not the specified game\n", $html, 0, $player_name);}
        next;
      }
      if ($tourney_id && $game_tourney_id ne $tourney_id)
      {
        if ($verbose) {print_or_append( "Game $full_game_file_name is not in the specified tournament\n", $html, 0, $player_name);}
        next;
      }
      if ($opponent_name && $opponent_name ne $player_one_name && $opponent_name ne $player_two_name)
      {
        if ($verbose) {print_or_append( "Game $full_game_file_name is not against the specified opponent\n", $html, 0, $player_name);}
        next;
      }
      if (($startdate && $date_sanitized < $startdate) || ($enddate && $date_sanitized > $enddate))
      {
        if ($verbose) {print_or_append( "Game $full_game_file_name is not in the specified timeframe\n", $html, 0, $player_name);}
        next;  
      }
      if ($lexicon && $this_lexicon ne $lexicon)
      {
        if ($verbose) {print_or_append( "Game $full_game_file_name is not in the specified lexicon\n", $html, 0, $player_name);}
        next;  
      }
      if ($blacklisted_tournaments->{$game_tourney_id})
      {
        print_or_append( "Game $full_game_file_name is from a blacklisted tournament\n", $html, 0, $player_name);
        next;
      }

      my $is_tourney_game = $tourney_name;

      # Check for casual/club or only tournament games
      if ( (uc $cort eq 'T' && !$is_tourney_game) || (uc $cort eq 'C' && $is_tourney_game))
      {
        if ($verbose) {print_or_append( "Game $full_game_file_name is not the specified type\n", $html, 0, $player_name);}
        next;
      }

      # Check for repeat tournament games
      if ($game_tourney_id && $round_number && $is_tourney_game)
      {
        my $key = $game_tourney_id.'+'.$round_number;
        if($tourney_game_hash{$key})
        {
          print_or_append( "\nGame $full_game_file_name is a duplicate\n", $html, 0, $player_name);
          next;
        }
        $tourney_game_hash{$key} = 1;
      }

      if ($player_one_name eq $player_two_name)
      {
        print_or_append( "\nERROR:  Both players have the same name\nFILE:   $full_game_file_name\n", $html, 1, $player_name);
        $num_errors++;
        next;
      }

      if (!$ext || $ext ne "gcg")
      {
        print_or_append( "\nERROR:  Invalid file extension\nFILE:   $full_game_file_name", $html, 1, $player_name);
        $num_errors++;
        next;
      }

      if (!(-e $full_game_file_name))
      {
        print_or_append( "\nERROR: No GCG found for index $full_game_file_name\n", $html, 1, $player_name);
        $num_errors++;
        next;
      }

      my $lexicon_ref;

      if ($this_lexicon eq 'TWL98')
      {
        $lexicon_ref = TWL98::TWL98_LEXICON;
      }
      elsif ($this_lexicon eq 'TWL06')
      {
        $lexicon_ref = TWL06::TWL06_LEXICON;
      }
      elsif ($this_lexicon eq 'TWL15')
      {
        $lexicon_ref = American::AMERICAN_LEXICON;
      }
      elsif ($this_lexicon eq 'NSW18')
      {
        $lexicon_ref = NSW18::NSW18_LEXICON;
      }
      elsif ($this_lexicon eq 'CSW07')
      {
        $lexicon_ref = CSW07::CSW07_LEXICON;
      }
      elsif ($this_lexicon eq 'CSW12')
      {
        $lexicon_ref = CSW12::CSW12_LEXICON;
      }
      elsif ($this_lexicon eq 'CSW15')
      {
        $lexicon_ref = CSW15::CSW15_LEXICON;
      }
      else
      {
        print_or_append( "\nERROR: no lexicon found for game $full_game_file_name\n", $html, 1, $player_name);
        $num_errors++;
        next;
      }

      my $game = Game->new($full_game_file_name, $player_is_first, $lexicon_ref, $player_one_name, $player_two_name, $html);
      
      if (ref($game) ne "Game")
      {
        print_or_append( "\nERROR:  $game", $html, 1, $player_name);
        $num_errors++;
        next;
      }
      elsif ($game->{'warnings'})
      {
        print_or_append( "\n" . $game->{'warnings'}, $html, 0, $player_name);
        $num_warnings++;
      }

      # if ($verbose)
      # {
      #  print_or_append( "\nData structures for $full_game_file_name\n\n", $html, 0);
      #  print_or_append( $game->toString(), $html, 0);
      #  $single_game_stats->addGame($game);
      #  print_or_append( $single_game_stats->toString(), $html, 0);
      #  $single_game_stats->resetStats();
      # }
      
      my $possible_warnings = $all_stats->addGame($game);
      if ($possible_warnings)
      {
        print_or_append($possible_warnings, $html, 0, $player_name);
        $num_warnings++;
      }
      $at_least_one = 1;
    }
  }

  print_or_append($stats_note, $html, 0);

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
  }
  print_or_append( "\n", $html, 0);
  print_or_append( "Errors:   $num_errors\n", $html, 0);
  print_or_append( "Warnings: $num_warnings\n", $html, 0);
  print_or_append( "\n", $html, 0);

  if ($statsdump && $all_stats->{'num_games'} >= Constants::LEADERBOARD_MIN_GAMES)
  {
    system "mkdir -p $stats_dir";
    open(my $fh, '>', $stats_dir . "/" . $player_name . ".stats");
    my @entries = @{$all_stats->{'entries'}};
    foreach my $e (@entries)
    {
      my $type = $e->{'type'};
      if ($type eq Constants::STAT_ITEM_GAME || $type eq Constants::STAT_ITEM_PLAYER)
      {
        print $fh $e->{'name'} . "," . $e->{'total'} . "\n";
        if ($e->{'subitems'})
        {
          my %subitems = %{$e->{'subitems'}};
          my @order    = @{$e->{'list'}};
          for(my $i = 0; $i < scalar @order; $i ++)
          {
            my $key = $order[$i];
            print $fh $e->{'name'} . " " . $key . "," . $subitems{$key} . "\n";
          }
        }
      }
    }
    close $fh;
  }

  if ($html)
  {
    print "<pre style='white-space: pre-wrap;' > $html_string </pre>";
  }
}

sub print_or_append
{
  my $addition    = shift;
  my $html        = shift;
  my $error       = shift;
  my $this_player = shift;

  if ($html)
  {
    if ($addition =~ /\.(\d+)\.(\w+)\.(\w+)\.gcg/)
    {
      my $opp = $2;
      if ($opp eq $this_player)
      {
        $opp = $3;
      }
      my $url = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX;
      my $link = "<a href='$url$1' target='_blank'>against $opp</a>";
      $addition =~ s/\.[^\.]+\.[^\.]+\.[^\.]+\.[^\.]+\.[^\.]+\.[^\.]+\.[^\.]+\.[^\.]+\.gcg/$link/g;
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


