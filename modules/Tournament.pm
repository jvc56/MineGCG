#!/usr/bin/perl

# NEed to account for score of byes

package Tournament;

use warnings;
use strict;
use Getopt::Long;
use Data::Dumper;
use List::Util qw(shuffle min max);

use lib './modules';
use Constants;
use Utils;

unless (caller)
{
  my $file                  = Constants::DEFAULT_TOURNAMENT_URL;
  my $number_of_rounds      = Constants::DEFAULT_NUMBER_OF_ROUNDS;
  my $pairing_method        = Constants::DEFAULT_PAIRING_METHOD;
  my $scoring_method        = Constants::DEFAULT_SCORING_METHOD;
  my $number_of_simulations = Constants::DEFAULT_NUMBER_OF_SIMULATIONS;
  my $reset_round           = Constants::DEFAULT_START_ROUND;
  my $html                  = 0;
  my $all;

  GetOptions (
              "file:s"   => \$file,
              "rounds:s" => \$number_of_rounds,
              "pair:s"   => \$pairing_method,
              "score:s"  => \$scoring_method,
              "sim:s"    => \$number_of_simulations,
              "start:s"  => \$reset_round,
              "html"     => \$html,
              "all"      => \$all
             );

  my $tournament = Tournament->new(
                    $file,
                    $number_of_rounds,
                    $pairing_method,
                    $scoring_method,
                    $number_of_simulations,
                    $reset_round - 1,
                    $html);
  if ($all)
  {
    my $pairing_methods = Constants::PAIRING_METHOD_LIST;
    my $scoring_methods = Constants::SCORING_METHOD_LIST;
    foreach my $pm (@{$pairing_methods})
    {
      foreach my $sm (@{$scoring_methods})
      {
        $tournament->{Constants::TOURNAMENT_SCORING_METHOD} = $sm;
        $tournament->{Constants::TOURNAMENT_PAIRING_METHOD} = $pm;
        $tournament->simulation_reset();
        $tournament->simulate();
      }
    }
  }
  else
  {
    $tournament->simulate();
  }

}

