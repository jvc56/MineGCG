#!/usr/bin/perl

package Board;

use warnings;
use strict;
use Data::Dumper;
use lib '.';
use Square;
use Tile;
use Constants;

sub new
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

sub __placeNewTile
{
  my $this = shift;

  my $c = shift;
  my $pos = shift;
  my $turn = shift;
  my $play_number = shift;

  my $tile = Tile->new($c, $turn, $play_number);

  $this->{'grid'}[$pos]->addTile($tile);
}
sub addMoves
{
  my $this = shift;
  my $move_array_ref = shift;

  my @moves = @{$move_array_ref};

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
      my $play_number  = $move->{'number'};
      my $displacement = 0;

      my $dotted_word = "";

      my @added_positions = ();

      my $play_is_connected = 0;

      foreach my $c (split //, $word)
      {
        my $pos = $row*Constants::BOARD_WIDTH + $column;
        if ($vertical)
        {
          $pos += $displacement * Constants::BOARD_WIDTH;
        }
        else
        {
          $pos += $displacement;
        }
        if ($c ne '.' && !$this->{'grid'}[$pos]->{'has_tile'})
        {
          $this->__placeNewTile($c, $pos, $turn, $play_number);
          push @added_positions, $pos;
          $dotted_word .= $c;
          if ($pos == 112)
          {
            $play_is_connected = 1;
          }
        }
        else
        {
          $dotted_word .= ".";
          $play_is_connected = 1;
        }
        $displacement++;
      }

      if (!$play_is_connected)
      {
        my @adjacent_positions = ();
        foreach my $added_pos (@added_positions)
        {
          my @four_adjacent = ();
          push @four_adjacent, $added_pos - 1;
          push @four_adjacent, $added_pos + 1;
          push @four_adjacent, $added_pos - Constants::BOARD_WIDTH;
          push @four_adjacent, $added_pos + Constants::BOARD_WIDTH;
          foreach my $fa (@four_adjacent)
          {
            my $is_valid = 1;
            if ($fa < 0 || $fa > Constants::BOARD_WIDTH*Constants::BOARD_HEIGHT - 1)
            {
              $is_valid = 0;
            }
            foreach my $added_pos (@added_positions)
            {
              if ($fa == $added_pos) {$is_valid = 0;}
            }
            if ($is_valid)
            {
              push @adjacent_positions, $fa;
            }
          }
        }

        foreach my $ap (@adjacent_positions)
        {

          if ($this->{'grid'}[$ap]->{'has_tile'})
          {
            $play_is_connected = 1;
            last;
          }
        }
      }

      if (!$play_is_connected)
      {
        return "disconnected play detected";
      }

      $move->{'play'} = $dotted_word;

    }
    $this->{'moves_completed'}++;
  }
  $this->{'player_one_total'} = $moves[-1]->{'player_one_total'};
  $this->{'player_two_total'} = $moves[-1]->{'player_two_total'};
  return "";
}

sub getNumBonusSquaresCovered
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
sub toString
{
  my $this = shift;
  my $s = "   A B C D E F G H I J K L M N O";
  $s   .= "\n  -------------------------------";
  
  for (my $i = 0; $i < Constants::BOARD_HEIGHT; $i++)
  {
    my $t = "\n" . (sprintf "%2s", ($i+1)) . '|';
    for (my $k = 0; $k < Constants::BOARD_WIDTH; $k++)
    {
      my $index = $i*Constants::BOARD_WIDTH + $k;
      my $maybe_space = ' ';
      if ($k == Constants::BOARD_WIDTH - 1)
      {
        $maybe_space = '';
      }
      $t .= $this->{'grid'}[$index]->toString . $maybe_space;
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

