#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage qw(pod2usage);

require "./scripts/retrieve_games.pl";
# require "./scripts/mine_games.pl";
require "./scripts/utils.pl";

my $verbose        = '';
my $update         = '';
my $reset          = '';
my $cort           = '';
my $tid            = '';
my $html           = '';
my $resolve        = '';
my $skipmetaupdate = '';
my $game           = '';
my $opponent       = '';
my $opponent_sanitized;
my $startdate      = '';
my $enddate        = '';
my $lexicon        = '';
my $statsdump      = '';
my $notabledump    = '';
my $missingracks   = '';
my $name;
my $raw_name;

my $man  = 0;
my $help = 0;
GetOptions (
            'verbose'          => \$verbose,
            'update'           => \$update,
            'game:s'           => \$game,
            'cort:s'           => \$cort,
            'tournamentid:s'   => \$tid,
            'opponent:s'       => \$opponent,
            'startdate:s'      => \$startdate,
            'enddate:s'        => \$enddate,
            'lexicon:s'        => \$lexicon,
            'html'             => \$html,
            'statsdump'        => \$statsdump,
            'notabledump'      => \$notabledump,
            'missingracks'     => \$missingracks,
            'name=s'           => \$name,
            'help|?'           => \$help
           );

pod2usage(1) if $help || !$name;

$raw_name = $name;
$name = sanitize($name);
$opponent_sanitized = sanitize($opponent);
$startdate =~ s/[^\d]//g;
$enddate =~ s/[^\d]//g;
$lexicon = uc $lexicon;

retrieve($name, $raw_name, $update, $tid, $cort, $game, $opponent_sanitized, $startdate, $enddate, $lexicon, $verbose, $html, $missingracks);
# mine($name, $cort, $game, $opponent_sanitized, $startdate, $enddate, $lexicon, $verbose, $tid, $html, $statsdump, $notabledump, $missingracks);


__END__
 
=head1 SYNOPSIS
 

 ./main.pl -n=<playername> [-v] [-u] [-r] [-c=<gametype>] [-t=<tournamentid>]

 
 Options:
   -h, --help            brief help message
   -v, --verbose         print statistics for each game being processed
   -u, --update          update the game directory specified by -d with
                         missing games for the player specified by -n
       --reset           delete the directory specified by -d and remake
                         it with games from the player specified by -n
   -c, --cort            option to specify whether to process just club and casual
                         games (-c=<c>) or just tournament games (-c=<t>)
   -t, --tournament-id   optional argument to specify a particular tournament
                         for which statistics will be calculated. If this option 
                         is specified, only games from that tournament will be processed.
                         The tournament id is the id in the cross-tables url of the tournament.
                         For example, the cross-tables url for the 29th National Championship is

                         https://www.cross-tables.com/tourney.php?t=10353&div=1

   -g, --game            Similar to the -t option except for individual games
                         instead of tournaments
   -s, --skipmetaupdate  Skip the check for the most recent version of MineGCG
                         Which has a tournament id of 10353
       --resolve         Attempt to resolve inconsistencies in game and index data
       --html            Make output HTML-friendly
   -n, --name            name of the player whose games will be processed
                         (Must be in quotes, for example, "Matthew O'Connor")

=cut

