#!/usr/bin/perl

package Game;

use warnings;
use strict;
use Data::Dumper;
use List::Util qw(sum);
use lib '.';
use Board;
use Move;
use Tile;

sub new($$)
{
  my $this = shift;

  my $filename = shift;
  my $this_player_name = shift;

  my $player_one_name;
  my $player_two_name;
  my @moves;
  my $turn_number = 1;
  my $player_one_prev_total = 0;
  my $player_two_prev_total = 0;
  my $is_tourney_game = 0;
  my @moves_removed = ();
  open(GAMEHTML, '<', $filename);
  while(<GAMEHTML>)
  {
    #print $_;
    chomp $_;
    # Find who goes first and second
    if (/(.*)<a.*vs.([^<]*)</)
    {
      $player_one_name = $1;
      $player_two_name = $2;
      $player_one_name =~ s/^\s+|\s+$//g;
      $player_two_name =~ s/^\s+|\s+$//g;
      #print "Player 1: $player_one_name\nPlayer 2: $player_two_name\n";
    }
    # Move
    elsif (/Array\( (\d+), '(.*)', (\d+), (\d+), (\d+), (\d+), '(.*)', (\d+), (\d+), (\d+), \['?(.*?)'?\] \)/)
    {
      #printf "%d, %s, %d, %d, %d, %d, %s, %d, %d, %d, %s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11;
      #print "$_\n";
      my $play = $2;
      if (!$play)
      {
        next;
      }
      my $zero_index_row = $3;
      my $zero_index_column = $4;
      my $vertical = $5;
      my $rack = $7;
      my $player_turn = $8;
      my $player_one_total_after_move = $9;
      my $player_two_total_after_move = $10;
      my $play_type = 'word';
      my $challenge_lost = 0;
      my $challenge_points = 0;
      my $out_points = 0;
      my $comment = $11;

      # player_one's turn
      my $score;
      if (!$player_turn)
      {
      	$score = $player_one_total_after_move - $player_one_prev_total;
      }
      else
      {
       	$score = $player_two_total_after_move - $player_two_prev_total;     	
      }

      # Unsuccessful Collins challenge
      if ($play eq '---' && !$rack)
      {
      	# player1's turn
      	#print "A CHALLENGE: $_\n";
      	my $prev_score;
      	if ($player_turn)
      	{
          $moves[-1]{'challenge_points'} = $player_one_total_after_move - $player_one_prev_total;
          #print "Player 1's turn\n";
          #print "Current total: $player_one_total_after_move\n";
          #print "Previous total: $player_one_prev_total\n";
      	}
      	else
      	{
          $moves[-1]{'challenge_points'} = $player_two_total_after_move - $player_two_prev_total;
      	}
        $moves[-1]{'player_one_total'} = $player_one_total_after_move;
        $moves[-1]{'player_two_total'} = $player_two_total_after_move;
        $moves[-1]{'score'} += $moves[-1]{'challenge_points'};
        push @moves_removed, 1;
      	next;
      }
      # Successful Challenge
      if ($play =~ /^-chl-/)
      {
        $moves[-1]{'challenge_lost'} = 1;
        $moves[-1]{'player_one_total'} = $player_one_total_after_move;
        $moves[-1]{'player_two_total'} = $player_two_total_after_move;
        $moves[-1]{'score'} = 0;
        push @moves_removed, 1;
        next;
      }

      my $move = Move->new( $turn_number,
      	                    $play,
      	                    $score,
      	                    $zero_index_row,
      	                    $zero_index_column,
      	                    $vertical,
      	                    $rack,
      	                    $player_turn,
      	                    $player_one_total_after_move,
      	                    $player_two_total_after_move,
      	                    $play_type,
      	                    $challenge_lost,
      	                    $challenge_points,
      	                    $out_points,
      	                    $comment );
      push @moves, $move;
      $turn_number++;
      push @moves_removed, 0;
      $player_one_prev_total = $player_one_total_after_move;
      $player_two_prev_total = $player_two_total_after_move;
    }
    # Detect passes
    elsif (/id="moveselectorlower(\d+)" class="moveselector">Pass/)
    {
      my $index = $1 - 1;
      my $sum = 0;
      for (my $j = 0; $j < $index; $j++)
      {
      	$sum += $moves_removed[$j];
      }
      $index -= $sum;
      $moves[$index]->setMoveType('pass');
      my $com = $moves[$index]->{'comment'};
      # A best guess at what is a pass and what is an unsuccessful challenge
      # They are indistinguishable on cross-tables
      if (!($com =~ /pass/i or (length $moves[$index]->{'rack'}) <= 2) && !($index > 0 && $moves[$index-1]->{'play_type'} ne 'word'))
      {
        $moves[$index]->{'challenge_lost'} = 1;
      }
    }
    # Detect exchanges
    elsif (/id=.moveselectorlower(\d+). class=.moveselector.>Exchange (\w+)/)
    {
      my $index = $1 - 1;
      my $sum = 0;
      for (my $j = 0; $j < $index; $j++)
      {
        $sum += $moves_removed[$j];
      }
      $index -= $sum;
      $moves[$index]->setMoveType('exch');
      $moves[$index]->setMovePlay($2);
      #print "Move $1 was exchange $2\n";
    }
    if (/tourney.php/)
    {
      $is_tourney_game = 1;
    }
  }
  if ($moves[-1]->{'play_type'} ne 'pass')
  {
    $moves[-1]->{'out_points'} = $moves[-1]->{'challenge_points'};
    $moves[-1]->{'challenge_points'} = 0;
  }

  my $board = Board->new();
  $board->addMoves(\@moves);

  if (
        scalar @moves >= 6 &&
        $moves[-1]->{'score'} == 0 &&
        $moves[-2]->{'score'} == 0 &&
        $moves[-3]->{'score'} == 0 &&
        $moves[-4]->{'score'} == 0 &&
        $moves[-5]->{'score'} == 0 &&
        $moves[-6]->{'score'} == 0
     )
  {
    my $last_rack_value = sum( (map {Tile->charToValue($_)} (split //, $moves[-1]->{'rack'})) );
    my $penult_rack_value = sum( map {Tile->charToValue($_)} (split //, $moves[-2]->{'rack'}) );
    if (!$moves[-1]->{'turn'})
    {
      $board->{'player_one_total'} -= $last_rack_value;
      $board->{'player_two_total'} -= $penult_rack_value;
    }
    else
    {
      $board->{'player_one_total'} -= $penult_rack_value;
      $board->{'player_two_total'} -= $last_rack_value;
    }
  } 
  
  my $play_num = 0;
  if ($this_player_name eq $player_two_name)
  {
  	$play_num = 1;
  }
  my %game = 
  (
    tourney_game    => $is_tourney_game,
  	this_player     => $play_num,
  	player_one_name => $player_one_name,
  	player_two_name => $player_two_name,
    board => $board,
    moves => \@moves
  );

  my $self = bless \%game, $this;
  return $self;
}

sub getNumTurns()
{
	my $this = shift;

	return scalar @{$this->{'moves'}};
}

sub getNumWins($)
{
  my $this = shift;

  my $player = shift;

  my $board = $this->{'board'};
  my $p1s = $board->{'player_one_total'};
  my $p2s = $board->{'player_two_total'};
  if ($p1s == $p2s)
  {
   return 0.5;
  }
  if ($p1s > $p2s)
  {
    if (!$player)
    {
      return 1;
    }
    return 0;
  }
  if ($p1s < $p2s)
  {
  	if (!$player)
  	{
  	  return 0;
  	}
    return 1;
  }
  return 0.1;
}

sub getScore($)
{
  my $this = shift;

  my $player = shift;
  my $board = $this->{'board'};
  my $p1s = $board->{'player_one_total'};
  my $p2s = $board->{'player_two_total'};
  if (!$player)
  {
    return $p1s;
  }
  return $p2s;
}

sub getNumBingosPlayed($)
{
  my $this = shift;

  my $player = shift;

  my @moves = @{$this->{'moves'}};
  my $sum = 0;
  foreach my $move (@moves)
  {
  	$sum += $move->getNumBingosPlayed($player);
  }
  return $sum;
}

sub getNumTilesPlayed($)
{
  my $this = shift;

  my $player = shift;

  my @moves = @{$this->{'moves'}};
  my $sum = 0;
  foreach my $move (@moves)
  {
  	$sum += $move->getNumTilesPlayed($player);
  }
  return $sum;
}

sub getNumBlanksPlayed($)
{
  my $this = shift;

  my $player = shift;
  my @moves = @{$this->{'moves'}};
  my $sum = 0;
  foreach my $move (@moves)
  {
  	$sum += $move->getNumBlanksPlayed($player);
  }
  return $sum;
}

sub getNumTripleTriplesPlayed($)
{
  my $this = shift;

  my $player =shift;
  my @moves = @{$this->{'moves'}};
  my $sum = 0;
  foreach my $move (@moves)
  {
    if ($move->isTripleTriple($player))
    {
      $sum++;
    }
  }
  return $sum;
}

sub getNumBonusSquaresCovered($)
{
  my $this = shift;
  
  my $player = shift;
  my $board = $this->{'board'};

  return $board->getNumBonusSquaresCovered($player);
}

sub getNumChallenges($)
{
  my $this = shift;
  
  my $player = shift;

  my @moves = @{$this->{'moves'}};
  my %sums = (
               Constants::PLAYER_CHALLENGE_LOST => 0,
               Constants::PLAYER_CHALLENGE_WON  => 0,
               Constants::OPP_CHALLENGE_LOST    => 0,
               Constants::OPP_CHALLENGE_WON     => 0,
               Constants::NO_CHALLENGE          => 0
             );
  foreach my $move (@moves)
  {
    $sums{$move->getChallengeType($player)}++;
  }
  return \%sums;
}

sub toString()
{
  my $this = shift;

  my $s;
  my $p1 = $this->{'player_one_name'};
  my $p2 = $this->{'player_two_name'};
  $s .= "$p1 vs. $p2\n\n";
  $s .= "Moves:\n";
  my $l = scalar @{$this->{'moves'}};
  for (my $i = 0; $i < $l; $i++)
  {
  	$s .= $this->{'moves'}[$i]->toString();
  }
  $s .= "\nBoard: \n";
  $s .=  $this->{'board'}->toString();
  $s .= "\n";
  return $s;
}
1;

