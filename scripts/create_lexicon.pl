#!/usr/bin/perl


use warnings;
use strict;
use Data::Dumper;

use lib './modules';
use Constants;
use Utils;
use Update;
use CSW19;

my $dbh = Utils::connect_to_typing_database();

my $dictionary_hash = CSW19::CSW19_LEXICON;
my $word_column_name = Constants::WORD_COLUMN_NAME;
my $word_length_column_name = Constants::WORD_LENGTH_COLUMN_NAME;
my $table = Constants::WORDS_TABLE_NAME;

my $insert = "INSERT INTO $table ($word_column_name, $word_length_column_name) VALUES (?,?)";
my $sth = $dbh->prepare($insert);

foreach my $word (keys %{$dictionary_hash})
{
  $sth->execute(($word, length $word));
}
