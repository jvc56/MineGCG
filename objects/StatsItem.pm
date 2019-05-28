#!/usr/bin/perl

package StatsItem;

use warnings;
use strict;
use List::Util qw(sum);
use Data::Dumper;
use lib '.';
use Constants;

sub new
{
  my $this = shift;

  my $name     = shift;
  my $type     = shift;
  my %item =
  (
    name     => $name,
    type     => $type,
    single   => 0,
    total    => 0,
    subitems => undef,
    list     => undef,
    init     => 0
  );
  my $self = bless \%item, $this;
  return $self;
}

sub resetItem
{
  my $this = shift;

  $this->{'total'} = 0;
  $this->{'init'}  = 0;
  $this->{'list'}  = undef;

  if ($this->{'subitems'})
  {
    foreach my $key (keys %{$this->{'subitems'}})
    {
      $this->{'subitems'}->{$key} = 0;
    }
  }
}

sub addGame
{
  my $this = shift;

  my $game = shift;

  my $this_player = $game->{'this_player'};

  if ($this->{'type'} eq Constants::STAT_ITEM_OPP || $this->{'type'} eq Constants::STAT_ITEM_LIST_OPP || $this->{'type'} eq Constants::MISTAKE_ITEM_LIST_OPP)
  {
    $this_player = 1 - $this_player;
  }

  my $name = $this->{'name'};

  if ($name eq "Bingos")
  {
    $this->updateBingoList($game, $this_player);
  }
  elsif ($name eq "Triple Triples")
  {
    $this->updateTripleTripleList($game, $this_player);
  }
  elsif ($name eq "Bingo Nines or Above")
  {
    $this->updateBingoNinesOrAboveList($game, $this_player);
  }
  elsif ($name eq "Challenged Phonies")
  {
    $this->updatePhoniesFormed($game, $this_player, 1);
  }
  elsif ($name eq "Unchallenged Phonies")
  {
    $this->updatePhoniesFormed($game, $this_player, 0);
  }
  elsif ($name eq "Plays That Were Challenged")
  {
    $this->updatePlaysChallenged($game, $this_player);
  }
  elsif ($name eq "Games")
  {
    $this->updateNumGames($game);
  }
  elsif ($name eq "Total Turns")
  {
    $this->updateNumTurns($game, -1);
  }
  elsif ($name eq "Challenges")
  {
    $this->updateNumChallenges($game, $this_player);
  }
  elsif ($name eq "Wins")
  {
    $this->updateNumWins($game, $this_player);
  }
  elsif ($name eq "Score")
  {
    $this->updateScore($game, $this_player);
  }
  elsif ($name eq "Turns")
  {
    $this->updateNumTurns($game, $this_player);
  }
  elsif ($name eq "Score per Turn")
  {
    $this->updateScorePerTurn($game, $this_player);
  }
  elsif ($name eq "Firsts")
  {
    $this->updateNumFirsts($game, $this_player);
  }
  elsif ($name eq "Full Rack per Turn")
  {
    $this->updateFullRackPerTurn($game, $this_player);
  }
  elsif ($name eq "High Game")
  {
    $this->updateHighGame($game, $this_player);
  }
  elsif ($name eq "Low Game")
  {
    $this->updateLowGame($game, $this_player);
  }
  elsif ($name eq "Bingos Played")
  {
    $this->updateNumBingosPlayed($game, $this_player);
  }
  elsif ($name eq "Bingo Probabilities")
  {
    $this->updateBingoProbabilities($game, $this_player);
  }
  elsif ($name eq "Tiles Played")
  {
    $this->updateNumTilesPlayed($game, $this_player);
  }
  elsif ($name eq "Power Tiles Played")
  {
    $this->updateNumPowerTilesPlayed($game, $this_player);
  }
  elsif ($name eq "Power Tiles Stuck With")
  {
    $this->updateNumPowerTilesStuckWith($game, $this_player);
  }
  elsif ($name eq "Es Played")
  {
    $this->updateNumEsPlayed($game, $this_player);
  }
  elsif ($name eq "Triple Triples Played")
  {
    $this->updateNumTripleTriplesPlayed($game, $this_player);
  }
  elsif ($name eq "Bingoless Games")
  {
    $this->updateBingolessGames($game, $this_player);
  }
  elsif ($name eq "Turns With a Blank")
  {
    $this->updateTurnsWithBlank($game, $this_player);
  }
  elsif ($name eq "Bonus Square Coverage")
  {
    $this->updateNumBonusSquaresCovered($game, $this_player);
  }
  elsif ($name eq "Phony Plays")
  {
    $this->updateNumPhonyPlays($game, $this_player);
  }
  elsif ($name eq "Challenge Percentage")
  {
    $this->updateChallengePercentage($game, $this_player);
  }
  elsif ($name eq "Defending Challenge Percentage")
  {
    $this->updateDefendingChallengePercentage($game, $this_player);
  }
  elsif ($name eq "Percentage Phonies Unchallenged")
  {
    $this->updatePercentagePhoniesUnchallenged($game, $this_player);
  }
  elsif ($name eq "Comments")
  {
    $this->updateNumComments($game);
  }
  elsif ($name eq "Comments Word Length")
  {
    $this->updateNumCommentsWordLength($game);
  }
  elsif ($name eq "Many Double Letters Covered")
  {
    $this->updateAllDoubleLettersCovered($game);
  }
  elsif ($name eq "Many Double Words Covered")
  {
    $this->updateAllDoubleWordsCovered($game);
  }
  elsif ($name eq "All Triple Letters Covered")
  {
    $this->updateAllTripleLettersCovered($game);
  }
  elsif ($name eq "All Triple Words Covered")
  {
    $this->updateAllTripleWordsCovered($game);
  }
  elsif ($name eq "High Scoring")
  {
    $this->updateHighScoring($game);
  }
  elsif ($name eq "Combined High Scoring")
  {
    $this->updateCombinedHighScoring($game);
  }
  elsif ($name eq "Combined Low Scoring")
  {
    $this->updateCombinedLowScoring($game);
  }
  elsif ($name eq "Ties")
  {
    $this->updateTies($game);
  }
  elsif ($name eq "One Player Plays Every Power Tile")
  {
    $this->updateAllPowerTilesPlayed($game);
  }
  elsif ($name eq "One Player Plays Every E")
  {
    $this->updateAllEsPlayed($game);
  }
  elsif ($name eq "Many Challenges")
  {
    $this->updateManyChallenges($game);
  }
  elsif ($name eq "Mistakes")
  {
    $this->updateNumMistakes($game, $this_player);
  }
  elsif ($name eq "Mistakes List")
  {
    $this->updateMistakesList($game, $this_player);
  }
}

