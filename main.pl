#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage qw(pod2usage);
use Cwd qw(abs_path getcwd);

require "./retrieve_games.pl";
require "./mine_games.pl";

my $verbose = '';
my $update  = '';
my $reset   = '';
my $cort    = '';
my $tid     = '';
my $dir;
my $name;

my $man  = 0;
my $help = 0;
GetOptions (
            'verbose'          => \$verbose,
            'update'           => \$update,
            'reset'            => \$reset,
            'cort:s'           => \$cort,
            'tournament-id:s'  => \$tid,
            'dir=s'            => \$dir,
            'name=s'           => \$name,
            'help|?'           => \$help
           );

pod2usage(1) if $help || !$dir || !$name;

my $cp = getcwd();
my $gp = abs_path($dir);

if ($cp eq $gp)
{
  print "\nDo not use the current directory for storing game files\n";
  print "Specify a different directory, subdirectories are recommended\n";
  print "For example ./games\n\n";
  exit(0);
}

my $option = "";
if ($update)
{
  $option = "update";
}
if ($reset)
{
  $option = "reset";
}

$name =~ s/'//g;
retrieve($name, $dir, $option, $tid, $cort, $verbose);
mine($name, $dir, $cort, $verbose, $tid);

open (CMDOUT, "git fetch --dry-run 2>&1 |");
my $response = '';
while (<CMDOUT>)
{
  $response .= $_;
}

if (!$response)
{
  print "Completed with the latest version of MineGCG\n"
}
else
{
  print "Your current version of MineGCG is out of date!\n";
  print "Use 'git pull' to get the latest version\n";
}



__END__
 
=head1 SYNOPSIS
 

 ./main.pl -n=<playername> -d=<directory> [-v] [-u] [-r] [-c=<gametype>] [-t=<tournamentid>]

 
 Options:
   -h, --help            brief help message
   -v, --verbose         print statistics for each game being processed
   -u, --update          update the game directory specified by -d with
                         missing games for the player specified by -n
   -r, --reset           delete the directory specified by -d and remake
                         it with games from the player specified by -n
   -c, --cort            option to specify whether to process just club and casual
                         games (-c=<c>) or just tournament games (-c=<t>)
   -t, --tournament-id   optional argument to specify a particular tournament
                         for which statistics will be calculated. If this option 
                         is specified, only games from that tournament will be processed.
                         The tournament id is the id in the cross-tables url of the tournament.
                         For example, the cross-tables url for the 29th National Championship is

                         https://www.cross-tables.com/tourney.php?t=10353&div=1

                         Which has a tournament id of 10353

   -d, --dir             full path name of the directory to which games
                         will be stored
   -n, --name            name of the player whose games will be processed
                         (Must be in quotes, for example, "Matthew O'Connor")

 Example:
   The following command:

     ./main.pl -n "Joshua Castellano" -d ./games -v -u

   will download any of Joshua Castellano's annotated cross-tables.com
   games that do not exist in the directory ./games and print the statistics
   and board for each individual tournament game as well as the statistics
   for all of the tournament games combined
 
=cut

