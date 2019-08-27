#!/usr/bin/perl

package Stats;

use warnings;
use strict;
use Data::Dumper;
use List::Util qw(sum);
use Clone qw(clone);

use lib '.';
use lib './modules';

use Constants;
use Utils;
use JSON;

sub new
{
  my $this            = shift;
  my $player_is_first = shift;

  my $json            = shift;

  if ($json)
  {
    my $stats = decode_json($json);
    $stats->{'player_is_first'} = $player_is_first;
    my $self = bless $stats, $this;
    return $self;
  }

  my $statlist = statsList();

  my @player1_stats = ();
  my @player2_stats = ();
  my @game_stats    = ();
  my @notable_stats = ();

  for (my $i = 0; $i < scalar @{$statlist}; $i++)
  {
    my $statitem = $statlist->[$i];
    if ($statitem->{Constants::STAT_METATYPE_NAME} eq Constants::METATYPE_GAME)
    {
      push @game_stats, $statitem;
    }
    elsif ($statitem->{Constants::STAT_METATYPE_NAME} eq Constants::METATYPE_NOTABLE)
    {
      push @notable_stats, $statitem;
    }
    elsif ($statitem->{Constants::STAT_METATYPE_NAME} eq Constants::METATYPE_PLAYER)
    {
      my $cloned_item = clone($statitem);
      push @player1_stats, $statitem;
      push @player2_stats, $cloned_item;
    }
  }

  my %stats =
  (
    Constants::STATS_PLAYER_IS_FIRST_KEY_NAME => $player_is_first,
    Constants::STATS_DATA_KEY_NAME =>
    {
      Constants::STATS_DATA_PLAYER_ONE_KEY_NAME => \@player1_stats,
      Constants::STATS_DATA_PLAYER_TWO_KEY_NAME => \@player2_stats,
      Constants::STATS_DATA_GAME_KEY_NAME       => \@game_stats,
      Constants::STATS_DATA_NOTABLE_KEY_NAME    => \@notable_stats,
    }
  );
  my $self = bless \%stats, $this;
  return $self;
}

sub addGame
{
  my $this = shift;

  my $game   = shift;

  my $stats = $this->{Constants::STATS_DATA_KEY_NAME};

  my $function_name = Constants::STAT_ADD_FUNCTION_NAME;
  my $object_name   = Constants::STAT_ITEM_OBJECT_NAME;
  foreach my $key (keys %{$stats})
  {
    my $statlist = $stats->{$key};
    for (my $i = 0; $i < scalar @{$statlist}; $i++)
    {
      my $stat = $statlist->[$i];
      my $player_is_first;
      if ($key =~ /player(\d)/)
      {
        $player_is_first = ($1 - 2) * (-1);
      }
      $stat->{$function_name}->($stat->{$object_name}, $game, $player_is_first);
    }
  }
}

sub addStat
{
  my $this = shift;

  my $other_stat_object = shift;

  my $stats       = $this->{Constants::STATS_DATA_KEY_NAME};
  my $other_stats = $other_stat_object->{Constants::STATS_DATA_KEY_NAME};

  my $switch = 1 - $other_stat_object->{Constants::STATS_PLAYER_IS_FIRST_KEY_NAME};

  foreach my $key (keys %{$stats})
  {
    my $this_statlist = $stats->{$key};
    my $other_key = $key;

    if ($switch)
    {
      if ($key eq Constants::STATS_DATA_PLAYER_ONE_KEY_NAME)
      {
        $other_key = Constants::STATS_DATA_PLAYER_TWO_KEY_NAME;
      }
      elsif ($key eq Constants::STATS_DATA_PLAYER_TWO_KEY_NAME)
      {
        $other_key = Constants::STATS_DATA_PLAYER_ONE_KEY_NAME;
      }
    }
    for (my $i = 0; $i < scalar @{$this_statlist}; $i++)
    {
      my $this_stat  = $this_statlist->[$i];

      my $other_stat = $other_stats->{$other_key}->[$i];

      if (
           $this_stat->{Constants::STAT_NAME}          ne $other_stat->{Constants::STAT_NAME} || 
           $this_stat->{Constants::STAT_DATATYPE_NAME} ne $other_stat->{Constants::STAT_DATATYPE_NAME} || 
           $this_stat->{Constants::STAT_METATYPE_NAME} ne $other_stat->{Constants::STAT_METATYPE_NAME}
         )
      {
        my $die_statement  = Utils::format_error("Stats do not match!", $this_stat, $other_stat);
        die $die_statement;
      }
      my $this_object  = $this_stat->{Constants::STAT_ITEM_OBJECT_NAME};
      my $other_object = $other_stat->{Constants::STAT_ITEM_OBJECT_NAME};

      $this_stat->{Constants::STAT_COMBINE_FUNCTION_NAME}->($this_object, $other_object);
    }
  }
}

sub makeTitleRow
{
  my $tiw = shift;
  my $aw  = shift;
  my $tow = shift;
  my $a   = shift;
  my $b   = shift;
  my $c   = shift;

  return "|" . (sprintf "%-$tiw"."s", $a) .
               (sprintf "%-$aw"."s", $b)  .
               (sprintf "%-$tow"."s", $c) . "|\n";
}

sub makeRow
{
  my $this = shift;
  my $tiw = Constants::TITLE_WIDTH;
  my $aw =  Constants::AVERAGE_WIDTH;
  my $tow = Constants::TOTAL_WIDTH;
  my $name = shift;
  my $total = shift;
  my $num_games = shift;

  $name =~ /^(\s*)/;

  my $average = sprintf "%.2f", $total/$num_games;

  if ($this->{Constants::STAT_OBJECT_DISPLAY_NAME} && $this->{Constants::STAT_OBJECT_DISPLAY_NAME} eq Constants::STAT_OBJECT_DISPLAY_PCAVG)
  {
    $average = $total;
    $total = '-';
  }

  if ($this->{'link'})
  {
    my $link = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX . $this->{'link'};
    $tiw -= length $name;
    $name = "<a href='$link' target='_blank'>$name</a>";
    $tiw += length $name;
  }

  my $spaces = $1;
  $tow = $tow - (length $spaces);

  my $s = "";

  $s .= "|" .  (sprintf "%-$tiw"."s", "  ".$name) . 
               (sprintf $spaces."%-$aw"."s", $average) . 
               (sprintf "%-$tow"."s", $total) . "|\n";
  return $s;
}
sub makeItem
{
  my $this = shift;
  my $name = shift;
  my $total = shift;
  my $num_games = shift;

  my $r = makeRow($this, $name, $total, $num_games);

  if ($this->{'subitems'})
  {
    my %subs  = %{$this->{'subitems'}};
    my @order = @{$this->{'list'}};
    for (my $i = 0; $i < scalar @order; $i++)
    {
      my $key = $order[$i];
      $r .= makeRow($this, "  " . $key, $subs{$key}, $num_games);
    }
  }
  return $r;
}

