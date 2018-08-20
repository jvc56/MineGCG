#!/usr/bin/perl

package Board;

use warnings;
use strict;
use lib '.';
use Square;
use Tile;
use Constants;

sub new()
{
  my $this = shift;

  my @grid;
  for (my $i = 0; $i < Constants::BOARD_WIDTH*Constants::BOARD_HEIGHT; $i++)
  {
      push @grid, Square->new($i);
  }

  my %board = 
  (
    moves_completed  => 0,
    player_one_total => 0,
    player_two_total => 0,
    grid             => \@grid
  );
  my $self = bless \%board, $this;
  return $self;
}

sub placeNewTile($$$$$$)
{
  my $this = shift;

  my $c = shift;
  my $row = shift;
  my $column = shift;
  my $displacement = shift;
  my $vertical = shift;
  my $turn = shift;

  my $pos = $row*Constants::BOARD_WIDTH + $column;

  if ($vertical)
  {
    $pos += $displacement * Constants::BOARD_WIDTH;
  }
  else
  {
    $pos += $displacement;
  }

  my $tile = Tile->new($c, $turn);

  $this->{'grid'}[$pos]->addTile($tile);
}
sub addMoves($)
{
  my $this = shift;

  my $move_array_ref = shift;
  my @moves = @{$move_array_ref};
  if ($this->{'moves_completed'} + 1 != $moves[0]->{'number'})
  {
    print "Could not add moves: move number incorrect. Doing nothing.";
    return;
  }
  for (my $i = 0; $i < scalar @moves; $i++)
  {
    my $move = $moves[$i];
    if ($move->{'play_type'} eq 'word' && !$move->{'challenge_lost'})
    {
      my $word         = $move->{'play'};
      my $row          = $move->{'row'};
      my $column       = $move->{'column'};
      my $vertical     = $move->{'vertical'};
      my $turn         = $move->{'turn'};
      my $displacement = 0;

      foreach my $c (split //, $word)
      {
        if ($c ne '.')
        {
          $this->placeNewTile($c, $row, $column, $displacement, $vertical, $turn);
        }
        $displacement++;
      }
    }
    $this->{'moves_completed'}++;
    $this->{'player_one_total'} = $move->{'player_one_total'};
    $this->{'player_two_total'} = $move->{'player_two_total'};
  }
}

sub getNumBonusSquaresCovered($$)
{
  my $this = shift;

  my $player = shift;
  my $square_type = shift;

  my @grid = @{$this->{'grid'}};
  my %sums = (
               ' ' => 0,
               Constants::DOUBLE_LETTER => 0,
               Constants::TRIPLE_LETTER => 0,
               Constants::DOUBLE_WORD   => 0,
               Constants::TRIPLE_WORD   => 0
             );
  foreach my $square (@grid)
  {
    my $tile = $square->{'tile'};
    if ($tile && $tile->{'placed_by'} == $player)
    {
      $sums{$square->{'bonus'}}++;
    }
  }
  return \%sums;
}
sub toString()
{
  my $this = shift;
  my $s = "   A B C D E F G H I J K L M N O";
  $s   .= "\n  -------------------------------";
  
  for (my $i = 0; $i < Constants::BOARD_HEIGHT; $i++)
  {
    my $t = "\n" . (sprintf "%2s", $i) . '|';
    for (my $k = 0; $k < Constants::BOARD_WIDTH; $k++)
    {
      my $index = $i*Constants::BOARD_WIDTH + $k;
      my $maybe_space = ' ';
      if ($k == Constants::BOARD_WIDTH - 1)
      {
        $maybe_space = '';
      }
      $t .= $this->{'grid'}[$index]->toString() . $maybe_space;
    }
    $s .= $t . "|";
  }
  $s .= "\n  -------------------------------\n";
  my $first_score = $this->{'player_one_total'};
  my $second_score = $this->{'player_two_total'};
  $s .= "Score: $first_score - $second_score\n";
  return $s;
}
1;

