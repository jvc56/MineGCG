#!/usr/bin/perl

package Move;

use warnings;
use strict;
use lib '.';
use Constants;
use Data::Dumper;
sub new
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
  my $last_name = shift;
  my $oppo_stuck_rack = shift;
  my @words_made = ();

  my %move = (
  	           number           => $turn_number,
      	       play             => $play,
               words_made       => \@words_made,
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
      	       oppo_stuck_rack  => $oppo_stuck_rack,
      	       comment          => $comment,
               last_name        => $last_name,
               is_phony         => 1,
               prob             => 0
      	     );

  my $self = bless \%move, $this;
  return $self;
}

sub getAlphanumericLocation
{
  my $this = shift;
  my $index_column_mapping_ref = Constants::INDEX_COLUMN_MAPPING;
  my %index_column_mapping = %{$index_column_mapping_ref};
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

sub getNumTilesPlayed
{
  my $this = shift;

  my $this_player = shift;
  my $play = $this->{'play'};
  
  if (
      $this_player != $this->{'turn'} ||
      !$play ||
      $play eq '---' ||
      $this->{'challenge_lost'} ||
      $this->{'play_type'} ne Constants::PLAY_TYPE_WORD
     )
  {
    return 0;
  }
  else
  {
    $play =~ s/\.//g;
    return length $play;
  }
}

sub getLength
{
  my $this = shift;

  my $this_player = shift;
  my $play = $this->{'play'};
  
  if (
      $this_player != $this->{'turn'} ||
      !$play ||
      $play eq '---' ||
      $this->{'challenge_lost'} ||
      $this->{'play_type'} ne Constants::PLAY_TYPE_WORD
     )
  {
    return 0;
  }
  else
  {
    return length $play;
  }
}

sub getNumBlanksPlayed
{
  my $this = shift;

  my $this_player = shift;
  my $play = $this->{'play'};
  
  if ($this_player != $this->{'turn'} ||
      !$play ||
      $play eq '---' ||
      $this->{'challenge_lost'} ||
      $this->{'play_type'} ne Constants::PLAY_TYPE_WORD)
  {
    return 0;
  }
  else
  {
    $play =~ s/\.|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z//g;
    return length $play;
  }	
}

sub getChallengeType
{
  my $this = shift;

  # 0 - Player who went first
  # 1 - Player who went second
  my $player = shift;

  my $your_turn = $this->{'turn'} == $player;
  my $play_is_pass = $this->{'play_type'} eq Constants::PLAY_TYPE_PASS;
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

sub isBingo
{
  my $this = shift;

  my $this_player = shift;

  my $l = $this->getNumTilesPlayed($this_player);

  if ($l == 7)
  {
    return $this->getLength($this_player);
  }
  return 0;
}

sub isFullRack
{
  my $this = shift;

  my $this_player = shift;
  my $play = $this->{'play'};
  
  if ($this_player != $this->{'turn'})
  {
    return 0;
  }
  else
  {
    return $this->{'is_full_rack'};
  }
}

sub isTripleTriple
{
  my $this = shift;

  my $this_player = shift;

  if($this_player != $this->{'turn'} || $this->{'play_type'} ne Constants::PLAY_TYPE_WORD || $this->{'challenge_lost'})
  {
  	return 0;
  }
  my $r = $this->{'row'};
  my $c = $this->{'column'};
  my $v = $this->{'vertical'};
  
  if (!($r == 0 || $r == 7 || $r == 14 || $c == 0 || $c == 7 || $c == 14))
  {
  	return 0;
  }
  my $play = $this->{'play'};
  my $l = length $play;
  if ($v && ($c == 0 || $c == 7 || $c == 14) && $r <= 7)
  {
    $play = ("." x $r) . $play . ("." x (Constants::BOARD_HEIGHT - ($r + $l)));
    $play =~ /(.)......(.)......(.)/;
    return ($1 ne "." && $2 ne ".") || ($2 ne "." && $3 ne ".") || ($1 ne "." && $3 ne ".");
  }
  if (!$v && ($r == 0 || $r == 7 || $r == 14) && $c <= 7)
  {
    $play = ("." x $c) . $play . ("." x (Constants::BOARD_WIDTH - ($c + $l)));
    $play =~ /(.)......(.)......(.)/;
    return ($1 ne "." && $2 ne ".") || ($2 ne "." && $3 ne ".") || ($1 ne "." && $3 ne ".");
  }
  return 0;
}

sub hasBlankOnRack
{
  my $this = shift;

  my $this_player = shift;

  if($this_player != $this->{'turn'})
  {
    return 0;
  }

  return $this->{'rack'} =~ /\?/;
}

sub getCommentLength
{
  my $this = shift;

  my $this_player = shift;

  return length $this->{'comment'};
}

sub getCommentWordLength
{
  my $this = shift;

  my $this_player = shift;

  my $text = $this->{'comment'};

  my $num = 0; 
  $num++ while $text =~ /\S+/g;

  return $num;
}

sub toString
{
  my $this = shift;
  my $readable_move = shift;

  my $printed_play = $this->{'play'};

  my $loc = $this->{'play_type'};
  if ($this->{'play_type'} eq Constants::PLAY_TYPE_WORD)
  {
    $loc = $this->getAlphanumericLocation;
    $printed_play = $readable_move;
  }

  my $ch = '';
  if ($this->{'challenge_lost'})
  {
  	$ch = ' (Lost challenge) ';
  }
  my $return_string = sprintf "%s %s +%d%s", $loc, $printed_play, $this->{'score'}, $ch;
  return $return_string;
}
1;