sub makeMistakeItem
{
  my $this         = shift;
  my $html         = shift;
  my $mistake_item = shift;
  my $is_title_row = shift;
  my $num_mistakes = shift;

  my $s = "";

  if ($is_title_row)
  {
    if ($html)
    {
      $s .= "<tr>\n";
      $s .= "<td colspan='$is_title_row' align='center'><b>$mistake_item Mistakes ($num_mistakes)</b></td>\n";
      $s .= "</tr>\n";
    }
    else
    {
      $s .= "\n$mistake_item Mistakes\n";
    }
    return $s;
  }

  my @mistake_array = @{$mistake_item};
  my $mm = $mistake_array[1];
  if ($html)
  {
    my $color_hash = Constants::MISTAKE_COLORS;
    my $color = $color_hash->{$mistake_array[0]};

    $s .= "<tr style='background-color: $color'>\n";
    $s .= "<td>$mistake_array[0]</td>\n";
    $s .= "<td>$mm</td>\n";
    $s .= "<td>$mistake_array[2]</td>\n";
    $s .= "<td>$mistake_array[3]</td>\n";
    $s .= "<td>$mistake_array[4]</td>\n";
    $s .= "</tr>\n";
  }
  else
  {
    $s .= "Mistake:   $mistake_array[0]\n";
    $s .= "Magnitude: $mm              \n";
    $s .= "Game:      $mistake_array[2]\n";
    $s .= "Play:      $mistake_array[3]\n";
    $s .= "Comment:   $mistake_array[4]\n";
  }
  return $s;
}

sub statItemToString
{
  my $this        = shift;
  my $total_games = shift;
  my $type        = shift;
  my $html        = shift;

  my $tiw = Constants::TITLE_WIDTH;
  my $aw =  Constants::AVERAGE_WIDTH;
  my $tow = Constants::TOTAL_WIDTH;
  my $tot = $tiw + $aw + $tow;

  my $s = "";
  if ($type && $type eq Constants::STAT_ITEM_LIST)
  {
    $s .= "\n".$this->{Constants::STAT_NAME} . ": ";
    my @list = @{$this->{'list'}};
    for (my $i = 0; $i < scalar @list; $i++)
    {
      my $commaspace = ", ";
      if ($i == (scalar @list) - 1)
      {
        $commaspace = "\n";
      }
      $s .= $list[$i] . $commaspace;
    }
    $s .= "\n";
  }
  elsif ($type && $type eq Constants::MISTAKE_ITEM_LIST)
  {
    $s .= "\n";
    my @list = @{$this->{'list'}};


    if ($html && scalar @list > 0)
    {
      $s .= "<table>\n<tbody>\n";
    }

    my @mistakes_magnitude = Constants::MISTAKES_ORDER;

    my %magnitude_strings = ();

    my %mistakes_magnitude_count = ();

    foreach my $mag (@mistakes_magnitude)
    {
      $magnitude_strings{$mag} = "";
      $mistakes_magnitude_count{$mag} = 0;
    }

    my $mistake_elements_length;

    for (my $i = 0; $i < scalar @list; $i++)
    {
      my @mistake_elements = @{$list[$i]};
      $mistake_elements_length = scalar @mistake_elements;
      $magnitude_strings{$mistake_elements[1]} .= makeMistakeItem($this, $html, $list[$i], 0);
      $mistakes_magnitude_count{$mistake_elements[1]}++;
    }

    for (my $i = 0; $i < scalar @mistakes_magnitude; $i++)
    {
      my $mag = $mistakes_magnitude[$i];
      if ($magnitude_strings{$mag})
      {
        if ($html)
        {
          $s .= "<tr><td style='height: 50px'></td></tr>\n";
        }
        $s .= makeMistakeItem($this, $html, $mag, $mistake_elements_length, $mistakes_magnitude_count{$mag});
        if ($html)
        {
          $s .= "<tr>\n";
          $s .= "<th>Mistake</th>\n";
          $s .= "<th>Magnitude</th>\n";
          $s .= "<th>Game</th>\n";
          $s .= "<th>Play</th>\n";
          $s .= "<th>Comment</th>\n";
          $s .= "</tr>\n";
        }
        else
        {
          $s .= "\n\n\n";
        }
        $s .= $magnitude_strings{$mag};
      }
    }

    if ($html && scalar @list > 0)
    {
      $s .= "</tbody>\n</table>\n";
    }

    $s .= "\n";
  }
  else
  {
    $s .= makeItem($this, $this->{Constants::STAT_NAME}, $this->{'total'}, $total_games);
  }

  return $s;  
}


sub toString
{
  my $this = shift;
  my $html = shift;

  my $tiw        = Constants::TITLE_WIDTH;
  my $aw         = Constants::AVERAGE_WIDTH;
  my $tow        = Constants::TOTAL_WIDTH;
  my $tot        = $tiw + $aw + $tow;
  my $num;

  my $player1_ref = $this->{Constants::STATS_DATA_KEY_NAME}->{Constants::STATS_DATA_PLAYER_ONE_KEY_NAME};
  my $player2_ref = $this->{Constants::STATS_DATA_KEY_NAME}->{Constants::STATS_DATA_PLAYER_TWO_KEY_NAME};
  my $game_ref    = $this->{Constants::STATS_DATA_KEY_NAME}->{Constants::STATS_DATA_GAME_KEY_NAME      };
  my $notable_ref = $this->{Constants::STATS_DATA_KEY_NAME}->{Constants::STATS_DATA_NOTABLE_KEY_NAME   };

  foreach my $statob (@{$game_ref})
  {
    if ($statob->{Constants::STAT_NAME} eq 'Games')
    {
      $num = $statob->{Constants::STAT_ITEM_OBJECT_NAME}->{'total'};
      last;
    }
  }

  my @notable_stats = ();    
  my @game_stats = ();

  for (my $i = 0; $i < scalar @{$notable_ref}; $i++) 
  {
    my $object = $notable_ref->[$i]->{Constants::STAT_ITEM_OBJECT_NAME};
    $object->{Constants::STAT_NAME} = $notable_ref->[$i]->{Constants::STAT_NAME};
    push @notable_stats, $object;
  }
  for (my $i = 0; $i < scalar @{$game_ref}; $i++) 
  {
    my $object = $game_ref->[$i]->{Constants::STAT_ITEM_OBJECT_NAME};
    $object->{Constants::STAT_NAME} = $game_ref->[$i]->{Constants::STAT_NAME};
    push @game_stats, $object;
  }

  my @player_list_stats  = ();
  my @opp_list_stats     = ();

  my @player_item_stats  = ();
  my @opp_item_stats     = ();

  my $player_mistake_list;
  my $opp_mistake_list;

  for (my $i = 0; $i < scalar @{$player1_ref}; $i++)
  {
    my $stat   = $player1_ref->[$i];
    my $object = $stat->{Constants::STAT_ITEM_OBJECT_NAME};
    $object->{Constants::STAT_NAME} = $stat->{Constants::STAT_NAME};
    if ($stat->{Constants::STAT_NAME} eq "Mistakes List")
    {
      $player_mistake_list = $object;
    }
    elsif ($stat->{Constants::STAT_DATATYPE_NAME} eq Constants::DATATYPE_LIST)
    {
      push @player_list_stats, $object;
    }
    elsif ($stat->{Constants::STAT_DATATYPE_NAME} eq Constants::DATATYPE_ITEM)
    {
      push @player_item_stats, $object;
    }
  }

  for (my $i = 0; $i < scalar @{$player2_ref}; $i++)
  {
    my $stat   = $player2_ref->[$i];
    my $object = $stat->{Constants::STAT_ITEM_OBJECT_NAME};
    $object->{Constants::STAT_NAME} = $stat->{Constants::STAT_NAME};
    if ($stat->{Constants::STAT_NAME} eq "Mistakes List")
    {
      $opp_mistake_list = $object;
    }
    elsif ($stat->{Constants::STAT_DATATYPE_NAME} eq Constants::DATATYPE_LIST)
    {
      push @opp_list_stats, $object;
    }
    elsif ($stat->{Constants::STAT_DATATYPE_NAME} eq Constants::DATATYPE_ITEM)
    {
      push @opp_item_stats, $object;
    }
  }


  my $s = "";

  $s .= "\n" . Constants::STAT_ITEM_LIST_PLAYER . "\n\n";
  for (my $i = 0; $i < scalar @player_list_stats; $i++)
  {
    $s .= statItemToString($player_list_stats[$i], $num, Constants::STAT_ITEM_LIST, $html);
  }
  $s .= "\n" . Constants::STAT_ITEM_LIST_OPP . "\n\n";
  for (my $i = 0; $i < scalar @opp_list_stats; $i++)
  {
    $s .= statItemToString($opp_list_stats[$i], $num, Constants::STAT_ITEM_LIST, $html);
  }
  $s .= "\n" . Constants::STAT_ITEM_LIST_NOTABLE . "\n\n";
  for (my $i = 0; $i < scalar @notable_stats; $i++)
  {
    $s .= statItemToString($notable_stats[$i], $num, Constants::STAT_ITEM_LIST, $html);
  }

  my $title_divider = ("_" x ($tot+2)) . "\n";
  my $empty_line = "|" . (" " x $tot) . "|\n";

  $s .= "\nResults for $num game(s)\n";
  $s .= $title_divider;
  $s .= makeTitleRow($tiw, $aw, $tow, "", "AVERAGE", "TOTAL");

  $s .= makeTitleRow($tiw, $aw, $tow, Constants::STAT_ITEM_GAME, "", "");
  
  for (my $i = 0; $i < scalar @game_stats; $i++)
  {
    $s .= statItemToString($game_stats[$i], $num, $html);
  }

  $s .= makeTitleRow($tiw, $aw, $tow, "", "", "");

  $s .= makeTitleRow($tiw, $aw, $tow, Constants::STAT_ITEM_PLAYER, "", "");
  
  for (my $i = 0; $i < scalar @player_item_stats; $i++)
  {
    $s .= statItemToString($player_item_stats[$i], $num, $html);
  }

  $s .= makeTitleRow($tiw, $aw, $tow, "", "", "");

  $s .= makeTitleRow($tiw, $aw, $tow, Constants::STAT_ITEM_OPP, "", "");
  
  for (my $i = 0; $i < scalar @opp_item_stats; $i++)
  {
    $s .= statItemToString($opp_item_stats[$i], $num, $html);
  }
  
  $s .= ("_" x ($tot+2)) . "\n\n";

  if ($html)
  {
    $s .= "<div id='" . Constants::MISTAKES_DIV_ID . "' style='display: none;'>";
  }

  $s .= "\n".Constants::MISTAKE_ITEM_LIST_PLAYER . "\n";

  $s .= statItemToString($player_mistake_list, $num, Constants::MISTAKE_ITEM_LIST, $html);

  $s .= "\n\n\n".Constants::MISTAKE_ITEM_LIST_OPP . "\n";
  
  $s .= statItemToString($opp_mistake_list, $num, Constants::MISTAKE_ITEM_LIST, $html);

  if ($html)
  {
      $s .=  "</div>\n\n";
      $s .=  "<button onclick='toggle(\"" . Constants::MISTAKES_DIV_ID . "\")'>Toggle Mistakes List</button>\n";
  }

  return $s; 
}

