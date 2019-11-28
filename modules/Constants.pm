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
use constant SCRIPTS_DIRECTORY_NAME           => './scripts';
use constant DOWNLOADS_DIRECTORY_NAME         => './downloads';
use constant STATS_DIRECTORY_NAME             => './stats';
use constant NOTABLE_DIRECTORY_NAME           => './notable';
use constant CACHE_DIRECTORY_NAME             => './cache';
use constant HTML_DIRECTORY_NAME              => './html';
use constant CGIBIN_DIRECTORY_NAME            => './cgi-bin';
use constant LOGS_DIRECTORY_NAME              => './logs';
use constant HTML_STATIC_DIRECTORY_NAME       => './html_static';
use constant LEGACY_DIRECTORY_NAME            => './legacy';
use constant ABOUT_PAGE_NAME                  => 'about.html';
use constant QUALIFIERS_PAGE_NAME             => 'alchemist_qualifiers.html';
use constant TOURNAMENT_OPTION                => 'Tournament';
use constant CASUAL_OPTION                    => 'Casual';

use constant CHART_TAB_NAME                   => 'Win Correlation';
use constant CONFIDENCE_LEVEL                 => 0.99;
use constant OVER_CONFIDENCE_COLOR            => '#6c131c';
use constant UNDER_CONFIDENCE_COLOR           => '#0f3e1a';

use constant ANNOTATED_GAMES_API_CALL         => 'http://cross-tables.com/rest/allanno.php';
use constant PLAYER_INFO_API_CALL             => 'http://cross-tables.com/rest/player.php?player=';
use constant TOURNAMENT_INFO_API_CALL         => 'http://cross-tables.com/rest/tourney.php?tourney=';
use constant PLAYER_RESULTS_API_CALL          => 'http://cross-tables.com/rest/results.php?player=';

use constant CGI_WRAPPER_FILENAME             => 'cgi_wrapper.pl';
use constant INDEX_HTML_FILENAME              => 'index.html';

use constant GAME_TYPE_CASUAL                 => 'Casual';
use constant GAME_TYPE_TOURNAMENT             => 'Tournament';

use constant WRAPPER_SCRIPT                   => 'wrapper.pl';
use constant DIRECTORY_FIELD_NAME             => 'directory';

use constant PLAYER_SEARCH_OPTION             => 'player_search';
use constant PLAYER_FIELD_NAME                => 'name';
use constant CORT_FIELD_NAME                  => 'cort';
use constant GAME_ID_FIELD_NAME               => 'gameid';
use constant TOURNAMENT_ID_FIELD_NAME         => 'tournamentid';
use constant OPPONENT_FIELD_NAME              => 'opponent';
use constant START_DATE_FIELD_NAME            => 'startdate';
use constant END_DATE_FIELD_NAME              => 'enddate';
use constant LEXICON_FIELD_NAME               => 'lexicon';

use constant PLAYER_SEARCH_DISPATCH => "
  require './modules/Mine.pm';
  Mine::mine
  (
    \$".PLAYER_FIELD_NAME.",
    \$".CORT_FIELD_NAME.",
    \$".GAME_ID_FIELD_NAME.",
    \$".OPPONENT_FIELD_NAME.",
    \$".START_DATE_FIELD_NAME.",
    \$".END_DATE_FIELD_NAME.",
    \$".LEXICON_FIELD_NAME.",
    0,
    \$".TOURNAMENT_ID_FIELD_NAME.",
    0,
    1,
    0
  );
"
;

use constant TYPING_SEARCH_OPTION         => 'typing_search';
use constant TYPING_MIN_LENGTH_FIELD_NAME => 'min_length';
use constant TYPING_MAX_LENGTH_FIELD_NAME => 'max_length';
use constant TYPING_MIN_PROB_FIELD_NAME   => 'min_prob';
use constant TYPING_MAX_PROB_FIELD_NAME   => 'max_prob';
use constant TYPING_NUM_WORDS_FIELD_NAME  => 'num_words';
use constant TYPING_HTML_FILENAME         => 'typing.html';

use constant TYPING_SEARCH_DISPATCH => "
  require './modules/Passage.pm';
  Passage::passage
  (
    \$" . TYPING_MIN_LENGTH_FIELD_NAME . ",
    \$" . TYPING_MAX_LENGTH_FIELD_NAME . ",
    \$" . TYPING_MIN_PROB_FIELD_NAME . ",
    \$" . TYPING_MAX_PROB_FIELD_NAME . ",
    \$" . TYPING_NUM_WORDS_FIELD_NAME . "
  );
