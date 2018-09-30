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
use CSW15;
use American;

sub new($$)
{
  my $this = shift;

  my $filename         = shift;
  my $this_player_name = shift;
  my $lexicon          = shift;

  my $player_one_name;
  my $player_two_name;
  my @moves;
  my $turn_number = 1;
  my $player_one_prev_total = 0;
  my $player_two_prev_total = 0;
  my $is_tourney_game = 0;
  my $lexicon_ref = '';
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
      my $play_type = Constants::PLAY_TYPE_WORD;
      my $challenge_lost = 0;
      my $challenge_points = 0;
      my $out_points = 0;
      my $comment = $11;
      my $last_name = '';


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
      	                    $comment,
                            $last_name );
      push @moves, $move;
      $turn_number++;
      push @moves_removed, 0;
      $player_one_prev_total = $player_one_total_after_move;
      $player_two_prev_total = $player_two_total_after_move;
    }
    # Detect passes and unsuccessful TWL Challenges
    elsif (/id=.moveselectorlower(\d+). class=.moveselector.>Pass/)
    {
      my $index = $1 - 1;
      my $sum = 0;
      for (my $j = 0; $j < $index; $j++)
      {
      	$sum += $moves_removed[$j];
      }
      $index -= $sum;
      $moves[$index]->setMoveType(Constants::PLAY_TYPE_PASS);
      my $com = $moves[$index]->{'comment'};
      # A best guess at what is a pass and what is an unsuccessful challenge
      # They are indistinguishable on cross-tables
      if (!($com =~ /pass/i ||
         (length $moves[$index]->{'rack'}) <= 2) && !($index > 0 && $moves[$index-1]->{'play_type'} ne Constants::PLAY_TYPE_WORD))
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
    }
    if (/tourney.php/)
    {
      $is_tourney_game = 1;
    }
  }
  if ($moves[-1]->{'play_type'} ne Constants::PLAY_TYPE_PASS)
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
  
  foreach my $move (@moves)
  {
    # Set names
    my $this_move_player_name = $player_one_name;
    if ($move->{'turn'})
    {
      $this_move_player_name = $player_two_name;
    }
    $this_move_player_name =~ /([^\s]*)$/;
  }


  my $play_num = 0;
  if ($this_player_name eq $player_two_name)
  {
  	$play_num = 1;
  }
  if (!$lexicon)
  {
    print "\nNo lexicon found for game $filename, using CSW15 as a default\n";
    $lexicon = 'CSW15';
  }
  
  if ($lexicon eq 'TWL15')
  {
    $lexicon_ref = American::AMERICAN_LEXICON;
  }
  else
  {
    $lexicon_ref = CSW15::CSW15_LEXICON;
  }

  my %game = 
  (
    lexicon         => $lexicon_ref,
    tourney_game    => $is_tourney_game,
  	this_player     => $play_num,
  	player_one_name => $player_one_name,
  	player_two_name => $player_two_name,
    board => $board,
    moves => \@moves
  );

  my $self = bless \%game, $this;

  $self->postConstruction();
  
  return $self;
}