sub new
{
  my $this                = shift;
  my $tournament_file_url = shift;
  my $number_of_rounds    = shift;
  my $pairing_method      = shift;
  my $scoring_method      = shift;
  my $simulations         = shift;
  my $force_current_round = shift;
  my $html                = shift;

  if (!$tournament_file_url)
  {
    $tournament_file_url = Constants::DEFAULT_TOURNAMENT_URL;
    $number_of_rounds    = Constants::DEFAULT_NUMBER_OF_ROUNDS;
    $pairing_method      = Constants::DEFAULT_PAIRING_METHOD;
    $scoring_method      = Constants::DEFAULT_SCORING_METHOD;
    $simulations         = Constants::DEFAULT_NUMBER_OF_SIMULATIONS;
    $force_current_round = Constants::DEFAULT_START_ROUND;
  }
  my $downloads_dir = Constants::DOWNLOADS_DIRECTORY_NAME;
  my $wget_flags    = Constants::WGET_FLAGS;

  my $tournament_file = $downloads_dir . '/' . Utils::sanitize($tournament_file_url);

  system "wget $wget_flags $tournament_file_url -O $tournament_file > /dev/null 2>&1";

  my $reset_round;
  my $number_of_players = 0;
  my @players = ();

  open(my $fh, '<',  $tournament_file) or return "Error: Cannot read file $tournament_file_url";
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
      return "Error: Different number of opponents and scores for $first_name $last_name";
    }
    elsif($reset_round &&
           ($reset_round != $number_of_opponents - 1 ||
            $reset_round != $number_of_scores - 1)
         )
    {
      return "Error: Inconsistent number of opponents or scores between players for at $first_name $last_name";
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
      my $opponent_number = $player_opponents->[$j];
      if ($opponent_number == -1)
      {
        $player_opponents->[$j] = $players[$i];
      }
      else
      {
        $player_opponents->[$j] = $players[$player_opponents->[$j]];
      }
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
      if ($player->{Constants::PLAYER_NUMBER} ==
            $player_opponents->[$j]->{Constants::PLAYER_NUMBER})
      {
        $opponent_score = 0;
      }
      my $spread = $player_score - $opponent_score;
      $player->{Constants::PLAYER_RESET_SPREAD} += $spread;
      if ($player_score > $opponent_score)
      {
        $player->{Constants::PLAYER_RESET_WINS}++;
      }
      elsif ($player_score < $opponent_score)
      {
        $player->{Constants::PLAYER_RESET_LOSSES}++;
      }
      else
      {
        $player->{Constants::PLAYER_RESET_WINS}   += 0.5;
        $player->{Constants::PLAYER_RESET_LOSSES} += 0.5;
      }
    }
    $players[$i]->{Constants::PLAYER_WINS}   =
      $players[$i]->{Constants::PLAYER_RESET_WINS};
    $players[$i]->{Constants::PLAYER_LOSSES} =
      $players[$i]->{Constants::PLAYER_RESET_LOSSES};
    $players[$i]->{Constants::PLAYER_SPREAD} =
      $players[$i]->{Constants::PLAYER_RESET_SPREAD};
    my @player_final_ranks = (0) x $number_of_players;
    $player->{Constants::PLAYER_FINAL_RANKS} = \@player_final_ranks;
  }

  my @scenario_matrix = ();
  for (my $i = 0; $i < $number_of_players; $i++)
  {
    my @rank_scenarios = (undef) x $number_of_players;
    push @scenario_matrix, \@rank_scenarios;
  }

  my %tournament =
    (
     Constants::TOURNAMENT_RESET_ROUND       => $reset_round,
     Constants::TOURNAMENT_NUMBER_OF_ROUNDS  => $number_of_rounds,
     Constants::TOURNAMENT_NUMBER_OF_PLAYERS => $number_of_players,
     Constants::TOURNAMENT_PLAYERS           => \@players,
     Constants::TOURNAMENT_SCENARIO_MATRIX   => \@scenario_matrix, 
     Constants::TOURNAMENT_PAIRING_METHOD    => $pairing_method,
     Constants::TOURNAMENT_SCORING_METHOD    => $scoring_method,

     Constants::TOURNAMENT_CURRENT_ROUND                 => $reset_round,
     Constants::TOURNAMENT_CURRENT_NUMBER_OF_SIMULATIONS => 0,
     Constants::TOURNAMENT_MAXIMUM_NUMBER_OF_SIMULATIONS => $simulations,
     Constants::TOURNAMENT_FILENAME                      => $tournament_file_url,
     Constants::TOURNAMENT_HTML_FORMAT                   => $html
    );
  my $self = bless \%tournament, $this;
  $self->rerank();
  return $self;
}

