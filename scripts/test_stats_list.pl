#!/usr/bin/perl

use warnings;
use strict;

use lib './objects';
use Constants;

my $statitems = 
[
  'Bingos' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      push @{$this->{'list'}}, @{$game->getBingos($this_player)};
    }
  },
  'Triple Triples' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      push @{$this->{'list'}}, @{$game->getTripleTriples($this_player)};
    }
  },
  'Bingo Nines or Above' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      push @{$this->{'list'}}, @{$game->getBingoNinesOrAbove($this_player)};
    }
  },
  'Highest Scoring Play' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'score'} = -1;
        $this->{'list'} = [];
      }

      my $game_highest = $game->getHighestScoringPlay($this_player);

      my @current_list = @{$this->{'list'}};

      if (!@current_list || $this->{'score'} < $game_highest->[1])
      {
        $this->{'score'} = $game_highest->[1];
        $this->{'list'}  = [$game_highest->[0] . " ($game_highest->[1] points)"];
      }
    }
  },
  'Highest Scoring Turn' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'}   = 1;
        $this->{'single'} = 1;
        if ($game->{'html'})
        {
          $this->{'link'}   = $game->{'filename'};
        }
        $this->{'total'}  = $game->getHighestScoringPlay($this_player)->[1];
        return;
      }

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
  'Challenged Phonies' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this        = shift;
      my $game        = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      push @{$this->{'list'}}, @{$game->getPhoniesFormed($this_player, 1)};
    }
  },
  'Unchallenged Phonies' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this        = shift;
      my $game        = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      push @{$this->{'list'}}, @{$game->getPhoniesFormed($this_player, 0)};
    }
  },
  'Plays That Were Challenged' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      push @{$this->{'list'}}, @{$game->getPlaysChallenged($this_player)};
    }
  },
  'Games' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_GAME,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }

      $this->{'total'}++;
    }
  },
  'Total Turns' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_GAME,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this   = shift;
      my $game   = shift;
      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }
      $this->{'total'} += $game->getNumTurns(-1);
    }
  },
  'Wins' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }

      $this->{'total'} += $game->getNumWins($this_player);
    }
  },
  'Score' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }

      $this->{'total'} += $game->getScore($this_player);
    }
  },
  'Score per Turn' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'single'} = 1;
      }

      $this->{'total_score'} += $game->getScore($this_player);
      $this->{'total_turns'} += $game->getNumTurns($this_player);
      $this->{'total'} = sprintf "%.4f", $this->{'total_score'} / $this->{'total_turns'};
    }
  },
  'Turns' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }

      $this->{'total'} += $game->getNumFirsts($this_player);
    }
  },
  'Firsts' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }

      $this->{'total'} += $game->getNumFirsts($this_player);
    }
  },
  'Full Rack per Turn' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'single'} = 1;
      }

      $this->{'total_full_racks'} += $game->getNumFullRacks($this_player);
      $this->{'total_turns'}      += $game->getNumTurns($this_player);
      $this->{'total'} = sprintf "%.4f", $this->{'total_full_racks'} / $this->{'total_turns'};
    }
  },
  'Exchanges' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }

      $this->{'total'} += $game->getNumExchanges($this_player);
    }
  },
  'High Game' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => ,
    Constants::STAT_METATYPE_NAME => ,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'}   = 1;
        $this->{'single'} = 1;
        if ($game->{'html'})
        {
          $this->{'link'}   = $game->{'filename'};
        }
        $this->{'total'}  = $game->getScore($this_player);
        return;
      }

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
  'Low Game' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => ,
    Constants::STAT_METATYPE_NAME => ,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'}   = 1;
        $this->{'single'} = 1;
        if ($game->{'html'})
        {
          $this->{'link'}   = $game->{'filename'};
        }
        $this->{'total'}  = $game->getScore($this_player);
        return;
      }

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
  'Bingos Played' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        my %subitems =
        (
          Constants::SEVENS_TITLE    => 0,
          Constants::EIGHTS_TITLE    => 0,
          Constants::NINES_TITLE     => 0,
          Constants::TENS_TITLE      => 0,
          Constants::ELEVENS_TITLE   => 0,
          Constants::TWELVES_TITLE   => 0,
          Constants::THIRTEENS_TITLE => 0,
          Constants::FOURTEENS_TITLE => 0,
          Constants::FIFTEENS_TITLE  => 0
        );
        $this->{'subitems'} = \%subitems;
        my @order =
        (
          Constants::SEVENS_TITLE,
          Constants::EIGHTS_TITLE,
          Constants::NINES_TITLE,
          Constants::TENS_TITLE,
          Constants::ELEVENS_TITLE,
          Constants::TWELVES_TITLE,
          Constants::THIRTEENS_TITLE,
          Constants::FOURTEENS_TITLE,
          Constants::FIFTEENS_TITLE
        );
        $this->{'list'} = \@order;
      }
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
  'Bingo Probabilities' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'single'} = 1;
        my %subitems =
        (
          Constants::SEVENS_TITLE    => 0,
          Constants::EIGHTS_TITLE    => 0,
          Constants::NINES_TITLE     => 0,
          Constants::TENS_TITLE      => 0,
          Constants::ELEVENS_TITLE   => 0,
          Constants::TWELVES_TITLE   => 0,
          Constants::THIRTEENS_TITLE => 0,
          Constants::FOURTEENS_TITLE => 0,
          Constants::FIFTEENS_TITLE  => 0
        );
        $this->{'subitems'} = \%subitems;
        my @order =
        (
          Constants::SEVENS_TITLE,
          Constants::EIGHTS_TITLE,
          Constants::NINES_TITLE,
          Constants::TENS_TITLE,
          Constants::ELEVENS_TITLE,
          Constants::TWELVES_TITLE,
          Constants::THIRTEENS_TITLE,
          Constants::FOURTEENS_TITLE,
          Constants::FIFTEENS_TITLE
        );
        $this->{'list'} = \@order;
        my %prob_totals =
        (
          Constants::SEVENS_TITLE    => 0,
          Constants::EIGHTS_TITLE    => 0,
          Constants::NINES_TITLE     => 0,
          Constants::TENS_TITLE      => 0,
          Constants::ELEVENS_TITLE   => 0,
          Constants::TWELVES_TITLE   => 0,
          Constants::THIRTEENS_TITLE => 0,
          Constants::FOURTEENS_TITLE => 0,
          Constants::FIFTEENS_TITLE  => 0
        );
        $this->{'prob_totals'} = \%prob_totals;
        $this->{'prob_total'} = 0;
        my %bingo_totals =
        (
          Constants::SEVENS_TITLE    => 0,
          Constants::EIGHTS_TITLE    => 0,
          Constants::NINES_TITLE     => 0,
          Constants::TENS_TITLE      => 0,
          Constants::ELEVENS_TITLE   => 0,
          Constants::TWELVES_TITLE   => 0,
          Constants::THIRTEENS_TITLE => 0,
          Constants::FOURTEENS_TITLE => 0,
          Constants::FIFTEENS_TITLE  => 0
        );
        $this->{'bingo_totals'} = \%bingo_totals;
        $this->{'bingo_total'} = 0;
      }

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

      $this->{'total'} = sprintf "%.2f", ($this->{'prob_total'} / $dem_total);
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
  'Tiles Played' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        my %subitems =
        (
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
        );
        $this->{'subitems'} = \%subitems;
        my @order =
        (
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
        );
        $this->{'list'} = \@order;
      }

      $this->{'total'} += $game->{'tiles_played'}->{$this_player}->{'total'};

      my $blanks = $game->{'tiles_played'}->{$this_player}->{'?'};
      $this->{'subitems'}->{'?'} += $blanks;

      foreach my $c ("A" .. "Z")
      {
         $this->{'subitems'}->{$c} += $game->{'tiles_played'}->{$this_player}->{$c};
      }
    }
  },
  'Power Tiles Played' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        my %subitems =
        (
          '?' => 0,
          'J' => 0,
          'Q' => 0,
          'X' => 0,
          'Z' => 0,
          'S' => 0
        );
        $this->{'subitems'} = \%subitems;
        my @order =
        (
          '?',
          'J',
          'Q',
          'X',
          'Z',
          'S'
        );
        $this->{'list'} = \@order;
      }
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
  'Power Tiles Stuck With' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        my %subitems =
        (
          '?' => 0,
          'J' => 0,
          'Q' => 0,
          'X' => 0,
          'Z' => 0,
          'S' => 0
        );
        $this->{'subitems'} = \%subitems;
        my @order =
        (
          '?',
          'J',
          'Q',
          'X',
          'Z',
          'S'
        );
        $this->{'list'} = \@order;
      }
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
  'Triple Triples Played' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }

      $this->{'total'} += $game->getNumTripleTriplesPlayed($this_player);
    }
  },
  'Bingoless Games' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }

      $this->{'total'} += $game->isBingoless($this_player);
    }
  },
  'Turns With a Blank' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }

      $this->{'total'} += $game->getTurnsWithBlank($this_player);
    }
  },
  'Bonus Square Coverage' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        my %subitems =
        (
          Constants::DOUBLE_LETTER_TITLE => 0,
          Constants::TRIPLE_LETTER_TITLE => 0,
          Constants::DOUBLE_WORD_TITLE => 0,
          Constants::TRIPLE_WORD_TITLE => 0
        );
        $this->{'subitems'} = \%subitems;
        my @order =
        (
          Constants::DOUBLE_LETTER_TITLE,
          Constants::DOUBLE_WORD_TITLE,
          Constants::TRIPLE_LETTER_TITLE,
          Constants::TRIPLE_WORD_TITLE
        );
        $this->{'list'} = \@order;
      }

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
  'Phony Plays' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        my %subitems =
        (
           Constants::UNCHALLENGED  => 0,
           Constants::CHALLENGED_OFF => 0,   
        );
        $this->{'subitems'} = \%subitems;
        my @order =
        (
           Constants::UNCHALLENGED,
           Constants::CHALLENGED_OFF, 
        );
        $this->{'list'} = \@order;
      }

      # 0 to get all phonies, 1 to get unchallenged phonies
      my $num_phonies = $game->getNumPhonyPlays($this_player, 0);
      my $num_phonies_unchal = $game->getNumPhonyPlays($this_player, 1);



      $this->{'total'} += $num_phonies;
      $this->{'subitems'}->{Constants::UNCHALLENGED} += $num_phonies_unchal;
      $this->{'subitems'}->{Constants::CHALLENGED_OFF} += $num_phonies - $num_phonies_unchal;
    }
  },
  'Challenge Percentage' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this   = shift;
      my $game   = shift;
      my $player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'single'} = 1;
      }

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
  'Defending Challenge Percentage' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this   = shift;
      my $game   = shift;
      my $player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'single'} = 1;
      }

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
  'Comments' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this   = shift;
      my $game   = shift;
      my $player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }

      $this->{'total'} += $game->getNumComments($player);
    }
  },
  'Comments Word Length' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this   = shift;
      my $game   = shift;
      my $player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }

      $this->{'total'} += $game->getNumCommentsWordLength($player);
    }
  },
  'Many Double Letters Covered' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }
      # All is 24
      if (20 <= $game->getNumBonusSquaresCovered(0)->{Constants::DOUBLE_LETTER} + $game->getNumBonusSquaresCovered(1)->{Constants::DOUBLE_LETTER})
      {
        push @{$this->{'list'}}, $game->getReadableName();
      }
    }
  },
  'Many Double Letters Covered' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }
      # All is 17

      my $sum = $game->getNumBonusSquaresCovered(0)->{Constants::DOUBLE_WORD} + $game->getNumBonusSquaresCovered(1)->{Constants::DOUBLE_WORD};

      if (15 <= $sum)
      {
        if ($sum == 15)
        {
          push @{$this->{'list'}}, $game->getReadableName();
        }
        else
        {
          unshift @{$this->{'list'}}, $game->getReadableName();
        }
      }
    }
  },
  'All Triple Letters Covered' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      if (12 == $game->getNumBonusSquaresCovered(0)->{Constants::TRIPLE_LETTER} + $game->getNumBonusSquaresCovered(1)->{Constants::TRIPLE_LETTER})
      {
        push @{$this->{'list'}}, $game->getReadableName();
      }
    }
  },
  'All Triple Letters Covered' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => ,
    Constants::STAT_METATYPE_NAME => ,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }
      if (8 == $game->getNumBonusSquaresCovered(0)->{Constants::TRIPLE_WORD} + $game->getNumBonusSquaresCovered(1)->{Constants::TRIPLE_WORD})
      {
        push @{$this->{'list'}}, $game->getReadableName();
      }
    }
  },
  'High Scoring' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      if (700 <= $game->{'board'}->{"player_one_total"} || 700 <= $game->{'board'}->{"player_two_total"})
      {
        push @{$this->{'list'}}, $game->getReadableName();
      }
    }
  },
  'High Combined Score' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      if (1100 <= $game->{'board'}->{"player_one_total"} + $game->{'board'}->{"player_two_total"})
      {
        push @{$this->{'list'}}, $game->getReadableName();
      }
    }
  },
  'Low Combined Score' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      if (200 >= $game->{'board'}->{"player_one_total"} + $game->{'board'}->{"player_two_total"})
      {
        push @{$this->{'list'}}, $game->getReadableName();
      }
    }
  },
  'Ties' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      if ($game->{'board'}->{"player_one_total"} == $game->{'board'}->{"player_two_total"})
      {
        push @{$this->{'list'}}, $game->getReadableName();
      }
    }
  },
  'One Player Plays Every Power Tile' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

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
        push @{$this->{'list'}}, $game->getReadableName();
      }
    }
  },
  'One Player Plays Every E' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;
      my $this_player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      my $sum1 = $game->{'tiles_played'}->{0}->{'E'};

      my $sum2 = $game->{'tiles_played'}->{1}->{'E'};

      if ($sum1 == 12 || $sum2 == 12)
      {
        push @{$this->{'list'}}, $game->getReadableName();
      }
    }
  },
  'Many Challenges' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_NOTABLE,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this = shift;
      my $game = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
      }

      my $chal = $game->getNumChallenges(0);

      my $pcw  = $chal->{Constants::PLAYER_CHALLENGE_WON};
      my $pcl  = $chal->{Constants::PLAYER_CHALLENGE_LOST};
      my $ocw  = $chal->{Constants::OPP_CHALLENGE_WON};
      my $ocl  = $chal->{Constants::OPP_CHALLENGE_LOST};

      if (5 <= $pcw + $pcl + $ocw + $ocl)
      {
        push @{$this->{'list'}}, $game->getReadableName();
      }
    }
  },
  'Mistakeless Turns' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this   = shift;
      my $game   = shift;
      my $player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
      }

      $this->{'total'}  += $game->getNumMistakelessTurns($player);
    }
  },
  'Mistakes' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_ITEM,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this   = shift;
      my $game   = shift;
      my $player = shift;
      
      my @categories = Constants::MISTAKES;


      if (!$this->{'init'})
      {
        $this->{'init'} = 1;

        my %subitems;
        foreach my $cat (@categories)
        {
          $subitems{$cat} = 0;
        }
        $this->{'subitems'} = \%subitems;
        $this->{'list'} = \@categories;
      }

      my $mistakes_hash_ref = $game->getNumMistakes($player);

      foreach my $cat (@categories)
      {
        my $val                      = $mistakes_hash_ref->{$cat};
        $this->{'total'}            += $val;
        $this->{'subitems'}->{$cat} += $val;
      }
    }
  },
  'Mistakes List' =>
  {
    Constants::STAT_ITEM_OBJECT_NAME => {},
    Constants::STAT_DATATYPE_NAME => Constants::DATATYPE_LIST,
    Constants::STAT_METATYPE_NAME => Constants::METATYPE_PLAYER,
    Constants::STAT_FUNCTION_NAME =>
    sub
    {
      my $this   = shift;
      my $game   = shift;
      my $player = shift;

      if (!$this->{'init'})
      {
        $this->{'init'} = 1;
        $this->{'list'} = [];
        $this->{'html'} = $game->{'html'}
      }

      push @{$this->{'list'}}, @{$game->getMistakes($player)};
    }
  }
];

print "OK\n";

