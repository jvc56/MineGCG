#!/usr/bin/perl

package Game;

use warnings;
use strict;
use Data::Dumper;
use List::Util qw(sum min max);
use lib '.';
use Board;
use Move;
use Tile;

sub new
{
  my $this = shift;

  my $filename        = shift;
  my $player_is_first = shift;
  my $lexicon_ref     = shift;

  my $player_one_real_name = shift;
  my $player_two_real_name = shift;

  my $player_one_name;
  my $player_two_name;
  my @moves;
  my $turn_number = 1;
  my $player_one_total_after_move = 0;
  my $player_two_total_after_move = 0;
  my $is_tourney_game = 0;

  my $in_note = 0;
  my $line_number = 0;
  my $warning     = "";

  open(GCG, '<', $filename);
  while(<GCG>)
  {
    $line_number++;
    my $line = $_;
    chomp $_;
    # Skip if line is empty or all whitespace
    if (!$_ || $_ =~ /^\s+$/)
    {
      next;
    }
    # Find who goes first and second
    if (/#player1\s([^\s]+)\s/)
    {
      $player_one_name = $1;
      $player_one_name =~ s/_/ /g;
      next;
    }
    elsif (/#player2\s([^\s]+)\s/)
    {
      $player_two_name = $1;
      $player_two_name =~ s/_/ /g;
      next;
    }

    elsif (!$_ || !$player_one_name || !$player_two_name)
    {
      next;
    }

    elsif(/^#note/ || ($in_note && /^[^>]/)) # assume all other regexes are notes capture notes
    {
      if (!(@moves))
      {
        $warning .= "Warning: note before moves detected\nFILE:   $filename\nLINE $line_number: $line\n";
      }
      else
      {
        $line =~ s/^#note//g;
        $moves[-1]->{'comment'} .= $line . "\n";
        $in_note = 1;
      }
      next;
    }

    elsif(/^#/)
    {
      next;
    }

    $in_note = 0;

    # Remove leading and trailing whitespace
    $line =~ s/^\s+|\s+$//g;
    # Remove trailing whitespace on the > character
    $line =~ s/>\s+/>/g;
    # Remove leading whitespace ONLY from the : character
    # Also add a space after the : in case there was no
    # space between the : and the rack
    $line =~ s/\s*:/: /g;
    
    my @items = split /\s+/, $line;
    my $num_items = scalar @items;

    # Possible plays:
    
    # Pass                  5 -
    # +5 Collins            5 -
    # Word challenged off   5 -
    # Word played           6 -
    # exchanged             5 -
    # 6 pass                5 -
    # outplay               4 -
    # outplay (legacy)      5 -

    my $name  = $items[0];
    my $rack  = $items[1];
    my $loc;
    my $play;
    my $score;
    my $total;

    $name =~ s/_/ /g;
    $name =~ s/[>:]//g;


    # Additional variables
    # needed for the constructor

    my $zero_index_row;
    my $zero_index_column;
    my $vertical;
    my $player_turn;
    my $play_type;
    my $challenge_lost = 0;
    my $challenge_points = 0;
    my $out_points = 0;
    my $comment = "";

    if ($name eq $player_one_name)
    {
      $player_turn = 1;
    }
    else
    {
      $player_turn = 0;
    }

    # An outplay
    if (scalar $num_items  == 4)
    {
      $score = $items[2];
      $total = $items[3];

      $score =~ s/[\+-]//g; 

      if (!(@moves))
      {
        return "outplay detected as the first move\nFILE:   $filename\nLINE $line_number: $line\n";
      }
      if ($player_turn)
      {
        $moves[-1]->{'player_one_total'} = $total;
      }
      else
      {
        $moves[-1]->{'player_two_total'} = $total;
      }
      $moves[-1]->{'score'} += $score;
      $moves[-1]->{'out_points'} = $score;
      next;
    }
    elsif (scalar $num_items == 5)
    {
      $play  = $items[2];
      $score = $items[3];
      $total = $items[4];

      $name =~ s/_/ /g;
      $name =~ s/[>:]//g;
      $score =~ s/[\+-]//g; 

      # A pass
      if ($items[2] eq "-")
      {

        $play_type =  Constants::PLAY_TYPE_PASS;

        if (@moves && $moves[-1]->{'play_type'} eq Constants::PLAY_TYPE_WORD && $filename =~ /TWL/)
        {
          $challenge_lost = 1;
        }

      }
      # Word challenged off
      elsif ($items[2] eq "--")
      {
        $moves[-1]->{'challenge_lost'} = 1;
        $moves[-1]->{'score'} = 0;
        if ($player_turn)
        {
          $player_one_total_after_move = $total;
        }
        else
        {
          $player_two_total_after_move = $total;
        }
        next;
      }
      # Collins +5
      elsif ($items[2] eq "(challenge)")
      {
        $moves[-1]->{'challenge_points'} = $score;
        $moves[-1]->{'score'} += $score;
        if ($player_turn)
        {
          $player_one_total_after_move = $total;
        }
        else
        {
          $player_two_total_after_move = $total;
        }
        next;
      }
      # A six pass
      elsif ($items[3] =~ /\+-\d+/)
      {
        if (scalar @moves < 6)
        {
          return "six pass detected with less than six moves\nFILE:   $filename\nLINE $line_number: $line\n";
        }
        my $rack_value = 0;
        my @rack_array = split //, $moves[-2]->{'rack'};
        foreach my $tile (@rack_array)
        {
          $rack_value += Tile->charToValue($tile);
        }
        if ($turn_number % 2 == 0)
        {
          $moves[-1]->{'player_one_total'} = $total;
          $moves[-1]->{'player_two_total'} -= $rack_value;
        }
        else
        {
          $moves[-1]->{'player_two_total'} = $total;
          $moves[-1]->{'player_one_total'} -= $rack_value;
        }
        next;
      }
      # Also an outplay for older quackle versions
      # $items[1] is a rare outplay sequence only seen in
      # in game 970
      elsif ($items[2] =~ /\(.*\)/ || $items[1] =~ /\(.*\)/)
      {
        if ($items[1] =~ /\(.*\)/)
        {
          $score = $items[2];
          $total = $items[3];
        }
        if (!(@moves))
        {
          return "outplay detected as the first move\nFILE:   $filename\nLINE $line_number: $line\n";
        }
        if ($player_turn)
        {
          $moves[-1]->{'player_one_total'} = $total;
        }
        else
        {
          $moves[-1]->{'player_two_total'} = $total;
        }
        $moves[-1]->{'score'} += $score;
        $moves[-1]->{'out_points'} = $score;
        next;
      }
      # Also an outplay for older quackle versions

      # An exchange
      elsif ($items[2] =~ /-([^-]+)/)
      {
        $play_type = Constants::PLAY_TYPE_EXCHANGE;
        $play = $1;
      }
      else
      {
        return "no valid 5 item sequence found\nFILE:   $filename\nLINE $line_number: $line\n";
      }
    }
    # A play
    # For some GCGs, the words formed by
    # the play are appended to the line
    # making the number of items > 6
    # in this case we just ignore them
    # and continue
    elsif (scalar $num_items >= 6)
    {
      $loc   = $items[2];
      $play  = $items[3];
      $score = $items[4];
      $total = $items[5];

      $loc = uc $loc;
      $name =~ s/_/ /g;
      $name =~ s/[>:]//g;
      $score =~ s/[\+-]//g; 

      my $column_letter;
      my $row_number;
      if (!$loc)
      {
        return "play location undefined\nFILE:   $filename\nLINE $line_number: $line\n";
      }
      my @loc_array = split //, $loc;
      $play_type = Constants::PLAY_TYPE_WORD;
      if ($loc_array[0] =~ /\d/)
      {
        $vertical = 0;
        $column_letter = uc pop @loc_array;
        $row_number = join "", @loc_array;
      }
      else
      {
        $vertical = 1;
        $column_letter = uc shift @loc_array;
        $row_number = join "", @loc_array;
      }
      if (!($row_number =~ /^\d+$/))
      {
        return "invalid row number: $row_number\nFILE:   $filename\nLINE $line_number: $line\n";
      }
      my $column_index_mapping_ref = Constants::COLUMN_INDEX_MAPPING;
      $zero_index_row = $row_number - 1;
      $zero_index_column = $column_index_mapping_ref->{$column_letter};
    }
    else
    {
      return "invalid number of items detected: $num_items\nFILE:   $filename\nLINE $line_number: $line\n";
    }

    # Update total score
    if ($player_turn)
    {
      $player_one_total_after_move = $total;
    }
    else
    {
      $player_two_total_after_move = $total;
    }

    my $move = Move->new(   
                          $turn_number,
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
                          $name
                      );
    push @moves, $move;
    $turn_number++;
  }
  
  my $board = Board->new();
  
  if (@moves)
  {
    $board->addMoves(\@moves);
  }
  else
  {
    return "no moves found\nFILE:   $filename\n";
  }

  my %game = 
  (
    filename        => $filename,
    lexicon         => $lexicon_ref,
    tourney_game    => $is_tourney_game,
  	this_player     => !$player_is_first,
  	player_one_name => $player_one_real_name,
  	player_two_name => $player_two_real_name,
    board           => $board,
    moves           => \@moves,
    warnings        => $warning
  );

  my $self = bless \%game, $this;

  $self->postConstruction();

  return $self;
}

sub getNumTurns
{
	my $this = shift;

  my $player = shift;

  my @moves = @{$this->{'moves'}};

  my $sum = 0;
  foreach my $move (@moves)
  {
    my $turn = $move->{'turn'};
    if ((($player != -1 && $turn == $player) || $player == -1))
    {
      $sum++;
    }
  }
  return $sum;
}

sub getNumWins
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
    if ($player)
    {
      return 1;
    }
    return 0;
  }
  if ($p1s < $p2s)
  {
  	if ($player)
  	{
  	  return 0;
  	}
    return 1;
  }
  return 0.1;
}

sub getScore
{
  my $this = shift;

  my $player = shift;
  my $board = $this->{'board'};
  my $p1s = $board->{'player_one_total'};
  my $p2s = $board->{'player_two_total'};
  if ($player)
  {
    return $p1s;
  }
  return $p2s;
}

sub getBingos
{
  my $this = shift;

  my $player = shift;

  my @moves = @{$this->{'moves'}};

  my @bingos = ();

  my @filename_items = split /\./, $this->{'filename'};

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
      push @bingos, $this->readableMove($move) . $prob . " [". $filename_items[6] . "]";
    }
  }
  return \@bingos;
}