"
;

use constant SIM_SEARCH_OPTION             => 'sim_search';
use constant SIM_TOURNAMENT_FIELD_NAME     => 'tournamenturl';
use constant SIM_START_ROUND_FIELD_NAME    => 'startround';
use constant SIM_END_ROUND_FIELD_NAME      => 'endround';
use constant SIM_PAIRING_METHOD_FIELD_NAME => 'pairingmethod';
use constant SIM_SCORING_METHOD_FIELD_NAME => 'scoringmethod';
use constant SIM_NUMBER_OF_SIMS_FIELD_NAME => 'numberofsims';
use constant SIM_URL_ERROR                 => 'INVALID URL';
use constant SIM_HTML_FILENAME             => 'simulate.html';

use constant SIM_SEARCH_DISPATCH => "
  require './modules/Tournament.pm';
  my \$tournament = 
  Tournament->new
  (
    \$" . SIM_TOURNAMENT_FIELD_NAME . ",
    \$" . SIM_END_ROUND_FIELD_NAME . ",
    \$" . SIM_PAIRING_METHOD_FIELD_NAME . ",
    \$" . SIM_SCORING_METHOD_FIELD_NAME . ",
    \$" . SIM_NUMBER_OF_SIMS_FIELD_NAME . ",
    \$" . SIM_START_ROUND_FIELD_NAME . ",
    1
  );
  if (ref(\$tournament) ne 'Tournament')
  {
    print \$tournament;
  }
  else
  {
    \$tournament->simulate();
  }
"
;


use constant CRONJOB_OPTION               => 'cron';


use constant FIELD_LIST                   => 'fieldlist';
use constant DISPATCH_FUNCTION            => 'dispatch';

use constant CGI_TYPE => 'whichcgi';

use constant WRAPPER_FUNCTIONS =>
[
  {
    Constants::CGI_TYPE => Constants::PLAYER_SEARCH_OPTION,
    Constants::DISPATCH_FUNCTION => Constants::PLAYER_SEARCH_DISPATCH,
    Constants::FIELD_LIST =>
    [
      Constants::PLAYER_FIELD_NAME,
      Constants::CORT_FIELD_NAME,
      Constants::GAME_ID_FIELD_NAME,
      Constants::TOURNAMENT_ID_FIELD_NAME,
      Constants::OPPONENT_FIELD_NAME,
      Constants::START_DATE_FIELD_NAME,
      Constants::END_DATE_FIELD_NAME,
      Constants::LEXICON_FIELD_NAME
    ]
  },
  {
    Constants::CGI_TYPE => Constants::TYPING_SEARCH_OPTION,
    Constants::DISPATCH_FUNCTION => Constants::TYPING_SEARCH_DISPATCH,
    Constants::FIELD_LIST =>
    [
      Constants::TYPING_MIN_LENGTH_FIELD_NAME,
      Constants::TYPING_MAX_LENGTH_FIELD_NAME,
      Constants::TYPING_MIN_PROB_FIELD_NAME,
      Constants::TYPING_MAX_PROB_FIELD_NAME,
      Constants::TYPING_NUM_WORDS_FIELD_NAME
    ]
  },
  {
    Constants::CGI_TYPE => Constants::SIM_SEARCH_OPTION,
    Constants::DISPATCH_FUNCTION => Constants::SIM_SEARCH_DISPATCH,
    Constants::FIELD_LIST =>
    [
      Constants::SIM_TOURNAMENT_FIELD_NAME,
      Constants::SIM_START_ROUND_FIELD_NAME,
      Constants::SIM_END_ROUND_FIELD_NAME,
      Constants::SIM_PAIRING_METHOD_FIELD_NAME,
      Constants::SIM_SCORING_METHOD_FIELD_NAME,
      Constants::SIM_NUMBER_OF_SIMS_FIELD_NAME,
    ]
  },
  {
    Constants::CGI_TYPE => Constants::CRONJOB_OPTION,
    Constants::DISPATCH_FUNCTION => "system '" . Constants::SCRIPTS_DIRECTORY_NAME . "/daily_cronjob.pl';",
    Constants::FIELD_LIST =>
    [
    ]
  }
];

use constant SANITIZE_EXEMPTIONS =>
{
  Constants::SIM_TOURNAMENT_FIELD_NAME => 1
};

use constant COLLINS_OPTION                   => 'Collins';
use constant TWL_OPTION                       => 'TWL/NSW';

