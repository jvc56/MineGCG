#!/usr/bin/perl

package Passage;

use warnings;
use strict;
use Data::Dumper;

use lib "./modules";

use Constants;
use Utils;

sub passage
{
  my $min_length = shift;
  my $max_length = shift;
  my $min_prob   = shift;
  my $max_prob   = shift;
  my $num_words  = shift;

  my $dbh = Utils::connect_to_typing_database();

  my $table_name = Constants::WORDS_TABLE_NAME;
  my $word_column_name = Constants::WORD_COLUMN_NAME;
  my $word_length_column_name = Constants::WORD_LENGTH_COLUMN_NAME;
  my $word_prob_column_name = Constants::WORD_PROBABILITY_COLUMN_NAME;

  my $query =
  "
  SELECT $word_column_name
  FROM $table_name
  ";

  my $nonzero_valid_params =
  $min_length ||
  $max_length ||
  $min_prob   ||
  $max_prob; 

  if ($nonzero_valid_params)
  {
    $query .= "\n  WHERE\n";
    my $and = '';
    if ($min_length)
    {
      $query .= "$word_length_column_name >= $min_length";
      $and = ' AND ';
    }
    if ($max_length)
    {
      $query .= "$and $word_length_column_name <= $max_length";
      $and = ' AND ';
    }
    if ($min_prob)
    {
      $query .= "$and $word_length_column_name >= $min_prob";
      $and = ' AND ';
    }
    if ($max_prob)
    {
      $query .= "$and $word_length_column_name <= $max_prob";
    }
  }
  if (!$num_words)
  {
    $num_words = Constants::DEFAULT_NUMBER_OF_PASSAGE_WORDS;
  } 
  $query .= " ORDER BY random() LIMIT $num_words ";
  my @passage = @{$dbh->selectall_arrayref($query, {"RaiseError" => 1})};
  my $result = join (" ", map {$_->[0]} @passage);
  print $result;
}

1;