sub pair
{
  my $this   = shift;
  my $round  = shift;

  my $method = $this->{Constants::TOURNAMENT_PAIRING_METHOD};
  my $players = $this->{Constants::TOURNAMENT_PLAYERS};
  my $number_of_players = $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS};
  my @pairings;
  if ($method eq Constants::PAIRING_METHOD_RANDOM_PAIR)
  {
    @pairings = (0 .. $number_of_players - 1);

    my $player_one;
    my $player_two;
    while (scalar @pairings >= 2)
    {
      $player_one = splice(@pairings, int(rand(scalar @pairings)), 1);
      $player_two = splice(@pairings, int(rand(scalar @pairings)), 1);
      $players->[$player_one]->{Constants::PLAYER_OPPONENTS}->[$round] = 
        $players->[$player_two];
      $players->[$player_two]->{Constants::PLAYER_OPPONENTS}->[$round] = 
        $players->[$player_one];
    }
    if (@pairings)
    {
      $players->[$pairings[0]]->{Constants::PLAYER_OPPONENTS}->[$round] = 
        $players->[$pairings[0]];
      $this->{Constants::TOURNAMENT_BYE_PLAYER} = $pairings[0] + 1;
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
        $this->{Constants::TOURNAMENT_BYE_PLAYER} = $i + 1;
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
            $this->{Constants::TOURNAMENT_BYE_PLAYER} = $i + 1;
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
  my @parameters =
  (
     Constants::TOURNAMENT_FILENAME,
     Constants::TOURNAMENT_RESET_ROUND,
     Constants::TOURNAMENT_NUMBER_OF_ROUNDS,
     Constants::TOURNAMENT_NUMBER_OF_PLAYERS,
     Constants::TOURNAMENT_PAIRING_METHOD,
     Constants::TOURNAMENT_SCORING_METHOD,
     Constants::TOURNAMENT_MAXIMUM_NUMBER_OF_SIMULATIONS
  );

  if (!$this->{Constants::TOURNAMENT_HTML_FORMAT})
  {
    my $pad  = Constants::DEFAULT_NAME_PADDING;
    my $rpad = Constants::DEFAULT_PERCENTAGE_PADDING;
  
    my $result_string = "Simulation Parameters:\n\n";
  
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
  else
  {
    my $div_style    = Constants::TOURNAMENT_DIV_STYLE;
    my $matrix_style = Constants::TOURNAMENT_MATRIX_STYLE;
    my $table_style  = Constants::TOURNAMENT_TABLE_STYLE; 
    my $params_div_id = 'params_div_id';
    my $spaces = '&nbsp;' x 5;
    my $params_table  = "<div id='$params_div_id' class='collapse' $div_style><table>\n<tbody>\n"; 
    for (my $i = 0; $i < scalar @parameters; $i++)
    {
      my $param = $parameters[$i];
      my $value = $this->{$param};
      if ($param eq Constants::TOURNAMENT_RESET_ROUND)
      {
        $value++;
      }
      $params_table .= "<tr><td><b><b>$param:$spaces</b></b></td><td><b>$value</b></td></tr>";
    }
    $params_table .= "</tbody></table></div>";
    my $params_table_expander = Utils::make_expander($params_div_id);
    my $params_string = 
      Utils::make_content_item(
        $params_table_expander,
        '<b><b>Simulation Parameters</b></b>',
        $params_table,
        $div_style);
   
    my $initial_standings_string = "<div $div_style>" . $this->standings() . '</div>';

    my $rank_matrix = "<table style='width: 100%'><tbody><tr><td style='width: 1px'></td>";
    for (my $i = 0; $i < $number_of_players; $i++)
    {
      $rank_matrix .= sprintf "<td><b><b>%s</b></b></td>", $i + 1;
    }
    $rank_matrix .= '</tr>';
    my $corner_radius = '5px';
    my $button_style = "style='color: white; padding: 0px; margin: 0px;'";
    for (my $i = 0; $i < $number_of_players; $i++)
    {
      my $player = $players->[$i];
      my $player_number = $player->{Constants::PLAYER_NUMBER};
      my $name   = $player->{Constants::PLAYER_NAME};
      my $outcome_row  = "<tr style='white-space: nowrap'><td style='text-align: left'><b><b>$name</b></b></td>";
      my $srow_id      = "scenario_row_$i";
      my $pranks = $player->{Constants::PLAYER_FINAL_RANKS};
      my $pranks_length = scalar @{$pranks};
      my $cspan = $pranks_length + 1;
      my $scenario_row = "<tr id='$srow_id'><td style='text-align: center; width: 100%' colspan='$cspan'><div class='accordion' id='$srow_id'>";
      for (my $j = 0; $j < $pranks_length; $j++)
      {
        my $jrank = $pranks->[$j];
        my $cell_color = '#000000'; 
        my $scenario = '';
        my $outcome_content = '';
        my $scenario_id = "scenario_$i"."_$j";
        if ($jrank != 0)
        {
          my $perc = 100 * (sprintf '%.4f', $jrank / $sims) . '%';
          $cell_color = '#00' . (sprintf("%02X", max(int(255/20), int(255*$jrank/$sims)))). '00';
          my $scenario_matrix = $this->{Constants::TOURNAMENT_SCENARIO_MATRIX}->[$player_number]->[$j];
          $scenario = "<br><b><b>Example Scenario of $name finishing in position ".($j + 1)."</b></b><br>$scenario_matrix";
          $outcome_content = "<button class='btn btn-link collapsed' type='button' data-toggle='collapse' data-target='#$scenario_id' aria-expanded='false' aria-controls='$scenario_id' $button_style><b>$perc</b></button>"; 
        }
        my $radius_style = '';
        if ($i == 0)
        {
          if ($j == 0)
          {
            $radius_style = "border-top-left-radius: $corner_radius";
          }
          elsif ($j == $pranks_length - 1)
          {
            $radius_style = "border-top-right-radius: $corner_radius";
          }
        }
        elsif ($i == $number_of_players - 1)
        {
          if ($j == 0)
          {
            $radius_style = "border-bottom-left-radius: $corner_radius";
          }
          elsif ($j == $pranks_length - 1)
          {
            $radius_style = "border-bottom-right-radius: $corner_radius";
          }
        }
        $outcome_row .= "<td style='background-color: $cell_color; $radius_style'>$outcome_content</td>";
        $scenario_row .= "<div id='$scenario_id' class='collapse' data-parent='#$srow_id' style='text-align: center'>$scenario</div>";
      }
      $rank_matrix .= $outcome_row  . '</tr>';
      $rank_matrix .= $scenario_row . '</td></tr>';
    }
    $rank_matrix .= "</tbody></table>";
    $rank_matrix  = "<div $matrix_style><h3><b><b>Rank Matrix</b></b></h3>$rank_matrix</div>";
    return "$params_string $initial_standings_string $rank_matrix";
  }
}

sub record_results
{
  my $this = shift;

  my $players = $this->{Constants::TOURNAMENT_PLAYERS};
  my $number_of_players = $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS};
  my $scenario_string;
  for (my $i = 0; $i < $number_of_players; $i++)
  {
    if (!$players->[$i]->{Constants::PLAYER_FINAL_RANKS}->[$i])
    {
      if (!$scenario_string)
      {
        $scenario_string = $this->scenario();
      }
      $this->{Constants::TOURNAMENT_SCENARIO_MATRIX}->
        [$players->[$i]->{Constants::PLAYER_NUMBER}]->[$i] = $scenario_string;
    }
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
  print $this->get_results();
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

sub scenario
{
  my $this = shift;

  my $players = $this->{Constants::TOURNAMENT_PLAYERS};
  my $div_style    = Constants::TOURNAMENT_DIV_STYLE;
  my $matrix_style = Constants::TOURNAMENT_MATRIX_STYLE;
  my $table_style  = Constants::TOURNAMENT_TABLE_STYLE; 
  my $number_of_players = $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS};
  my $number_of_rounds = $this->{Constants::TOURNAMENT_NUMBER_OF_ROUNDS};
  my $scenario_matrix = "<table style='width: 100%'><tbody><tr><td style='width: 1px'></td>";
  for (my $i = 0; $i < $number_of_rounds; $i++)
  {
    $scenario_matrix .= sprintf "<td><b><b>%s</b></b></td>", $i + 1;
  }
  $scenario_matrix .= '</tr>';
  my $corner_radius = '5px';
  for (my $i = 0; $i < $number_of_players; $i++)
  {
    my $player          = $players->[$i];
    my $name            = $player->{Constants::PLAYER_NAME};
    my $player_scores   = $player->{Constants::PLAYER_SCORES};
    my $opponents       = $player->{Constants::PLAYER_OPPONENTS};
    $scenario_matrix .= "<tr style='white-space: nowrap'><td style='text-align: left'><b><b>$name</b></b></td>";
    for (my $j = 0; $j < $number_of_rounds; $j++)
    {
      my $player_score   = $player_scores->[$j];
      my $opponent       = $opponents->[$j];
      my $opponent_score = $opponent->{Constants::PLAYER_SCORES}->[$j];
      
      my $wl         = 'L';
      my $cell_color = '#000000'; 
      if ($player_score > $opponent_score)
      {
        $wl = 'W';
        $cell_color = '#00CC00';
      }
      elsif ($player->{Constants::PLAYER_NUMBER} == $opponent->{Constants::PLAYER_NUMBER})
      {
        $wl = 'B';
        $cell_color = '#CCCC00';
        $opponent_score = 0;
      }
      elsif ($player_score == $opponent_score)
      {
        $wl = 'T';
        $cell_color = '#0000CC';
      }
      my $scores     = "$player_score - $opponent_score";
      my $cell_content = "$wl";
      my $radius_style = '';
      if ($i == 0)
      {
        if ($j == 0)
        {
          $radius_style = "border-top-left-radius: $corner_radius";
        }
        elsif ($j == $number_of_rounds - 1)
        {
          $radius_style = "border-top-right-radius: $corner_radius";
        }
      }
      elsif ($i == $number_of_players - 1)
      {
        if ($j == 0)
        {
          $radius_style = "border-bottom-left-radius: $corner_radius";
        }
        elsif ($j == $number_of_rounds - 1)
        {
          $radius_style = "border-bottom-right-radius: $corner_radius";
        }
      }
      $scenario_matrix .= "<td style='background-color: $cell_color; $radius_style'><b>$cell_content</b></td>";
    }
    $scenario_matrix .= '</tr>';
  }
  $scenario_matrix .= "</tbody></table>";
  $scenario_matrix  = "<div $matrix_style>$scenario_matrix</div>";
  return $scenario_matrix;
}

sub score
{
  my $this = shift;
  my $round = shift;


  my $method = $this->{Constants::TOURNAMENT_SCORING_METHOD};
  my $players = $this->{Constants::TOURNAMENT_PLAYERS};
  my $number_of_players = $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS};
  my $bye_player = $this->{Constants::TOURNAMENT_BYE_PLAYER};

  my $win;
  my $player_score;
  my $opponent_score;

  if ($method eq Constants::SCORING_METHOD_RANDOM_UNIFORM)
  {
    for (my $i = 0; $i < $number_of_players; $i++)
    {
      $players->[$i]->{Constants::PLAYER_SCORES}->[$round] = 300 + int(rand(300));
    }
  }
  elsif($method eq Constants::SCORING_METHOD_RANDOM_BLOWOUTS)
  {
    my @scored = (0) x $number_of_players;
    my $blowout_scores = Constants::BLOWOUT_SCORES;
    my $random_index;
    for (my $i = 0; $i < $number_of_players; $i++)
    {
      if (!$scored[$players->[$i]->{Constants::PLAYER_NUMBER}])
      {
        # Make blowouts predefined
        $random_index = int(rand(2));

        $players->[$i]->{Constants::PLAYER_SCORES}->[$round]  = $blowout_scores->[$random_index];
        $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$round]->
          {Constants::PLAYER_SCORES}->[$round] = 1 - $blowout_scores->[$random_index];

        $scored[$players->[$i]->{Constants::PLAYER_NUMBER}] = 1;
        $scored[$players->[$i]->{Constants::PLAYER_OPPONENTS}->
                 [$round]->{Constants::PLAYER_NUMBER}] = 1;
      }
    }    
  }
  elsif($method eq Constants::SCORING_METHOD_RANDOM_BST)
  {
    my @scored = (0) x $number_of_players;
    my $bst_scores = Constants::BST_SCORES;
    my $l = scalar @{$bst_scores};
    my $random_index;
    my $random_pair;
    for (my $i = 0; $i < $number_of_players; $i++)
    {
      if (!$scored[$players->[$i]->{Constants::PLAYER_NUMBER}])
      {
        # Make blowouts predefined
        $random_pair = int(rand($l));
        $random_index = int(rand(2));

        $players->[$i]->{Constants::PLAYER_SCORES}->[$round]  =
          $bst_scores->[$random_pair]->[$random_index];
        
        $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$round]->
          {Constants::PLAYER_SCORES}->[$round] =
          $bst_scores->[$random_pair]->[1 - $random_index];

        $scored[$players->[$i]->{Constants::PLAYER_NUMBER}] = 1;
        #print "Player name: " . "$players->[$i]->{Constants::PLAYER_NAME}"."\n";
        #print "Player opp: " . "$players->[$i]->{Constants::PLAYER_OPPONENTS}->[$round]->{Constants::PLAYER_NAME}" . "\n";
        $scored[$players->[$i]->{Constants::PLAYER_OPPONENTS}->[$round]->{Constants::PLAYER_NUMBER}] = 1;
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
            int (
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
    if ($bye_player && $i == $bye_player - 1)
    {
      $players->[$i]->{Constants::PLAYER_SCORES}->[$round] = Constants::DEFAULT_BYE_SCORE;
      $players->[$i]->{Constants::PLAYER_SPREAD} += Constants::DEFAULT_BYE_SCORE;
      $players->[$i]->{Constants::PLAYER_WINS}   += 1;
    }
    else
    {
      $player_score = $players->[$i]->{Constants::PLAYER_SCORES}->[$round];
      $opponent_score = $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$round]->
        {Constants::PLAYER_SCORES}->[$round];
      $players->[$i]->{Constants::PLAYER_SPREAD} += $player_score - $opponent_score;
      $win = (($player_score <=> $opponent_score) + 1) / 2;
      $players->[$i]->{Constants::PLAYER_WINS}   += $win;
      $players->[$i]->{Constants::PLAYER_LOSSES} += 1 - $win;
    }
  }
}

sub standings
{
  my $this = shift;
  $this->rerank();
  if (!$this->{Constants::TOURNAMENT_HTML_FORMAT})
  {
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
  else
  {
    my $table_style = Constants::TOURNAMENT_TABLE_STYLE;
    my $div_style   = Constants::TOURNAMENT_DIV_STYLE;
    my $players = $this->{Constants::TOURNAMENT_PLAYERS};
    my $number_of_players = $this->{Constants::TOURNAMENT_NUMBER_OF_PLAYERS};
    my $spaces = '&nbsp;' x 5;
    my $init_div_id = 'init_div_id';
    my $title_row = join "", (map {"<td><b><b>$_$spaces</b></b></td>"} ('Rank','Player', 'Wins', 'Losses', 'Spread'));
    my $standings_string =
     "<div id='$init_div_id' class='collapse' $div_style>\n<table>\n<tbody>
        <tr>$title_row</tr>"; 
    for (my $i = 0; $i < $number_of_players; $i++)
    {
      my $wins   = $players->[$i]->{Constants::PLAYER_WINS};
      my $losses = $players->[$i]->{Constants::PLAYER_LOSSES};
      my $spread = $players->[$i]->{Constants::PLAYER_SPREAD}; 
      my $name   = $players->[$i]->{Constants::PLAYER_NAME};
      
      #my $this_round = $this->{Constants::TOURNAMENT_CURRENT_ROUND};
      #my $pscore = $players->[$i]->{Constants::PLAYER_SCORES}->[$this_round];
      #my $oscore = $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$this_round]
      #    ->{Constants::PLAYER_SCORES}->[$this_round];
      #my $opp = $players->[$i]->{Constants::PLAYER_OPPONENTS}->[$this_round]->{Constants::PLAYER_NAME};
      #my $last = "$pscore - $oscore against $opp";
      my $row = join "", (map {"<td><b>$_$spaces</b></td>"} ($i + 1, $name, $wins, $losses, $spread));
      $standings_string .= "<tr>$row</tr>";
    }
    $standings_string .= "</tbody>\n</table>\n</div>";
    my $init_table_expander = Utils::make_expander($init_div_id);
    return
      Utils::make_content_item(
        $init_table_expander,
        '<b><b>Initial Standings</b></b>',
        $standings_string);
  }
}

sub trim
{
  my $s = shift;
  $s =~ s/^\s+|\s+$//g;
  return $s;
}
