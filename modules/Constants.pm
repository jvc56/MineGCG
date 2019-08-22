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
use constant BLACKLISTED_TOURNAMENTS          => {
                                                    '9194' => 1 # Can-Am Match 08/29/15
                                                 };

use constant CGI_SCRIPT_FILENAME              => 'mine_webapp.pl';
use constant INDEX_HTML_FILENAME              => 'index.html';

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

use constant TRIPLE_TRIPLE_COLOR            => 'red';
use constant NINE_OR_ABOVE_COLOR            => 'lime';
use constant IMPROBABLE_COLOR               => 'royalblue';
use constant TRIPLE_TRIPLE_NINE_COLOR       => 'yellow';
use constant IMPROBABLE_NINE_OR_ABOVE_COLOR => 'cyan';
use constant IMPROBABLE_TRIPLE_TRIPE_COLOR  => 'blueviolet';
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

use constant STATS_NOTE => "\n\nFor more information about how these statistcs were computed, check the <a href='https://github.com/jvc56/MineGCG#minegcg'>documentation</a>.\n\n";


use constant STAT_DATATYPE_NAME         => 'datatype';
use constant STAT_METATYPE_NAME         => 'metatype';
use constant STAT_ADD_FUNCTION_NAME     => 'function';
use constant STAT_COMBINE_FUNCTION_NAME => 'combine_function';
use constant STAT_ITEM_OBJECT_NAME      => 'object';
use constant STAT_NAME                  => 'name';

use constant DATATYPE_LIST => 'list';
use constant DATATYPE_ITEM => 'item';

use constant METATYPE_PLAYER  => 'player';
use constant METATYPE_GAME    => 'game';
use constant METATYPE_NOTABLE => 'notable';

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

1;


