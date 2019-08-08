#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage qw(pod2usage);

use lib './modules';
use lib './objects';

use Retrieve;
use Mine;
use Utils;


my $verbose        = '';
my $update         = '';
my $cort           = '';
my $tid            = '';
my $html           = '';
my $game           = '';
my $opponent       = '';
my $opponent_sanitized;
my $startdate      = '';
my $enddate        = '';
my $lexicon        = '';
my $statsdump      = '';
my $missingracks   = '';
my $name;
my $raw_name;

my $man  = 0;
my $help = 0;
GetOptions (
            'verbose'          => \$verbose,
            'update=s'         => \$update,
            'game:s'           => \$game,
            'cort:s'           => \$cort,
            'tournamentid:s'   => \$tid,
            'opponent:s'       => \$opponent,
            'startdate:s'      => \$startdate,
            'enddate:s'        => \$enddate,
            'lexicon:s'        => \$lexicon,
            'statsdump:s'      => \$statsdump,
            'html'             => \$html,
            'missingracks'     => \$missingracks,
            'name=s'           => \$name,
            'help|?'           => \$help
           );

pod2usage(1) if $help || !$name || ($update && ($update ne Constants::UPDATE_OPTION_KEYS  &&
                                                $update ne Constants::UPDATE_OPTION_STATS &&
                                                $update ne Constants::UPDATE_OPTION_GCG   )
                                   );

$raw_name           = $name;
$name               = Utils::sanitize($name);
$opponent_sanitized = Utils::sanitize($opponent);
$startdate          =~ s/[^\d]//g;
$enddate            =~ s/[^\d]//g;
$lexicon            = uc $lexicon;

Retrieve::retrieve($name, $raw_name, $update, $tid, $cort, $game, $opponent_sanitized, $startdate, $enddate, $lexicon, $verbose, $html, $missingracks);
Mine::mine    ($name, $cort, $game, $opponent_sanitized, $startdate, $enddate, $lexicon, $verbose, $tid, $statsdump, $html, $missingracks);


__END__
 
=head1 SYNOPSIS
 

 ./main.pl -n=<playername> [-v] [-u=(keys|stats|gcg)] [-r] [-c=<gametype>] [-t=<tournamentid>]

 
 Options:
   -h, --help            brief help message

=cut

