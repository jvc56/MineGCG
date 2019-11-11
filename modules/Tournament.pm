#!/usr/bin/perl

# NEed to account for score of byes

package Tournament;

use warnings;
use strict;
use Getopt::Long;
use Data::Dumper;
use List::Util qw(shuffle min);

use lib '.';
use Constants;

my $file                  = Constants::DEFAULT_TOURNAMENT_FILE;
my $number_of_rounds;
my $pairing_method        = Constants::DEFAULT_PAIRING_METHOD;
my $scoring_method        = Constants::DEFAULT_SCORING_METHOD;
my $number_of_simulations = Constants::DEFAULT_NUMBER_OF_SIMULATIONS;
my $reset_round         = -1;
my $all;

unless (caller)
{

  GetOptions (
              "file:s"   => \$file,
              "rounds:s" => \$number_of_rounds,
              "pair:s"   => \$pairing_method,
              "score:s"  => \$scoring_method,
              "sim:s"    => \$number_of_simulations,
              "start:s"  => \$reset_round,
              "all"      => \$all
             );

  if (!$number_of_rounds)
  {
    print "Must specify the total number of rounds with --rounds\n";
    exit(0);
  }
  my $tournament = Tournament->new(
                    $file,
                    $number_of_rounds,
                    $pairing_method,
                    $scoring_method,
                    $number_of_simulations,
                    $reset_round - 1);
  if ($all)
  {
    my @pairing_methods = 
    (
      Constants::PAIRING_METHOD_KOTH,
      Constants::PAIRING_METHOD_RANK_PAIR,
      Constants::PAIRING_METHOD_RANDOM_PAIR,
    );
    my @scoring_methods =
    (
      Constants::SCORING_METHOD_RATING,
      Constants::SCORING_METHOD_RANDOM_UNIFORM,
      Constants::SCORING_METHOD_RANDOM_BLOWOUTS
    );
    foreach my $pm (@pairing_methods)
    {
      foreach my $sm (@scoring_methods)
      {
        $tournament->{Constants::TOURNAMENT_SCORING_METHOD} = $sm;
        $tournament->{Constants::TOURNAMENT_PAIRING_METHOD} = $pm;
        $tournament->simulation_reset();
        $tournament->simulate();
        print $tournament->get_results();
      }
    }
  }
  else
  {
    $tournament->simulate();
    print $tournament->get_results();
  }

}

