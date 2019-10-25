#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
use Cwd;

use lib 'MineGCGDEV/modules';
use Constants;

  sub sanitize_name
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
  
  sub sanitize_number
  {
    my $string = shift;
  
    $string = substr( $string, 0, 256);
  
    # Remove trailing and leading whitespace
    $string =~ s/^\s+|\s+$//g;
  
    # Remove anything that is not a number
    $string =~ s/[^\d]//g;
  
    return $string;
  }



my $name;
my $cort      = '';
my $game      = '';
my $tid       = '';
my $gid       = '';
my $opp       = '';
my $start     = '';
my $end       = '';
my $lexicon   = '';
my $dir       = '';

my $name_option = Constants::PLAYER_FIELD_NAME         ;
my $cort_option = Constants::CORT_FIELD_NAME           ;
my $gid_option = Constants::GAME_ID_FIELD_NAME        ;
my $tid_option = Constants::TOURNAMENT_ID_FIELD_NAME  ;
my $opp_option = Constants::OPPONENT_FIELD_NAME       ;
my $start_option = Constants::START_DATE_FIELD_NAME     ;
my $end_option = Constants::END_DATE_FIELD_NAME       ;
my $lex_option = Constants::LEXICON_FIELD_NAME        ;
my $dir_option = Constants::DIRECTORY_FIELD_NAME      ;

GetOptions (
            "$name_option=s"      => \$name,
            "$cort_option:s"      => \$cort,
            "$gid_option:s"       => \$game,
            "$tid_option:s"       => \$tid,
            "$gid_option:s"       => \$gid,
            "$opp_option:s"       => \$opp,
            "$start_option:s"     => \$start,
            "$end_option:s"       => \$end,
            "$lex_option:s"       => \$lexicon,
	    "$dir_option:s"       => \$dir
           );

  my $name_arg = '--name "' . sanitize_name($name) . '"';
  my $cort_arg = "";
  my $tid_arg = "";
  my $gid_arg = "";
  my $opp_arg = "";
  my $start_arg = "";
  my $end_arg = "";
  my $lexicon_arg = "";
  
  if ($cort)
  {
    $cort_arg = "--$cort_option ". sanitize_name($cort);
  }
  
  if ($tid)
  {
    $tid_arg = "--$tid_option " . sanitize_number($tid);
  }
  
  if ($gid)
  {
    $gid_arg = "--$gid_option ". sanitize_number($gid);
  }
  
  if ($opp)
  {
    $opp_arg = "--$opp_option " . sanitize_name($opp);
  }
  
  if ($start)
  {
    $start_arg = "--$start_option " . sanitize_number($start);
  }
  
  if ($end)
  {
    $end_arg = "--$end_option " . sanitize_number($end);
  }
  
  if ($lexicon)
  {
    $lexicon_arg = "--$lex_option " . sanitize_name($lexicon);
  }


chdir ($dir);
my $cmd =  "./scripts/webapp_main.pl $name_arg $cort_arg $tid_arg $gid_arg $opp_arg $start_arg $end_arg $lexicon_arg";
system $cmd;