sub statsList
{
  return
  [
    {
      Constants::STAT_NAME => 'Bingos',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        push @{$this->{'list'}}, @{$game->getBingos($this_player)};
      }
    },
    {
      Constants::STAT_NAME => 'Triple Triples',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        push @{$this->{'list'}}, @{$game->getTripleTriples($this_player)};
      }
    },
    {
      Constants::STAT_NAME => 'Bingo Nines or Above',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        push @{$this->{'list'}}, @{$game->getBingoNinesOrAbove($this_player)};
      }
    },
    {
      Constants::STAT_NAME => 'Highest Scoring Play',
      Constants::STAT_ITEM_OBJECT_NAME =>  {'list' => [], 'score' => -1},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;

        if ($other->{'score'} > $this->{'score'})
        {
          $this->{'score'} = $other->{'score'};
          $this->{'list'}  = $other->{'list'};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        my $game_highest = $game->getHighestScoringPlay($this_player);

        my @current_list = @{$this->{'list'}};

        if (!@current_list || $this->{'score'} < $game_highest->[1])
        {
          $this->{'score'} = $game_highest->[1];
          $this->{'list'}  = [$game_highest->[0] . " ($game_highest->[1] points)"];
        }
      }
    },
    {
      Constants::STAT_NAME => 'Challenged Phonies',
      Constants::STAT_ITEM_OBJECT_NAME =>  {'list' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this        = shift;
        my $game        = shift;
        my $this_player = shift;

        push @{$this->{'list'}}, @{$game->getPhoniesFormed($this_player, 1)};
      }
    },
    {
      Constants::STAT_NAME => 'Unchallenged Phonies',
      Constants::STAT_ITEM_OBJECT_NAME =>  {'list' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this        = shift;
        my $game        = shift;
        my $this_player = shift;

        push @{$this->{'list'}}, @{$game->getPhoniesFormed($this_player, 0)};
      }
    },
    {
      Constants::STAT_NAME => 'Plays That Were Challenged',
      Constants::STAT_ITEM_OBJECT_NAME =>  {'list' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        push @{$this->{'list'}}, @{$game->getPlaysChallenged($this_player)};
      }
    },
    {
      Constants::STAT_NAME => 'Games',
      Constants::STAT_ITEM_OBJECT_NAME =>  {'total' => 0, Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_TOTAL, 'int' => 1},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_GAME,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;

        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;

        $this->{'total'}++;
      }
    },
    {
      Constants::STAT_NAME => 'Challenges',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
        'total' => 0,
        'subitmes' =>
        {
           Constants::PLAYER_CHALLENGE_WON  => 0,
           Constants::PLAYER_CHALLENGE_LOST => 0,
           Constants::OPP_CHALLENGE_WON     => 0,
           Constants::OPP_CHALLENGE_LOST    => 0    
        },
        'list' =>
        [
           Constants::PLAYER_CHALLENGE_WON,
           Constants::OPP_CHALLENGE_LOST,   
           Constants::PLAYER_CHALLENGE_LOST,
           Constants::OPP_CHALLENGE_WON
        ];        
      },
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_GAME,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;

        $this->{'total'} += $other->{'total'};
        foreach my $key (keys %{$this->{'subitems'}})
        {
          $this->{'subitems'}->{$key} += $other->{'subitems'}->{$key};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;

        my $chal = $game->getNumChallenges($this_player);

        my $pcw = $chal->{Constants::PLAYER_CHALLENGE_WON};
        my $pcl = $chal->{Constants::PLAYER_CHALLENGE_LOST};
        my $ocw = $chal->{Constants::OPP_CHALLENGE_WON};
        my $ocl = $chal->{Constants::OPP_CHALLENGE_LOST};

        $this->{'total'} += $pcw + $pcl + $ocw + $ocl;
        $this->{'subitems'}->{Constants::PLAYER_CHALLENGE_WON}  += $pcw;
        $this->{'subitems'}->{Constants::PLAYER_CHALLENGE_LOST} += $pcl;
        $this->{'subitems'}->{Constants::OPP_CHALLENGE_WON}     += $ocw;
        $this->{'subitems'}->{Constants::OPP_CHALLENGE_LOST}    += $ocl;
      }
    },
    {
      Constants::STAT_NAME => 'Total Turns',
      Constants::STAT_ITEM_OBJECT_NAME =>  {'total' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_GAME,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this   = shift;
        my $game   = shift;

        $this->{'total'} += $game->getNumTurns(-1);
      }
    },
    {
      Constants::STAT_NAME => 'Wins',
      Constants::STAT_ITEM_OBJECT_NAME => {'total' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        $this->{'total'} += $game->getNumWins($this_player);
      }
    },
    {
      Constants::STAT_NAME => 'Score',
      Constants::STAT_ITEM_OBJECT_NAME =>  {'total' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        $this->{'total'} += $game->getScore($this_player);
      }
    },
    {
      Constants::STAT_NAME => 'Score per Turn',
      Constants::STAT_ITEM_OBJECT_NAME =>  {Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_PCAVG, 'total' => 0, 'total_score' => 0, 'total_turns' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total_score'} += $other->{'total_score'};
        $this->{'total_turns'} += $other->{'total_turns'};
        $this->{'total'} = sprintf "%.4f", $this->{'total_score'} / $this->{'total_turns'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        $this->{'total_score'} += $game->getScore($this_player);
        $this->{'total_turns'} += $game->getNumTurns($this_player);
        $this->{'total'} = sprintf "%.4f", $this->{'total_score'} / $this->{'total_turns'};
      }
    },
    {
      Constants::STAT_NAME => 'Turns',
      Constants::STAT_ITEM_OBJECT_NAME =>  {'total' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        $this->{'total'} += $game->getNumTurns($this_player);
      }
    },
    {
      Constants::STAT_NAME => 'Firsts',
      Constants::STAT_ITEM_OBJECT_NAME => {'total' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        $this->{'total'} += $game->getNumFirsts($this_player);
      }
    },
    {
      Constants::STAT_NAME => 'Full Rack per Turn',
      Constants::STAT_ITEM_OBJECT_NAME => {Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_PCAVG, 'total' => 0, 'total_full_racks' => 0, 'total_turns' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total_full_racks'} += $other->{'total_full_racks'};
        $this->{'total_turns'}      += $other->{'total_turns'};
        $this->{'total'} = sprintf "%.4f", $this->{'total_full_racks'} / $this->{'total_turns'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        $this->{'total_full_racks'} += $game->getNumFullRacks($this_player);
        $this->{'total_turns'}      += $game->getNumTurns($this_player);
        $this->{'total'} = sprintf "%.4f", $this->{'total_full_racks'} / $this->{'total_turns'};
      }
    },
    {
      Constants::STAT_NAME => 'Exchanges',
      Constants::STAT_ITEM_OBJECT_NAME =>  {'total' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        $this->{'total'} += $game->getNumExchanges($this_player);
      }
    },
    {
      Constants::STAT_NAME => 'High Game',
      Constants::STAT_ITEM_OBJECT_NAME =>  {'total' => -10000, Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_PCAVG, 'int' => 1},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;

        if ($other->{'total'} > $this->{'total'})
        {
          $this->{'total'} = $other->{'total'};
          $this->{'link'}  = $other->{'link'};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        my $score = $game->getScore($this_player);
        if ($score > $this->{'total'})
        {
          $this->{'total'} = $score;
          if ($game->{'html'})
          {
            $this->{'link'}   = $game->{'filename'};
          }
        }
      }
    },
    {
      Constants::STAT_NAME => 'Low Game',
      Constants::STAT_ITEM_OBJECT_NAME => {'total' => 100000, Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_PCAVG, 'int' => 1},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;

        if ($other->{'total'} < $this->{'total'})
        {
          $this->{'total'} = $other->{'total'};
          $this->{'link'}  = $other->{'link'};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        my $score = $game->getScore($this_player);
        if ($score < $this->{'total'})
        {
          $this->{'total'} = $score;
          if ($game->{'html'})
          {
            $this->{'link'}   = $game->{'filename'};
          }
        }
      }
    },
    {
      Constants::STAT_NAME => 'Highest Scoring Turn',
      Constants::STAT_ITEM_OBJECT_NAME =>  {'total' => -1, Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_PCAVG, 'int' => 1},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        
        if ($other->{'total'} > $this->{'total'})
        {
          $this->{'total'} = $other->{'total'};
          $this->{'link'}  = $other->{'link'};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        my $score = $game->getHighestScoringPlay($this_player)->[1];
        if ($score > $this->{'total'})
        {
          $this->{'total'} = $score;
          if ($game->{'html'})
          {
            $this->{'link'}   = $game->{'filename'};
          }
        }
      }
    },
    {
      Constants::STAT_NAME => 'Bingos Played',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
        'total' => 0,
        'subitems' => 
        {
            Constants::SEVENS_TITLE    => 0,
            Constants::EIGHTS_TITLE    => 0,
            Constants::NINES_TITLE     => 0,
            Constants::TENS_TITLE      => 0,
            Constants::ELEVENS_TITLE   => 0,
            Constants::TWELVES_TITLE   => 0,
            Constants::THIRTEENS_TITLE => 0,
            Constants::FOURTEENS_TITLE => 0,
            Constants::FIFTEENS_TITLE  => 0
        },
        'list' => 
        [
            Constants::SEVENS_TITLE    ,
            Constants::EIGHTS_TITLE    ,
            Constants::NINES_TITLE     ,
            Constants::TENS_TITLE      ,
            Constants::ELEVENS_TITLE   ,
            Constants::TWELVES_TITLE   ,
            Constants::THIRTEENS_TITLE ,
            Constants::FOURTEENS_TITLE ,
            Constants::FIFTEENS_TITLE
        ]
      },
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;

        $this->{'total'} += $other->{'total'};
        foreach my $key (keys %{$this->{'subitems'}})
        {
          $this->{'subitems'}->{$key} += $other->{'subitems'}->{$key};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;
        # Add 0 at end to include phonies
        my @bingos = @{$game->getNumWordsPlayed($this_player, 1, 0)};
        $this->{'total'} += sum(@bingos);
        $this->{'subitems'}->{Constants::SEVENS_TITLE}    += $bingos[6];
        $this->{'subitems'}->{Constants::EIGHTS_TITLE}    += $bingos[7];
        $this->{'subitems'}->{Constants::NINES_TITLE}     += $bingos[8];
        $this->{'subitems'}->{Constants::TENS_TITLE}      += $bingos[9];
        $this->{'subitems'}->{Constants::ELEVENS_TITLE}   += $bingos[10];
        $this->{'subitems'}->{Constants::TWELVES_TITLE}   += $bingos[11];
        $this->{'subitems'}->{Constants::THIRTEENS_TITLE} += $bingos[12];
        $this->{'subitems'}->{Constants::FOURTEENS_TITLE} += $bingos[13];
        $this->{'subitems'}->{Constants::FIFTEENS_TITLE}  += $bingos[14];
      }
    },
    {
      Constants::STAT_NAME => 'Bingo Probabilities',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
          Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_PCAVG,
          'subitems' =>
          {
            Constants::SEVENS_TITLE    => 0,
            Constants::EIGHTS_TITLE    => 0,
            Constants::NINES_TITLE     => 0,
            Constants::TENS_TITLE      => 0,
            Constants::ELEVENS_TITLE   => 0,
            Constants::TWELVES_TITLE   => 0,
            Constants::THIRTEENS_TITLE => 0,
            Constants::FOURTEENS_TITLE => 0,
            Constants::FIFTEENS_TITLE  => 0
          },
          'list' =>
          [
            Constants::SEVENS_TITLE,
            Constants::EIGHTS_TITLE,
            Constants::NINES_TITLE,
            Constants::TENS_TITLE,
            Constants::ELEVENS_TITLE,
            Constants::TWELVES_TITLE,
            Constants::THIRTEENS_TITLE,
            Constants::FOURTEENS_TITLE,
            Constants::FIFTEENS_TITLE
          ],
          'prob_totals' =>
          {
            Constants::SEVENS_TITLE    => 0,
            Constants::EIGHTS_TITLE    => 0,
            Constants::NINES_TITLE     => 0,
            Constants::TENS_TITLE      => 0,
            Constants::ELEVENS_TITLE   => 0,
            Constants::TWELVES_TITLE   => 0,
            Constants::THIRTEENS_TITLE => 0,
            Constants::FOURTEENS_TITLE => 0,
            Constants::FIFTEENS_TITLE  => 0
          },
          'prob_total' => 0,
          'bingo_totals' =>
          {
            Constants::SEVENS_TITLE    => 0,
            Constants::EIGHTS_TITLE    => 0,
            Constants::NINES_TITLE     => 0,
            Constants::TENS_TITLE      => 0,
            Constants::ELEVENS_TITLE   => 0,
            Constants::TWELVES_TITLE   => 0,
            Constants::THIRTEENS_TITLE => 0,
            Constants::FOURTEENS_TITLE => 0,
            Constants::FIFTEENS_TITLE  => 0
          },
          'bingo_total' => 0
      },
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;

        $this->{'prob_total'} += $other->{'prob_total'};
        $this->{'bingo_total'} += $other->{'bingo_total'};
        my @top_keys = ('prob_totals', 'bingo_totals');
        foreach my $top_key (@top_keys)
        {
          foreach my $key (keys %{$this->{$top_key}})
          {
            $this->{$top_key}->{$key} += $other->{$top_key}->{$key};
          }
        }

        my $dem_total = $this->{'bingo_total'};
        if (!$dem_total){$dem_total = 1;}
        my @dems = (0, 0, 0, 0, 0, 0, 0, 0, 0);
        $dems[0] = $this->{'bingo_totals'}->{Constants::SEVENS_TITLE};
        if (!$dems[0]){$dems[0] = 1;}
        $dems[1] = $this->{'bingo_totals'}->{Constants::EIGHTS_TITLE};
        if (!$dems[1]){$dems[1] = 1;}
        $dems[2] = $this->{'bingo_totals'}->{Constants::NINES_TITLE};
        if (!$dems[2]){$dems[2] = 1;}
        $dems[3] = $this->{'bingo_totals'}->{Constants::TENS_TITLE};
        if (!$dems[3]){$dems[3] = 1;}
        $dems[4] = $this->{'bingo_totals'}->{Constants::ELEVENS_TITLE};
        if (!$dems[4]){$dems[4] = 1;}
        $dems[5] = $this->{'bingo_totals'}->{Constants::TWELVES_TITLE};
        if (!$dems[5]){$dems[5] = 1;}
        $dems[6] = $this->{'bingo_totals'}->{Constants::THIRTEENS_TITLE};
        if (!$dems[6]){$dems[6] = 1;}
        $dems[7] = $this->{'bingo_totals'}->{Constants::FOURTEENS_TITLE};
        if (!$dems[7]){$dems[7] = 1;}
        $dems[8] = $this->{'bingo_totals'}->{Constants::FIFTEENS_TITLE};
        if (!$dems[8]){$dems[8] = 1;}

        $this->{'total'}                                  = sprintf "%.2f", ($this->{'prob_total'} / $dem_total);
        $this->{'subitems'}->{Constants::SEVENS_TITLE}    = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::SEVENS_TITLE}    / $dems[0]);
        $this->{'subitems'}->{Constants::EIGHTS_TITLE}    = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::EIGHTS_TITLE}    / $dems[1]);
        $this->{'subitems'}->{Constants::NINES_TITLE}     = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::NINES_TITLE}     / $dems[2]);
        $this->{'subitems'}->{Constants::TENS_TITLE}      = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::TENS_TITLE}      / $dems[3]);
        $this->{'subitems'}->{Constants::ELEVENS_TITLE}   = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::ELEVENS_TITLE}   / $dems[4]);
        $this->{'subitems'}->{Constants::TWELVES_TITLE}   = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::TWELVES_TITLE}   / $dems[5]);
        $this->{'subitems'}->{Constants::THIRTEENS_TITLE} = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::THIRTEENS_TITLE} / $dems[6]);
        $this->{'subitems'}->{Constants::FOURTEENS_TITLE} = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::FOURTEENS_TITLE} / $dems[7]);
        $this->{'subitems'}->{Constants::FIFTEENS_TITLE}  = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::FIFTEENS_TITLE}  / $dems[8]);

      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        my @probs = @{$game->getWordsProbability($this_player, 1)};
        $this->{'prob_total'} += sum(@probs);
        $this->{'prob_totals'}->{Constants::SEVENS_TITLE}    += $probs[6];
        $this->{'prob_totals'}->{Constants::EIGHTS_TITLE}    += $probs[7];
        $this->{'prob_totals'}->{Constants::NINES_TITLE}     += $probs[8];
        $this->{'prob_totals'}->{Constants::TENS_TITLE}      += $probs[9];
        $this->{'prob_totals'}->{Constants::ELEVENS_TITLE}   += $probs[10];
        $this->{'prob_totals'}->{Constants::TWELVES_TITLE}   += $probs[11];
        $this->{'prob_totals'}->{Constants::THIRTEENS_TITLE} += $probs[12];
        $this->{'prob_totals'}->{Constants::FOURTEENS_TITLE} += $probs[13];
        $this->{'prob_totals'}->{Constants::FIFTEENS_TITLE}  += $probs[14];
        # Add 1 at the end to get only valid bingos
        my @bingos = @{$game->getNumWordsPlayed($this_player, 1, 1)};
        $this->{'bingo_total'} += sum(@bingos);
        $this->{'bingo_totals'}->{Constants::SEVENS_TITLE}    += $bingos[6];
        $this->{'bingo_totals'}->{Constants::EIGHTS_TITLE}    += $bingos[7];
        $this->{'bingo_totals'}->{Constants::NINES_TITLE}     += $bingos[8];
        $this->{'bingo_totals'}->{Constants::TENS_TITLE}      += $bingos[9];
        $this->{'bingo_totals'}->{Constants::ELEVENS_TITLE}   += $bingos[10];
        $this->{'bingo_totals'}->{Constants::TWELVES_TITLE}   += $bingos[11];
        $this->{'bingo_totals'}->{Constants::THIRTEENS_TITLE} += $bingos[12];
        $this->{'bingo_totals'}->{Constants::FOURTEENS_TITLE} += $bingos[13];
        $this->{'bingo_totals'}->{Constants::FIFTEENS_TITLE}  += $bingos[14];

        my $dem_total = $this->{'bingo_total'};
        if (!$dem_total){$dem_total = 1;}
        my @dems = (0, 0, 0, 0, 0, 0, 0, 0, 0);
        $dems[0] = $this->{'bingo_totals'}->{Constants::SEVENS_TITLE};
        if (!$dems[0]){$dems[0] = 1;}
        $dems[1] = $this->{'bingo_totals'}->{Constants::EIGHTS_TITLE};
        if (!$dems[1]){$dems[1] = 1;}
        $dems[2] = $this->{'bingo_totals'}->{Constants::NINES_TITLE};
        if (!$dems[2]){$dems[2] = 1;}
        $dems[3] = $this->{'bingo_totals'}->{Constants::TENS_TITLE};
        if (!$dems[3]){$dems[3] = 1;}
        $dems[4] = $this->{'bingo_totals'}->{Constants::ELEVENS_TITLE};
        if (!$dems[4]){$dems[4] = 1;}
        $dems[5] = $this->{'bingo_totals'}->{Constants::TWELVES_TITLE};
        if (!$dems[5]){$dems[5] = 1;}
        $dems[6] = $this->{'bingo_totals'}->{Constants::THIRTEENS_TITLE};
        if (!$dems[6]){$dems[6] = 1;}
        $dems[7] = $this->{'bingo_totals'}->{Constants::FOURTEENS_TITLE};
        if (!$dems[7]){$dems[7] = 1;}
        $dems[8] = $this->{'bingo_totals'}->{Constants::FIFTEENS_TITLE};
        if (!$dems[8]){$dems[8] = 1;}

        $this->{'total'}                                  = sprintf "%.2f", ($this->{'prob_total'} / $dem_total);
        $this->{'subitems'}->{Constants::SEVENS_TITLE}    = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::SEVENS_TITLE}    / $dems[0]);
        $this->{'subitems'}->{Constants::EIGHTS_TITLE}    = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::EIGHTS_TITLE}    / $dems[1]);
        $this->{'subitems'}->{Constants::NINES_TITLE}     = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::NINES_TITLE}     / $dems[2]);
        $this->{'subitems'}->{Constants::TENS_TITLE}      = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::TENS_TITLE}      / $dems[3]);
        $this->{'subitems'}->{Constants::ELEVENS_TITLE}   = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::ELEVENS_TITLE}   / $dems[4]);
        $this->{'subitems'}->{Constants::TWELVES_TITLE}   = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::TWELVES_TITLE}   / $dems[5]);
        $this->{'subitems'}->{Constants::THIRTEENS_TITLE} = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::THIRTEENS_TITLE} / $dems[6]);
        $this->{'subitems'}->{Constants::FOURTEENS_TITLE} = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::FOURTEENS_TITLE} / $dems[7]);
        $this->{'subitems'}->{Constants::FIFTEENS_TITLE}  = sprintf "%.2f", ($this->{'prob_totals'}->{Constants::FIFTEENS_TITLE}  / $dems[8]);
      }  
    },
    {
      Constants::STAT_NAME => 'Tiles Played',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
          'subitems' => 
          {
              'A' => 0,
              'B' => 0,
              'C' => 0,
              'D' => 0,
              'E' => 0,
              'F' => 0,
              'G' => 0,
              'H' => 0,
              'I' => 0,
              'J' => 0,
              'K' => 0,
              'L' => 0,
              'M' => 0,
              'N' => 0,
              'O' => 0,
              'P' => 0,
              'Q' => 0,
              'R' => 0,
              'S' => 0,
              'T' => 0,
              'U' => 0,
              'V' => 0,
              'W' => 0,
              'X' => 0,
              'Y' => 0,
              'Z' => 0,
              '?' => 0
          },
          'list' =>
          [
              'A',
              'B',
              'C',
              'D',
              'E',
              'F',
              'G',
              'H',
              'I',
              'J',
              'K',
              'L',
              'M',
              'N',
              'O',
              'P',
              'Q',
              'R',
              'S',
              'T',
              'U',
              'V',
              'W',
              'X',
              'Y',
              'Z',
              '?'
          ],
          'total' => 0
      },
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
        foreach my $key (keys %{$this->{'subitems'}})
        {
          $this->{'subitems'}->{$key} += $other->{'subitems'}->{$key};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        $this->{'total'} += $game->{'tiles_played'}->{$this_player}->{'total'};

        my $blanks = $game->{'tiles_played'}->{$this_player}->{'?'};
        $this->{'subitems'}->{'?'} += $blanks;

        foreach my $c ("A" .. "Z")
        {
           $this->{'subitems'}->{$c} += $game->{'tiles_played'}->{$this_player}->{$c};
        }
      }
    },
    {
      Constants::STAT_NAME => 'Power Tiles Played',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
          'subitems' =>
          {
            '?' => 0,
            'J' => 0,
            'Q' => 0,
            'X' => 0,
            'Z' => 0,
            'S' => 0
          },
          'list' =>
          [
            '?',
            'J',
            'Q',
            'X',
            'Z',
            'S'
          ],
          'total' => 0
      },
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;

        $this->{'total'} += $other->{'total'};
        foreach my $key (keys %{$this->{'subitems'}})
        {
          $this->{'subitems'}->{$key} += $other->{'subitems'}->{$key};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        my $blanks = $game->{'tiles_played'}->{$this_player}->{'?'};
        my $js     = $game->{'tiles_played'}->{$this_player}->{'J'};
        my $qs     = $game->{'tiles_played'}->{$this_player}->{'Q'};
        my $xs     = $game->{'tiles_played'}->{$this_player}->{'X'};
        my $zs     = $game->{'tiles_played'}->{$this_player}->{'Z'};
        my $ss     = $game->{'tiles_played'}->{$this_player}->{'S'};

        $this->{'total'} += $blanks + $js + $qs + $xs + $zs + $ss;
        $this->{'subitems'}->{'?'} += $blanks;
        $this->{'subitems'}->{'J'} += $js;
        $this->{'subitems'}->{'Q'} += $qs;
        $this->{'subitems'}->{'X'} += $xs;
        $this->{'subitems'}->{'Z'} += $zs;
        $this->{'subitems'}->{'S'} += $ss;
      }
    },
    {
      Constants::STAT_NAME => 'Power Tiles Stuck With',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
          'subitems' =>
          {
            '?' => 0,
            'J' => 0,
            'Q' => 0,
            'X' => 0,
            'Z' => 0,
            'S' => 0
          },
          'list' =>
          [
            '?',
            'J',
            'Q',
            'X',
            'Z',
            'S'
          ],
          'total' => 0
      },
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;

        $this->{'total'} += $other->{'total'};
        foreach my $key (keys %{$this->{'subitems'}})
        {
          $this->{'subitems'}->{$key} += $other->{'subitems'}->{$key};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        my $blanks = $game->getNumTilesStuckWith($this_player, '?');
        my $js     = $game->getNumTilesStuckWith($this_player, 'J');
        my $qs     = $game->getNumTilesStuckWith($this_player, 'Q');
        my $xs     = $game->getNumTilesStuckWith($this_player, 'X');
        my $zs     = $game->getNumTilesStuckWith($this_player, 'Z');
        my $ss     = $game->getNumTilesStuckWith($this_player, 'S');

        $this->{'total'} += $blanks + $js + $qs + $xs + $zs + $ss;
        $this->{'subitems'}->{'?'} += $blanks;
        $this->{'subitems'}->{'J'} += $js;
        $this->{'subitems'}->{'Q'} += $qs;
        $this->{'subitems'}->{'X'} += $xs;
        $this->{'subitems'}->{'Z'} += $zs;
        $this->{'subitems'}->{'S'} += $ss;
      }
    },
    {
      Constants::STAT_NAME => 'Turns With a Blank',
      Constants::STAT_ITEM_OBJECT_NAME => {'total' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        $this->{'total'} += $game->getTurnsWithBlank($this_player);
      }
    },
    {
      Constants::STAT_NAME => 'Triple Triples Played',
      Constants::STAT_ITEM_OBJECT_NAME => {'total' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        $this->{'total'} += $game->getNumTripleTriplesPlayed($this_player);
      }
    },
    {
      Constants::STAT_NAME => 'Bingoless Games',
      Constants::STAT_ITEM_OBJECT_NAME => {'total' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        $this->{'total'} += $game->isBingoless($this_player);
      }
    },
    {
      Constants::STAT_NAME => 'Bonus Square Coverage',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
          'subitems' =>
          {
            Constants::DOUBLE_LETTER_TITLE => 0,
            Constants::TRIPLE_LETTER_TITLE => 0,
            Constants::DOUBLE_WORD_TITLE => 0,
            Constants::TRIPLE_WORD_TITLE => 0
          },
          'list' =>
          [
            Constants::DOUBLE_LETTER_TITLE,
            Constants::DOUBLE_WORD_TITLE,
            Constants::TRIPLE_LETTER_TITLE,
            Constants::TRIPLE_WORD_TITLE
          ],
          'total' => 0
      },
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
        foreach my $key (keys %{$this->{'subitems'}})
        {
          $this->{'subitems'}->{$key} += $other->{'subitems'}->{$key};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        my $bs = $game->getNumBonusSquaresCovered($this_player);
        my $dl = $bs->{Constants::DOUBLE_LETTER};
        my $tl = $bs->{Constants::TRIPLE_LETTER};
        my $dw = $bs->{Constants::DOUBLE_WORD};
        my $tw = $bs->{Constants::TRIPLE_WORD};

        $this->{'total'} += $dl + $tl + $dw + $tw;
        $this->{'subitems'}->{Constants::DOUBLE_LETTER_TITLE} += $dl;
        $this->{'subitems'}->{Constants::TRIPLE_LETTER_TITLE} += $tl;
        $this->{'subitems'}->{Constants::DOUBLE_WORD_TITLE}   += $dw;
        $this->{'subitems'}->{Constants::TRIPLE_WORD_TITLE}   += $tw;
      }
    },
    {
      Constants::STAT_NAME => 'Phony Plays',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
          'subitems' =>
          {
             Constants::UNCHALLENGED  => 0,
             Constants::CHALLENGED_OFF => 0,   
          },
          'list' =>
          [
             Constants::UNCHALLENGED,
             Constants::CHALLENGED_OFF, 
          ],
          'total' => 0
      },
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
        foreach my $key (keys %{$this->{'subitems'}})
        {
          $this->{'subitems'}->{$key} += $other->{'subitems'}->{$key};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        # 0 to get all phonies, 1 to get unchallenged phonies
        my $num_phonies = $game->getNumPhonyPlays($this_player, 0);
        my $num_phonies_unchal = $game->getNumPhonyPlays($this_player, 1);

        $this->{'total'} += $num_phonies;
        $this->{'subitems'}->{Constants::UNCHALLENGED} += $num_phonies_unchal;
        $this->{'subitems'}->{Constants::CHALLENGED_OFF} += $num_phonies - $num_phonies_unchal;
      }
    },
    {
      Constants::STAT_NAME => 'Challenge Percentage',
      Constants::STAT_ITEM_OBJECT_NAME => {Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_PCAVG, 'total' => 0, 'challenges' => 0, 'successful_challenges' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'challenges'}            += $other->{'challenges'} ;
        $this->{'successful_challenges'} += $other->{'successful_challenges'};
        if ($this->{'challenges'} == 0)
        {
          $this->{'total'}                  = sprintf "%.4f", 0;
        }
        else
        {
          $this->{'total'}                  = sprintf "%.4f", $this->{'successful_challenges'} / $this->{'challenges'};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this   = shift;
        my $game   = shift;
        my $player = shift;

        my $chal = $game->getNumChallenges($player);

        my $pcw = $chal->{Constants::PLAYER_CHALLENGE_WON};
        my $pcl = $chal->{Constants::PLAYER_CHALLENGE_LOST};

        if ($pcw + $pcl == 0)
        {
          return;
        }

        $this->{'challenges'}            += $pcw + $pcl;
        $this->{'successful_challenges'} += $pcw;
        $this->{'total'}                  = sprintf "%.4f", $this->{'successful_challenges'} / $this->{'challenges'};
      }
    },
    {
      Constants::STAT_NAME => 'Defending Challenge Percentage',
      Constants::STAT_ITEM_OBJECT_NAME => {Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_PCAVG, 'total' => 0, 'challenges' => 0, 'successful_challenges' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'challenges'}            += $other->{'challenges'} ;
        $this->{'successful_challenges'} += $other->{'successful_challenges'};
        if ($this->{'challenges'} == 0)
        {
          $this->{'total'}                  = sprintf "%.4f", 0;
        }
        else
        {
          $this->{'total'}                  = sprintf "%.4f", $this->{'successful_challenges'} / $this->{'challenges'};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this   = shift;
        my $game   = shift;
        my $player = shift;

        my $chal = $game->getNumChallenges($player);

        my $ocw = $chal->{Constants::OPP_CHALLENGE_WON};
        my $ocl = $chal->{Constants::OPP_CHALLENGE_LOST};

        if ($ocw + $ocl == 0)
        {
          return;
        }

        $this->{'challenges'}            += $ocw + $ocl;
        $this->{'successful_challenges'} += $ocl;
        $this->{'total'}                  = sprintf "%.4f", $this->{'successful_challenges'} / $this->{'challenges'};
      }
    },
    {
      Constants::STAT_NAME => 'Percentage Phonies Unchallenged',
      Constants::STAT_ITEM_OBJECT_NAME => {Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_PCAVG, 'total' => 0, 'num_phonies' => 0, 'num_phonies_unchal' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'num_phonies'}            += $other->{'num_phonies'} ;
        $this->{'num_phonies_unchal'}     += $other->{'num_phonies_unchal'};
        if ($this->{'num_phonies'} == 0)
        {
          $this->{'total'}                  = sprintf "%.4f", 0;
        }
        else
        {
          $this->{'total'}                  = sprintf "%.4f", $this->{'num_phonies_unchal'} / $this->{'num_phonies'};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this   = shift;
        my $game   = shift;
        my $player = shift;

        # 0 to get all phonies, 1 to get unchallenged phonies
        my $num_phonies        = $game->getNumPhonyPlays($player, 0);
        my $num_phonies_unchal = $game->getNumPhonyPlays($player, 1);

        if ($num_phonies == 0)
        {
          return;
        }

        $this->{'num_phonies'}        += $num_phonies;
        $this->{'num_phonies_unchal'} += $num_phonies_unchal;
        $this->{'total'} = sprintf "%.4f", $this->{'num_phonies_unchal'} / $this->{'num_phonies'};
      }
    },
    {
      Constants::STAT_NAME => 'Comments',
      Constants::STAT_ITEM_OBJECT_NAME => {'total' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this   = shift;
        my $game   = shift;
        my $player = shift;

        $this->{'total'} += $game->getNumComments($player);
      }
    },
    {
      Constants::STAT_NAME => 'Comments Word Length',
      Constants::STAT_ITEM_OBJECT_NAME =>  {'total' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this   = shift;
        my $game   = shift;
        my $player = shift;

        $this->{'total'} += $game->getNumCommentsWordLength($player);
      }
    },
    {
      Constants::STAT_NAME => 'Many Double Letters Covered',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => [], 'ids' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'ids'}}, @{$other->{'ids'}};
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;

        # All is 24
        if (20 <= $game->getNumBonusSquaresCovered(0)->{Constants::DOUBLE_LETTER} + $game->getNumBonusSquaresCovered(1)->{Constants::DOUBLE_LETTER})
        {
          push @{$this->{'ids'}},  $game->{'id'};
          push @{$this->{'list'}}, $game->getReadableName();
        }
      }
    },
    {
      Constants::STAT_NAME => 'Many Double Words Covered',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => [], 'ids' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'ids'}}, @{$other->{'ids'}};
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        # All is 17

        my $sum = $game->getNumBonusSquaresCovered(0)->{Constants::DOUBLE_WORD} + $game->getNumBonusSquaresCovered(1)->{Constants::DOUBLE_WORD};

        if (15 <= $sum)
        {
          if ($sum == 15)
          {
            push @{$this->{'ids'}},  $game->{'id'};
            push @{$this->{'list'}}, $game->getReadableName();
          }
          else
          {
            unshift @{$this->{'ids'}},  $game->{'id'};
            unshift @{$this->{'list'}}, $game->getReadableName();
          }
        }
      }
    },
    {
      Constants::STAT_NAME => 'All Triple Letters Covered',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => [], 'ids' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'ids'}}, @{$other->{'ids'}};
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;

        if (12 == $game->getNumBonusSquaresCovered(0)->{Constants::TRIPLE_LETTER} + $game->getNumBonusSquaresCovered(1)->{Constants::TRIPLE_LETTER})
        {
          push @{$this->{'ids'}},  $game->{'id'};
          push @{$this->{'list'}}, $game->getReadableName();
        }
      }
    },
    {
      Constants::STAT_NAME => 'All Triple Words Covered',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => [], 'ids' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'ids'}}, @{$other->{'ids'}};
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;
        if (8 == $game->getNumBonusSquaresCovered(0)->{Constants::TRIPLE_WORD} + $game->getNumBonusSquaresCovered(1)->{Constants::TRIPLE_WORD})
        {
          push @{$this->{'ids'}},  $game->{'id'};
          push @{$this->{'list'}}, $game->getReadableName();
        }
      }
    },
    {
      Constants::STAT_NAME => 'High Scoring',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => [], 'ids' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'ids'}}, @{$other->{'ids'}};
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;

        if (700 <= $game->{'board'}->{"player_one_total"} || 700 <= $game->{'board'}->{"player_two_total"})
        {
          push @{$this->{'ids'}},  $game->{'id'};
          push @{$this->{'list'}}, $game->getReadableName();
        }
      }
    },
    {
      Constants::STAT_NAME => 'Combined High Scoring',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => [], 'ids' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'ids'}}, @{$other->{'ids'}};
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;

        if (1100 <= $game->{'board'}->{"player_one_total"} + $game->{'board'}->{"player_two_total"})
        {
          push @{$this->{'ids'}},  $game->{'id'};
          push @{$this->{'list'}}, $game->getReadableName();
        }
      }
    },
    {
      Constants::STAT_NAME => 'Combined Low Scoring',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => [], 'ids' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'ids'}}, @{$other->{'ids'}};
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;

        if (200 >= $game->{'board'}->{"player_one_total"} + $game->{'board'}->{"player_two_total"})
        {
          push @{$this->{'ids'}},  $game->{'id'};
          push @{$this->{'list'}}, $game->getReadableName();
        }
      }
    },
    {
      Constants::STAT_NAME => 'Ties',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => [], 'ids' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'ids'}}, @{$other->{'ids'}};
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;

        if ($game->{'board'}->{"player_one_total"} == $game->{'board'}->{"player_two_total"})
        {
          push @{$this->{'ids'}},  $game->{'id'};
          push @{$this->{'list'}}, $game->getReadableName();
        }
      }
    },
    {
      Constants::STAT_NAME => 'One Player Plays Every Power Tile',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => [], 'ids' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'ids'}}, @{$other->{'ids'}};
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;

        my $sum1 =  $game->{'tiles_played'}->{0}->{'?'} + 
                    $game->{'tiles_played'}->{0}->{'Z'} + 
                    $game->{'tiles_played'}->{0}->{'X'} + 
                    $game->{'tiles_played'}->{0}->{'Q'} + 
                    $game->{'tiles_played'}->{0}->{'J'} + 
                    $game->{'tiles_played'}->{0}->{'S'};

        my $sum2 =  $game->{'tiles_played'}->{1}->{'?'} + 
                    $game->{'tiles_played'}->{1}->{'Z'} + 
                    $game->{'tiles_played'}->{1}->{'X'} + 
                    $game->{'tiles_played'}->{1}->{'Q'} + 
                    $game->{'tiles_played'}->{1}->{'J'} + 
                    $game->{'tiles_played'}->{1}->{'S'};

        if ($sum1 == 10 || $sum2 == 10)
        {
          push @{$this->{'ids'}},  $game->{'id'};
          push @{$this->{'list'}}, $game->getReadableName();
        }
      }
    },
    {
      Constants::STAT_NAME => 'One Player Plays Every E',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => [], 'ids' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'ids'}}, @{$other->{'ids'}};
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        my $sum1 = $game->{'tiles_played'}->{0}->{'E'};

        my $sum2 = $game->{'tiles_played'}->{1}->{'E'};

        if ($sum1 == 12 || $sum2 == 12)
        {
          push @{$this->{'ids'}},  $game->{'id'};
          push @{$this->{'list'}}, $game->getReadableName();
        }
      }
    },
    {
      Constants::STAT_NAME => 'Many Challenges',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => [], 'ids' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'ids'}}, @{$other->{'ids'}};
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;

        my $chal = $game->getNumChallenges(0);

        my $pcw  = $chal->{Constants::PLAYER_CHALLENGE_WON};
        my $pcl  = $chal->{Constants::PLAYER_CHALLENGE_LOST};
        my $ocw  = $chal->{Constants::OPP_CHALLENGE_WON};
        my $ocl  = $chal->{Constants::OPP_CHALLENGE_LOST};

        if (5 <= $pcw + $pcl + $ocw + $ocl)
        {
          push @{$this->{'ids'}},  $game->{'id'};
          push @{$this->{'list'}}, $game->getReadableName();
        }
      }
    },
    {
      Constants::STAT_NAME => 'Mistakeless Turns',
      Constants::STAT_ITEM_OBJECT_NAME => {'total' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this   = shift;
        my $game   = shift;
        my $player = shift;
        $this->{'total'}  += $game->getNumMistakelessTurns($player);
      }
    },
    {
      Constants::STAT_NAME => 'Mistakes',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
        'total'    => 0,
        'list'     => get_mistakes_order(), # Constants::MISTAKES
        'subitems' => get_mistakes_hash()   # map {$_ => 0} Constants::MISTAKES
      },
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        foreach my $key (keys %{$this->{'subitems'}})
        {
          $this->{'subitems'}->{$key} += $other->{'subitems'}->{$key};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this   = shift;
        my $game   = shift;
        my $player = shift;
        
        my @categories = Constants::MISTAKES;

        my $mistakes_hash_ref = $game->getNumMistakes($player);

        foreach my $cat (@categories)
        {
          my $val                      = $mistakes_hash_ref->{$cat};
          $this->{'total'}            += $val;
          $this->{'subitems'}->{$cat} += $val;
        }
      }
    },
    {
      Constants::STAT_NAME => 'Mistakes List',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        push @{$this->{'list'}}, @{$other->{'list'}};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this   = shift;
        my $game   = shift;
        my $player = shift;

        push @{$this->{'list'}}, @{$game->getMistakes($player)};
      }
    }
  ];
}

sub get_mistakes_order
{
  my @a = Constants::MISTAKES;
  return \@a;
}
sub get_mistakes_hash
{
  my @a = Constants::MISTAKES;
  my %b = map {$_ => 0} @a;
  return \%b; 
}
1;