sub new
{
  my $this                = shift;
  my $tournament_file     = shift;
  my $number_of_rounds    = shift;
  my $pairing_method      = shift;
  my $scoring_method      = shift;
  my $simulations         = shift;
  my $force_current_round = shift;

  my $reset_round;
  my $number_of_players = 0;
  my @players = ();

  open(my $fh, '<',  $tournament_file) or die "$!";
  while(<$fh>)
  {
    $number_of_players++;
    chomp $_;
    /(\D+),(\D+)\s+(\d+)\s+([^;]+);([^;]+);/;

    my $last_name         = trim($1);
    my $first_name        = trim($2);
    my $rating            = trim($3);
    my $opponents_string  = trim($4);
    my $scores_string     = trim($5);

    my @opponents = split / /, $opponents_string;
    my @scores    = split / /, $scores_string;

    if ($force_current_round >= -1)
    {
      splice @opponents, $force_current_round + 1;
      splice @scores, $force_current_round + 1;
    }

    my $number_of_opponents = scalar @opponents;
    my $number_of_scores    = scalar @scores;

    if ($number_of_opponents != $number_of_scores)
    {
      die 'Different number of opponents and scores';
    }
    elsif($reset_round &&
           ($reset_round != $number_of_opponents - 1 ||
            $reset_round != $number_of_scores - 1)
         )
    {
      die 'Inconsistent number of opponents or scores between players';
    }
    elsif (!$reset_round)
    {
      $reset_round = $number_of_opponents - 1;
    }

    @opponents = map {$_ - 1} @opponents;

    while (scalar @opponents < $number_of_rounds)
    {
      push @opponents, undef;
    }

    while (scalar @scores < $number_of_rounds)
    {
      push @scores, undef;
    }

    push @players, 
    {
      Constants::PLAYER_NAME              => $first_name . ' ' . $last_name,
      Constants::PLAYER_NUMBER            => $number_of_players,
      Constants::PLAYER_RATING            => $rating,
      Constants::PLAYER_OPPONENTS         => \@opponents,
      Constants::PLAYER_SCORES            => \@scores,
      Constants::PLAYER_WINS              => 0,
      Constants::PLAYER_LOSSES            => 0,
      Constants::PLAYER_SPREAD            => 0,

      Constants::PLAYER_RESET_WINS        => 0,
      Constants::PLAYER_RESET_LOSSES      => 0,
      Constants::PLAYER_RESET_SPREAD      => 0
    };
  }

  for (my $i = 0; $i < $number_of_players; $i++)
  {
    my $player_opponents = $players[$i]->{Constants::PLAYER_OPPONENTS};
    for (my $j = 0; $j <= $reset_round; $j++)
    {
      $player_opponents->[$j] = $players[$player_opponents->[$j]];
    }
  }
  
  for (my $i = 0; $i < $number_of_players; $i++)
  {
    my $player = $players[$i];
    my $player_scores = $player->{Constants::PLAYER_SCORES};
    my $player_opponents = $player->{Constants::PLAYER_OPPONENTS};
    for (my $j = 0; $j <= $reset_round; $j++)
    {
      my $player_score   = $player_scores->[$j];
      my $opponent_score = $player_opponents->[$j]->{Constants::PLAYER_SCORES}->[$j];
      my $spread = $player_score - $opponent_score;
      $player->{Constants::PLAYER_SPREAD}       += $spread;
      $player->{Constants::PLAYER_RESET_SPREAD} += $spread;
      if ($player_score > $opponent_score)
      {
        $player->{Constants::PLAYER_WINS}++;
        $player->{Constants::PLAYER_RESET_WINS}++;
      }
      elsif ($player_score < $opponent_score)
      {
        $player->{Constants::PLAYER_LOSSES}++;
        $player->{Constants::PLAYER_RESET_LOSSES}++;
      }
      else
      {
        $player->{Constants::PLAYER_WINS}   += 0.5;
        $player->{Constants::PLAYER_RESET_WINS}   += 0.5;
        $player->{Constants::PLAYER_LOSSES} += 0.5;
        $player->{Constants::PLAYER_RESET_LOSSES} += 0.5;
      }
    }
    my @player_final_ranks = (0) x $number_of_players;
    $player->{Constants::PLAYER_FINAL_RANKS} = \@player_final_ranks;
  }

  my %tournament =
    (
     Constants::TOURNAMENT_RESET_ROUND       => $reset_round,
     Constants::TOURNAMENT_NUMBER_OF_ROUNDS  => $number_of_rounds,
     Constants::TOURNAMENT_NUMBER_OF_PLAYERS => $number_of_players,
     Constants::TOURNAMENT_PLAYERS           => \@players,
     Constants::TOURNAMENT_PAIRING_METHOD    => $pairing_method,
     Constants::TOURNAMENT_SCORING_METHOD    => $scoring_method,

     Constants::TOURNAMENT_CURRENT_ROUND                 => $reset_round,
     Constants::TOURNAMENT_CURRENT_NUMBER_OF_SIMULATIONS => 0,
     Constants::TOURNAMENT_MAXIMUM_NUMBER_OF_SIMULATIONS => $simulations,
    );

  my $self = bless \%tournament, $this;
  $self->rerank();
  return $self;
}

