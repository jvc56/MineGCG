#!/usr/bin/perl

package Update;

use warnings;
use strict;
use Data::Dumper;


use lib './objects';
use lib './modules';

use Constants;
use Utils;
use Stats;

sub update_leaderboard
{
  my $cutoff         = Constants::LEADERBOARD_CUTOFF;
  my $min_games      = Constants::LEADERBOARD_MIN_GAMES;
  my $column_spacing = Constants::LEADERBOARD_COLUMN_SPACING;
  my $query_prefix   = Constants::CACHE_URL_PREFIX;
  my $stats_note     = Constants::STATS_NOTE;

  my %leaderboards  = ();
  my @name_order    = ();

  my $leaderboard_string = "";
  my $table_of_contents  = "<h1><a id='leaderboards'></a>LEADERBOARDS</h1>";

  my $dbh = Utils::connect_to_database();

  my $playerstable = Constants::PLAYERS_TABLE_NAME;
  my $gamestable   = Constants::GAMES_TABLE_NAME;
  my $total_games_name = Constants::PLAYER_TOTAL_GAMES_COLUMN_NAME;

  my @player_data = @{$dbh->selectall_arrayref("SELECT * FROM $playerstable WHERE $total_games_name >= 0", {Slice => {}, "RaiseError" => 1})};

  my $total_players = scalar @player_data;

  foreach my $player_item (@player_data)
  {
    my $name         = $player_item->{Constants::PLAYER_NAME_COLUMN_NAME};
    my $total_games  = $player_item->{Constants::PLAYER_TOTAL_GAMES_COLUMN_NAME};
    my $player_stats = Stats->new(1, $player_item->{Constants::PLAYER_STATS_COLUMN_NAME});
    my $player_stats_data = $player_stats->{Constants::STATS_DATA_KEY_NAME};

    my @stat_keys = (Constants::STATS_DATA_GAME_KEY_NAME, Constants::STATS_DATA_PLAYER_ONE_KEY_NAME);
    
    foreach my $key (@stat_keys)
    {
      my $statlist = $player_stats_data->{$key};
      for (my $i = 0; $i < scalar @{$statlist}; $i++)
      {
        if ($statlist->[$i]->{Constants::STAT_DATATYPE_NAME} eq Constants::DATATYPE_ITEM)
        {
          my $statitem = $statlist->[$i]->{Constants::STAT_ITEM_OBJECT_NAME};
          my $statname = $statlist->[$i]->{Constants::STAT_NAME};

          my $statval   = $statitem->{'total'};
          my $is_single = $statitem->{'single'};
          my $is_int    = $statitem->{'int'};

          add_stat(\%leaderboards, $name, $statname, $statval, $total_games, $is_single, $is_int, \@name_order);

          my $subitems = $statitem->{'subitems'};
          if ($subitems)
          {
            my $order = $statitem->{'list'};
            for (my $i = 0; $i < scalar @{$order}; $i++)
            {
              my $subitemname = $order->[$i];

              my $substatname = "$statname $subitemname";

              my $substatval  = $subitems->{$subitemname};

              add_stat(\%leaderboards, $name, $substatname, $substatval, $total_games, $is_single, $is_int, \@name_order);
            }
          }
        }
      }
    }
  }

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

    $table_of_contents .= "<a href='#$name'>$name</a>\n";

    $leaderboard_string .= "<h2><a id='$name'></a>AVERAGE $name: $sum</h2>";

    for (my $j = 0; $j < 2; $j++)
    {
      my @ranked_array;
      my $title;
      if ($j == 0)
      {
        @ranked_array = sort { $b->[0] <=> $a->[0] } @array;
        $title = "<h3>MOST $name</h3>";
      }
      else
      {
        @ranked_array = sort { $a->[0] <=> $b->[0] } @array;
        $title = "\n\n<h3>LEAST $name</h3>";
      }
      my $all_zeros = 1;
      for (my $k = 0; $k < $cutoff; $k++)
      {
        if ($ranked_array[$k] && $ranked_array[$k][0] != 0)
        {
          $all_zeros = 0;
          last;
        }
      }
      if ($all_zeros)
      {
        next;
      }

      $leaderboard_string .= $title;

      $title =~ />([^<]+)</g;

      $title = $1;

      for (my $k = 0; $k < $total_players; $k++)
      {
        my $name = $ranked_array[$k][1];
        my $name_with_underscores = $name;
        $name_with_underscores =~ s/ /_/g;

        if ($k == $cutoff)
        { 
          $leaderboard_string .= "<div id='$title' style='display: none;'>";
        }

        my $link = "<a href='$query_prefix$name_with_underscores.html' target='_blank'>$name</a>";

        my $spacing = $column_spacing + (length $link) - (length $name);
        my $ranked_player_name = sprintf "%-" . $spacing . "s", $link;
        my $ranking = sprintf "%-5s", ($k+1) . ".";
        $leaderboard_string .= $ranking . $ranked_player_name . $ranked_array[$k][0] . "\n";
      }
      $leaderboard_string .= "</div>\n";
      $leaderboard_string .= "<button onclick='toggle(\"$title\")'>Toggle Full Standings for $title</button>\n";
    }
    $leaderboard_string .= "\n\n\n\n";
    $leaderboard_string .= "<a href='#leaderboards'>Back to Top</a>\n";
    $leaderboard_string .= "\n\n\n\n";
  }

  my $lt = localtime();

  my $expand_all_button = "\n<button onclick='toggle_all()'>Toggle Full Standings for all leaderboards</button>\n";

  $leaderboard_string = "\nUpdated on $lt\n\n" . $stats_note . $table_of_contents . $expand_all_button . $leaderboard_string;

  $leaderboard_string = "<pre style='white-space: pre-wrap;' > $leaderboard_string </pre>\n";

  my $javascript = Constants::LEADERBOARD_JAVASCRIPT;

  $leaderboard_string = $javascript . $leaderboard_string;

  my $leaderboard_name = "./logs/" . Constants::LEADERBOARD_NAME . ".log";

  open(my $new_leaderboard, '>', $leaderboard_name);
  print $new_leaderboard $leaderboard_string;
  close $new_leaderboard;
}


