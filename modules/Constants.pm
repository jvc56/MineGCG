#!/usr/bin/perl

package Constants;

use warnings;
use strict;

use constant RR_IP_ADDRESS                    => '3.13.229.56';
use constant RR_HOSTNAME                      => 'randomracer.com';
use constant RR_USERNAME                      => 'ubuntu';

use constant SSH_ARGS                         => ' -i /home/jvc/randomracer-keypair1.pem ';

use constant VM_SSH_ARGS                      => ' -i /home/ubuntu/vm.pem -p 2222 ';
use constant VM_IP_ADDRESS                    => 'ocs.wgvc.com';
use constant VM_USERNAME                      => 'jvc';

use constant RR_NOTABLE_NAME                  => 'notable.html';
use constant RR_LEADERBOARD_NAME              => 'leaderboard.html';

use constant RR_LOGS_SOURCE                   => '/var/log/apache2/';
use constant RR_WORKING_DIR                   => '/home/ubuntu/';
use constant RR_REAL_DIR                      => '/var/www/';
use constant SEND_TO_REMOTE_DIR               => './remote';

use constant RR_NOTABLE_DEST                  => RR_WORKING_DIR . RR_NOTABLE_NAME;
use constant RR_LEADERBOARD_DEST              => RR_WORKING_DIR . RR_LEADERBOARD_NAME;

use constant WGET_FLAGS                       => '--no-check-certificate';
use constant CROSS_TABLES_URL                 => 'http://www.cross-tables.com/';
use constant QUERY_URL_PREFIX                 => 'http://www.cross-tables.com/players.php?query=';
use constant RR_URL_PREFIX                    => 'http://' . RR_HOSTNAME . '/cgi-bin/mine_webapp.pl?name=';
use constant CACHE_URL_PREFIX                 => 'http://' . RR_HOSTNAME . '/cache/';
use constant ANNOTATED_GAMES_URL_PREFIX       => 'http://www.cross-tables.com/anno.php?p=';
use constant SINGLE_ANNOTATED_GAME_URL_PREFIX => 'http://www.cross-tables.com/annotated.php?u=';
use constant CROSS_TABLES_COUNTRY_PREFIX      => 'http://www.cross-tables.com/bycountry.php?country=';
use constant ANNOTATED_GAMES_PAGE_NAME        => 'anno_page.html';
use constant QUERY_RESULTS_PAGE_NAME          => 'query_results.html';
use constant HTML_GAME_NAME                   => 'annotated_game.html';
use constant DOWNLOADS_DIRECTORY_NAME         => './downloads';
use constant STATS_DIRECTORY_NAME             => './stats';
use constant NOTABLE_DIRECTORY_NAME           => './notable';
use constant CACHE_DIRECTORY_NAME             => './cache';
use constant HTML_DIRECTORY_NAME              => './html';
use constant CGIBIN_DIRECTORY_NAME            => './cgi-bin';
use constant DATA_DIRECTORY_NAME              => './data';
use constant LOGS_DIRECTORY_NAME              => './logs';
use constant HTML_STATIC_DIRECTORY_NAME       => './html_static';
use constant LEGACY_DIRECTORY_NAME            => './legacy';
use constant NAME_ID_DATA_FILENAME            => 'NameConversion.pm';
use constant NAME_ID_VARIABLE_NAME            => 'NAMES_TO_IDS';
use constant BLACKLISTED_TOURNAMENTS          => {
                                                    '9194' => 1 # Can-Am Match 08/29/15
                                                 };

use constant TOURNAMENT_OPTION                => 'Tournament';
use constant CASUAL_OPTION                    => 'Casual';

use constant CHART_TAB_NAME                   => 'Win Correlation';

use constant ANNOTATED_GAMES_API_CALL         => 'http://cross-tables.com/rest/allanno.php';
use constant PLAYER_INFO_API_CALL             => 'http://cross-tables.com/rest/player.php?player=';
use constant TOURNAMENT_INFO_API_CALL         => 'http://cross-tables.com/rest/tourney.php?tourney=';

use constant CGI_SCRIPT_FILENAME              => 'mine_webapp.pl';
use constant INDEX_HTML_FILENAME              => 'index.html';

use constant GAME_TYPE_CASUAL                 => 'Casual';
use constant GAME_TYPE_TOURNAMENT             => 'Tournament';

use constant PLAYER_FIELD_NAME                => 'name';
use constant CORT_FIELD_NAME                  => 'cort';
use constant GAME_ID_FIELD_NAME               => 'game-id';
use constant TOURNAMENT_ID_FIELD_NAME         => 'tournament-id';
use constant OPPONENT_FIELD_NAME              => 'opponent';
use constant START_DATE_FIELD_NAME            => 'start-date';
use constant END_DATE_FIELD_NAME              => 'end-date';
use constant LEXICON_FIELD_NAME               => 'lexicon';
use constant DIRECTORY_FIELD_NAME             => 'directory';