sub pair
{
  my $this   = shift;
  my $round  = shift;
  my $method = shift;

  my $players = $this->{Constants::TOURNAMENT_PLAYERS};
  my $number_of_players = $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS};

  if (!$method)
  {
    $method = $this->{Constants::TOURNAMENT_PAIRING_METHOD};
  }

  if ($method eq Constants::PAIRING_METHOD_RANDOM_PAIR)
  {
    my @pairings = (0 .. $number_of_players - 1);
    @pairings = shuffle @pairings;
    if ($number_of_players % 2 == 1)
    {
      push @pairings, $pairings[$number_of_players - 1];
    }
    my $player_one;
    my $player_two;
    while (@pairings)
    {

      $player_one = shift @pairings;
      $player_two = shift @pairings;
      $players->[$player_one]->{Constants::PLAYER_OPPONENTS}->[$round] = 
        $players->[$player_two];
      $players->[$player_two]->{Constants::PLAYER_OPPONENTS}->[$round] = 
        $players->[$player_one];
    }
  }
  elsif ($method eq Constants::PAIRING_METHOD_KOTH)
  {
    $this->rerank();
    my $opponent_index;
    for (my $i = 0; $i < $number_of_players; $i++)
    {
      if ($i % 2 == 1)
      {
        $opponent_index = $i - 1;
      }
      elsif ($i == $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS} - 1)  
      {
        # Assign a bye to the last odd player out
        $opponent_index = $i;
      }
      else
      {
        $opponent_index = $i + 1;
      }
      $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$round] = 
        $players->[$opponent_index];
    }
  }
  elsif ($method eq Constants::PAIRING_METHOD_RANK_PAIR)
  {
    $this->rerank();
    my $opponent_index;
    my $offset = ($this->{Constants::TOURNAMENT_NUMBER_OF_ROUNDS} - $round) + 1;
    $offset = min($offset, int($number_of_players / 2));
    for (my $i = 0; $i < $number_of_players; $i++)
    {
      if ($i < $offset)
      {
        $opponent_index = $i + $offset;
      }
      elsif ($i < $offset * 2)
      {
        $opponent_index = $i - $offset;
      }
      else
      {
        if ($i % 2 == 1)
        {
          # Assign a bye to the last odd player out
          if ($i == $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS} - 1)
          {
            $opponent_index = $i;
          }
          else
          {
            $opponent_index = $i - 1;
          }
        }
        else
        {
          $opponent_index = $i + 1;
        }
      }
      $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$round] = 
        $players->[$opponent_index];
    }
  }
}

sub get_results
{
  my $this = shift;
  my $html = shift;

  $this->reset();

  my $players = $this->{Constants::TOURNAMENT_PLAYERS};
  my $number_of_players = $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS};
  my $sims = $this->{Constants::TOURNAMENT_MAXIMUM_NUMBER_OF_SIMULATIONS};

  my $pad  = Constants::DEFAULT_NAME_PADDING;
  my $rpad = Constants::DEFAULT_PERCENTAGE_PADDING;

  my $result_string = "Simulation Parameters:\n\n";

  my @parameters =
  (
     Constants::TOURNAMENT_RESET_ROUND,
     Constants::TOURNAMENT_NUMBER_OF_ROUNDS,
     Constants::TOURNAMENT_NUMBER_OF_PLAYERS,
     Constants::TOURNAMENT_PAIRING_METHOD,
     Constants::TOURNAMENT_SCORING_METHOD,
     Constants::TOURNAMENT_MAXIMUM_NUMBER_OF_SIMULATIONS
  );
  for (my $i = 0; $i < scalar @parameters; $i++)
  {
    my $param = $parameters[$i];
    $result_string .= sprintf "  %-" . $pad . "s", ($param . ':');
    if ($param eq Constants::TOURNAMENT_RESET_ROUND)
    {
      $result_string .= ($this->{$param} + 1) . "\n";
    }
    else
    {
      $result_string .= $this->{$param} . "\n";
    }
  }
  $result_string .= "\n";
  $result_string .= "Initial Standings:\n\n";
  $result_string .= $this->standings();
  $result_string .= "\n";
  $result_string .= sprintf "%-" . $pad . "s", '';
  for (my $i = 0; $i < $number_of_players; $i++)
  {
    $result_string .= sprintf "%-" . $rpad . "s", $i + 1;
  }
  for (my $i = 0; $i < $number_of_players; $i++)
  {
    my $player = $players->[$i];
    my $name   = $player->{Constants::PLAYER_NAME};
    $result_string .= sprintf "\n%-" . $pad . "s", $name;
    my $pranks = $player->{Constants::PLAYER_FINAL_RANKS};
    for (my $j = 0; $j < scalar @{$pranks}; $j++)
    {
      my $jrank = $pranks->[$j];
      my $perc = 100 * (sprintf '%.4f', $jrank / $sims) . '%';
      $result_string .= sprintf '%-' . $rpad . 's', $perc;
    }
  }
  return $result_string."\n\n";
}

