#!/usr/bin/perl

package Stats;

use warnings;
use strict;
use Data::Dumper;
use lib '.';
use Constants;
use StatsItem;

sub new
{
  my $this = shift;

  my @entries = ();

  my @items = Constants::STATS_ITEMS;

  for (my $i = 0; $i < scalar @items; $i++)
  {
    push @entries, StatsItem->new($items[$i]->{'name'}, $items[$i]->{'type'});
  }

  my %stats =
  (
    entries   => \@entries,
    num_games => 0
  );
  my $self = bless \%stats, $this;
  return $self;
}

sub addGame
{
  my $this = shift;

  my $game = shift;

  $this->{'num_games'}++;

  foreach my $stat_item (@{$this->{'entries'}})
  {
    $stat_item->addGame($game);
  }
}

sub resetStats
{
  my $this = shift;

  $this->{"num_games"} = 0;
  foreach my $stat_item (@{$this->{'entries'}})
  {
    $stat_item->resetItem;
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

sub toString
{
  my $this = shift;
  my $html = shift;

  my $tiw        = Constants::TITLE_WIDTH;
  my $aw         = Constants::AVERAGE_WIDTH;
  my $tow        = Constants::TOTAL_WIDTH;
  my $tot        = $tiw + $aw + $tow;
  my $num        = $this->{'num_games'};

  my $s = "\n";
  $s .= "\n".Constants::STAT_ITEM_LIST_PLAYER . "\n";
  for (my $i = 0; $i < scalar @{$this->{'entries'}}; $i++)
  {
    my $stat_item = ${$this->{'entries'}}[$i];
    if ($stat_item->{'type'} eq Constants::STAT_ITEM_LIST_PLAYER)
    {
      $s .= $stat_item->toString($num);
    }
  }

  $s .= "\n".Constants::STAT_ITEM_LIST_OPP . "\n";
  for (my $i = 0; $i < scalar @{$this->{'entries'}}; $i++)
  {
    my $stat_item = ${$this->{'entries'}}[$i];
    if ($stat_item->{'type'} eq Constants::STAT_ITEM_LIST_OPP)
    {
      $s .= $stat_item->toString($num);
    }
  }

  $s .= "\n".Constants::STAT_ITEM_LIST_NOTABLE . "\n";
  for (my $i = 0; $i < scalar @{$this->{'entries'}}; $i++)
  {
    my $stat_item = ${$this->{'entries'}}[$i];
    if ($stat_item->{'type'} eq Constants::STAT_ITEM_LIST_NOTABLE)
    {
      $s .= $stat_item->toString($num);
    }
  }

  my $title_divider = ("_" x ($tot+2)) . "\n";
  my $empty_line = "|" . (" " x $tot) . "|\n";

  $s .= "\nResults for $num game(s)\n";
  $s .= $title_divider;
  $s .= makeTitleRow($tiw, $aw, $tow, "", "AVERAGE", "TOTAL");

  $s .= makeTitleRow($tiw, $aw, $tow, Constants::STAT_ITEM_GAME, "", "");
  for (my $i = 0; $i < scalar @{$this->{'entries'}}; $i++)
  {
    my $stat_item = ${$this->{'entries'}}[$i];
    if ($stat_item->{'type'} eq Constants::STAT_ITEM_GAME)
    {
      $s .= $stat_item->toString($num);
    }
  }

  $s .= makeTitleRow($tiw, $aw, $tow, "", "", "");

  $s .= makeTitleRow($tiw, $aw, $tow, Constants::STAT_ITEM_PLAYER, "", "");
  for (my $i = 0; $i < scalar @{$this->{'entries'}}; $i++)
  {
    my $stat_item = ${$this->{'entries'}}[$i];
    if ($stat_item->{'type'} eq Constants::STAT_ITEM_PLAYER)
    {
      $s .= $stat_item->toString($num);
    }
  }

  $s .= makeTitleRow($tiw, $aw, $tow, "", "", "");

  $s .= makeTitleRow($tiw, $aw, $tow, Constants::STAT_ITEM_OPP, "", "");
  for (my $i = 0; $i < scalar @{$this->{'entries'}}; $i++)
  {
    my $stat_item = ${$this->{'entries'}}[$i];
    if ($stat_item->{'type'} eq Constants::STAT_ITEM_OPP)
    {
      $s .= $stat_item->toString($num);
    }
  }
  $s .= ("_" x ($tot+2)) . "\n\n";

  if ($html)
  {
    $s .= "<div id='" . Constants::MISTAKES_DIV_ID . "' style='display: none;'>";
  }

  $s .= "\n".Constants::MISTAKE_ITEM_LIST_PLAYER . "\n";
  for (my $i = 0; $i < scalar @{$this->{'entries'}}; $i++)
  {
    my $stat_item = ${$this->{'entries'}}[$i];
    if ($stat_item->{'type'} eq Constants::MISTAKE_ITEM_LIST_PLAYER)
    {
      $s .= $stat_item->toString($num);
    }
  }

  $s .= "\n\n\n".Constants::MISTAKE_ITEM_LIST_OPP . "\n";
  for (my $i = 0; $i < scalar @{$this->{'entries'}}; $i++)
  {
    my $stat_item = ${$this->{'entries'}}[$i];
    if ($stat_item->{'type'} eq Constants::MISTAKE_ITEM_LIST_OPP)
    {
      $s .= $stat_item->toString($num);
    }
  }

  if ($html)
  {
      $s .=  "</div>\n\n";
      $s .=  "<button onclick='toggle(\"" . Constants::MISTAKES_DIV_ID . "\")'>Toggle Mistakes List</button>\n";
  }

  return $s; 
}

1;