sub updateBingoList
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

sub updateTripleTripleList
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

sub updateBingoNinesOrAboveList
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

sub updatePhoniesFormed
{
  my $this        = shift;
  my $game        = shift;
  my $this_player = shift;
  my $challenged  = shift;

  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
    $this->{'list'} = [];
  }

  push @{$this->{'list'}}, @{$game->getPhoniesFormed($this_player, $challenged)};
}

sub updatePlaysChallenged
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

sub updateNumGames
{
  my $this = shift;
  my $game = shift;

  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
  }

  $this->{'total'}++;
}

sub updateNumTurns
{
  my $this   = shift;
  my $game   = shift;
  my $player = shift;
  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
  }

  $this->{'total'} += $game->getNumTurns($player);
}

sub updateNumWins
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

sub updateScore
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

sub updateScorePerTurn
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

sub updateNumFirsts
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

sub updateFullRackPerTurn
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

sub updateHighGame
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

sub updateLowGame
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

sub updateNumBingosPlayed
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

sub updateBingoProbabilities
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

sub updateNumTilesPlayed
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

sub updateNumPowerTilesPlayed
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

sub updateNumPowerTilesStuckWith
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

sub updateNumEsPlayed
{
  my $this = shift;
  my $game = shift;
  my $this_player = shift;

  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
  }

  $this->{'total'} += $game->{'tiles_played'}->{$this_player}->{'E'};
}

sub updateNumTripleTriplesPlayed
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

sub updateBingolessGames
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

sub updateTurnsWithBlank
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