use constant SEARCH_DATA_FILENAME             => 'search_data.html';

use constant INACTIVE_PLAYERS =>
(
  "Avery Mojica"
);

use constant DEV_ENV_KEYWORD                  => 'dev';
use constant UPDATE_OPTION_GCG                => 'gcg';
use constant UPDATE_OPTION_STATS              => 'stats';
use constant UPDATE_OPTION_KEYS               => 'keys';

use constant DATABASE_DRIVER   => 'Pg';
use constant DATABASE_NAME     => 'minegcg';
use constant DATABASE_HOSTNAME => 'localhost';
use constant DATABASE_USERNAME => 'postgres';
use constant DATABASE_PASSWORD => 'password';

use constant PLAYERS_TABLE_NAME => 'players';
use constant GAMES_TABLE_NAME   => 'games';

use constant CACHEFILE_EXTENSION => ".html";

use constant TABLE_CREATION_ORDER =>
[
  Constants::PLAYERS_TABLE_NAME,
  Constants::GAMES_TABLE_NAME
];

use constant PLAYER_ID_COLUMN_NAME                         => 'player_id';
use constant PLAYER_CROSS_TABLES_ID_COLUMN_NAME            => 'player_cross_tables_id';
use constant PLAYER_NAME_COLUMN_NAME                       => 'player_name';
use constant PLAYER_SANITIZED_NAME_COLUMN_NAME             => 'player_sanitized_name';
use constant PLAYER_TOTAL_GAMES_COLUMN_NAME                => 'player_total_games';
use constant PLAYER_STATS_COLUMN_NAME                      => 'player_stats';
use constant GAME_ID_COLUMN_NAME                           => 'game_id';
use constant GAME_PLAYER_ONE_CROSS_TABLES_ID_COLUMN_NAME   => 'game_player1_cross_tables_id';
use constant GAME_PLAYER_TWO_CROSS_TABLES_ID_COLUMN_NAME   => 'game_player2_cross_tables_id';
use constant GAME_PLAYER_ONE_NAME_COLUMN_NAME              => 'game_player1_name';
use constant GAME_PLAYER_TWO_NAME_COLUMN_NAME              => 'game_player2_name';
use constant GAME_CROSS_TABLES_ID_COLUMN_NAME              => 'game_cross_tables_id';
use constant GAME_GCG_COLUMN_NAME                          => 'game_gcg';
use constant GAME_STATS_COLUMN_NAME                        => 'game_stats';
use constant GAME_CROSS_TABLES_TOURNAMENT_ID_COLUMN_NAME   => 'game_tournament_cross_tables_id';
use constant GAME_LEXICON_COLUMN_NAME                      => 'game_lexicon';
use constant GAME_ROUND_COLUMN_NAME                        => 'game_round';
use constant GAME_NAME_COLUMN_NAME                         => 'game_name';
use constant GAME_DATE_COLUMN_NAME                         => 'game_date';
use constant GAME_ERROR_COLUMN_NAME                        => 'game_error';
use constant GAME_WARNING_COLUMN_NAME                      => 'game_warning';

use constant STATS_PLAYER_IS_FIRST_KEY_NAME      => 'player_is_first';
use constant STATS_DATA_KEY_NAME                 => 'data';
use constant STATS_DATA_PLAYER_ONE_KEY_NAME      => 'player1';
use constant STATS_DATA_PLAYER_TWO_KEY_NAME      => 'player2';
use constant STATS_DATA_GAME_KEY_NAME            => 'game';
use constant STATS_DATA_NOTABLE_KEY_NAME         => 'notable';
use constant STATS_DATA_ERROR_KEY_NAME           => 'error';

