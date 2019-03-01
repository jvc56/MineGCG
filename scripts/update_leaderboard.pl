#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use lib './objects';
use Constants;

sub update_leaderboard
{
  my $stats_dir      = Constants::STATS_DIRECTORY_NAME;
  my $cutoff         = Constants::LEADERBOARD_CUTOFF;
  my $min_games      = Constants::LEADERBOARD_MIN_GAMES;
  my $column_spacing = Constants::LEADERBOARD_COLUMN_SPACING;
  my $query_prefix   = Constants::QUERY_URL_PREFIX;
  my $stats_note     = Constants::STATS_NOTE;
  
  opendir my $stats, $stats_dir or die "Cannot open directory: $!";
  my @stat_files = readdir $stats;
  closedir $stats;

  my %leaderboards = ();
  my $init = 0;
  my @name_order = ();
  my $total_players = 0;

  my $leaderboard_string = "";

  $leaderboard_string .= "\n\nThe following leaderboards are based on uploaded\n";
  $leaderboard_string .= "cross-tables games and are not necessarily an accurate\n";
  $leaderboard_string .= "reflection of playing style or ability.\n";
  $leaderboard_string .= "\n";
  $leaderboard_string .= "With the exception of the GAMES leaderboard\n";
  $leaderboard_string .= "all statistics are listed as per game.\n";
  $leaderboard_string .= "\n";


  foreach my $stat_file (@stat_files)
  {
    if ($stat_file eq '.' || $stat_file eq '..')
    {
      next;
    }

    $stat_file =~ /(\w+).stats/;
    my $player_name = $1;
    $player_name =~ s/_/ /g;
    my $total_games = 0;

    open(PLAYER_STATS, '<', $stats_dir . "/" . $stat_file);
    while(<PLAYER_STATS>)
    {
      my ($name, $total) = split /,/, $_;
      chomp $name;
      chomp $total;
      $name = uc $name;

      # Games should always be the first stat
      my $stat;
      if ($name eq "GAMES")
      {
        $total_games = $total;
        $stat = $total;
      }
      elsif (
              $name eq "SCORE PER TURN" ||
              $name eq "HIGH GAME" ||
              $name eq "LOW GAME" || 
              $name =~ /BINGO PROBABILITIES/
             )
      {
        $stat = $total;
      }
      else
      {
        $stat = $total / $total_games;
      }

      $stat = sprintf "%.4f", $stat;

      if (!$init)
      {
        $leaderboards{$name} = [[$stat, $player_name]];
        push @name_order, $name;
      }
      else
      {
        push @{$leaderboards{$name}}, [$stat, $player_name];
      }
    }
    $total_players++;
    $init = 1;
  }

  $leaderboard_string .= "Leaderboard calculations included $total_players players with a minimum of $min_games games.\n\n\n";
  $leaderboard_string .= $stats_note;

  for (my $i = 0; $i < scalar @name_order; $i++)
  {

    my $name = $name_order[$i];
    my @array = @{$leaderboards{$name}};

    my $sum = 0;

    for (my $j = 0; $j < $total_players; $j++)
    {
      $sum += $array[$j][0];
    }

    $sum = sprintf "%.4f", $sum / $total_players;

    my $average_title_text = "AVERAGE " . $name;

    $leaderboard_string .= $average_title_text . ": $sum\n\n";

    for (my $j = 0; $j < 2; $j++)
    {
      my @ranked_array;
      if ($j == 0)
      {
        @ranked_array = sort { $b->[0] <=> $a->[0] } @array;
      }
      else
      {
        @ranked_array = sort { $a->[0] <=> $b->[0] } @array;
      }
      my $all_zeros = 1;
      for (my $k = 0; $k < $cutoff; $k++)
      {
        if ($ranked_array[$k][0] != 0)
        {
          $all_zeros = 0;
          last;
        }
      }
      if ($all_zeros)
      {
        next;
      }
      if ($j == 0)
      {
        $leaderboard_string .= "MOST " . $name . "\n\n";
      }
      else
      {
        $leaderboard_string .= "\n\nLEAST " . $name . "\n\n";
      }
      for (my $k = 0; $k < $cutoff; $k++)
      {
        my $name = $ranked_array[$k][1];
        my $name_with_plus = $name;
        $name_with_plus =~ s/ /+/g;

        my $link = "<a href='$query_prefix$name_with_plus' target='_blank'>$name</a>";

        my $spacing = $column_spacing + (length $link) - (length $name);
        my $ranked_player_name = sprintf "%-" . $spacing . "s", $link;
        my $ranking = sprintf "%-4s", ($k+1) . ".";
        $leaderboard_string .= $ranking . $ranked_player_name . $ranked_array[$k][0] . "\n";
      }
    }

    $leaderboard_string .= "\n\n\n\n";
  }

  my $lt = localtime();

  $leaderboard_string = "\nUpdated on $lt\n\n" . $leaderboard_string;

  $leaderboard_string = "<pre style='white-space: pre-wrap;' > $leaderboard_string </pre>\n";

  my $leaderboard_name = "./logs/" . Constants::LEADERBOARD_NAME . ".log";

  open(my $new_leaderboard, '>', $leaderboard_name);
  print $new_leaderboard $leaderboard_string;
  close $new_leaderboard;

  system "rm -r $stats_dir";

  system "scp -i /home/jvc/.ssh/randomracer.pem $leaderboard_name jvc\@media.wgvc.com:/home/bitnami/htdocs/rracer/leaderboard.html"

}

1;