sub getNumTurns()
{
	my $this = shift;

  my $player = shift;

  my @moves = @{$this->{'moves'}};

  my $sum = 0;
  foreach my $move (@moves)
  {
    my $turn = $move->{'turn'};
    if (
        (($player != -1 && $turn == $player) || $player == -1) &&
        !($move->{'challenge_lost'})
       )
    {
      $sum++;
    }
  }
  return $sum;
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

sub getBingos($)
{
  my $this = shift;

  my $player = shift;

  my @moves = @{$this->{'moves'}};

  my @bingos = ();

  foreach my $move (@moves)
  {
    my $bingo = $move->isBingo($player);
    if ($bingo)
    {
      my $bing_cap = $this->readableMoveCapitalized($move);
      my $prob = $this->{'lexicon'}->{$bing_cap};
      if (!$prob)
      {
        $prob = "* 0";
      }
      else
      {
        $prob = " " . $prob;
      }
      push @bingos, $this->readableMove($move) . $prob;
    }
  }
  return \@bingos;
}

sub getPhoniesFormed($)
{
  my $this = shift;

  my $player = shift;

  my @moves = @{$this->{'moves'}};

  my @phonies = ();

  foreach my $move (@moves)
  {
    my $play = $move->{'play'};
    if (
        $player != $move->{'turn'} ||
        !$play ||
        $play eq '---' ||
        $move->{'play_type'} ne Constants::PLAY_TYPE_WORD
       )
    {
      next;
    }
    my $readable_play = $this->readableMove($move);
    my $caps_play = $this->readableMoveCapitalized($move);
    my $prob = $this->{'lexicon'}->{$caps_play};
    if (!$prob)
    {
      push @phonies, $readable_play."*";
    }
    if (!$move->{'words_made'})
    {
      next;
    }
    my @words_made = @{$move->{'words_made'}};
    foreach my $word (@words_made)
    {
      my $word_made_prob = $this->{'lexicon'}->{$word};
      if (!$prob)
      {
        push @phonies, $word."*";
      }
    }
  }
  return \@phonies;
}

sub getPlaysChallenged($)
{
  my $this = shift;

  my $player = shift;

  my @moves = @{$this->{'moves'}};

  my @plays_chal = ();

  for (my $i = 0; $i < scalar @moves; $i++)
  {
    my $move = $moves[$i];
    if ($player != $move->{'turn'})
    {
      next;
    }
    if (
        $move->getChallengeType($player) eq Constants::NO_CHALLENGE &&
        !($move->{'challenge_lost'} && $move->{'play_type'} eq Constants::PLAY_TYPE_PASS)
       )
    {
      next;
    }
    if ($move->{'challenge_lost'} && $move->{'play_type'} eq Constants::PLAY_TYPE_PASS)
    {
      $move = $moves[$i-1];
    }

    my $readable_play = $this->readableMove($move);
    my $caps_play = $this->readableMoveCapitalized($move);
    my $prob = $this->{'lexicon'}->{$caps_play};
    if (!$prob)
    {
      $readable_play = $readable_play."*";
    }
    push @plays_chal, $readable_play;
  }
  return \@plays_chal;
}

sub getNumWordsPlayed($$$)
{
  my $this = shift;

  my $player      = shift;
  my $bingos_only = shift;
  my $valid_only  = shift;
  my @moves = @{$this->{'moves'}};
  my @sums = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  foreach my $move (@moves)
  {
  	my $bingo = $move->isBingo($player);
    my $bingo_cap = $this->readableMoveCapitalized($move);
    my $l = $move->getLength($player);
    if (
        (($bingos_only && $bingo) || !$bingos_only) &&
        (!$valid_only || $this->{'lexicon'}->{$bingo_cap})
       )
    {
      $sums[$l-1]++;
    }
  }
  return \@sums;
}

sub getNumTilesPlayed($$)
{
  my $this = shift;

  my $player = shift;
  my $tile   = shift;

  my @moves = @{$this->{'moves'}};
  my $sum = 0;
  foreach my $move (@moves)
  {
    my $inc = $move->getNumTilesPlayed($player);
    if ($inc && $tile)
    {
      my $play = $move->{'play'};
      $play =~ s/[^$tile]//g;
      $inc  = length $play;
    }
  	$sum += $inc
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

sub getNumPhonies($)
{
  my $this = shift;
  
  my $player = shift;

  my @moves = @{$this->{'moves'}};
  my $sum = 0;
  foreach my $move (@moves)
  {
    if ($move->{'turn'} == $player)
    {
      $sum += $move->{'is_phony'};
    }
  }
  return $sum;
}

sub getNumPhoniesUnchallenged($)
{
  my $this = shift;
  
  my $player = shift;

  my @moves = @{$this->{'moves'}};
  my $sum = 0;
  foreach my $move (@moves)
  {
    if (!$move->{'challenge_lost'} && $move->{'turn'} == $player)
    {
      $sum += $move->{'is_phony'};
    }
  }
  return $sum;
}

sub getWordsProbability($$)
{
  my $this = shift;
  
  my $player = shift;
  my $bingos_only = shift;

  my @moves = @{$this->{'moves'}};
  my @prob_sums = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  foreach my $move (@moves)
  {
    my $l = $move->getLength($player);
    my $bo = 1;
    if ($bingos_only)
    {
      $bo = $move->isBingo($player);
    }
    if ($l && $bo)
    {
      $prob_sums[$l-1] += $move->{'prob'};
    }
  }
  return \@prob_sums;
}


sub isBingoless()
{
  my $this = shift;
  
  my $player = shift;
  # Add 0 at the end to include phonies
  return sum(@{$this->getNumWordsPlayed($player, 1, 0)}) == 0;
}

sub readableMove($)
{
  my $this = shift;

  my $move = shift;
  my $play = $move->{'play'};
  my @play_array = split //, $play;
  my $last_was_play_through = 0;

  for (my $i = 0; $i < scalar @play_array; $i++)
  {
    if ($play_array[$i] eq ".")
    {
      my $new_paren = '(';
      if ($last_was_play_through)
      {
        $new_paren = '';
      }
      my $last_paren = '';
      if ($i == (scalar @play_array) - 1)
      {
        $last_paren = ')';
      }
      $last_was_play_through = 1;
      my $r = $move->{'row'};
      my $c = $move->{'column'};
      my $v = $move->{'vertical'};
      my $pos = $r*Constants::BOARD_WIDTH + $c;
      if (!$v)
      {
        $pos += $i;
      }
      else
      {
        $pos += $i*Constants::BOARD_WIDTH;
      }
      my $square = $this->{'board'}->{'grid'}[$pos];
      $play_array[$i] = $new_paren.$square->toString().$last_paren;
    }
    else
    {
      my $new_paren = '';
      if ($last_was_play_through)
      {
        $new_paren = ')';
      }
      $last_was_play_through = 0;
      $play_array[$i] = $new_paren.$play_array[$i];
    }
  }
  return join "", @play_array;
}

sub readableMoveCapitalized($)
{
  my $this = shift;
  my $move = shift;
  my $play = $move->{'play'};
  my @play_array = split //, $play;

  for (my $i = 0; $i < scalar @play_array; $i++)
  {
    if ($play_array[$i] eq ".")
    {
      my $r = $move->{'row'};
      my $c = $move->{'column'};
      my $v = $move->{'vertical'};
      my $pos = $r*Constants::BOARD_WIDTH + $c;
      if (!$v)
      {
        $pos += $i;
      }
      else
      {
        $pos += $i*Constants::BOARD_WIDTH;
      }
      my $square = $this->{'board'}->{'grid'}[$pos];
      $play_array[$i] = $square->toString();
    }
    $play_array[$i] = uc $play_array[$i];
  }
  return join "", @play_array;
}

sub postConstruction()
{
  my $this = shift;
  my @moves = @{$this->{'moves'}};

  # Determine phoniness and probabilities
  foreach my $move (@moves)
  {
    # Set is_phony and probability
    if ($move->{'play_type'} ne Constants::PLAY_TYPE_WORD)
    {
      $move->{'is_phony'} = 0;
      next;
    }
    my $caps_move = $this->readableMoveCapitalized($move);
    my $prob = $this->{'lexicon'}->{$caps_move};
    if ($prob)
    {
      $move->{'is_phony'} = 0;
      $move->{'prob'} = $prob;
    }
    else
    {
      next;
    }
    my $play = $move->{'play'};
    my $v = $move->{'vertical'};
    my $r = $move->{'row'};
    my $c = $move->{'column'};
    my $play_number = $move->{'number'};

    my @play_array = split //, $play;
    my @words_made = ();
    for (my $i = 0; $i < scalar @play_array; $i++)
    {
      my $char = $play_array[$i];
      if ($char eq ".")
      {
        next;
      }
      my $pos = $r*Constants::BOARD_WIDTH + $c;
      my $inc;
      my $original_row = -1;
      if (!$v)
      {
        $pos += $i;
        $inc = Constants::BOARD_WIDTH;
      }
      else
      {
        $pos += $i*Constants::BOARD_WIDTH;
        $inc = 1;
        $original_row = $r + $i;
      }
      my @formed_word = ($char);
      my $bi = $pos - $inc;
      my $fi = $pos + $inc;
      while (
             $bi >= 0 &&
             $bi <= 224 &&
             (!$v || (int ($bi/Constants::BOARD_WIDTH)) == $original_row )
            )
      {
        my $square = $this->{'board'}->{'grid'}[$bi];
        if (!$square->{'has_tile'})
        {
          last;
        }
        my $tile = $square->{'tile'};
        if ($tile->{'play_number'} > $play_number)
        {
          last;
        }
        my $new_char = $tile->{'char'};
        unshift @formed_word, $new_char;
        $bi -= $inc;
      }
      while (
             $fi >= 0 &&
             $fi <= 224 &&
             (!$v || (int ($fi/Constants::BOARD_WIDTH)) == $original_row )
            )
      {
        my $square = $this->{'board'}->{'grid'}[$fi];
        if (!$square->{'has_tile'})
        {
          last;
        }
        my $tile = $square->{'tile'};
        if ($tile->{'play_number'} > $play_number)
        {
          last;
        }
        my $new_char = $tile->{'char'};
        push @formed_word, $new_char;
        $fi += $inc;
      }
      if (scalar @formed_word > 1)
      {
        push @words_made, uc (join "", @formed_word);
      }
    }
    $move->{'words_made'} = \@words_made;
    foreach my $word (@words_made)
    {
      if (!$this->{'lexicon'}->{$word})
      {
        $move->{'is_phony'} = 1;
        last;
      }
    }
  }
}

sub toString()
{
  my $this = shift;

  my $number_column = 3;
  my $c1 = 27;
  my $s;
  my $p1 = $this->{'player_one_name'};
  my $p2 = $this->{'player_two_name'};
  $s .= " " x $number_column . sprintf "%-".$c1."s%s\n", $p1, $p2;

  my $l = scalar @{$this->{'moves'}};
  for (my $i = 0; $i < $l; $i++)
  {
    if ($i % 2 == 0)
    {
      $s .= sprintf "%-".$number_column."s", ( (int ($i / 2)) + 1);
    }
  	$s .= sprintf "%-".$c1."s", $this->{'moves'}[$i]->toString();
    if ($i % 2 == 1)
    {
      $s .= "\n";
    }
  }
  $s .=  "\n\n".$this->{'board'}->toString();
  $s .= "\n";
  return $s;
}
1;

