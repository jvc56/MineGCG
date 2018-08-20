#!/usr/bin/perl

package Stats;

use warnings;
use strict;
use Data::Dumper;
use lib '.';
use Constants;

sub new()
{
  my $this = shift;

  my %pbs = (
              Constants::DOUBLE_LETTER => 0,
              Constants::TRIPLE_LETTER => 0,
              Constants::DOUBLE_WORD => 0,
              Constants::TRIPLE_WORD => 0
            );

  my %obs = (
              Constants::DOUBLE_LETTER => 0,
              Constants::TRIPLE_LETTER => 0,
              Constants::DOUBLE_WORD => 0,
              Constants::TRIPLE_WORD => 0
            );

  my %chal = (
               Constants::NO_CHALLENGE          => 0,
               Constants::PLAYER_CHALLENGE_WON  => 0,
               Constants::PLAYER_CHALLENGE_LOST => 0,
               Constants::OPP_CHALLENGE_WON     => 0,
               Constants::OPP_CHALLENGE_LOST    => 0               
             );

  my %stats = (
  	            num_game  => 0,
  	            player_wins => 0,
  	            opp_wins    => 0,
  	            player_score => 0,
  	            opp_score    => 0,
  	            player_bingos  => 0,
  	            opp_bingos     => 0,
                num_turns => 0,
                num_player_tiles => 0,
                num_opp_tiles => 0,
                num_player_blanks => 0,
                num_opp_blanks => 0,
                num_player_tt  => 0,
                num_opp_tt     => 0,
                player_bonus_squares => \%pbs,
                opp_bonus_squares    => \%obs,
                challenges           => \%chal
              );
  my $self = bless \%stats, $this;
  return $self;
}

sub addGame($)
{
  my $this = shift;

  my $game = shift;

  my $this_player = $game->{'this_player'};
  my $opp = 1 - $this_player;

  $this->{'num_game'}++;
  $this->{'num_turns'} += $game->getNumTurns();

  $this->{'player_wins'} += $game->getNumWins($this_player);
  $this->{'opp_wins'} += $game->getNumWins($opp);
  $this->{'player_score'} += $game->getScore($this_player);
  $this->{'opp_score'} += $game->getScore($opp);
  $this->{'player_bingos'} += $game->getNumBingosPlayed($this_player);
  $this->{'opp_bingos'} += $game->getNumBingosPlayed($opp);

  $this->{'num_player_tiles'} += $game->getNumTilesPlayed($this_player);
  $this->{'num_opp_tiles'} += $game->getNumTilesPlayed($opp);
  $this->{'num_player_blanks'} += $game->getNumBlanksPlayed($this_player);
  $this->{'num_opp_blanks'} += $game->getNumBlanksPlayed($opp);
  $this->{'num_player_tt'} += $game->getNumTripleTriplesPlayed($this_player);
  $this->{'num_opp_tt'} += $game->getNumTripleTriplesPlayed($opp);

  my $pbs = $game->getNumBonusSquaresCovered($this_player);

  $this->{'player_bonus_squares'}->{Constants::DOUBLE_LETTER} += $pbs->{Constants::DOUBLE_LETTER};
  $this->{'player_bonus_squares'}->{Constants::TRIPLE_LETTER} += $pbs->{Constants::TRIPLE_LETTER};
  $this->{'player_bonus_squares'}->{Constants::DOUBLE_WORD}   += $pbs->{Constants::DOUBLE_WORD};
  $this->{'player_bonus_squares'}->{Constants::TRIPLE_WORD}   += $pbs->{Constants::TRIPLE_WORD};

  my $obs = $game->getNumBonusSquaresCovered($opp);

  $this->{'opp_bonus_squares'}->{Constants::DOUBLE_LETTER} += $obs->{Constants::DOUBLE_LETTER};
  $this->{'opp_bonus_squares'}->{Constants::TRIPLE_LETTER} += $obs->{Constants::TRIPLE_LETTER};
  $this->{'opp_bonus_squares'}->{Constants::DOUBLE_WORD}   += $obs->{Constants::DOUBLE_WORD};
  $this->{'opp_bonus_squares'}->{Constants::TRIPLE_WORD}   += $obs->{Constants::TRIPLE_WORD};

  my $chal = $game->getNumChallenges($this_player);
  $this->{'challenges'}->{Constants::PLAYER_CHALLENGE_WON}  += $chal->{Constants::PLAYER_CHALLENGE_WON};
  $this->{'challenges'}->{Constants::PLAYER_CHALLENGE_LOST} += $chal->{Constants::PLAYER_CHALLENGE_LOST};
  $this->{'challenges'}->{Constants::OPP_CHALLENGE_WON}     += $chal->{Constants::OPP_CHALLENGE_WON};
  $this->{'challenges'}->{Constants::OPP_CHALLENGE_LOST}    += $chal->{Constants::OPP_CHALLENGE_LOST};
  $this->{'challenges'}->{Constants::NO_CHALLENGE}          += $chal->{Constants::NO_CHALLENGE};
}