use constant DATABASE_TABLES =>
{
  Constants::PLAYERS_TABLE_NAME =>
  [
    Constants::PLAYER_ID_COLUMN_NAME              . " SERIAL PRIMARY  KEY",
    Constants::PLAYER_CROSS_TABLES_ID_COLUMN_NAME . " INT NOT NULL UNIQUE",
    Constants::PLAYER_NAME_COLUMN_NAME            . " VARCHAR(255)",
    Constants::PLAYER_SANITIZED_NAME_COLUMN_NAME  . " VARCHAR(255)",
    Constants::PLAYER_TOTAL_GAMES_COLUMN_NAME     . " INT",
    Constants::PLAYER_STATS_COLUMN_NAME           . " JSON"
  ],
  Constants::GAMES_TABLE_NAME   =>
  [
    Constants::GAME_ID_COLUMN_NAME                         . " SERIAL PRIMARY KEY",
    Constants::GAME_PLAYER_ONE_CROSS_TABLES_ID_COLUMN_NAME . " INT REFERENCES " . Constants::PLAYERS_TABLE_NAME . " (" . Constants::PLAYER_CROSS_TABLES_ID_COLUMN_NAME . ")",
    Constants::GAME_PLAYER_TWO_CROSS_TABLES_ID_COLUMN_NAME . " INT REFERENCES " . Constants::PLAYERS_TABLE_NAME . " (" . Constants::PLAYER_CROSS_TABLES_ID_COLUMN_NAME . ")",
    Constants::GAME_PLAYER_ONE_NAME_COLUMN_NAME            . " TEXT",
    Constants::GAME_PLAYER_TWO_NAME_COLUMN_NAME            . " TEXT",
    Constants::GAME_CROSS_TABLES_ID_COLUMN_NAME            . " INT NOT NULL UNIQUE",
    Constants::GAME_GCG_COLUMN_NAME                        . " TEXT",
    Constants::GAME_STATS_COLUMN_NAME                      . " JSON",
    Constants::GAME_CROSS_TABLES_TOURNAMENT_ID_COLUMN_NAME . " INT",
    Constants::GAME_LEXICON_COLUMN_NAME                    . " VARCHAR(5)",
    Constants::GAME_ROUND_COLUMN_NAME                      . " INT",
    Constants::GAME_NAME_COLUMN_NAME                       . " TEXT",
    Constants::GAME_DATE_COLUMN_NAME                       . " DATE",
    Constants::GAME_ERROR_COLUMN_NAME                      . " TEXT",
    Constants::GAME_WARNING_COLUMN_NAME                    . " TEXT",
  ]
};

use constant UNSPECIFIED_MISTAKE_NAME => 'Unspecified';

use constant MISTAKES =>
(
  'Knowledge',
  'Finding',
  'Vision',
  'Tactics',
  'Strategy',
  'Endgame',
  'Time',
  'Focus'
);

use constant MISTAKES_MAGNITUDE =>
{
  'Large'   => 'Large',
  'Medium'  => 'Medium',
  'Small'   => 'Small',

  'Saddest' => 'Large',
  'Sadder'  => 'Medium',
  'Sad'     => 'Small'
};

use constant MISTAKES_ORDER =>
(
  'Large',
  'Medium',
  'Small',
  UNSPECIFIED_MISTAKE_NAME
);

use constant MISTAKE_COLORS =>
{
  'Knowledge' => 'yellow',
  'Finding'   => 'cyan',
  'Vision'    => 'orange',
  'Tactics'   => 'red',
  'Strategy'  => 'green',
  'Endgame'   => 'purple',
  'Time'      => 'magenta',
  'Focus'     => 'blue'
};



use constant PRELOAD_COUNTRIES =>
(
  'ARE',
  'AUS',
  'BHR',
  'BRB',
  'CAN',
  'DEU',
  'ENG',
  'GBR',
  'IND',
  'ISR',
  'JPN',
  'MYS',
  'NGA',
  'NIR',
  'SGP',
  'USA'
);

use constant MONTH_TO_NUMBER_HASHREF =>
{
  Jan => 1,
  Feb => 2,
  Mar => 3,
  Apr => 4,
  May => 5,
  Jun => 6,
  Jul => 7,
  Aug => 8,
  Sep => 9,
  Oct => 10,
  Nov => 11,
  Dec => 12
};

use constant STAT_ITEM_GAME            => 'GAME STATS';
use constant STAT_ITEM_PLAYER          => 'YOUR STATS';
use constant STAT_ITEM_OPP             => 'OPPONENT STATS';
use constant STAT_ITEM_LIST_PLAYER     => 'YOUR LISTS';
use constant MISTAKE_ITEM_LIST_PLAYER  => 'YOUR MISTAKES';
use constant MISTAKE_ITEM_LIST_OPP     => 'OPPONENT MISTAKES';
use constant STAT_ITEM_LIST_OPP        => 'OPPONENT LISTS';
use constant STAT_ITEM_LIST_NOTABLE    => 'NOTABLE GAMES';

use constant MISTAKE_ITEM_LIST         => 'MISTAKE LIST';
use constant STAT_ITEM_LIST            => 'STATS LIST';


use constant ERROR_DIV_ID              => 'error';
use constant MISTAKES_DIV_ID           => 'mistakes';

use constant LEADERBOARD_CUTOFF         => 10;
use constant LEADERBOARD_COLUMN_SPACING => 31;
use constant LEADERBOARD_NAME           => "leaderboard";
use constant LEADERBOARD_MIN_GAMES      => 50;

use constant MISTAKES_REEL_LENGTH       => 200;

use constant NOTABLE_NAME               => "notable";


use constant INDEX_COLUMN_MAPPING =>
{
    0 => 'A',
    1 => 'B',
    2 => 'C',
    3 => 'D',
    4 => 'E',
    5 => 'F',
    6 => 'G',
    7 => 'H',
    8 => 'I',
    9 => 'J',
    10 => 'K',
    11 => 'L',
    12 => 'M',
    13 => 'N',
    14 => 'O'
};

