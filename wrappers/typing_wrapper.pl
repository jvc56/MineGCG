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



my $min_length = '';
my $max_length = '';
my $min_prob   = '';
my $max_prob   = '';
my $num_words  = '';
my $dir        = '';

my $min_length_option = Constants::TYPING_MIN_LENGTH_FIELD_NAME;
my $max_length_option = Constants::TYPING_MAX_LENGTH_FIELD_NAME;
my $min_prob_option   = Constants::TYPING_MIN_PROB_FIELD_NAME;
my $max_prob_option   = Constants::TYPING_MAX_PROB_FIELD_NAME;
my $num_words_option  = Constants::TYPING_NUM_WORDS_FIELD_NAME;
my $dir_option        = Constants::DIRECTORY_FIELD_NAME;

GetOptions (
            "$min_length_option:s" => \$min_length,
            "$max_length_option:s" => \$max_length,
            "$min_prob_option:s"   => \$min_prob,
            "$max_prob_option:s"   => \$min_prob,
            "$num_words_option:s"  => \$num_words,
            "$dir_option:s"        => \$dir
           );

my $min_length_arg = "";
my $max_length_arg = "";
my $min_prob_arg   = "";
my $max_prob_arg   = "";
my $num_words_arg  = "";
  
if ($min_length)
{
  $min_length_arg = "--$min_length_option ". sanitize_number($min_length);
}
if ($max_length)
{
  $max_length_arg = "--$max_length_option ". sanitize_number($max_length);
}
if ($min_prob)
{
  $min_prob_arg = "--$min_prob_option ". sanitize_number($min_prob);
}
if ($max_prob)
{
  $max_prob_arg = "--$max_prob_option ". sanitize_number($max_prob);
}
if ($num_words)
{
  $num_words_arg = "--$num_words_option ". sanitize_number($num_words);
}

my $typing_script = Constants::TYPING_CGI_SCRIPT;
chdir ($dir);
my $cmd =  "./scripts/$typing_script $min_length_arg $max_length_arg $min_prob_arg $max_prob_arg $num_words_arg";
system $cmd;