sub getPhoniesFormed
{
  my $this = shift;

  my $player = shift;

  my @moves = @{$this->{'moves'}};

  my @phonies = ();

  my @filename_items = split /\./, $this->{'filename'};

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

    my $move_phonies = '';
    my $readable_play = $this->readableMove($move);
    my $caps_play = $this->readableMoveCapitalized($move);
    my $prob = $this->{'lexicon'}->{$caps_play};
    if (!$prob)
    {
      $move_phonies .= $readable_play."*";
    }
    my @words_made = @{$move->{'words_made'}};
    foreach my $word (@words_made)
    {
      my $word_made_prob = $this->{'lexicon'}->{$word};
      if (!$word_made_prob)
      {
        $move_phonies .= ' '.$word."*";
      }
    }
    if ($move_phonies)
    {
      push @phonies, $move_phonies . " [". $filename_items[6] . "]";
    }
  }
  return \@phonies;
}

sub getPlaysChallenged
{
  my $this = shift;

  my $player = shift;

  my @moves = @{$this->{'moves'}};

  my @plays_chal = ();

  my @filename_items = split /\./, $this->{'filename'};

  for (my $i = 0; $i < scalar @moves; $i++)
  {
    my $move = $moves[$i];
    my $next_move = undef;
    if ($i + 1 < scalar @moves)
    {
      $next_move = $moves[$i + 1];
    }
    if (
         ($player == $move->{'turn'} && $move->{'play_type'} ne Constants::PLAY_TYPE_PASS && ($move->{'challenge_lost'} || $move->{'challenge_points'}))
         || ($next_move && $player != $next_move->{'turn'} && $next_move->{'challenge_lost'} && $next_move->{'play_type'} eq Constants::PLAY_TYPE_PASS)
       )
    {
      my $readable_play = $this->readableMove($move);
      my $caps_play = $this->readableMoveCapitalized($move);
      my $prob = $this->{'lexicon'}->{$caps_play};
      if (!$prob)
      {
        $readable_play = $readable_play."*";
      }
      push @plays_chal, $readable_play . " [". $filename_items[6] . "]";
    }
  }
  return \@plays_chal;
}

