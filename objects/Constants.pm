#!/usr/bin/perl

package Constants;

use warnings;
use strict;

use constant WGET_FLAGS                       => '--no-check-certificate';
use constant CROSS_TABLES_URL                 => 'http://www.cross-tables.com/';
use constant QUERY_URL_PREFIX                 => 'http://www.cross-tables.com/players.php?query=';
use constant ANNOTATED_GAMES_URL_PREFIX       => 'http://www.cross-tables.com/anno.php?p=';
use constant SINGLE_ANNOTATED_GAME_URL_PREFIX => 'http://www.cross-tables.com/annotated.php?u=';
use constant CROSS_TABLES_COUNTRY_PREFIX      => 'https://www.cross-tables.com/bycountry.php?country=';
use constant ANNOTATED_GAMES_PAGE_NAME        => './downloads/anno_page.html';
use constant QUERY_RESULTS_PAGE_NAME          => './downloads/query_results.html';
use constant NON_TOURNAMENT_GAME              => 'casual_or_club';
use constant GAME_DIRECTORY_NAME              => './games';
use constant NAMES_DIRECTORY_NAME             => './names';
use constant DEFAULT_LEXICON                  => 'CSW15';
use constant BLACKLISTED_TOURNAMENTS          => {
                                                    '9194' => 1 # Can-Am Match 08/29/15
                                                 };



use constant STAT_ITEM_GAME        => 'GAME STATS';
use constant STAT_ITEM_PLAYER      => 'YOUR STATS';
use constant STAT_ITEM_OPP         => 'OPPONENT STATS';
use constant STAT_ITEM_LIST_PLAYER => 'YOUR LISTS';
use constant STAT_ITEM_LIST_OPP    => 'OPPONENT LISTS';

use constant STATS_ITEMS =>
(
    {name => 'Bingos',                type => STAT_ITEM_LIST_PLAYER},
    {name => 'Phonies Formed',        type => STAT_ITEM_LIST_PLAYER},
    {name => 'Plays That Were Challenged',   type => STAT_ITEM_LIST_PLAYER},
    {name => 'Bingos',                type => STAT_ITEM_LIST_OPP},
    {name => 'Phonies Formed',        type => STAT_ITEM_LIST_OPP},
    {name => 'Plays That Were Challenged',      type => STAT_ITEM_LIST_OPP},
    {name => 'Games',                 type => STAT_ITEM_GAME},
    {name => 'Total Turns',           type => STAT_ITEM_GAME},
    {name => 'Challenges',            type => STAT_ITEM_GAME},
    {name => 'Wins',                  type => STAT_ITEM_PLAYER},
    {name => 'Score',                 type => STAT_ITEM_PLAYER},
    {name => 'Turns',                 type => STAT_ITEM_PLAYER},
    {name => 'Score per Turn',        type => STAT_ITEM_PLAYER},
    {name => 'High Game',             type => STAT_ITEM_PLAYER},
    {name => 'Low Game',              type => STAT_ITEM_PLAYER},
    {name => 'Bingos Played',         type => STAT_ITEM_PLAYER},
    {name => 'Bingo Probabilities',   type => STAT_ITEM_PLAYER},
    {name => 'Tiles Played',          type => STAT_ITEM_PLAYER},
    {name => 'Power Tiles Played',    type => STAT_ITEM_PLAYER},
    {name => 'Triple Triples Played', type => STAT_ITEM_PLAYER},
    {name => 'Bingoless Games',       type => STAT_ITEM_PLAYER},
    {name => 'Bonus Square Coverage', type => STAT_ITEM_PLAYER},
    {name => 'Phony Plays',           type => STAT_ITEM_PLAYER},
    {name => 'Wins',                  type => STAT_ITEM_OPP},
    {name => 'Score',                 type => STAT_ITEM_OPP},
    {name => 'Turns',                 type => STAT_ITEM_OPP},
    {name => 'Score per Turn',        type => STAT_ITEM_OPP},
    {name => 'High Game',             type => STAT_ITEM_OPP},
    {name => 'Low Game',              type => STAT_ITEM_OPP},
    {name => 'Bingos Played',         type => STAT_ITEM_OPP},
    {name => 'Bingo Probabilities',   type => STAT_ITEM_OPP},
    {name => 'Tiles Played',          type => STAT_ITEM_OPP},
    {name => 'Power Tiles Played',    type => STAT_ITEM_OPP},
    {name => 'Triple Triples Played', type => STAT_ITEM_OPP},
    {name => 'Bingoless Games',       type => STAT_ITEM_OPP},
    {name => 'Bonus Square Coverage', type => STAT_ITEM_OPP},
    {name => 'Phony Plays',           type => STAT_ITEM_OPP},
);

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
    A => 0,
    B => 1,
    C => 2,
    D => 3,
    E => 4,
    F => 5,
    G => 6,
    H => 7,
    I => 8,
    J => 9,
    K => 10,
    L => 11,
    M => 12,
    N => 13,
    O => 14
};

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

use constant TITLE_WIDTH   => 25;
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

1;


