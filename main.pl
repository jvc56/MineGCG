#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage qw(pod2usage);

require "./retrieve_games.pl";
require "./mine_games.pl";


my $verbose = '';
my $update  = '';
my $reset   = '';
my $torc    = '';
my $dir;
my $name;

my $man  = 0;
my $help = 0;
GetOptions (
            'verbose' => \$verbose,
            'update'  => \$update,
            'reset'   => \$reset,
            'torc:s'  => \$torc,
            'dir=s'   => \$dir,
            'name=s'  => \$name,
            'help|?'  => \$help
           );

pod2usage(1) if $help || !$dir || !$name;

my $option = "";
if ($update)
{
  $option = "update";
}
if ($reset)
{
  $option = "reset";
}

retrieve($name, $dir, $option);
mine($name, $dir, $torc, $verbose);

__END__
 
=head1 SYNOPSIS
 

 ./main.pl -n=<playername> -d=<directory> [-v] [-u] [-r] [-t=<gametype>]

 
 Options:
   -h, --help       brief help message
   -v, --verbose    print statistics show each game being processed
   -u, --update     update the game directory specified by -d with
                    missing games for the player specified by -n
   -r, --reset      delete the directory specified by -d and remake
                    it with games from the player specified by -n
   -t, --torc       option to specify whether to process just club and casual
                    games (-t=<c>) or just tournament games (-t=<t>)
                    (Note: every annotated game will still be downloaded from
                    cross-tables.com, only the specified games will appear in
                    the statistics)
   -d, --dir        full path name of the directory to which games
                    will be stored
   -n, --name       name of the player whose games will be processed
                    (Must be in quotes, for example, "Matthew O'Connor")

 Example:
   The following command:

     ./main.pl -n "Joshua Castellano" -d ./games -v -u -t t

   will download any of Joshua Castellano's annotated cross-tables.com
   games that do not exist in the directory ./games and print the statistics
   and board for each individual tournament game as well as the statistics
   for all of the tournament games combined
 
=cut