use constant SEARCH_DATA_FILENAME             => 'search_data.html';

use constant CANADA_QUALIFIERS                =>
[
  'Adam Logan',
  'Jackson Smylie',
  'Joshua Sokol',
  'Evan Berofsky',
  'Joshua Castellano',
  'Jesse Matthews',
  'Tony Leah',
  'Shan Abbasi'
];

use constant US_QUALIFIERS                    =>
[
  'Dave Wiegand',
  'Austin Shin',
  'Will Anderson',
  'Evans Clinchy',
  'David Koenig',
  'Jesse Day',
  'Jason Keller',
  'Conrad Bassett-Bouchard',
  'Rob Robinsky',
  'Chris Lipe',
  'Ben Schoenbrun',
  'Rasheed Balogun',
  'Cesar Del Solar',
  'Lucas Freeman',
  'Puneet Sharma'
];

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
use constant PLAYER_PHOTO_URL_COLUMN_NAME                  => 'player_photo_url';
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
    Constants::PLAYER_PHOTO_URL_COLUMN_NAME       . " TEXT",
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


use constant TYPING_DATABASE_NAME    => 'typing';
use constant WORDS_TABLE_NAME        => 'words';
use constant WORD_COLUMN_NAME        => 'word';
use constant WORD_LENGTH_COLUMN_NAME => 'word_length';
use constant WORD_PROBABILITY_COLUMN_NAME => 'word_probability';
use constant DEFAULT_NUMBER_OF_PASSAGE_WORDS => 30;
use constant TYPING_DATABASE_TABLES =>
{
  Constants::WORDS_TABLE_NAME =>
  [
    Constants::WORD_COLUMN_NAME                     . " VARCHAR(15) NOT NULL",
    Constants::WORD_LENGTH_COLUMN_NAME              . " INT NOT NULL",
    Constants::WORD_PROBABILITY_COLUMN_NAME         . " INT NOT NULL",
  ]
};

use constant TYPING_TABLE_CREATION_ORDER =>
[
  Constants::WORDS_TABLE_NAME
];



use constant UNSPECIFIED_MISTAKE_NAME => 'Unspecified';