sub updateNumBonusSquaresCovered
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

sub updateNumChallenges
{
  my $this = shift;
  my $game = shift;
  my $this_player = $game->{'this_player'};

  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
    my %subitems =
    (
       Constants::PLAYER_CHALLENGE_WON  => 0,
       Constants::PLAYER_CHALLENGE_LOST => 0,
       Constants::OPP_CHALLENGE_WON     => 0,
       Constants::OPP_CHALLENGE_LOST    => 0    
    );
    $this->{'subitems'} = \%subitems;
    my @order =
    (
       Constants::PLAYER_CHALLENGE_WON,
       Constants::OPP_CHALLENGE_LOST,   
       Constants::PLAYER_CHALLENGE_LOST,
       Constants::OPP_CHALLENGE_WON
    );
    $this->{'list'} = \@order;
  }

  my $chal = $game->getNumChallenges($this_player);

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

sub updateNumPhonyPlays
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

sub updateChallengePercentage
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

sub updateDefendingChallengePercentage
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

sub updatePercentagePhoniesUnchallenged
{
  my $this   = shift;
  my $game   = shift;
  my $player = shift;

  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
    $this->{'single'} = 1;
  }

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

sub updateNumComments
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

sub updateNumCommentsWordLength
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


sub updateAllDoubleLettersCovered
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

sub updateAllDoubleWordsCovered
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

sub updateAllTripleLettersCovered
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

sub updateAllTripleWordsCovered
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

sub updateHighScoring
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

sub updateCombinedHighScoring
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

sub updateCombinedLowScoring
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

sub updateTies
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

sub updateAllPowerTilesPlayed
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

sub updateAllEsPlayed
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

sub updateManyChallenges
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

sub updateNumMistakes
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

sub updateMistakesList
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

  if ($this->{'single'})
  {
    $average = $total;
    $total = '-';
  }

  if ($this->{'link'})
  {
    my @items = split /\./, $this->{'link'};
    my $id = $items[6];
    my $link = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX . $id;
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

  my $r = $this->makeRow($name, $total, $num_games);

  if ($this->{'subitems'})
  {
    my %subs  = %{$this->{'subitems'}};
    my @order = @{$this->{'list'}};
    for (my $i = 0; $i < scalar @order; $i++)
    {
      my $key = $order[$i];
      $r .= $this->makeRow("  " . $key, $subs{$key}, $num_games);
    }
  }
  return $r;
}

sub makeMistakeItem
{
  my $this         = shift;
  my $mistake_item = shift;
  my $is_title_row = shift;
  my $num_mistakes = shift;

  my $html         = $this->{'html'};

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

sub toString
{
  my $this = shift;

  my $total_games = shift;
  my $tiw = Constants::TITLE_WIDTH;
  my $aw =  Constants::AVERAGE_WIDTH;
  my $tow = Constants::TOTAL_WIDTH;
  my $tot = $tiw + $aw + $tow;

  my $s = "";
  if ($this->{'type'} eq Constants::STAT_ITEM_LIST_PLAYER || $this->{'type'} eq Constants::STAT_ITEM_LIST_OPP  || $this->{'type'} eq Constants::STAT_ITEM_LIST_NOTABLE)
  {
    $s .= "\n".$this->{'name'} . ": ";
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
  elsif ($this->{'type'} eq Constants::MISTAKE_ITEM_LIST_PLAYER || $this->{'type'} eq Constants::MISTAKE_ITEM_LIST_OPP)
  {
    $s .= "\n";
    my $html = $this->{'html'};
    my @list = @{$this->{'list'}};

    if ($html && scalar @list > 0)
    {
      $s .= "<table>\n<tbody>\n";
    }

    my @mistakes_magnitude = Constants::MISTAKES_MAGNITUDE;

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
      $magnitude_strings{$mistake_elements[1]} .= $this->makeMistakeItem($list[$i], 0);
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
        $s .= $this->makeMistakeItem($mag, $mistake_elements_length, $mistakes_magnitude_count{$mag});
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
    $s .= $this->makeItem($this->{'name'}, $this->{'total'}, $total_games);
  }

  return $s;  
}

1;