sub resetStats()
{
  my $this = shift;

  $this->{'num_game'}          = 0;
  $this->{'num_turns'}         = 0;

  $this->{'player_wins'}  = 0;
  $this->{'opp_wins'}     = 0;
  $this->{'player_score'}  = 0;
  $this->{'opp_score'}     = 0;
  $this->{'player_bingos'}  = 0;
  $this->{'opp_bingos'}     = 0;

  $this->{'num_player_tiles'}  = 0;
  $this->{'num_opp_tiles'}     = 0;
  $this->{'num_player_blanks'} = 0;
  $this->{'num_opp_blanks'}    = 0;
  $this->{'num_player_tt'}     = 0;
  $this->{'num_opp_tt'}        = 0;

  $this->{'player_bonus_squares'}->{Constants::DOUBLE_LETTER} = 0;
  $this->{'player_bonus_squares'}->{Constants::TRIPLE_LETTER} = 0;
  $this->{'player_bonus_squares'}->{Constants::DOUBLE_WORD}   = 0;
  $this->{'player_bonus_squares'}->{Constants::TRIPLE_WORD}   = 0;

  $this->{'opp_bonus_squares'}->{Constants::DOUBLE_LETTER} = 0;
  $this->{'opp_bonus_squares'}->{Constants::TRIPLE_LETTER} = 0;
  $this->{'opp_bonus_squares'}->{Constants::DOUBLE_WORD}   = 0;
  $this->{'opp_bonus_squares'}->{Constants::TRIPLE_WORD}   = 0;

  $this->{'challenges'}->{Constants::PLAYER_CHALLENGE_WON}  = 0;
  $this->{'challenges'}->{Constants::PLAYER_CHALLENGE_LOST} = 0;
  $this->{'challenges'}->{Constants::OPP_CHALLENGE_WON}     = 0;
  $this->{'challenges'}->{Constants::OPP_CHALLENGE_LOST}    = 0;
  $this->{'challenges'}->{Constants::NO_CHALLENGE}          = 0;
}

sub toString()
{
  my $this = shift;

  my $tiw = Constants::TITLE_WIDTH;
  my $aw =  Constants::AVERAGE_WIDTH;
  my $tow = Constants::TOTAL_WIDTH;
  my $tot = $tiw + $aw + $tow;

  my $s = "";

  my $title_divider = ("_" x ($tot+2)) . "\n";
  my $empty_line = "|" . (" " x $tot) . "|\n";
  my $num = $this->{'num_game'};
  $s .= "Results for $num game(s)\n";
  $s .= $title_divider;
  $s .= $this->makeRow("", "AVERAGE", "TOTAL");
  
  $s .= $this->makeRow("GAME STATS", "", "", 1);
  my $pcw = $this->{'challenges'}->{Constants::PLAYER_CHALLENGE_WON};
  my $pcl = $this->{'challenges'}->{Constants::PLAYER_CHALLENGE_LOST};
  my $ocw = $this->{'challenges'}->{Constants::OPP_CHALLENGE_WON};
  my $ocl = $this->{'challenges'}->{Constants::OPP_CHALLENGE_LOST};
  my $chal_tot = $pcw + $pcl + $ocw + $ocl;
  $s .= $this->makeRow("  Challenges", $chal_tot);
  $s .= $this->makeRow("    You won", $pcw);
  $s .= $this->makeRow("    You lost", $pcl);
  $s .= $this->makeRow("    Opponent won", $ocw);
  $s .= $this->makeRow("    Opponent lost", $ocl);
  $s .= $this->makeRow("  Turns", $this->{'num_turns'});
  $s .= $empty_line;
  my $stitle = "YOUR STATS";
  my $player = "player";
  for (my $i = 0; $i < 2; $i++)
  {
  	if ($i == 1)
  	{
  	  $stitle = "OPPONENT STATS";
  	  $player = "opp";
  	}
    $s .= $this->makeRow($stitle, "", "", 1);
    $s .= $this->makeRow("  Wins",  $this->{$player."_wins"});
    $s .= $this->makeRow("  Score",  $this->{$player."_score"});
    $s .= $this->makeRow("  Bingos Played",  $this->{$player."_bingos"});
    $s .= $this->makeRow("  Tiles Played",  $this->{"num_".$player."_tiles"});
    $s .= $this->makeRow("  Blanks Played", $this->{"num_".$player."_blanks"});
    $s .= $this->makeRow("  3x3's Played",  $this->{"num_".$player."_tt"});
    
    my $pdl = $this->{$player."_bonus_squares"}->{Constants::DOUBLE_LETTER};
    my $ptl = $this->{$player."_bonus_squares"}->{Constants::TRIPLE_LETTER};
    my $pdw = $this->{$player."_bonus_squares"}->{Constants::DOUBLE_WORD};
    my $ptw = $this->{$player."_bonus_squares"}->{Constants::TRIPLE_WORD};
    my $pbs_tot = $pdl + $ptl + $pdw + $ptw;
    
    $s .= $this->makeRow("  Bonus Squares", $pbs_tot);
    $s .= $this->makeRow("    Double Letter", $pdl);
    $s .= $this->makeRow("    Triple Letter", $ptl);
    $s .= $this->makeRow("    Double Word", $pdw);
    $s .= $this->makeRow("    Triple Word", $ptw);
    $s .= $empty_line;
  }

  $s .= ("‾" x ($tot+2)) . "\n";
  return $s; 

}

sub makeRow($$$)
{
  my $this = shift;
  my $tiw = Constants::TITLE_WIDTH;
  my $aw =  Constants::AVERAGE_WIDTH;
  my $tow = Constants::TOTAL_WIDTH;
  my $a = shift;
  my $b = shift;
  my $c = shift;
  my $opt = shift;

  $a =~ /^(\s*)/;

  my $spaces = $1;
  $tow = $tow - (length $spaces);
  if (!$c && !$opt)
  {
  	$c = $b;
  	$b = sprintf "%.2f", $b/$this->{'num_game'};
  }
  return "|" . (sprintf "%-$tiw"."s", $a) . (sprintf $spaces."%-$aw"."s", $b) . (sprintf "%-$tow"."s", $c) . "|\n";

}

1;