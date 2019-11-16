#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long qw(GetOptionsFromArray GetOptions :config pass_through);

my @arguments = @ARGV;
my $dir  = '';
my $wcgi = '';

GetOptionsFromArray
           (
             \@arguments,
             'directory:s'       => \$dir,
             'whichcgi:s'         => \$wcgi
           );

@arguments = @ARGV;

chdir($dir);

if ($wcgi eq 'player_search')
{
  my $name = '';
  my $cort = '';
  my $gameid = '';
  my $tournamentid = '';
  my $opponent = '';
  my $startdate = '';
  my $enddate = '';
  my $lexicon = '';


  GetOptions
  (
    'name:s' => \$name,
    'cort:s' => \$cort,
    'gameid:s' => \$gameid,
    'tournamentid:s' => \$tournamentid,
    'opponent:s' => \$opponent,
    'startdate:s' => \$startdate,
    'enddate:s' => \$enddate,
    'lexicon:s' => \$lexicon,
  );


  require './modules/Mine.pm';
  Mine::mine
  (
    $name,
    $cort,
    $gameid,
    $opponent,
    $startdate,
    $enddate,
    $lexicon,
    0,
    $tournamentid,
    0,
    1,
    0
  );

}
elsif ($wcgi eq 'typing_search')
{
  my $min_length = '';
  my $max_length = '';
  my $min_prob = '';
  my $max_prob = '';
  my $num_words = '';


  GetOptions
  (
    'min_length:s' => \$min_length,
    'max_length:s' => \$max_length,
    'min_prob:s' => \$min_prob,
    'max_prob:s' => \$max_prob,
    'num_words:s' => \$num_words,
  );


  require './modules/Passage.pm';
  Passage::passage
  (
    $min_length,
    $max_length,
    $min_prob,
    $max_prob,
    $num_words
  );

}
elsif ($wcgi eq 'cron')
{



system './scripts/daily_cronjob.pl';
}


sub sanitize
{
  my $string = shift;

  $string = substr( $string, 0, 256);

  # Remove trailing and leading whitespace
  $string =~ s/^\s+|\s+$//g;

  # Replace spaces with underscores
  $string =~ s/ /_/g;

  # Remove anything that is not an
  # underscore, dash, letter, or number
  $string =~ s/[^\w-]//g;

  # Capitalize
  $string = uc $string;

  return $string;
}

  
