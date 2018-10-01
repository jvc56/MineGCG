#!/usr/bin/perl

package StatsItem;

use warnings;
use strict;
use List::Util qw(sum);
use Data::Dumper;
use lib '.';
use Constants;

sub new()
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

sub resetItem()
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

sub addGame($)
{
  my $this = shift;

  my $game = shift;

  my $this_player = $game->{'this_player'};

  if ($this->{'type'} eq Constants::STAT_ITEM_OPP || $this->{'type'} eq Constants::STAT_ITEM_LIST_OPP)
  {
    $this_player = 1 - $this_player;
  }

  my $name = $this->{'name'};

  if ($name eq "Bingos")
  {
    $this->__updateBingoList($game, $this_player);
  }
  elsif ($name eq "Phonies Formed")
  {
    $this->__updatePhoniesFormed($game, $this_player);
  }
  elsif ($name eq "Plays Challenged")
  {
    $this->__updatePlaysChallenged($game, $this_player);
  }
  elsif ($name eq "Games")
  {
    $this->__updateNumGames($game);
  }
  elsif ($name eq "Total Turns")
  {
    $this->__updateNumTurns($game, -1);
  }
  elsif ($name eq "Challenges")
  {
    $this->__updateNumChallenges($game, $this_player);
  }
  elsif ($name eq "Wins")
  {
    $this->__updateNumWins($game, $this_player);
  }
  elsif ($name eq "Score")
  {
    $this->__updateScore($game, $this_player);
  }
  elsif ($name eq "Turns")
  {
    $this->__updateNumTurns($game, $this_player);
  }
  elsif ($name eq "Score per Turn")
  {
    $this->__updateScorePerTurn($game, $this_player);
  }
  elsif ($name eq "High Game")
  {
    $this->__updateHighGame($game, $this_player);
  }
  elsif ($name eq "Low Game")
  {
    $this->__updateLowGame($game, $this_player);
  }
  elsif ($name eq "Bingos Played")
  {
    $this->__updateNumBingosPlayed($game, $this_player);
  }
  elsif ($name eq "Bingo Probabilities")
  {
    $this->__updateBingoProbabilities($game, $this_player);
  }
  elsif ($name eq "Tiles Played")
  {
    $this->__updateNumTilesPlayed($game, $this_player);
  }
  elsif ($name eq "Power Tiles Played")
  {
    $this->__updateNumPowerTilesPlayed($game, $this_player);
  }
  elsif ($name eq "Triple Triples Played")
  {
    $this->__updateNumTripleTriplesPlayed($game, $this_player);
  }
  elsif ($name eq "Bingoless Games")
  {
    $this->__updateBingolessGames($game, $this_player);
  }
  elsif ($name eq "Bonus Square Coverage")
  {
    $this->__updateNumBonusSquaresCovered($game, $this_player);
  }
  elsif ($name eq "Phony Plays")
  {
    $this->__updateNumPhonyPlays($game, $this_player);
  }
}

sub __updateBingoList($$)
{
  my $this = shift;
  my $game = shift;
  my $this_player = shift;

  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
    $this->{'list'} = ();
  }

  push @{$this->{'list'}}, @{$game->getBingos($this_player)};
}

sub __updatePhoniesFormed($$)
{
  my $this = shift;
  my $game = shift;
  my $this_player = shift;

  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
    $this->{'list'} = ();
  }

  push @{$this->{'list'}}, @{$game->getPhoniesFormed($this_player)};
}

sub __updatePlaysChallenged($$)
{
  my $this = shift;
  my $game = shift;
  my $this_player = shift;

  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
    $this->{'list'} = ();
  }

  push @{$this->{'list'}}, @{$game->getPlaysChallenged($this_player)};
}

sub __updateNumGames($)
{
  my $this = shift;
  my $game = shift;

  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
  }

  $this->{'total'}++;
}

sub __updateNumTurns($)
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

sub __updateNumWins($$)
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

sub __updateScore($$)
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

sub __updateScorePerTurn($$)
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
  $this->{'total'} = sprintf "%.2f", $this->{'total_score'} / $this->{'total_turns'};
}

sub __updateHighGame($$)
{
  my $this = shift;
  my $game = shift;
  my $this_player = shift;

  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
    $this->{'single'} = 1;
    $this->{'total'} = $game->getScore($this_player);
    return;
  }

  my $score = $game->getScore($this_player);
  if ($score > $this->{'total'})
  {
    $this->{'total'} = $score;
  }
}

sub __updateLowGame($$)
{
  my $this = shift;
  my $game = shift;
  my $this_player = shift;

  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
    $this->{'single'} = 1;
    $this->{'total'} = $game->getScore($this_player);
    return;
  }

  my $score = $game->getScore($this_player);
  if ($score < $this->{'total'})
  {
    $this->{'total'} = $score;
  }
}

sub __updateNumBingosPlayed($$)
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

sub __updateBingoProbabilities($$)
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

sub __updateNumTilesPlayed($$)
{
  my $this = shift;
  my $game = shift;
  my $this_player = shift;

  if (!$this->{'init'})
  {
    $this->{'init'} = 1;
  }

  $this->{'total'} += $game->getNumTilesPlayed($this_player);
}

sub __updateNumPowerTilesPlayed($$)
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
  my $blanks = $game->getNumTilesPlayed($this_player, 'a-z');
  my $js = $game->getNumTilesPlayed($this_player, 'J');
  my $qs = $game->getNumTilesPlayed($this_player, 'Q');
  my $xs = $game->getNumTilesPlayed($this_player, 'X');
  my $zs = $game->getNumTilesPlayed($this_player, 'Z');
  my $ss = $game->getNumTilesPlayed($this_player, 'S');

  $this->{'total'} += $blanks + $js + $qs + $xs + $zs + $ss;
  $this->{'subitems'}->{'?'} += $blanks;
  $this->{'subitems'}->{'J'} += $js;
  $this->{'subitems'}->{'Q'} += $qs;
  $this->{'subitems'}->{'X'} += $xs;
  $this->{'subitems'}->{'Z'} += $zs;
  $this->{'subitems'}->{'S'} += $ss;
}

sub __updateNumTripleTriplesPlayed($$)
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

sub __updateBingolessGames($$)
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

sub __updateNumBonusSquaresCovered($$)
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

sub __updateNumChallenges($)
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

sub __updateNumPhonyPlays($$)
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

sub makeRow($$$)
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

  my $spaces = $1;
  $tow = $tow - (length $spaces);

  my $s = "";

  $s .= "|" .  (sprintf "%-$tiw"."s", "  ".$name) . 
               (sprintf $spaces."%-$aw"."s", $average) . 
               (sprintf "%-$tow"."s", $total) . "|\n";
  return $s;
}
sub makeItem($$$)
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

sub toString($)
{
  my $this = shift;

  my $total_games = shift;
  my $tiw = Constants::TITLE_WIDTH;
  my $aw =  Constants::AVERAGE_WIDTH;
  my $tow = Constants::TOTAL_WIDTH;
  my $tot = $tiw + $aw + $tow;

  my $s = "";

  if ($this->{'type'} eq Constants::STAT_ITEM_LIST_PLAYER || $this->{'type'} eq Constants::STAT_ITEM_LIST_OPP)
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
  else
  {
    $s .= $this->makeItem($this->{'name'}, $this->{'total'}, $total_games);
  }

  return $s;  
}

1;

