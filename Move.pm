#!/usr/bin/perl

package Move;

use warnings;
use strict;
use lib '.';
use Constants;

sub new($$$$$$$$$$$$$$$)
{
  my $this = shift;

  my $turn_number = shift;
  my $play = shift;
  my $score = shift;
  my $zero_index_row = shift;
  my $zero_index_column = shift;
  my $vertical = shift;
  my $rack = shift;
  my $player_turn = shift;
  my $player1_total_after_move = shift;
  my $player2_total_after_move = shift;
  my $play_type = shift;
  my $challenge_lost = shift;
  my $challenge_points = shift;
  my $out_points = shift;
  my $comment = shift;

  my %move = (
  	           number           => $turn_number,
      	       play             => $play,
      	       score            => $score,
      	       row              => $zero_index_row,
      	       column           => $zero_index_column,
      	       rack             => $rack,
      	       vertical         => $vertical,
      	       turn             => $player_turn,
      	       player_one_total => $player1_total_after_move,
      	       player_two_total => $player2_total_after_move,
      	       play_type        => $play_type,
      	       challenge_lost   => $challenge_lost,
      	       challenge_points => $challenge_points,
      	       out_points       => $out_points,
      	       comment          => $comment
      	     );

  my $self = bless \%move, $this;
  return $self;
}
sub setMoveType($)
{
  my $this = shift;

  my $type = shift;
  $this->{'play_type'} = $type;
}

sub setMovePlay($)
{
  my $this = shift;

  my $play = shift;
  $this->{'play'} = $play;
}
sub getAlphanumericLocation()
{
  my $this = shift;
  my %index_column_mapping = ( 0 => 'A',
                               1 => 'B',
                               2 => 'C',
                               3 => 'D',
                               4 => 'E',
                               5 => 'F',
                               6 => 'G',
                               7 => 'H',
                               8 => 'I',
                               9 => 'J',
                               10 => 'K',
                               11 => 'L',
                               12 => 'M',
                               13 => 'N',
                               14 => 'O' );

  my $row = $this->{'row'} + 1;
  my $column = $index_column_mapping{$this->{'column'}};
  if ($this->{'vertical'})
  {
    return $column . $row;
  }
  else
  {
  	return $row . $column;
  }
}

sub getNumBingosPlayed($)
{
  my $this = shift;

  my $this_player = shift;

  return $this->getNumTilesPlayed($this_player) == 7; 
}

sub getNumTilesPlayed($)
{
  my $this = shift;

  my $this_player = shift;
  my $play = $this->{'play'};
  
  if ($this_player != $this->{'turn'} or !$play or $play eq '---' or $this->{'challenge_lost'} or $this->{'play_type'} ne 'word')
  {
    return 0;
  }
  else
  {
    $play =~ s/\.//g;
    return length $play;
  }
}

sub getNumBlanksPlayed($)
{
  my $this = shift;

  my $this_player = shift;
  my $play = $this->{'play'};
  
  if ($this_player != $this->{'turn'} or !$play or $play eq '---' or $this->{'challenge_lost'} or $this->{'play_type'} ne 'word')
  {
    return 0;
  }
  else
  {
    $play =~ s/\.|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z//g;
    return length $play;
  }	
}

sub getChallengeType($)
{
  my $this = shift;

  # 0 - Player who went first
  # 1 - Player who went second
  my $player = shift;

  my $your_turn = $this->{'turn'} == $player;
  my $play_is_pass = $this->{'play_type'} eq 'pass';
  if ($this->{'challenge_lost'})
  {
    if ($your_turn) 
    {
      if ($play_is_pass)
      {
        return Constants::PLAYER_CHALLENGE_LOST;
      }
      return Constants::OPP_CHALLENGE_WON;
    }
    if ($play_is_pass)
    {
      return Constants::OPP_CHALLENGE_LOST;
    }
    return Constants::PLAYER_CHALLENGE_WON;
  }
  if ($this->{'challenge_points'})
  {
  	if ($your_turn)
  	{
  	  return Constants::OPP_CHALLENGE_LOST;
  	}
  	return Constants::PLAYER_CHALLENGE_LOST;
  }
  return Constants::NO_CHALLENGE;


}
sub isTripleTriple($)
{
  my $this = shift;

  my $this_player = shift;

  if($this_player != $this->{'turn'})
  {
  	return 0;
  }
  my $r = $this->{'row'};
  my $c = $this->{'column'};
  my $v = $this->{'vertical'};
  
  if (!($r == 0 || $r == 14 || $c == 0 || $c == 14))
  {
  	return 0;
  }
  my $play = $this->{'play'};
  my $l = length $play;
  if ($v && ($c == 0 || $c == 14) && $r <= 7)
  {
    $play = ("." x $r) . $play . ("." x (Constants::BOARD_HEIGHT - ($r + $l)));
    $play =~ /(.)......(.)......(.)/;
    return ($1 ne "." && $2 ne ".") || ($2 ne "." && $3 ne ".");
  }
  if (!$v && ($r == 0 || $r == 14) && $c <= 7)
  {
    $play = ("." x $c) . $play . ("." x (Constants::BOARD_WIDTH - ($c + $l)));
    $play =~ /(.)......(.)......(.)/;
    return ($1 ne "." && $2 ne ".") || ($2 ne "." && $3 ne ".");
  }
  return 0;
}
sub toString()
{
  my $this = shift;

  my $loc = $this->getAlphanumericLocation();
  if ($this->{'play_type'} ne 'word')
  {
  	$loc = $this->{'play_type'};
  } 
  my $ch = '';
  if ($this->{'challenge_lost'})
  {
  	$ch = ' (Lost challenge) ';
  }
  return sprintf "%d: %s %s +%d%s\n", $this->{'number'}, $loc, $this->{'play'}, $this->{'score'}, $ch;
}
1;