sub record_results
{
  my $this = shift;

  my $players = $this->{Constants::TOURNAMENT_PLAYERS};
  my $number_of_players = $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS};

  for (my $i = 0; $i < $number_of_players; $i++)
  {
    $players->[$i]->{Constants::PLAYER_FINAL_RANKS}->[$i]++;
  }
  $this->{Constants::TOURNAMENT_CURRENT_NUMBER_OF_SIMULATIONS}++;
}

sub rerank
{
  my $this = shift;
  my $players = $this->{Constants::TOURNAMENT_PLAYERS};

  @{$players} = sort
  {
    $b->{Constants::PLAYER_WINS} <=> $a->{Constants::PLAYER_WINS} ||
    $b->{Constants::PLAYER_SPREAD} <=> $a->{Constants::PLAYER_SPREAD}
  } @{$players};
}

sub reset
{
  my $this = shift;

  my $players = $this->{Constants::TOURNAMENT_PLAYERS};
  my $number_of_players = $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS};
  for (my $i = 0; $i < $number_of_players; $i++)
  {
    for (my $j = $this->{Constants::TOURNAMENT_RESET_ROUND} + 1;
         $j < $this->{Constants::TOURNAMENT_NUMBER_OF_ROUNDS}; $j++)
    {
      $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$j] = undef;
      $players->[$i]->{Constants::PLAYER_SCORES}->[$j] = undef;
    }
    $players->[$i]->{Constants::PLAYER_WINS}   =
      $players->[$i]->{Constants::PLAYER_RESET_WINS};
    $players->[$i]->{Constants::PLAYER_LOSSES} =
      $players->[$i]->{Constants::PLAYER_RESET_LOSSES};
    $players->[$i]->{Constants::PLAYER_SPREAD} =
      $players->[$i]->{Constants::PLAYER_RESET_SPREAD};
  }
  $this->{Constants::TOURNAMENT_CURRENT_ROUND} =
    $this->{Constants::TOURNAMENT_RESET_ROUND};
  $this->rerank();
}

sub simulate
{
  my $this = shift;

  my $reset_round   = $this->{Constants::TOURNAMENT_RESET_ROUND};
  my $max_rounds    = $this->{Constants::TOURNAMENT_NUMBER_OF_ROUNDS};
  
  $this->reset();

  while($this->{Constants::TOURNAMENT_CURRENT_NUMBER_OF_SIMULATIONS}
        < $this->{Constants::TOURNAMENT_MAXIMUM_NUMBER_OF_SIMULATIONS})
  {
    for (my $i = $reset_round + 1; $i < $max_rounds; $i++)
    {
      $this->pair($i);
      $this->score($i);
      $this->{Constants::TOURNAMENT_CURRENT_ROUND}++;
      #print $this->standings();
    }
    $this->rerank();
    $this->record_results();
    $this->reset();
  }
}

sub simulation_reset
{
  my $this = shift;
  $this->reset();

  my $players = $this->{Constants::TOURNAMENT_PLAYERS};
  my $number_of_players = $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS};
  for (my $i = 0; $i < $number_of_players; $i++)
  {
    my $player_final_ranks = $players->[$i]->{Constants::PLAYER_FINAL_RANKS};
    for (my $j = 0; $j < scalar @{$player_final_ranks}; $j++)
    {
      $player_final_ranks->[$j] = 0;
    }
  }
  $this->{Constants::TOURNAMENT_CURRENT_NUMBER_OF_SIMULATIONS} = 0;
}

