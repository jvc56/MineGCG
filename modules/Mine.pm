#!/usr/bin/perl

package Mine;

use warnings;
use strict;
use Data::Dumper;

use lib "./objects"; 
use lib "./modules";
use lib "./data";

use Constants;
use Stats;
use Utils;
use NameConversion;
use JSON::XS;

sub mine
{
  my $stats_dir               = Constants::STATS_DIRECTORY_NAME;
  my $notable_dir             = Constants::NOTABLE_DIRECTORY_NAME;
  my $blacklisted_tournaments = Constants::BLACKLISTED_TOURNAMENTS;
  my $cache_dir               = Constants::CACHE_DIRECTORY_NAME;
  my $names_to_info_hashref   = NameConversion::NAMES_TO_IDS;

  my $dbh = Utils::connect_to_database();

  my $player_name       = shift;
  my $cort              = shift;
  my $single_game_id    = shift;
  my $opponent_name     = shift;
  my $startdate         = shift;
  my $enddate           = shift;
  my $lexicon           = shift;
  my $verbose           = shift;
  my $tourney_id        = shift;
  my $statsdump         = shift;
  my $html              = shift;
  my $missingracks      = shift;



  if ($startdate)
  {
    $startdate = substr($startdate, 4, 8) . '-' . substr($startdate, 0, 2) . '-' . substr($startdate, 2, 2);
  }

  if ($enddate)
  {
    $enddate = substr($enddate, 4, 8) . '-' . substr($enddate, 0, 2) . '-' . substr($enddate, 2, 2);
  }


  my $sanitized_player_name = Utils::sanitize($player_name);

  my $cache_filename = "$cache_dir/$sanitized_player_name.html";
  my $cache_condition = !$cort &&
                        !$single_game_id &&
                        !$opponent_name &&
                        !$startdate &&
                        !$enddate &&
                        !$lexicon &&
                        !$tourney_id &&
                        $html;

  if (!$statsdump && $cache_condition && -e $cache_filename)
  {
    my $game_string = "";
    open(GAME, '<', $cache_filename);
    while (<GAME>)
    {
      $game_string .= $_;
    }
    print $game_string;
    return;
  }

  my $player_id          = $names_to_info_hashref->{$sanitized_player_name}->[0];
  my $player_pretty_name = $names_to_info_hashref->{$sanitized_player_name}->[1];
  my $player_photo       = $names_to_info_hashref->{$sanitized_player_name}->[2];

  if (!$player_id)
  {
    print STDERR "Player ID not found for $player_name\n";
    return;
  }
  my $all_stats = Stats->new(1);

  my %tourney_game_hash;
  my $at_least_one = 0;

  my $games_table   = Constants::GAMES_TABLE_NAME;
  my $players_table = Constants::PLAYERS_TABLE_NAME;

  my $player_sanitized_name_column_name           = Constants::PLAYER_SANITIZED_NAME_COLUMN_NAME;
  my $player_cross_tables_id_column_name          = Constants::PLAYER_CROSS_TABLES_ID_COLUMN_NAME;
  my $game_cross_tables_id_column_name            = Constants::GAME_CROSS_TABLES_ID_COLUMN_NAME;
  my $game_player1_cross_tables_id_column_name    = Constants::GAME_PLAYER_ONE_CROSS_TABLES_ID_COLUMN_NAME;
  my $game_player2_cross_tables_id_column_name    = Constants::GAME_PLAYER_TWO_CROSS_TABLES_ID_COLUMN_NAME;
  my $game_player1_name_column_name               = Constants::GAME_PLAYER_ONE_NAME_COLUMN_NAME;
  my $game_player2_name_column_name               = Constants::GAME_PLAYER_TWO_NAME_COLUMN_NAME;
  my $game_cross_tables_tournament_id_column_name = Constants::GAME_CROSS_TABLES_TOURNAMENT_ID_COLUMN_NAME;
  my $game_lexicon_column_name                    = Constants::GAME_LEXICON_COLUMN_NAME;
  my $game_round_column_name                      = Constants::GAME_ROUND_COLUMN_NAME;
  my $game_name_column_name                       = Constants::GAME_NAME_COLUMN_NAME;
  my $game_date_column_name                       = Constants::GAME_DATE_COLUMN_NAME;
  my $game_stats_column_name                      = Constants::GAME_STATS_COLUMN_NAME;
  my $game_error_column_name                      = Constants::GAME_ERROR_COLUMN_NAME;
  my $game_warning_column_name                    = Constants::GAME_WARNING_COLUMN_NAME;

  my $opp_table_statement = "";
  my $opp_query           = "";

  if ($opponent_name)
  {
    my $opp_id = $names_to_info_hashref->{Utils::sanitize($opponent_name)}->[0];
    $opp_query =
    "
      AND opp.$player_cross_tables_id_column_name = $opp_id
      AND
         (
          opp.$player_cross_tables_id_column_name = g.$game_player1_cross_tables_id_column_name OR
          opp.$player_cross_tables_id_column_name = g.$game_player2_cross_tables_id_column_name
         )
    ";

    $opp_table_statement = " , $players_table AS opp ";
  } 

  my $games_query =
  "
  SELECT 
       $game_player1_name_column_name,
       $game_player2_name_column_name,
       $game_error_column_name,
       $game_warning_column_name,
       $game_player1_cross_tables_id_column_name,
       $game_player2_cross_tables_id_column_name,
       $game_stats_column_name,
       $game_cross_tables_id_column_name,
       $game_cross_tables_tournament_id_column_name,
       $game_round_column_name
  FROM $games_table AS g, $players_table AS p $opp_table_statement
  WHERE
        p.$player_cross_tables_id_column_name = $player_id AND
        (
         g.$game_player1_cross_tables_id_column_name =
         p.$player_cross_tables_id_column_name
         OR
         g.$game_player2_cross_tables_id_column_name =
         p.$player_cross_tables_id_column_name
        )
  $opp_query
  ";

  if ($single_game_id)
  {
    $games_query .= " AND g.$game_cross_tables_id_column_name = $single_game_id";
  }
  if ($tourney_id)
  {
    $games_query .= " AND g.$game_cross_tables_tournament_id_column_name = $tourney_id";
  }
  if ($startdate)
  {
    $games_query .= " AND g.$game_date_column_name >= '$startdate'";
  }
  if ($enddate)
  {
    $games_query .= " AND g.$game_date_column_name <= '$enddate'";
  }
  if ($lexicon)
  {
    $games_query .= " AND g.$game_lexicon_column_name = '$lexicon'";
  }
  if ($cort eq Constants::TOURNAMENT_OPTION)
  {
    $games_query .= " AND g.$game_cross_tables_tournament_id_column_name > 0";
  }
  elsif ($cort eq Constants::CASUAL_OPTION)
  {
    $games_query .= " AND g.$game_cross_tables_tournament_id_column_name = 0";
  }

  my @game_results = @{$dbh->selectall_arrayref($games_query, {Slice => {}, "RaiseError" => 1})};
  my $num_games    = 0;
  my $num_errors   = 0;
  my $num_warnings = 0;
  my %duplicates   = ();

  while (@game_results)
  {
    my $game = shift @game_results;

    my $error      = $game->{$game_error_column_name};
    my $warning    = $game->{$game_warning_column_name};
    my $tournament = $game->{$game_cross_tables_tournament_id_column_name};
    my $round      = $game->{$game_round_column_name};
    my $dupkey;
    if ($tournament && $round)
    {
      $dupkey = $tournament . '-' . $round;
    }

    my $game_opp_name = $game->{$game_player2_name_column_name};
    my $player_is_first = 1;
   
    my $player2_id = $game->{$game_player2_cross_tables_id_column_name};

    if ($player2_id && $player_id == $player2_id)
    {
      $player_is_first = 0;
      $game_opp_name = $game->{$game_player1_name_column_name};
    }
    
    my $game_id = $game->{$game_cross_tables_id_column_name};

    if ($error)
    {
      $all_stats->addError($error);
      $num_errors++;
      next;
    }
    elsif ($warning)
    {
      $all_stats->addError($warning, 1);
      $num_warnings++;
    }
    
    if ($dupkey)
    {
      if ($duplicates{$dupkey})
      {
        $all_stats->addError("$game_id;0;Duplicate game detected (Tournament $tournament, Round $round).", 1);
        $num_warnings++;
      }
      else
      {
        $duplicates{$dupkey} = 1;
      }
    }

    my $game_stat = Stats->new($player_is_first, $game->{$game_stats_column_name});

    $all_stats->addStat($game_stat);
    $num_games++;
    $at_least_one = 1;
  }

  if ($statsdump && $at_least_one)
  {
    my $dump = JSON::XS::encode_json(Utils::prepare_stats($all_stats));
    Utils::update_player_record($dbh, $player_id, 0, 0, $dump, $num_games);
  }

  # Make error stats here
  my $html_string = '';
  if ($at_least_one)
  {
    $html_string .= $all_stats->toString($html);
  }
  else
  {
    # Print no games page or something
  }

  my $head_content = Constants::HTML_HEAD_CONTENT;
  my $nav          = Constants::HTML_NAV;
  my $default_scripts = Constants::HTML_SCRIPTS;
  my $body_style        = Constants::HTML_BODY_STYLE;
  my $javascript = Constants::RESULTS_PAGE_JAVASCRIPT;
  my $toggle_icon_script = Constants::TOGGLE_ICON_SCRIPT;
  my $html_styles         = Constants::HTML_STYLES;
  my $table_sort_function             = Constants::TABLE_SORT_FUNCTION;
  my $html_table_and_collapse_scripts = Constants::HTML_TABLE_AND_COLLAPSE_SCRIPTS;
  my $csv_download_scripts            = Constants::CSV_DOWNLOAD_SCRIPTS;
  my $footer = Constants::HTML_FOOTER;

  my $search_params =
    make_search_params_table
    ([
      ['Type', $cort],
      ['Game ID', $single_game_id],
      ['Opponent', $opponent_name],
      ['Lexicon', $lexicon],
      ['Tournament', $tourney_id],
      ['Start Date', $startdate],
      ['End Date',   $enddate]
    ]);

  if($search_params)
  {
    $search_params = make_infobox('Search Parameters', $search_params);
    $search_params = "<td style='vertical-align: top'>$search_params</td>";
  }

  my $total_games    = make_infobox('Games', $num_games);
  my $total_errors   = make_infobox('Errors', $num_errors);
  my $total_warnings = make_infobox('Warnings', $num_warnings);

  my $color_key = make_color_key();

  my $player_header_style =
  "
  style=
  '
    background-color: #22262a;
  '
  ";

  my $player_inner_header_style =
  "
  style=
  '
    width: 90%;
    margin: auto;
    padding: 20px;
  '
  "
  ;

  my $img_style = 
  "
  style='
    padding: 10px;
    background-color: #666666;
    border-radius: 20px;
    '
  ";

  # Put player stats header here, include color key
  my $player_header = <<PLAYERHEADER
  <div $player_header_style>
    <div $player_inner_header_style>
      <table style='margin: auto'>
        <tbody>
          <tr>
           <td><div style='margin: auto; text-align: center;'><img src='$player_photo' alt='$player_pretty_name' $img_style></div></td>
          </tr>
          <tr>
           <td>
             <table>
             <tbody>
             <tr>
               <td colspan='3' style='font-size: 20px; text-align: center;'>
                 <b>$player_pretty_name</b>
               </td>
             </tr>
             <tr>
               <td>
                 $total_games
               </td>
               <td>
                 $total_errors
               </td>
               <td>
                 $total_warnings
               </td>
             </tr>
             </tbody>
             </table>
           </td>
          </tr>
        </tbody>
      </table>
    </div>
    <div style='width: 100%' id='collapseKey' class="collapse">
      <table style='margin: auto'>
        <tr>
          $search_params
          <td style='vertical-align: top'>$color_key</td>
        </tr>
      </table>
    </div>
    <div style="text-align: center">
      <a data-toggle="collapse" data-target="#collapseKey"
        aria-expanded="false" aria-controls="collapseOptions" onclick='toggle_icon(this, "collapseKey", true)'>
        Show More<br><i class="fas fa-angle-down rotate-icon"></i>
      </a>
    </div>

  </div>
PLAYERHEADER
;


  my $final_output = <<FINAL

<!DOCTYPE html>
<html lang="en">
  <head>
  $head_content
  $html_styles
  </head>
  <body $body_style>
  $nav
  $player_header
  $html_string
  $default_scripts
  $toggle_icon_script
  $table_sort_function
  $html_table_and_collapse_scripts
  $csv_download_scripts
  $footer
  </body>
</html>
FINAL
;

  if ($cache_condition && $at_least_one && $statsdump)
  {
    system "mkdir -p $cache_dir";
    open(my $fh, '>', $cache_filename);
    print $fh $final_output; 
    close $fh;
  }

  print $final_output;
}

