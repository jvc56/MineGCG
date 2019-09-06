#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

use lib './modules';

use Mine;
use Constants;

my $name;
my $cort      = '';
my $game      = '';
my $tid       = '';
my $opponent  = '';
my $startdate = '';
my $enddate   = '';
my $lexicon   = '';

my $name_option = Constants::PLAYER_FIELD_NAME         ;
my $cort_option = Constants::CORT_FIELD_NAME           ;
my $gid_option = Constants::GAME_ID_FIELD_NAME        ;
my $tid_option = Constants::TOURNAMENT_ID_FIELD_NAME  ;
my $opp_option = Constants::OPPONENT_FIELD_NAME       ;
my $start_option = Constants::START_DATE_FIELD_NAME     ;
my $end_option = Constants::END_DATE_FIELD_NAME       ;
my $lex_option = Constants::LEXICON_FIELD_NAME        ;


GetOptions (
            "$name_option=s"      => \$name,
            "$cort_option:s"      => \$cort,
            "$gid_option:s"      => \$game,
            "$tid_option:s"       => \$tid,
            "$opp_option:s"  => \$opponent,
            "$start_option:s" => \$startdate,
            "$end_option:s"   => \$enddate,
            "$lex_option:s"   => \$lexicon
           );



Mine::mine
(
  $name,
  $cort,
  $game,
  $opponent,
  $startdate,
  $enddate,
  $lexicon,
  0,
  $tid,
  0,
  1,
  0
);