sub update_notable
{
  my $notable_dir    = Constants::NOTABLE_DIRECTORY_NAME;
  my $url            = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX;
  my $stats_note     = Constants::STATS_NOTE;
  
  my $rr_host         = Constants::RR_HOSTNAME;
  my $rr_username     = Constants::RR_USERNAME;
  my $rr_notable_dest = Constants::RR_NOTABLE_DEST;
  my $ssh_args        = Constants::SSH_ARGS;
  
  my $dbh = Utils::connect_to_database();
  my $playerstable = Constants::PLAYERS_TABLE_NAME;

  my %notable_hash;
  my %check_for_repeats_hash;
  my $notable_string = "";
  my $table_of_contents  = "<h1><a id='notable'></a>\"That's Notable!\"</h1>";
  my $init = 0;
  my @ordering = ();

  my @player_data = @{$dbh->selectall_arrayref("SELECT * FROM $playerstable", {Slice => {}, "RaiseError" => 1})};

  foreach my $player_item (@player_data)
  {
    my $player_stats = Stats->new(1, $player_item->{Constants::PLAYER_STATS_COLUMN_NAME});
    my $player_stats_data = $player_stats->{Constants::STATS_DATA_KEY_NAME};

    my @stat_keys = (Constants::STATS_DATA_NOTABLE_KEY_NAME);
    
    foreach my $key (@stat_keys)
    {
      my $statlist = $player_stats_data->{$key};

      for (my $i = 0; $i < scalar @{$statlist}; $i++)
      {
        my $statitem = $statlist->[$i]->{Constants::STAT_ITEM_OBJECT_NAME};
        my $statname = $statlist->[$i]->{Constants::STAT_NAME};

        if (!$notable_hash{$statname})
        {
          push @ordering, $statname;
          $notable_hash{$statname} = "";
        }
        my $list = $statitem->{'list'};
        my $ids  = $statitem->{'ids'};
        for (my $i = 0; $i < scalar @{$list}; $i++)
        {
          my $unique_name = $statname . $ids->[$i];
          if ($check_for_repeats_hash{$unique_name})
          {
            next;
          }
          my $notable_game = $list->[$i];
          $notable_hash{$statname} .= $notable_game . "<br>";
          $check_for_repeats_hash{$unique_name} = 1;
        }
      }
    }
  }

  for (my $i = 0; $i < scalar @ordering; $i++)
  {
    my $key             = $ordering[$i];
    $table_of_contents .= "<a href='#$key'>$key</a></br>";
    $notable_string    .= "</br></br></br><h3><a id='$key'></a>$key</h3>";
    $notable_string    .= $notable_hash{$key};
  }

  my $lt = localtime();

  $notable_string = "\nUpdated on $lt\n\n" . $stats_note . $table_of_contents . "</br></br></br>" . $notable_string;

  $notable_string = "<pre style='white-space: pre-wrap;' > $notable_string </pre>\n";

  my $notable_name = "./logs/" . Constants::NOTABLE_NAME . ".log";

  open(my $new_notable, '>', $notable_name);
  print $new_notable $notable_string;
  close $new_notable;
}


sub add_stat
{
  my $leaderboards = shift;
  my $playername   = shift;
  my $statname     = shift;
  my $statvalue    = shift;
  my $total_games  = shift;
  my $is_single    = shift;
  my $is_int       = shift;
  my $name_order   = shift;
  
  if (!$is_single)
  {
    $statvalue /= $total_games
  }
  $statvalue = sprintf "%.4f", $statvalue;
  if ($is_int)
  {
    $statvalue = int($statvalue);
  }
  if ($leaderboards->{$statname})
  {
    push @{$leaderboards->{$statname}}, [$statvalue, $playername];
  }
  else
  {
    push @{$name_order}, $statname;
    $leaderboards->{$statname} = [[$statvalue, $playername]];
  }
}



1;