use constant MISTAKES =>
(
  'Knowledge',
  'Finding',
  'Vision',
  'Tactics',
  'Strategy',
  'Endgame',
  'Time'
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
  'Time'      => 'magenta'
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

use constant STAT_DESCRIPTION_NAME      => 'description';

use constant DATATYPE_LIST => 'list';
use constant DATATYPE_ITEM => 'item';

use constant METATYPE_PLAYER  => 'player';
use constant METATYPE_GAME    => 'game';
use constant METATYPE_NOTABLE => 'notable';
use constant METATYPE_ERROR   => 'error';

use constant DATA_DOWNLOAD_ATTRIBUTE => "data-download='true'";

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
    border-radius: 10px;
    background-color: black;
    padding: 5px; 
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

  .noscrollwindow
  {
    max-height: none;
    overflow: auto;
    -ms-overflow-style: none;  /* IE 10+ */
    scrollbar-width: none;  /* Firefox */
  }
  .noscrollwindow::-webkit-scrollbar
  { 
      display: none;  /* Safari and Chrome */
  }

  .dropdown-toggle::after
  {
      vertical-align: 0em;
  }
  .info
  {
    text-align: center;
  }

  .loader
  {
    border: 16px solid #f3f3f3;
    border-radius: 50%;
    border-top: 16px solid #3498db;
    width: 120px;
    height: 120px;
    -webkit-animation: spin 2s linear infinite; /* Safari */
    animation: spin 2s linear infinite;
  }
  
  /* Safari */
  \@-webkit-keyframes spin
  {
    0% { -webkit-transform: rotate(0deg); }
    100% { -webkit-transform: rotate(360deg); }
  }
  
  \@keyframes spin
  {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  </style>


HTMLSTYLES
;

use constant HTML_CONTENT_LOADER => '<div style=\"text-align: center\"><div class=\"spinner-border text-primary\" role=\"status\"><span class=\"sr-only\">Loading...</span></div></div>';

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
      <li class="nav-item">
        <a class="nav-link" href="/alchemist_qualifiers.html" >Alchemist Cup Qualifiers</a>
      </li>
      <li class="nav-item">
        <a class="nav-link" href="/typing.html">RandomRacer 2.0</a>
      </li>
      <li class="nav-item">
        <a class="nav-link" href="/simulate.html">Tournament Simulation</a>
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
      <li class="nav-item">
        <a class="nav-link" href="/about.html" >About</a>
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

use constant AMCHART_SCRIPTS => <<AMCHARTS
  <!-- Amchart JavaScript -->
  <script src="https://www.amcharts.com/lib/4/core.js"></script>
  <script src="https://www.amcharts.com/lib/4/charts.js"></script>
  <script src="https://www.amcharts.com/lib/4/themes/dark.js"></script>
  <script src="https://www.amcharts.com/lib/4/themes/animated.js"></script>

AMCHARTS
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


function toggleMaxHeight(divid, conid)
{
  var div = document.getElementById(divid);
  if (div.className == 'scrollwindow')
  {
    div.className = 'noscrollwindow';
    document.getElementById(conid).className = 'fas fa-angle-up rotate-icon';
  }
  else
  {
    div.className = 'scrollwindow';
    document.getElementById(conid).className = 'fas fa-angle-down rotate-icon';
  }
}

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
    var val_obj = rows[i].getElementsByTagName("TD")[n];
    var val_alpha = val_obj.getAttribute('data-alpha');
    var val;
    if (val_alpha)
    {
      val = val_alpha;
    }
    else
    {
      val = val_obj.innerText;
    }
    if (numeric)
    {
      val = Number(val);
    }
    else if (!val)
    {
      val = rows[i].getElementsByTagName("TD")[n].innerHTML;
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

    var newrows = [];
    for (var i = 0; i < rows.length; i++)
    {
      var row = rows[i];
      if (row.getAttribute('data-download') == 'true')
      {
        newrows.push(row);
      }
    }

    rows = newrows;
    
    for (var i = 0; i < rows.length; i++)
    {
        var row = [], cols = rows[i].querySelectorAll("td, th");
        
        for (var j = 0; j < cols.length; j++)
        {
          var data = cols[j].innerText.trim();
          var altdata = cols[j].getAttribute('data-downloadtext');
          var otherid = cols[j].getAttribute('data-downloadid');
          if (altdata)
          {
            data = altdata;
          }
          else if (otherid)
          {
            data = document.getElementById(otherid).innerText.trim(0);
          }
          row.push(data);
        }
        
        csv.push(row.join(",") + ';');        
    }

    // Download CSV file
    downloadCSV(csv.join("\\n"), filename);       
}

</script>


CSV
;

use constant MATH_SCRIPTS => <<MATH
<script src=\"https://polyfill.io/v3/polyfill.min.js?features=es6\"></script>
<script id=\"MathJax-script\" async src=\"https://cdn.jsdelivr.net/npm/mathjax\@3/es5/tex-mml-chtml.js\"></script>
MATH
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

use constant SANITIZE_FUNCTION => <<SANITIZE
sub sanitize
{
  my \$string = shift;

  \$string = substr( \$string, 0, 256);

  # Remove trailing and leading whitespace
  \$string =~ s/^\\s+|\\s+\$//g;

  # Replace spaces with underscores
  \$string =~ s/ /_/g;

  # Remove anything that is not an
  # underscore, dash, letter, or number
  \$string =~ s/[^\\w-]//g;

  # Capitalize
  \$string = uc \$string;

  return \$string;
}
SANITIZE
;

use constant TOURNAMENT_DIV_STYLE =>
    "   
    style=
    '
      font-weight: bolder;
      color: #FFFFFF;
      border-radius: 20px;
      background: black;
      margin: 10px;
      padding: 10px;
    '
    "
;

use constant TOURNAMENT_MATRIX_STYLE =>
    "   
    style=
    '
      font-weight: bolder;
      color: #FFFFFF;
      border-radius: 20px;
      background: black;
      margin: 10px;
      padding: 10px;
      text-align: center;
    '
    "
;

use constant TOURNAMENT_TABLE_STYLE =>
    "   
    style=
    '
      table-layout: fixed;
      width: 100%;
    '
    "
;

use constant TOURNAMENT_RESET_ROUND         => 'Starting Round';
use constant TOURNAMENT_NUMBER_OF_ROUNDS    => 'Final Round';
use constant TOURNAMENT_PLAYERS             => 'Players';
use constant TOURNAMENT_SCENARIO_MATRIX     => 'Scenario Matrix';
use constant TOURNAMENT_SCENARIO_ID_COUNTER => 'Scenario ID Counter';
use constant TOURNAMENT_NUMBER_OF_PLAYERS   => 'Number of Players';
use constant TOURNAMENT_PAIRING_METHOD      => 'Pairing Method';
use constant TOURNAMENT_SCORING_METHOD      => 'Scoring Method';
use constant TOURNAMENT_FILENAME            => 'Tournament File';
use constant TOURNAMENT_HTML_FORMAT         => 'HTML Format';

use constant TOURNAMENT_BYE_PLAYER                    => 'Bye Player';
use constant TOURNAMENT_CURRENT_ROUND                 => 'Current Round';
use constant TOURNAMENT_CURRENT_NUMBER_OF_SIMULATIONS => 'Current Number of Simulations';
use constant TOURNAMENT_MAXIMUM_NUMBER_OF_SIMULATIONS => 'Simulations';

use constant PAIRING_METHOD_KOTH        => 'King of the Hill';
use constant PAIRING_METHOD_RANK_PAIR   => 'Rank Pair';
use constant PAIRING_METHOD_RANDOM_PAIR => 'Random Pair';

use constant PAIRING_METHOD_LIST =>
[
  Constants::PAIRING_METHOD_KOTH,
  Constants::PAIRING_METHOD_RANK_PAIR,
  Constants::PAIRING_METHOD_RANDOM_PAIR
];

use constant SCORING_METHOD_RATING          => 'Rating';
use constant SCORING_METHOD_RANDOM_UNIFORM  => 'Random Uniform';
use constant SCORING_METHOD_RANDOM_BLOWOUTS => 'Random Blowouts';
use constant SCORING_METHOD_RANDOM_BST      => 'Random Blowouts, Close Wins, and Ties';

use constant SCORING_METHOD_LIST =>
[
  Constants::SCORING_METHOD_RATING,
  Constants::SCORING_METHOD_RANDOM_UNIFORM,
  Constants::SCORING_METHOD_RANDOM_BLOWOUTS,
  Constants::SCORING_METHOD_RANDOM_BST
];


use constant PLAYER_NAME         => 'Name';
use constant PLAYER_NUMBER       => 'Number';
use constant PLAYER_RATING       => 'Rating';
use constant PLAYER_OPPONENTS    => 'Opponents';
use constant PLAYER_SCORES       => 'Scores';
use constant PLAYER_WINS         => 'Wins';
use constant PLAYER_LOSSES       => 'Losses';
use constant PLAYER_SPREAD       => 'Spread';
use constant PLAYER_RESET_WINS   => 'Reset Wins';
use constant PLAYER_RESET_LOSSES => 'Reset Losses';
use constant PLAYER_RESET_SPREAD => 'Reset Spread';
use constant PLAYER_FINAL_RANKS  => 'Player Final Ranks';


use constant SMALL_TOURNAMENT_URL          => 'http://dev.randomracer.com/a.t';
use constant MEDIUM_TOURNAMENT_URL         => 'http://dev.randomracer.com/b.t';
use constant LARGE_TOURNAMENT_URL          => 'http://event.scrabbleplayers.org/2019/nasc/build/tsh/2019-nasc-s/s.t';

use constant TOURNAMENT_LIST =>
[
  Constants::SMALL_TOURNAMENT_URL, 
  Constants::MEDIUM_TOURNAMENT_URL,
  Constants::LARGE_TOURNAMENT_URL
];

use constant DEFAULT_TOURNAMENT_URL        => Constants::SMALL_TOURNAMENT_URL;
use constant DEFAULT_PAIRING_METHOD        => PAIRING_METHOD_RANDOM_PAIR;
use constant DEFAULT_SCORING_METHOD        => SCORING_METHOD_RANDOM_BST;
use constant DEFAULT_NUMBER_OF_ROUNDS      => 6;
use constant DEFAULT_NUMBER_OF_SIMULATIONS => 100;
use constant DEFAULT_START_ROUND           => 3;

use constant DEFAULT_NAME_PADDING       => 40;
use constant DEFAULT_PERCENTAGE_PADDING => 10;

use constant DEFAULT_BASE_SCORE => 300;
use constant DEFAULT_SCORE_PER_RATING => 450 / 1850;
use constant DEFAULT_STANDARD_DEVIATION => 50;

use constant DEFAULT_NAME_STANDING_SPACING => 30;
use constant DEFAULT_STANDING_SPACING      => 8;

use constant BLOWOUT_SCORES              => [0, 1000];
use constant BST_SCORES                  => [[0, 1000], [0, 1], [1000, 0], [1, 0], [1, 1]];
use constant DEFAULT_BYE_SCORE                  => 50;

use constant SELECT_TAG_CLASS            => "class='browser-default custom-select mb-4'";
1;


