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
use JSON::XS;

sub new
{
  my $this            = shift;
  my $player_is_first = shift;

  my $json            = shift;

  if ($json)
  {
    my $stats = JSON::XS::decode_json($json);
    $stats->{'player_is_first'} = $player_is_first;
    my $self = bless $stats, $this;
    return $self;
  }

  my $statlist = statsList();

  my @player1_stats = ();
  my @player2_stats = ();
  my @game_stats    = ();
  my @notable_stats = ();
  my @error_stats   = ();

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
    elsif ($statitem->{Constants::STAT_METATYPE_NAME} eq Constants::METATYPE_ERROR)
    {
      push @error_stats, $statitem;
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
      Constants::STATS_DATA_ERROR_KEY_NAME      => \@error_stats,
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
sub addError
{
  my $this  = shift;
  my $error = shift;
  my $is_warning = shift;

  my $game_stats = $this->{Constants::STATS_DATA_KEY_NAME}->{Constants::STATS_DATA_GAME_KEY_NAME};
  my $invalid_stat;
  my $error_stat;

  for (my $i = 0; $i < scalar @{$game_stats}; $i++)
  {
    my $stat = $game_stats->[$i];
    if ($stat->{Constants::STAT_NAME} eq 'Invalid Games')
    {
      $invalid_stat = $stat->{Constants::STAT_ITEM_OBJECT_NAME};
    }
  }

  my $error_stats = $this->{Constants::STATS_DATA_KEY_NAME}->{Constants::STATS_DATA_ERROR_KEY_NAME};

  for (my $i = 0; $i < scalar @{$error_stats}; $i++)
  {
    my $stat = $error_stats->[$i];
    if ($is_warning && $stat->{Constants::STAT_NAME} eq 'Warnings')
    {
      $error_stat = $stat->{Constants::STAT_ITEM_OBJECT_NAME};
    }
    elsif (!$is_warning && $stat->{Constants::STAT_NAME} eq 'Errors')
    {
      $error_stat = $stat->{Constants::STAT_ITEM_OBJECT_NAME};
    }
  }

  my $incomp_pattern = Constants::GAMEERROR_INCOMPLETE;
  my $disco_pattern  = Constants::GAMEERROR_DISCONNECTED;

  if (!$is_warning)
  {
    $invalid_stat->{'total'}++;
    if ($error =~ /$incomp_pattern/i)
    {
      $invalid_stat->{'subitems'}->{Constants::GAMEERROR_INCOMPLETE}++;
    }
    elsif ($error =~ /$disco_pattern/i)
    {
      $invalid_stat->{'subitems'}->{Constants::GAMEERROR_DISCONNECTED}++;
    }
    else
    {
      $invalid_stat->{'subitems'}->{Constants::GAMEERROR_OTHER}++;
    }
  }
  my @items = split /;/, $error;
  push @{$error_stat->{'list'}}, \@items;
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

  my $num;

  my $player1_ref = $this->{Constants::STATS_DATA_KEY_NAME}->{Constants::STATS_DATA_PLAYER_ONE_KEY_NAME};
  my $player2_ref = $this->{Constants::STATS_DATA_KEY_NAME}->{Constants::STATS_DATA_PLAYER_TWO_KEY_NAME};
  my $game_ref    = $this->{Constants::STATS_DATA_KEY_NAME}->{Constants::STATS_DATA_GAME_KEY_NAME      };
  my $notable_ref = $this->{Constants::STATS_DATA_KEY_NAME}->{Constants::STATS_DATA_NOTABLE_KEY_NAME   };
  my $error_ref   = $this->{Constants::STATS_DATA_KEY_NAME}->{Constants::STATS_DATA_ERROR_KEY_NAME     };

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

  my $player_dynamic_list;
  my $opp_dynamic_list;

  for (my $i = 0; $i < scalar @{$player1_ref}; $i++)
  {
    my $stat   = $player1_ref->[$i];
    my $object = $stat->{Constants::STAT_ITEM_OBJECT_NAME};
    $object->{Constants::STAT_NAME} = $stat->{Constants::STAT_NAME};
    if ($stat->{Constants::STAT_NAME} eq "Mistakes List")
    {
      $player_mistake_list = $object;
    }
    elsif ($stat->{Constants::STAT_NAME} eq "Dynamic Mistakes List")
    {
      $player_dynamic_list = $object;
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
    elsif ($stat->{Constants::STAT_NAME} eq "Dynamic Mistakes List")
    {
      $opp_dynamic_list = $object;
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

  my $error_list;
  my $warning_list;

  for (my $i = 0; $i < scalar @{$error_ref}; $i++)
  {
    my $stat   = $error_ref->[$i];
    my $object = $stat->{Constants::STAT_ITEM_OBJECT_NAME};
    $object->{Constants::STAT_NAME} = $stat->{Constants::STAT_NAME};
    if ($stat->{Constants::STAT_NAME} eq 'Errors')
    {
      $error_list = $object;
    }
    elsif ($stat->{Constants::STAT_NAME} eq 'Warnings')
    {
      $warning_list = $object;
    }
  }



  my $s = '';
  my @styles = (Constants::DIV_STYLE_ODD, Constants::DIV_STYLE_EVEN);
  my $stylebit = 0;
  my $stmp;

  $stmp = statListToHTML(\@player_list_stats, 'Player Lists','player_list_stats_expander', $styles[$stylebit]);
  if ($stmp){$stylebit = 1 - $stylebit;}
  $s .= $stmp; 
  $stmp = statListToHTML(\@opp_list_stats,    'Opponent Lists', 'opponent_list_stats_expander', $styles[$stylebit]);
  if ($stmp){$stylebit = 1 - $stylebit;}
  $s .= $stmp; 
  $stmp = notableListToHTML(\@notable_stats,     'Notable Lists', 'notable_stats_expander', $styles[$stylebit]);
  if ($stmp){$stylebit = 1 - $stylebit;}
  $s .= $stmp; 
  $stmp = statItemsToHTML(\@game_stats,        $num, 'Game Stats', 'game_stats_expander', $styles[$stylebit]);
  if ($stmp){$stylebit = 1 - $stylebit;}
  $s .= $stmp; 
  $stmp = statItemsToHTML(\@player_item_stats, $num, 'Player Stats', 'player_stats_expander', $styles[$stylebit]);
  if ($stmp){$stylebit = 1 - $stylebit;}
  $s .= $stmp; 
  $stmp = statItemsToHTML(\@opp_item_stats,    $num, 'Opponent Stats', 'opp_stats_expander', $styles[$stylebit]);
  if ($stmp){$stylebit = 1 - $stylebit;}
  $s .= $stmp; 
  $stmp = mistakesToHTML($player_mistake_list, 'Player Mistakes', 'player_mistakes_expander', $styles[$stylebit]);
  if ($stmp){$stylebit = 1 - $stylebit;}
  $s .= $stmp; 
  $stmp = mistakesToHTML($player_dynamic_list, 'Player Dynamic Mistakes', 'player_dynamics_expander', $styles[$stylebit]);
  if ($stmp){$stylebit = 1 - $stylebit;}
  $s .= $stmp; 
  $stmp = mistakesToHTML($opp_mistake_list, 'Opponent Mistakes',     'opponent_mistake_expander', $styles[$stylebit]);
  if ($stmp){$stylebit = 1 - $stylebit;}
  $s .= $stmp; 
  $stmp = mistakesToHTML($opp_dynamic_list,'Opponent Dynamic Mistakes', 'opponent_dynamics_expander', $styles[$stylebit]);
  if ($stmp){$stylebit = 1 - $stylebit;}
  $s .= $stmp; 
  $stmp = errorsToHTML($error_list,   'Errors', 'error_list_expander', $styles[$stylebit]);
  if ($stmp){$stylebit = 1 - $stylebit;}
  $s .= $stmp; 
  $stmp = errorsToHTML($warning_list, 'Warnings', 'warning_list_expander', $styles[$stylebit]);

  return $s;
}

sub errorsToHTML
{
  my $error_list    = shift;
  my $title         = shift;
  my $expander_id   = shift;
  my $div_style     = shift;

  my $table_style  = Constants::RESULTS_PAGE_TABLE_STYLE;
  my $url = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX;
  my $download   = Constants::DATA_DOWNLOAD_ATTRIBUTE;

  my @error_list = @{$error_list->{'list'}};

  if (scalar @error_list == 0)
  {
    return '';
  }

  my $content = '';

  foreach my $error (@error_list)
  {
    my $id   = $error->[0];
    my $num  = $error->[1];
    my $type = $error->[2];
    my $game = "<a href='$url$id' target='_blank'>Game $id</a>";

    my $width = 100 / 3;
    my $width_style_part = "width: $width%;";
    my $width_style = "style='$width_style_part'";

    $content .=
    "
    <tr $download >
      <td  style='text-align: center; $width_style_part'>$game</td>
      <td  style='text-align: center; $width_style_part'>$num</td>
      <td  style='text-align: center; $width_style_part'>$type</td>
    </tr>";
  }

  my $error_table = Utils::make_datatable(
    $expander_id,
    $expander_id . '_actually_error_id_okay',
    ['Game', 'Line', 'Error'],
    ['text-align: center', 'text-align: center', 'text-align: center'],
    ['false', 'false', 'false'],
    $content
  );


  my $error_expander = Utils::make_expander($expander_id);
  my $table_id = $title . '_error_table_id';
  my $grouphtml = <<GROUP
  <div $div_style>
    $error_expander $title
    $error_table
  </div>
GROUP
;
  return $grouphtml;
}

sub mistakesToHTML
{
  my $mistakes_list = shift;
  my $title         = shift;
  my $expander_id   = shift;
  my $div_style     = shift;
  my $prefix        = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX;
  my $table_style   = Constants::RESULTS_PAGE_TABLE_STYLE;
  my $download      = Constants::DATA_DOWNLOAD_ATTRIBUTE;

  my $list = $mistakes_list->{'list'};
  my @list = @{$list};

  if (scalar @list == 0)
  {
    return '';
  }

  my $content = '';
  my $number = 0;
  foreach my $mistake (@list)
  {
    $number++;
    my $type = $mistake->[0];
    my $size = $mistake->[1];
    my $id   = $mistake->[2];
    my $play = $mistake->[3];
    my $cmnt = $mistake->[4];

    my $comment_expander_id = $expander_id . '_comment_' . $number;
    my $comment_expander = Utils::make_expander($comment_expander_id, 1, 1);


    my $play_download_text = "Game $id, $play";
    $play = "<a href='$prefix$id' target='_blank'>$play</a>";

    my $width = 100 / 4;
    my $width_style_part = "width: $width%;";
    my $width_style = "style='$width_style_part'";
    my $also_centered = "style='$width_style_part text-align: center'";

    $content .=
    "
    <tr>
      <td style='text-align: center'>
        <table style='width: 100%'>
    <tbody>
      <tr style='background-color: inherit'  $download >
              <td $also_centered data-downloadtext='$play_download_text'>$play</td>
              <td $also_centered>$type</td>
              <td $also_centered>$size</td>
        <td $also_centered data-downloadid='$comment_expander_id'>$comment_expander</td>
      </tr>
    </tbody>
  </table>
  <div class='collapse' id='$comment_expander_id'>
  $cmnt
  </div>
      </td>
    </tr>
    ";
  }

  my $mistake_table = Utils::make_datatable(
    $expander_id,
    $expander_id . '_actually_table_id_okay',
    ['Play', 'Type', 'Size', 'Comment'],
    ['text-align: center',  'text-align: center', 'text-align: center', 'text-align: center'],
    ['false', 'false', 'false', 'false'],
    $content
  );

  my $mistake_expander = Utils::make_expander($expander_id);
  my $grouphtml = <<GROUP
  <div $div_style>
    $mistake_expander $title
    $mistake_table
  </div>
GROUP
;
  return $grouphtml;
}

sub statItemsToHTML
{
  my $listref      = shift;
  my $numgames     = shift;
  my $grouptitle   = shift;
  my $group_expander_id  = shift;
  my $div_style    = shift;
  my $table_style  = Constants::RESULTS_PAGE_TABLE_STYLE;

  my $tableclass = 'statitemtable';
  my $divclass   = 'statitemdiv';
  my $download   = Constants::DATA_DOWNLOAD_ATTRIBUTE;

  my $content = '';
  my $width = 100 / 3;
  my $width_style_part = "width: $width%;";
  my $width_style = "style='$width_style_part'";
  my $also_centered = "style='$width_style_part text-align: center'";

  for(my $i = 0; $i < scalar @{$listref}; $i++)
  {
    my $statitem     = $listref->[$i];
    my $title        = $statitem->{Constants::STAT_NAME};
    my $subitems     = $statitem->{'subitems'};
    my $display_name = $statitem->{Constants::STAT_OBJECT_DISPLAY_NAME};
    my $nototal_cond = $display_name && $display_name eq Constants::STAT_OBJECT_DISPLAY_PCAVG;
    my $stat_expander = '';  
    my $subtable      = '';

    my $total    = $statitem->{'total'};
    my $average = sprintf "%.2f", $total/$numgames;

    if ($nototal_cond)
    {
      $average = $total;
      $total   = '';
    }

    if ($statitem->{'link'})
    {
      my $link = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX . $statitem->{'link'};
      $title = "<a data-sort='$title' href='$link' target='_blank'>$title</a>";
    }

    $content .=
    "
    <tr>
      <td style='text-align: center'>
        <table style='width: 100%'>
          <tbody>
            <tr style='background-color: inherit' $download >
              <td $also_centered>$title</td>
              <td $also_centered>$average</td>
              <td $also_centered>$total</td>
            </tr>
          </tbody>
        </table>
    ";

    if ($subitems)
    {
      my $stat_expander_id = $grouptitle . $title . '_subitems';
      $stat_expander_id =~ s/\s//g;
      $stat_expander = Utils::make_expander($stat_expander_id, 1, 1);

      $content .=
      "
      <div class='collapse' id='$stat_expander_id'>
        <table  class='$tableclass' >
          <tbody>
      ";

      my $order = $statitem->{'list'};
      for (my $i = 0; $i < scalar @{$order}; $i++)
      {
        my $subtitle = $order->[$i];
        my $subtotal = $subitems->{$subtitle};
        my $subaverage = sprintf "%.2f", $subtotal/$numgames; 
        if ($nototal_cond)
        {
          $subaverage = $subtotal;
          $subtotal   = '';
        }
        $content .=
        "
        <tr $download  >
          <td $also_centered>$subtitle</td>
          <td $also_centered>$subaverage</td>
          <td $also_centered>$subtotal</td>
        </tr>
        ";
      }
      $content .=
      "
          </tbody>
        </table>
      </div>
      <div>
        $stat_expander
      </div>
      ";
    }
    $content .= "</td></tr>";
  }

  $content = Utils::make_datatable(
    $group_expander_id,
    $group_expander_id . '_actually_table_id_okay',
    ['Stat', 'Average', 'Total'],
    ['text-align: center',  'text-align: center', 'text-align: center'],
    ['false', 'disable', 'disable'],
    $content
  );

  my $group_expander = Utils::make_expander($group_expander_id);
  return make_group($group_expander, $grouptitle, $group_expander_id, $div_style, $content);
}

sub statListToHTML
{
  my $listref      = shift;
  my $grouptitle   = shift;
  my $group_expander_id  = shift;
  my $div_style    = shift;
  my $table_style  = Constants::RESULTS_PAGE_TABLE_STYLE;
  my $download   = Constants::DATA_DOWNLOAD_ATTRIBUTE;

  my $prefix = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX;

  my $list_color_to_type =
  {
    Constants::TRIPLE_TRIPLE_COLOR            => 'Triple Triple',
    Constants::NINE_OR_ABOVE_COLOR            => 'Bingo Nine or Above',
    Constants::IMPROBABLE_COLOR               => 'Improbable',
    Constants::TRIPLE_TRIPLE_NINE_COLOR       => 'Triple Triple and Nine or Above',
    Constants::IMPROBABLE_NINE_OR_ABOVE_COLOR => 'Improbable and Nine or Above',
    Constants::IMPROBABLE_TRIPLE_TRIPLE_COLOR => 'Improbable and Triple Triple',
    Constants::ALL_THREE_COLOR                => 'Triple Triple and Bingo Nine or Above and Improbable'
  };

  my $content = '';
  for(my $i = 0; $i < scalar @{$listref}; $i++)
  {
    my $statitem = $listref->[$i];
    my $playlist = $statitem->{'list'};
    if (scalar @{$playlist} == 0)
    {
      next;
    }
    my $title    = $statitem->{Constants::STAT_NAME};
    my $expander_id = $group_expander_id . '_' . $title;
    $expander_id =~ s/\s//g;
    my $table_id = $grouptitle . '_' . $title . '_statlist_table_id';
    my $table_content = '';

    for (my $i = 0; $i < scalar @{$playlist}; $i++)
    {
      my $item  = $playlist->[$i];
      my $color  = $item->[0];
      my $play  = $item->[1];
      my $prob  = $item->[2];
      my $score = $item->[3];
      my $id    = $item->[4];

      my $texttype = $list_color_to_type->{$color};
      if (!$texttype)
      {
        $texttype = '';
      }
      my $alphaplay = $play;
      $alphaplay =~ s/\W//g;

      my $width = 100 / 4;
      my $width_style_part = "width: $width%;";
      my $width_style = "style='$width_style_part'";

      my $span_style = Utils::get_color_dot_style($color);
      $table_content .=
      "
        <tr $download >
          <td style='text-align: center; $width_style_part'  data-downloadtext='$texttype'><span $span_style></span></td>
          <td style='text-align: center; $width_style_part' ><a data-alpha='$alphaplay' href='$prefix$id' target='_blank'>$play</a></td>
          <td style='text-align: center; $width_style_part' >$prob</td>
          <td style='text-align: center; $width_style_part' >$score</td>
        </tr>\n";
    }  

    my $list_table = Utils::make_datatable(
    
      $expander_id,
      $table_id,
      ['Type', 'Play', 'Probability', 'Score'],
      ['text-align: center', '', '', ''],
      ['false', 'false', 'true', 'true'],
      $table_content
    );

    my $expander = Utils::make_expander($expander_id);
  
    $content .= Utils::make_content_item($expander, $title, $list_table);
  }
  if (!$content)
  {
    return '';
  }
  my $group_expander = Utils::make_expander($group_expander_id);
  return make_group($group_expander, $grouptitle, $group_expander_id, $div_style, $content);
}

sub notableListToHTML
{
  my $listref           = shift;
  my $grouptitle        = shift;
  my $group_expander_id = shift;
  my $div_style         = shift;
  my $table_style  = Constants::RESULTS_PAGE_TABLE_STYLE;
  my $download   = Constants::DATA_DOWNLOAD_ATTRIBUTE;

  my $prefix = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX;

  my $content = '';
  for(my $i = 0; $i < scalar @{$listref}; $i++)
  {
    my $statitem = $listref->[$i];
    my $gamelist = $statitem->{'list'};
    if (scalar @{$gamelist} == 0)
    {
      next;
    }
    my $idslist  = $statitem->{'ids'};
    my $title    = $statitem->{Constants::STAT_NAME};
    my $expander_id = $group_expander_id . '_' . $title;
    my $table_id    = $grouptitle . '_' . $title . '_notable_table_id';
    $expander_id =~ s/\s//g;
    my $notable_list = '';
    for (my $i = 0; $i < scalar @{$gamelist}; $i++)
    {
      my $gamename  = $gamelist->[$i];
      my $gameid    = $idslist->[$i];
  
      $notable_list .= "<tr $download ><td style='text-align: center'><a href='$prefix$gameid' target='_blank'>$gamename</a></td></tr>\n";
    }
  
    my $notable_table = Utils::make_datatable(
      $expander_id,
      $table_id,
      ['Game'],
      ['text-align: center'],
      ['false'],
      $notable_list
    );

    my $expander = Utils::make_expander($expander_id);
  
    $content .= Utils::make_content_item($expander, $title, $notable_table);
  }
  if (!$content)
  {
    return '';
  }
  my $group_expander = Utils::make_expander($group_expander_id);
  return make_group($group_expander, $grouptitle, $group_expander_id, $div_style, $content);
}


sub make_group
{
  my $group_expander    = shift;
  my $grouptitle        = shift;
  my $group_expander_id = shift;
  my $div_style         = shift;
  my $content           = shift;

  return
  "
  <div $div_style>
    $group_expander $grouptitle
     <div class='collapse' id='$group_expander_id'>
       $content
     </div>
  </div>
  ";
}

sub statsList
{
  return
  [
    {
      Constants::STAT_NAME => 'Errors',
      Constants::STAT_DESCRIPTION_NAME =>
'Errors are (most likely) the result of malformed GCG files.
Common errors are described below:

<h5>No moves found</h5>
This error appears when an empty GCG file is detected.
<h5>Disconnected play detected</h5>
This error appears when a play is made that does not connect to other tiles on the board.
<h5>Both players have the same name</h5>
This error appears when both players have the exact same name. In this case the program cannot distinguish who is making which plays.
<h5>No valid lexicon found</h5>
This error appears when the game is not tagged with a lexicon or the game uses an unrecognized lexicon, such as THTWL85.
<h5>Game is incomplete</h5>
This error appears when the GCG file is incomplete.
The errors above are relatively common and well-tested.
If you encounter any of these errors, it probably means
that the GCG file of the game is somehow malformed or tagged incorrectly.
To correct these errors, update the game on cross-tables.com and
the corrected version should appear in your stats the next day.

Any other errors that appear are rare and likely due to a bug.
If you see an error or warning that was not described above,
please email them to joshuacastellano7@gmail.com.',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_ERROR,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        # Do nothing, errors added elsewhere        
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        # Do nothing, errors added elsewhere
      }
    },
    {
      Constants::STAT_NAME => 'Warnings',
      Constants::STAT_DESCRIPTION_NAME =>

'Warnings are for letting players know that they
might want to correct certain GCG files. The complete
list of warnings is below:
      
<h5>Duplicate game detected</h5>
This appears when two games with the same tournament
and round number are detected. The duplicate game is
not included in statistics or leaderboards. It probably
means that both you and your opponent uploaded the same
game. In this case the racks that you recorded might
have been overwritten when you opponent uploaded their game.

<h5>Note before moves detected</h5>
Notes that appear before moves are not associated with
either player, so mistakes tagged in these notes will
not be recorded.',
      Constants::STAT_ITEM_OBJECT_NAME => {'list' => []},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_ERROR,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        # Do nothing, warnings added elsewhere        
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        # Do nothing, warnings added elsewhere
      }
    },
    {
      Constants::STAT_NAME => 'Games',
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of valid games RandomRacer retrieved from cross-tables.com.',
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
      Constants::STAT_NAME => 'Invalid Games',
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of games that threw an error when being processed by RandomRacer.',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
        'total' => 0,
        'subitems' =>
        {
          Constants::GAMEERROR_INCOMPLETE    => 0,
          Constants::GAMEERROR_DISCONNECTED  => 0,
          Constants::GAMEERROR_OTHER         => 0,
        },
        'list' =>
        [
          Constants::GAMEERROR_INCOMPLETE,
          Constants::GAMEERROR_DISCONNECTED,
          Constants::GAMEERROR_OTHER
        ],
        Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_TOTAL,
        'int' => 1
      },
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_GAME,
      Constants::STAT_ERRORTYPE_NAME => Constants::ERRORTYPE_ERROR,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        # Do nothing, errors are added elsewhere
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        # Do nothing, errors are added elsewhere
      }
    },
    {
      Constants::STAT_NAME => 'Total Turns',
      Constants::STAT_DESCRIPTION_NAME =>
      'The total number of turns of the player and the opponent.',
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
      Constants::STAT_NAME => 'Bingos',
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of bingos played by the player that were not challenged off.',
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
      Constants::STAT_DESCRIPTION_NAME =>'Triple triples played by the player that were not challenged off. They do not have to be bingos.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Bingos played by the player that were nine letters or longer and were not challenged off.',
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
      Constants::STAT_NAME => 'Challenged Phonies',
      Constants::STAT_DESCRIPTION_NAME =>
      'Plays made by the player that formed at least one phony and were challenged off by an opponent.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Plays made by the player that formed at least one phony and were not challenged by an opponent.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Plays made by the player that were challenged by an opponent.',
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
      Constants::STAT_NAME => 'Wins',
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of wins of the player.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The game score of the player.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The average score per turn of the player based on all of their games.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of turns made by the player.',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
        'total' => 0,
        'subitems' =>
        {
          'Vertical Plays'   => 0,
          'Horizontal Plays' => 0,
          'One Tile Plays'   => 0,
          'Other Plays'      => 0
        },
        'list' =>
        [
          'Vertical Plays'  ,
          'Horizontal Plays',
          'One Tile Plays'  ,
          'Other Plays'
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

        $this->{'total'} += $game->getNumTurns($this_player);
        $this->{'subitems'}->{'Vertical Plays'}   += $game->getNumVerticalPlays($this_player);
        $this->{'subitems'}->{'Horizontal Plays'} += $game->getNumHorizontalPlays($this_player);
        $this->{'subitems'}->{'One Tile Plays'}   += $game->getNumOneTilePlays($this_player);
        $this->{'subitems'}->{'Other Plays'}      += $game->getNumOtherPlays($this_player);
      }
    },
    {
      Constants::STAT_NAME => 'Firsts',
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of times the player went first.',
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
      Constants::STAT_NAME => 'Vertical Openings per First',
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of times the player went first and opened vertically. Vertical openings that were challenged off do not count.',
      Constants::STAT_ITEM_OBJECT_NAME => {Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_PCAVG, 'total' => 0, 'total_firsts' => 0, 'total_verticals' => 0},
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total_verticals'} += $other->{'total_verticals'};
        $this->{'total_firsts'}      += $other->{'total_firsts'};
        if ($this->{'total_firsts'} == 0)
        {
          return;
        }
        $this->{'total'} = sprintf "%.4f", $this->{'total_verticals'} / $this->{'total_firsts'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        $this->{'total_verticals'}   += $game->getNumVerticalOpeningPlays($this_player);
        $this->{'total_firsts'}      += $game->getNumFirsts($this_player);
  if ($this->{'total_firsts'} == 0)
  {
          return;
  }
        $this->{'total'} = sprintf "%.4f", $this->{'total_verticals'} / $this->{'total_firsts'};
      }
    },
    {
      Constants::STAT_NAME => 'Full Rack per Turn',
      Constants::STAT_DESCRIPTION_NAME =>
      'The percentage of fully annotated racks out of all of the players racks for every game.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of exchanges made by the player.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The player\'s highest game.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The player\'s lowest game.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The player\s highest scoring turn.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of bingos played by the player that were not challenged off, shown as a total and broken down by length.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The average probabilities of the bingos played by the player. These are the probabilities as listed in the Zyzzyva word study program, so higher values are less probable.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of tiles played by the player.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The power number of tiles played by the player. This includes J, Q, X, Z, S, and the blank.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of power tiles left on the player\'s rack after the opponent went out.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number turns that the play had a blank on their rack. This statistic is only meaningful for players with a significant portion of the full racks recorded.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of triple triples played by the player. The triple triples do not have to be bingos.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of games where the player does not bingo.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of bonus squares that the player covered.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of phony plays made by the player, both challenged and unchalleged.',
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
      Constants::STAT_NAME => 'Challenges',
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of challenges made by both the player and the opponent, broken down by challenges that the player made against opponent\'s plays and challenges that the opponent made against the player\'s plays.',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
        'total' => 0,
        'subitems' =>
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
        my $this   = shift;
        my $game   = shift;
        my $player = shift;

        my $chal = $game->getNumChallenges($player);

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
      Constants::STAT_NAME => 'Challenge Percentage',
      Constants::STAT_DESCRIPTION_NAME =>
      'The percentage of challenges that the player made against an opponent\'s play which were successful.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The percentage of challenges made by opponents against the player\'s plays that were unsuccessful.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The percentage of plays that formed a phony and were not challenged off by an opponent.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of comments made in the GCG file. This stat counts comments that appear on both the player and the opponent\'s turn.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number words in all the comments of the GCG file of the game. This stat counts comments that appear on the player\'s turn and the opponent\'s turn.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Games in which at least 20 double letter bonus squares were covered.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Games in which at least 15 double word bonus squares were covered.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Games in which every triple letter bonus square was covered.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Games in which every triple word bonus square was covered.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Games in which at least one player scores at least 700 points.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Games in which the combined score is at least 1100 points.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Games in which the combined score is no greater than 200 points. Many games on cross-tables.com end before a combined score of 200 points but are considered incomplete and are not counted. Many valid six pass games are not included because they are malformed.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Games that end in ties.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Games in which one player plays the Z, X, Q, J, every blank, and every S.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Games in which one player plays every E.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'Games in which there are at least 5 challenges made.',
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of turns the player made that are not tagged with a mistake. Dynamic mistakes do not count for this statistic.',
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
      Constants::STAT_NAME => 'Mistakes per Turn',
      Constants::STAT_DESCRIPTION_NAME =>
      'The number of mistakes that the player makes per turn.',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
        Constants::STAT_OBJECT_DISPLAY_NAME => Constants::STAT_OBJECT_DISPLAY_PCAVG,
        'total'          => 0,
        'total_mistakes' => 0,
        'total_turns'    => 0,
      },
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total_mistakes'} += $other->{'total_mistakes'};
        $this->{'total_turns'}    += $other->{'total_turns'};
        if ($this->{'total_turns'} == 0)
        {
          return;
        }
        $this->{'total'} = sprintf "%.4f", $this->{'total_mistakes'} / $this->{'total_turns'};
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this = shift;
        my $game = shift;
        my $this_player = shift;

        my @categories = Constants::MISTAKES;

        my $mistakes_hash_ref = $game->getNumMistakes($this_player);

        foreach my $cat (@categories)
        {
          $this->{'total_mistakes'}            += $mistakes_hash_ref->{$cat};
        }

        $this->{'total_turns'} += $game->getNumTurns($this_player);
        if ($this->{'total_turns'} == 0)
        {
          return;
        }
        $this->{'total'} = sprintf "%.4f", $this->{'total_mistakes'} / $this->{'total_turns'};
      }
    },
    {
      Constants::STAT_NAME => 'Mistakes',
      Constants::STAT_DESCRIPTION_NAME =>
      'yeet',
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
        $this->{'total'} += $other->{'total'};
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
      Constants::STAT_DESCRIPTION_NAME =>
      'The listing of all of the player\'s mistakes.',
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
    },
    {
      Constants::STAT_NAME => 'Dynamic Mistakes',
      Constants::STAT_DESCRIPTION_NAME =>
      'More on this later.',
      Constants::STAT_ITEM_OBJECT_NAME =>
      {
        'total'    => 0,
        'list'     => [],
        'subitems' => {} 
      },
      Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
      Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
      Constants::STAT_COMBINE_FUNCTION_NAME =>
      sub
      {
        my $this  = shift;
        my $other = shift;
        $this->{'total'} += $other->{'total'};
        foreach my $key (keys %{$other->{'subitems'}})
        {
          if (! (defined $this->{'subitems'}->{$key}))
          {
            $this->{'subitems'}->{$key} = 0;
	    push @{$this->{'list'}}, $key;
          }
          $this->{'subitems'}->{$key} += $other->{'subitems'}->{$key};
        }
      },
      Constants::STAT_ADD_FUNCTION_NAME =>
      sub
      {
        my $this   = shift;
        my $game   = shift;
        my $player = shift;
        
        my $dynamic_mistakes_hash_ref = $game->getNumDynamicMistakes($player);

        foreach my $key (keys %{$dynamic_mistakes_hash_ref})
        {
          if (! (defined $this->{'subitems'}->{$key}))
          {
            $this->{'subitems'}->{$key} = 0;
	    push @{$this->{'list'}}, $key;
          }
          my $num = $dynamic_mistakes_hash_ref->{$key};
          $this->{'total'}            += $num;
          $this->{'subitems'}->{$key} += $num;
        }
      }
    },
    {
      Constants::STAT_NAME => 'Dynamic Mistakes List',
      Constants::STAT_DESCRIPTION_NAME =>
      'The listing of the player\'s dynamic mistakes.',
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

        push @{$this->{'list'}}, @{$game->getDynamicMistakes($player)};
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