use constant COLUMN_INDEX_MAPPING =>
{
    'A' => 0,
    'B' => 1,
    'C' => 2,
    'D' => 3,
    'E' => 4,
    'F' => 5,
    'G' => 6,
    'H' => 7,
    'I' => 8,
    'J' => 9,
    'K' => 10,
    'L' => 11,
    'M' => 12,
    'N' => 13,
    'O' => 14
};

use constant CHAR_TO_VALUE =>
{
  "A" => 1,
  "B" => 3,
  "C" => 3,
  "D" => 2,
  "E" => 1,
  "F" => 4,
  "G" => 2,
  "H" => 4,
  "I" => 1,
  "J" => 8,
  "K" => 5,
  "L" => 1,
  "M" => 3,
  "N" => 1,
  "O" => 1,
  "P" => 3,
  "Q" => 10,
  "R" => 1,
  "S" => 1,
  "T" => 1,
  "U" => 1,
  "V" => 4,
  "W" => 4,
  "X" => 8,
  "Y" => 4,
  "Z" => 10,
  "?" => 0,
};

use constant TILE_FREQUENCIES =>
{
  "A" => 9,
  "B" => 2,
  "C" => 2,
  "D" => 4,
  "E" => 12,
  "F" => 2,
  "G" => 3,
  "H" => 2,
  "I" => 9,
  "J" => 1,
  "K" => 1,
  "L" => 4,
  "M" => 2,
  "N" => 6,
  "O" => 8,
  "P" => 2,
  "Q" => 1,
  "R" => 6,
  "S" => 4,
  "T" => 6,
  "U" => 4,
  "V" => 2,
  "W" => 2,
  "X" => 1,
  "Y" => 2,
  "Z" => 1,
  "?" => 2
};

use constant TRIPLE_TRIPLE_COLOR            => 'red';
use constant NINE_OR_ABOVE_COLOR            => 'lime';
use constant IMPROBABLE_COLOR               => 'royalblue';
use constant TRIPLE_TRIPLE_NINE_COLOR       => 'yellow';
use constant IMPROBABLE_NINE_OR_ABOVE_COLOR => 'cyan';
use constant IMPROBABLE_TRIPLE_TRIPLE_COLOR => 'blueviolet';
use constant ALL_THREE_COLOR                => 'orangered';

use constant NO_CHALLENGE          => 'No Challenge';
use constant PLAYER_CHALLENGE_WON  => 'You Won';
use constant PLAYER_CHALLENGE_LOST => 'You Lost';
use constant OPP_CHALLENGE_WON     => 'Opponent Won';
use constant OPP_CHALLENGE_LOST    => 'Opponent Lost';

use constant UNCHALLENGED   => 'Unchallenged';
use constant CHALLENGED_OFF => 'Challenged Off';

use constant PLAY_TYPE_WORD     => 'word';
use constant PLAY_TYPE_EXCHANGE => 'exch';
use constant PLAY_TYPE_PASS     => 'pass';

use constant BOARD_WIDTH   => 15;
use constant BOARD_HEIGHT  => 15;

use constant DOUBLE_LETTER_TITLE  => 'Double Letter';
use constant TRIPLE_LETTER_TITLE  => 'Double Word';
use constant DOUBLE_WORD_TITLE    => 'Triple Letter';
use constant TRIPLE_WORD_TITLE    => 'Triple Word';

use constant SEVENS_TITLE    => 'Sevens';
use constant EIGHTS_TITLE    => 'Eights';
use constant NINES_TITLE     => 'Nines';
use constant TENS_TITLE      => 'Tens';
use constant ELEVENS_TITLE   => 'Elevens';
use constant TWELVES_TITLE   => 'Twelves';
use constant THIRTEENS_TITLE => 'Thirteens';
use constant FOURTEENS_TITLE => 'Fourteens';
use constant FIFTEENS_TITLE  => 'Fifteens';

use constant DOUBLE_LETTER  => "'";
use constant TRIPLE_LETTER  => '"';
use constant DOUBLE_WORD    => '-';
use constant TRIPLE_WORD    => '=';

use constant TITLE_WIDTH   => 40;
use constant AVERAGE_WIDTH => 20;
use constant TOTAL_WIDTH   => 20;


