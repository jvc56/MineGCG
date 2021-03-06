#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage qw(pod2usage);

use lib './modules';
use lib './objects';

use Mine;
use Constants;


my $verbose        = '';
my $cort           = '';
my $tid            = '';
my $game_min           = '';
my $game_max           = '';
my $opponent       = '';
my $startdate      = '';
my $enddate        = '';
my $lexicon        = '';
my $statsdump      = '';
my $missingracks   = '';
my $name;
my $raw_name;

my $man  = 0;
my $help = 0;

  my $name_option = Constants::PLAYER_FIELD_NAME         ;
  my $cort_option = Constants::CORT_FIELD_NAME           ;
  my $gid_min_option = Constants::GAME_ID_MIN_FIELD_NAME        ;
  my $gid_max_option = Constants::GAME_ID_MAX_FIELD_NAME        ;
  my $tid_option = Constants::TOURNAMENT_ID_FIELD_NAME  ;
  my $opp_option = Constants::OPPONENT_FIELD_NAME       ;
  my $start_option = Constants::START_DATE_FIELD_NAME     ;
  my $end_option = Constants::END_DATE_FIELD_NAME       ;
  my $lex_option = Constants::LEXICON_FIELD_NAME        ;


GetOptions (
            "verbose"          => \$verbose,
            "$gid_min_option:s"    => \$game_min,
            "$gid_max_option:s"    => \$game_max,
            "$cort_option:s"   => \$cort,
            "$tid_option:s"    => \$tid,
            "$opp_option:s"    => \$opponent,
            "$start_option:s"  => \$startdate,
            "$end_option:s"    => \$enddate,
            "$lex_option:s"    => \$lexicon,
            "statsdump"        => \$statsdump,
            "missingracks"     => \$missingracks,
            "name=s"           => \$name,
            "help|?"           => \$help
           );

pod2usage(1) if $help || !$name;

Mine::mine($name, $cort, $game_min, $game_max, $opponent, $startdate, $enddate, $lexicon, $verbose, $tid, $statsdump, $missingracks);


__END__
 
=head1 SYNOPSIS
 

 ./main.pl -n=<playername> [-v] [-u=(keys|stats|gcg)] [-r] [-c=<gametype>] [-t=<tournamentid>]

 
 Options:
   -h, --help            brief help message

=cut

