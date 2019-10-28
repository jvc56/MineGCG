#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

use lib './modules';

use Passage;
use Constants;

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
            "$max_prob_option:s"   => \$max_prob,
            "$num_words_option:s"  => \$num_words,
            "$dir_option:s"        => \$dir
           );

Passage::passage
(
  $min_length,
  $max_length,
  $min_prob,
  $max_prob,
  $num_words
);