use constant BONUS_SQUARE_STRING => 
TRIPLE_WORD . '  ' . DOUBLE_LETTER . '   ' . TRIPLE_WORD . '   ' . DOUBLE_LETTER . '  ' . TRIPLE_WORD .
' ' . DOUBLE_WORD . '   ' . TRIPLE_LETTER . '   ' . TRIPLE_LETTER . '   ' . DOUBLE_WORD . ' ' .
'  ' . DOUBLE_WORD . '   ' . DOUBLE_LETTER . ' ' . DOUBLE_LETTER . '   ' . DOUBLE_WORD . '  ' .
DOUBLE_LETTER . '  ' . DOUBLE_WORD . '   ' . DOUBLE_LETTER . '   ' . DOUBLE_WORD . '  ' . DOUBLE_LETTER .
'    ' . DOUBLE_WORD . '     ' . DOUBLE_WORD . '    ' .
' ' . TRIPLE_LETTER . '   ' . TRIPLE_LETTER . '   ' . TRIPLE_LETTER . '   ' . TRIPLE_LETTER . ' ' .
'  ' . DOUBLE_LETTER . '   ' . DOUBLE_LETTER . ' ' . DOUBLE_LETTER . '   ' . DOUBLE_LETTER . '  ' .
TRIPLE_WORD . '  ' . DOUBLE_LETTER . '   ' . DOUBLE_WORD . '   ' . DOUBLE_LETTER . '  ' . TRIPLE_WORD .
'  ' . DOUBLE_LETTER . '   ' . DOUBLE_LETTER . ' ' . DOUBLE_LETTER . '   ' . DOUBLE_LETTER . '  ' .
' ' . TRIPLE_LETTER . '   ' . TRIPLE_LETTER . '   ' . TRIPLE_LETTER . '   ' . TRIPLE_LETTER . ' ' .
'    ' . DOUBLE_WORD . '     ' . DOUBLE_WORD . '    ' .
DOUBLE_LETTER . '  ' . DOUBLE_WORD . '   ' . DOUBLE_LETTER . '   ' . DOUBLE_WORD . '  ' . DOUBLE_LETTER .
'  ' . DOUBLE_WORD . '   ' . DOUBLE_LETTER . ' ' . DOUBLE_LETTER . '   ' . DOUBLE_WORD . '  ' .
' ' . DOUBLE_WORD . '   ' . TRIPLE_LETTER . '   ' . TRIPLE_LETTER . '   ' . DOUBLE_LETTER . ' ' .
TRIPLE_WORD . '  ' . DOUBLE_LETTER . '   ' . TRIPLE_WORD . '   ' . DOUBLE_LETTER . '  ' . TRIPLE_WORD
;

use constant STAT_DATATYPE_NAME         => 'datatype';
use constant STAT_METATYPE_NAME         => 'metatype';
use constant STAT_ADD_FUNCTION_NAME     => 'function';
use constant STAT_COMBINE_FUNCTION_NAME => 'combine_function';
use constant STAT_ITEM_OBJECT_NAME      => 'object';
use constant STAT_NAME                  => 'name';
use constant STAT_ERRORTYPE_NAME        => 'errortype';
use constant ERRORTYPE_ERROR            => 'invalid';
use constant ERRORTYPE_VALID            => 'valid';

use constant GAMEERROR_INCOMPLETE    => 'Incomplete';
use constant GAMEERROR_DISCONNECTED  => 'Disconnected';
use constant GAMEERROR_OTHER         => 'Other';

use constant STAT_OBJECT_DISPLAY_NAME   => 'display';
use constant STAT_OBJECT_DISPLAY_TOTAL  => 'total';
use constant STAT_OBJECT_DISPLAY_PCAVG  => 'pcavg';

use constant DATATYPE_LIST => 'list';
use constant DATATYPE_ITEM => 'item';

use constant METATYPE_PLAYER  => 'player';
use constant METATYPE_GAME    => 'game';
use constant METATYPE_NOTABLE => 'notable';
use constant METATYPE_ERROR   => 'error';

use constant HTML_BODY_STYLE => 'style="background-color: #343a40; color: white"';

use constant DIV_STYLE_EVEN => <<DIVEVEN
style=
      '
       background-color: #22262a;
       padding: 1%;
      '

DIVEVEN
;

use constant DIV_STYLE_ODD => <<DIVODD
style=
      '
       background-color: #394047;
       padding: 1%;
      '

DIVODD
;

use constant RESULTS_PAGE_TABLE_STYLE => <<RESULTSPAGETABLE
style=
      'width: 100%;
       table-layout: fixed;
      '

RESULTSPAGETABLE
;