sub score
{
  my $this = shift;
  my $round = shift;
  my $method = shift;

  my $players = $this->{Constants::TOURNAMENT_PLAYERS};
  my $number_of_players = $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS};

  if (!$method)
  {
    $method = $this->{Constants::TOURNAMENT_SCORING_METHOD};
  }

  my $player_score;
  my $opponent_score;

  if ($method eq Constants::SCORING_METHOD_RANDOM_UNIFORM)
  {
    for (my $i = 0; $i < $number_of_players; $i++)
    {
      if ()
      $players->[$i]->{Constants::PLAYER_SCORES}->[$round] = 300 + int(rand(300));
    }
  }
  elsif($method eq Constants::SCORING_METHOD_RANDOM_BLOWOUTS)
  {
    for (my $i = 0; $i < $number_of_players; $i++)
    {
      if (
          !$players->[$i]->{Constants::PLAYER_OPPONENTS}->[$round]->
          {Constants::PLAYER_SCORES}->[$round]
         )
      {
        $player_score = Constants::BLOWOUT_SCORE * int(rand(2));
        $players->[$i]->{Constants::PLAYER_SCORES}->[$round]  = $player_score + 1;
        $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$round]->
          {Constants::PLAYER_SCORES}->[$round] =
          (Constants::BLOWOUT_SCORE - $player_score) + 1;
      }
    }    
  }
  elsif ($method eq Constants::SCORING_METHOD_RATING)
  {
    for (my $i = 0; $i < $number_of_players; $i++)
    {
      # Uniform random for now
      $players->[$i]->{Constants::PLAYER_SCORES}->[$round] =
        (
          Constants::DEFAULT_BASE_SCORE +
            (
              $players->[$i]->{Constants::PLAYER_RATING} *
              Constants::DEFAULT_SCORE_PER_RATING
            )
        ) +
        int(rand(Constants::DEFAULT_STANDARD_DEVIATION * 2)) -
        Constants::DEFAULT_STANDARD_DEVIATION;
    }   
  }
  for (my $i = 0; $i < $number_of_players; $i++)
  {
    $player_score = $players->[$i]->{Constants::PLAYER_SCORES}->[$round];
    $opponent_score = $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$round]->
      {Constants::PLAYER_SCORES}->[$round];
    $players->[$i]->{Constants::PLAYER_SPREAD} += $player_score - $opponent_score;
    if ($player_score > $opponent_score)
    {
      $players->[$i]->{Constants::PLAYER_WINS}++;
    }
    elsif ($player_score < $opponent_score)
    {
      $players->[$i]->{Constants::PLAYER_LOSSES}++;
    }
    else
    {
      $players->[$i]->{Constants::PLAYER_WINS}   += 0.5;
      $players->[$i]->{Constants::PLAYER_LOSSES} += 0.5;
    }
  }
}

sub standings
{
  my $this = shift;
  $this->rerank();

  my $sns = Constants::DEFAULT_NAME_STANDING_SPACING;
  my $ss  = Constants::DEFAULT_STANDING_SPACING;
  my $print_string = '%-'.$sns.'s%-'.$ss.'s%-'.$ss.'s%-'.$ss.'s%-'.$ss."s\n";
  my $standings_string = '';
  my $players = $this->{Constants::TOURNAMENT_PLAYERS};
  my $number_of_players = $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS};
  $standings_string .= sprintf $print_string, '', 'Wins', 'Losses', 'Spread', 'Next';
  for (my $i = 0; $i < $number_of_players; $i++)
  {
    my $wins   = $players->[$i]->{Constants::PLAYER_WINS};
    my $losses = $players->[$i]->{Constants::PLAYER_LOSSES};
    my $spread = $players->[$i]->{Constants::PLAYER_SPREAD}; 
    my $name   = $players->[$i]->{Constants::PLAYER_NAME};
    
    my $next = '';
    my $this_round = $this->{Constants::TOURNAMENT_CURRENT_ROUND};
    #print "\n\n\n\nthis round: $this_round\n";
    my $next_round = $this->{Constants::TOURNAMENT_CURRENT_ROUND} + 1;
    my $next_opp = $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$next_round];
    if ($next_opp)
    {
      $next = $next_opp->{Constants::PLAYER_NAME};
    }
    else
    {
      my $pscore = $players->[$i]->{Constants::PLAYER_SCORES}->[$this_round];
      my $oscore = $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$this_round]
                    ->{Constants::PLAYER_SCORES}->[$this_round];
      my $opp = $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$this_round]->{Constants::PLAYER_NAME};
      $next = "$pscore - $oscore against $opp";
    }
    $standings_string .= sprintf $print_string, $name, $wins, $losses, $spread, $next;
  }
  return $standings_string;
}

sub trim
{
  my $s = shift;
  $s =~ s/^\s+|\s+$//g;
  return $s;
}