sub make_search_params_table
{
  my $params = shift;
  my $content = '';
  for (my $i = 0; $i < scalar @{$params}; $i++)
  {
    my $item = $params->[$i];
    my $title = $item->[0];
    my $value = $item->[1];
    if ($value)
    {
      $content .= "<tr><td>$title</td><td>$value</td></tr>\n";
    }
  }
  if ($content)
  {
    return "<table><tbody>$content</tbody></table>";
  }
  return '';
}

sub make_color_key
{
  my @colors_and_titles =
  (
    [Constants::TRIPLE_TRIPLE_COLOR, 'Triple Triple'],
    [Constants::NINE_OR_ABOVE_COLOR, 'Bingo 9+'],
    [Constants::IMPROBABLE_COLOR,    'Improbable'],
    [Constants::TRIPLE_TRIPLE_NINE_COLOR, 'Triple Triple and Bingo Nine or Above', [0, 1]],
    [Constants::IMPROBABLE_NINE_OR_ABOVE_COLOR, 'Improbable and Bingo Nine or Above', [2, 1]],
    [Constants::IMPROBABLE_TRIPLE_TRIPLE_COLOR, 'Triple Triple and Improbable', [0, 2]],
    [Constants::ALL_THREE_COLOR,               'Triple Triple and Bingo Nine or Above and Improbable', [0, 1, 2]]
  );
  
  my $color_key = '<table class="infobox"><tbody><tr><td>Color Key</td></tr><tr><td class="content_td"><table><tbody>';
  for (my $i = 0; $i < scalar @colors_and_titles; $i++)
  {
    my $item     = $colors_and_titles[$i];
    my $color    = $item->[0];
    my $title    = $item->[1];
    my $listref  = $item->[2];
    my @list;
    
    if ($listref)
    {
      @list = @{$listref};
      $title = '';
      for (my $k = 0; $k < scalar @list; $k++)
      {
        my $color_part = $colors_and_titles[$list[$k]]->[0];
        my $style_part = Utils::get_color_dot_style($color_part);
        $title .= " <span $style_part></span> +";
      }
      chop($title);
    }

    my $style = Utils::get_color_dot_style($color);
    my $td_style = "style='text-align: center; padding-left: 10px; padding-right: 10px'";
    $color_key .= "<tr class='content_td'><td $td_style><span $style></span></td><td $td_style> = </td><td $td_style>$title</td></tr>";
  }
  $color_key .= '</tbody></table></td></tr></tbody></table>';
  return $color_key;
}

sub make_infobox
{
  my $title   = shift;
  my $content = shift;

  my $html = <<HTML
  <div>
  <table class='infobox'>
    <tbody>
    <tr><td>$title</td></tr>
    <tr><td class='content_td'>$content</td></tr>
    </tbody>
  </table>
  </div>
HTML
;
  return $html;
}


1;