use constant HTML_STYLES => <<HTMLSTYLES

  <style>
  .infobox
  {
    border-radius: 5px;
    background-color: #000000;
    text-align: center;
    border-collapse: separate;
    margin: auto;
  }
  .content_td
  {
    background-color: #394047;
    border-radius: 5px;
  }
  .display
  {
    width: 99%;
    margin: auto;
    border-collapse: separate;
    border-spacing: 0;
    border-radius: 5px;
    border: 1px solid black;
  }
  .display th
  {
    cursor: pointer;
  }
  .display tr:nth-child(odd)
  {
    /*background: #22262a; */
    background-color: black;
  }
  .display tr:nth-child(even)
  {
    /* background:  #394047; */
    background-color: #111111;
  }

  .display tr:last-child td:first-child
  {
      border-bottom-left-radius: 5px;
  }
  .display tr:last-child td:last-child
  {
      border-bottom-right-radius: 5px;
  }
  .display tr:first-child td:first-child
  {
      border-top-left-radius: 5px;
  }
  .display tr:first-child td:last-child
  {
      border-top-right-radius: 5px;
  }


  .titledisplay
  {
    width: 99%;
    margin: auto;
    border-collapse: separate;
    border-spacing: 0;
    border-radius: 5px;
    background-color: black;
    padding: 10px;
  }
  .titledisplay th
  {
    text-align: center;
    cursor: pointer;
    font-size: 20px;
    border-radius: 10px;
  }
  .dscclass
  {
    background-color: #444444;
    color: white;
  }
  .ascclass
  {
    background-color: #222222;
    color: white;
  }

  .statitemtable
  {
    width: 100%;
  }

  .statitemtable td, th
  {
    width: 33.333333333%;
  }

  .statitemdiv
  {
    background-color: black;
    padding: 10px;
    border-radius: 10px;
    text-align: center;
    margin: 5px;
  }

  .scrollwindow
  {
    max-height: 500px;
    overflow: auto;
    -ms-overflow-style: none;  /* IE 10+ */
    scrollbar-width: none;  /* Firefox */
  }
  .scrollwindow::-webkit-scrollbar
  { 
      display: none;  /* Safari and Chrome */
  }

  .dropdown-toggle::after
  {
      vertical-align: 0em;
  }
  </style>


HTMLSTYLES
;

use constant HTML_TABLE_AND_COLLAPSE_SCRIPTS => <<TCSCRIPTS

  <script>
      \$(document).ready(function () {

        \$('.collapse').on('shown.bs.collapse', function (e) {
          var id = e.target.id;

          id = 'button_' + id;
          var el = document.getElementById(id);
          if (el && el.nodeName == "BUTTON")
          {
            el.innerHTML = '&#8722';
          }

        });

        \$('.collapse').on('hidden.bs.collapse', function (e) {

          var id = e.target.id;

          id = 'button_' + id;
          var el = document.getElementById(id);
          if (el && el.nodeName == "BUTTON")
          {
            el.innerHTML = '+';
          }

        });
      });
  </script>


TCSCRIPTS
;


use constant HTML_HEAD_CONTENT => <<HEAD
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <meta http-equiv="x-ua-compatible" content="ie=edge">
  <title>RandomRacer</title>
  <!-- Font Awesome -->
  <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.2/css/all.css">
  <!-- Bootstrap core CSS -->
  <link href="/css/bootstrap.min.css" rel="stylesheet">
  <!-- Material Design Bootstrap -->
  <link href="/css/mdb.min.css" rel="stylesheet">
  <!-- Your custom styles (optional) -->

  <!-- Datepicker Syles -->
  <link href="/datepickercss/bootstrap-datepicker3.css" rel="stylesheet">
  <link href="/datepickercss/bootstrap-datepicker3.min.css" rel="stylesheet">

  <link href="/datepickercss/bootstrap-datepicker3.standalone.css" rel="stylesheet">
  <link href="/datepickercss/bootstrap-datepicker3.standalone.min.css" rel="stylesheet">

  <link href="/datepickercss/bootstrap-datepicker.css" rel="stylesheet">
  <link href="/datepickercss/bootstrap-datepicker.min.css" rel="stylesheet">

  <link href="/datepickercss/bootstrap-datepicker.standalone.css" rel="stylesheet">
  <link href="/datepickercss/bootstrap-datepicker.standalone.min.css" rel="stylesheet">

  <link href="/css/style.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css?family=VT323" rel="stylesheet">
HEAD
;

use constant HTML_NAV => <<NAV

<!--Navbar-->
<nav class="navbar navbar-expand-lg navbar-dark elegant-color-dark">

  <!-- Navbar brand -->
  <a class="navbar-brand" href="/" style="font-family: 'VT323', monospace;" >RandomRacer</a>

  <!-- Collapse button -->
  <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#basicExampleNav"
    aria-controls="basicExampleNav" aria-expanded="false" aria-label="Toggle navigation">
    <span class="navbar-toggler-icon"></span>
  </button>

  <!-- Collapsible content -->
  <div class="collapse navbar-collapse" id="basicExampleNav">

    <!-- Links -->
    <ul class="navbar-nav mr-auto">
      <li class="nav-item">
        <a class="nav-link" href="/leaderboard.html" >Leaderboards</a>
      </li>
      <li class="nav-item">
        <a class="nav-link" href="/notable.html" >Notable</a>
      </li>

      <!-- Dropdown -->
      <li class="nav-item dropdown">
        <a class="nav-link dropdown-toggle" id="navbarDropdownMenuLink" data-toggle="dropdown"
          aria-haspopup="true" aria-expanded="false">Legacy</a>
        <div class="dropdown-menu dropdown-primary" aria-labelledby="navbarDropdownMenuLink">
          <a class="dropdown-item" href="/legacy/notable.html">Notable</a>
          <a class="dropdown-item" href="/legacy/leaderboard.html">Leaderboards</a>
        </div>
      </li>
    </ul>
    <!-- Links -->
  </div>
  <!-- Collapsible content -->