sub getNumWordsPlayed
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

sub getNumTilesPlayed
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

sub getNumTripleTriplesPlayed
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

sub getNumBonusSquaresCovered
{
  my $this = shift;
  
  my $player = shift;
  my $board = $this->{'board'};

  return $board->getNumBonusSquaresCovered($player);
}

sub getNumChallenges
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

sub getNumPhonyPlays
{
  my $this = shift;
  
  my $player = shift;
  my $unchal = shift;

  my @moves = @{$this->{'moves'}};
  my $sum = 0;
  foreach my $move (@moves)
  {
    if ((!$unchal || !$move->{'challenge_lost'}) && $move->{'turn'} == $player && $move->{'is_phony'})
    {
      $sum++;
    }
  }
  return $sum;
}

sub getWordsProbability
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


sub isBingoless
{
  my $this = shift;
  
  my $player = shift;
  # Add 0 at the end to include phonies
  return sum(@{$this->getNumWordsPlayed($player, 1, 0)}) == 0;
}

sub readableMove
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

sub readableMoveCapitalized
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

sub postConstruction
{
  my $this = shift;
  my @moves = @{$this->{'moves'}};

  # Determine phoniness and probabilities
  foreach my $move (@moves)
  {
    if ($move->{'play_type'} ne Constants::PLAY_TYPE_WORD)
    {
      $move->{'is_phony'} = 0;
      next;
    }
    
    my $play = $move->{'play'};
    my $v = $move->{'vertical'};
    my $r = $move->{'row'};
    my $c = $move->{'column'};
    my $play_number = $move->{'number'};

    # Add dots to one tile plays

    if (length $play == 1)
    {
      my $pos = $r * Constants::BOARD_WIDTH + $c;
      
      my $iter_r = $pos - Constants::BOARD_WIDTH;
      my $iter_c = $pos - 1;

      # Some numbers higher than the maximum row and column
      my $new_r = $r;
      my $new_c = $c;

      my @formed_word = ($play);

      # Try the horizontal direction first
      
      while ($iter_c >= 0 && (int ($iter_c/Constants::BOARD_WIDTH)) == $r )
      {
        my $square = $this->{'board'}->{'grid'}[$iter_c];
        if (!$square->{'has_tile'})
        {
          last;
        }
        my $tile = $square->{'tile'};
        if ($tile->{'play_number'} > $play_number)
        {
          last;
        }
        $new_c = min($new_c, $iter_c % Constants::BOARD_WIDTH);
        unshift @formed_word, ".";
        $iter_c--;
      }

      $iter_c = $pos + 1;

      while ($iter_c <= 224 && (int ($iter_c/Constants::BOARD_WIDTH)) == $r )
      {
        my $square = $this->{'board'}->{'grid'}[$iter_c];
        if (!$square->{'has_tile'})
        {
          last;
        }
        my $tile = $square->{'tile'};
        if ($tile->{'play_number'} > $play_number)
        {
          last;
        }
        $new_c = min($new_c, $iter_c % Constants::BOARD_WIDTH);
        push @formed_word, ".";
        $iter_c++;
      }

      if (scalar @formed_word > 1)
      {
        $move->{'play'} = (join "", @formed_word);
        $move->{'column'} = $new_c;
        $move->{'vertical'} = 0;
      }
      else
      {
        while ($iter_r >= 0)
        {
          my $square = $this->{'board'}->{'grid'}[$iter_r];
          if (!$square->{'has_tile'})
          {
            last;
          }
          my $tile = $square->{'tile'};
          if ($tile->{'play_number'} > $play_number)
          {
            last;
          }
          $new_r = min($new_r, int ($iter_r/Constants::BOARD_WIDTH) );
          unshift @formed_word, ".";
          $iter_r -= Constants::BOARD_WIDTH;
        }

        $iter_r = $pos + Constants::BOARD_WIDTH;

        while ($iter_r <= 224)
        {
          my $square = $this->{'board'}->{'grid'}[$iter_r];
          if (!$square->{'has_tile'})
          {
            last;
          }
          my $tile = $square->{'tile'};
          if ($tile->{'play_number'} > $play_number)
          {
            last;
          }
          $new_r = min($new_r, int ($iter_r/Constants::BOARD_WIDTH) );
          push @formed_word, ".";
          $iter_r += Constants::BOARD_WIDTH;
        }

        $move->{'play'} = (join "", @formed_word);
        $move->{'row'} = $new_r;
        $move->{'vertical'} = 1;
      }
    }

    # Set is_phony and probability
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


    my @play_array = split //, $play;
    my @words_made = ();
    for (my $i = 0; $i < scalar @play_array; $i++)
    {
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

      my $char = $play_array[$i];
      my $tile = $this->{'board'}->{'grid'}[$pos]->{'tile'};
      if ($char eq "." || ($tile && $play_number > $tile->{'play_number'}))
      {
        next;
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

sub toString
{
  my $this = shift;

  my $number_column = 3;
  my $c1 = 40;
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
  	$s .= sprintf "%-".$c1."s", $this->{'moves'}[$i]->toString($this->readableMove($this->{'moves'}[$i]));
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