</nav>
<!--/.Navbar-->


NAV
;

use constant HTML_SCRIPTS => <<SCRIPTS
  <!-- SCRIPTS -->
  <!-- JQuery -->
  <script type="text/javascript" src="/js/jquery-3.4.1.min.js"></script>
  <!-- Bootstrap tooltips -->
  <script type="text/javascript" src="/js/popper.min.js"></script>
  <!-- Bootstrap core JavaScript -->
  <script type="text/javascript" src="/js/bootstrap.min.js"></script>
  <!-- MDB core JavaScript -->
  <script type="text/javascript" src="/js/mdb.min.js"></script>

  <!-- Datepicker JavaScript -->
  <script type="text/javascript" src="/datepickerjs/bootstrap-datepicker.js"></script>
  <script type="text/javascript" src="/datepickerjs/bootstrap-datepicker.min.js"></script>

SCRIPTS
;

use constant TOGGLE_ICON_SCRIPT => <<TOGGLEICON
<script>
    function toggle_icon(el, key, showtext)
    {
      var text = '';
      if (el.innerHTML.includes('down'))
      {
	if (showtext)
	{
          text = '<br>Show Less<br>';
	}
        el.innerHTML = text + '<i class="fas fa-angle-up rotate-icon"></i>'
      }
      else
      {
	if (showtext)
	{
          text = '<br>Show More<br>';
	}
        el.innerHTML = text + '<i class="fas fa-angle-down rotate-icon"></i>'
      }
      \$('#' + key).collapse('toggle');
    }
</script>
TOGGLEICON
;

use constant TABLE_SORT_FUNCTION => <<TABLESORT

<script>

function filterTable(input, tableid)
{
  var table = document.getElementById(tableid);
  var allrows  = table.getElementsByTagName("tr");
  var rows = [];

  for (j = 0; j < allrows.length; j++)
  {
    var row = allrows[j];
    console.log(row.parentElement.parentElement);
    if (row.parentElement.parentElement.id == tableid)
    {
      rows.push(row);
    }
  }

  var s     = input.value;
  var cc    = 0;
  console.log('In filter: ' + s);
  for (i = 0; i < rows.length; i++)
  {
    var row = rows[i];
    var text = row.innerText;
    var style = '';
    var color = 'black'
    if (!(text.toLowerCase().includes(s.toLowerCase())))
    {
      style = 'none';
    }
    else
    {
      cc++;
    }

    if (cc % 2 == 0)
    {
      color = '#111111';
    }
    row.style.backgroundColor = color;
    row.style.display = style;
  }
}
function sortNumeric(a, b)
{
    if (a[0] === b[0])
    {
        return 0;
    }
    else
    {
        return (a[0] < b[0]) ? -1 : 1;
    }
}
function sortAlpha(a, b)
{
    var x = a[0].toLowerCase();
    var y = b[0].toLowerCase();
    if (x === y)
    {
        return 0;
    }
    else
    {
        return (x < y) ? -1 : 1;
    }
}

function changeSelector(tableid, thclass, n)
{
  var titleths = document.getElementById(tableid).getElementsByTagName("TH");
  for (k = 0; k < titleths.length; k++)
  {
    if (k == n)
    {
      titleths[k].className = thclass;
    }
    else
    {
      titleths[k].className = '';
    }
  }
}

function sortTable(n, tableid, numeric)
{
  var table = document.getElementById(tableid);
  var rows = table.rows;
  var content  = [];
  var values   = [];
  for (i = 0; i < rows.length; i++)
  {
    var val = rows[i].getElementsByTagName("TD")[n].innerText;
    if (numeric)
    {
      val = Number(val);
    }
    values.push([val , i]);
    content.push(rows[i].innerHTML);
  }
  if (numeric)
  {
    values.sort(sortNumeric);
  }
  else
  {
    values.sort(sortAlpha);
  }

  var thclass = 'dscclass';
  var sort_state = table.getAttribute('data-sort');
  if (!sort_state || sort_state != 'asc' + n)
  {
    table.setAttribute('data-sort', 'asc' + n);
    thclass = 'ascclass';
  }
  else if (sort_state == 'asc' + n)
  {
    content.reverse();
    table.setAttribute('data-sort', 'dsc' + n);
  }

  changeSelector(tableid + '_title_row_id', thclass, n);

  for (j = 0; j < rows.length; j++)
  {
    rows[j].innerHTML = content[values[j][1]];
  }
}
</script>

TABLESORT
;

use constant RESULTS_PAGE_JAVASCRIPT =>
"
<script>
function toggle(id)
{
  var x = document.getElementById(id);
  if (x.style.display === 'none')
  {
    x.style.display = 'block';
  }
  else
  {
    x.style.display = 'none';
  }
}
</script>
";

use constant LEADERBOARD_JAVASCRIPT =>
"
<script>
  function toggle(id)
  {
    var x = document.getElementById(id);
    if (x.style.display === 'none')
    {
      x.style.display = 'block';
    } 
    else
    {
      x.style.display = 'none';
    }
  }
  function toggle_all()
  {
    var list = document.getElementsByTagName('DIV');
    for (i = 0; i < list.length; i++)
    { 
      var x = list[i];
      if (x.style.display === 'none')
      {
        x.style.display = 'block';
      }
      else
      {
        x.style.display = 'none';
      }
    }
  }
</script>
";

use constant CSV_DOWNLOAD_SCRIPTS => <<CSV

<script>

function downloadCSV(csv, filename)
{
    var csvFile;
    var downloadLink;

    // CSV file
    csvFile = new Blob([csv], {type: "text/csv"});

    // Download link
    downloadLink = document.createElement("a");

    // File name
    downloadLink.download = filename;

    // Create a link to the file
    downloadLink.href = window.URL.createObjectURL(csvFile);

    // Hide download link
    downloadLink.style.display = "none";

    // Add the link to DOM
    document.body.appendChild(downloadLink);

    // Click download link
    downloadLink.click();
}

function exportTableToCSV(filename, tableid)
{
    var csv = [];
    var rows = document.getElementById(tableid).getElementsByTagName("TR");
    
    if (
        tableid == 'player_mistakes_expander_actually_table_id_okay' ||
        tableid == 'opponent_mistakes_expander_actually_table_id_okay' 
       )
    {
       for (var i = 0; i < rows.length; i += 2)
       {
         var cells = rows[i].getElementsByTagName("TD");

	 var play = cells[1].innerText;
	 var type = cells[2].innerText;
	 var size = cells[3].innerText;
	 var cmnt = rows[i].getElementsByTagName("DIV")[0].innerText;

	 cmnt = cmnt.replace(/^\\s+|\\s+\$/g, '');
         
	 var row = [play, type, size, cmnt]; 
         csv.push(row.join(",") + ';');        
       }
  
      // Download CSV file
      downloadCSV(csv.join("\\n"), filename);     
    }
    else if (tableid.includes('Player Lists') || tableid.includes('Opponent Lists'))
    {
      for (var i = 0; i < rows.length; i += 2)
       {
         var cells = rows[i].getElementsByTagName("TD");
	 var type  = cells[0].getElementsByTagName("SPAN")[0].getAttribute('data-text');;
	 var play  = cells[1].innerText;
	 var prob  = cells[2].innerText;
	 var score = cells[3].innerText;

	 var row = [type, play, prob, score]; 
         csv.push(row.join(",") + ';');        
       }
  
      // Download CSV file
      downloadCSV(csv.join("\\n"), filename);          
    }
    if (
        tableid == 'player_stats_expander_actually_table_id_okay' ||
        tableid == 'opponent_stats_expander_actually_table_id_okay' 
       )
    {
      var newrows = [];
      for (var i = 0; i < rows.length; i++)
      {
        var row = rows[i];
        if (row.name == 'data')
        {
          newrows.push(row);
        }
      }
      rows = newsrows;
      for (var i = 0; i < rows.length; i++)
      {
          var row = [], cols = rows[i].querySelectorAll("td, th");
          
          for (var j = 0; j < cols.length; j++) 
              row.push(cols[j].innerText);
          
          csv.push(row.join(",") + ';');        
      }
  
      // Download CSV file
      downloadCSV(csv.join("\\n"), filename);       
    }


    else
    {
      for (var i = 0; i < rows.length; i++)
      {
        var row = [], cols = rows[i].querySelectorAll("td, th");
        for (var j = 0; j < cols.length; j++) 
        {
          row.push(cols[j].innerText);
        }  
        csv.push(row.join(",") + ';');        
      }
  
      // Download CSV file
      downloadCSV(csv.join("\\n"), filename);
    }
}

</script>


CSV
;

use constant HTML_FOOTER => <<FOOTER
<footer>
  <!-- Copyright -->
  <div class="footer-copyright text-center py-3" style='font-size: 12px'>© 2019 Copyright
    <a href="/">RandomRacer.com</a>
  </div>
  <!-- Copyright -->
</footer>


FOOTER
;

1;


