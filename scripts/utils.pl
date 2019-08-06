#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use DBI;

use lib "./objects"; 
use lib "./lexicons";

use Constants;
use CSW07;
use CSW12;
use CSW15;
use CSW19;
use TWL98;
use TWL06;
use American;
use NSW18;

sub connect_to_database
{
  my $driver        = Constants::DATABASE_DRIVER;
  my $database_name = Constants::DATABASE_NAME;
  my $hostname      = Constants::DATABASE_HOSTNAME;
  my $username      = Constants::DATABASE_USERNAME;
  my $password      = Constants::DATABASE_PASSWORD;

  my $dbh = DBI->connect("DBI:$driver:dbname = $database_name;host=$hostname",
                         $username, $password) or die $DBI::errstr;

  $dbh->do("SET client_min_messages TO WARNING");

  my $tables_hashref = Constants::DATABASE_TABLES;
  my $creation_order = Constants::TABLE_CREATION_ORDER;

  for(my $i = 0; $i < scalar @{$creation_order}; $i++)
  {
    my $key = $creation_order->[$i];
    my @columns = @{$tables_hashref->{$key}};
    my $columns_string = join ", ", @columns;
    my $statement = "CREATE TABLE IF NOT EXISTS $key ($columns_string);";
    $dbh->do($statement);
  }   
  return $dbh;
}

sub query_table
{
  my $dbh       = shift;
  my $tablename = shift;
  my $fieldname = shift;
  my $value     = shift;

  my $arrayref =  $dbh->selectall_arrayref("SELECT * FROM $tablename WHERE $fieldname = '$value'", {Slice => {}}) or die DBI::errstr;
  return $arrayref;
}

sub insert_or_set_hash_into_table
{
  my $dbh       = shift;
  my $table     = shift;
  my $hashref   = shift;
  my $record_id = shift;

  my $stmt;

  if (!$record_id)
  {
    my $keys_string   = "("; 
    my $values_string = "("; 

    foreach my $key (keys %{$hashref})
    {
      $keys_string   .= "$key,";
      if (defined $hashref->{$key})
      {    
        $values_string .= "'$hashref->{$key}',";
      }
      else
      {
        $values_string .= "NULL,";
      }
    }

    chop($keys_string);
    chop($values_string);

    if (!$keys_string || !$values_string)
    {
      return undef;
    }

    $keys_string   .= ")"; 
    $values_string .= ")"; 

    $stmt = "INSERT INTO $table $keys_string VALUES $values_string;";
    $dbh->do($stmt) or die DBI::errstr;
    return $dbh->last_insert_id(undef, undef, $table, undef);
  }
  else
  {
    my $set_stmt   = ""; 
    foreach my $key (keys %{$hashref})
    {
      my $value;
      if (defined $hashref->{$key})
      {    
        $value = "'$hashref->{$key}'";
      }
      else
      {
        $value = "NULL";
      }
      $set_stmt = "$key = $value,";
    }
    chop($set_stmt);
    $stmt = "UPDATE $table SET $set_stmt WHERE id = '$record_id'";
    $dbh->do($stmt) or die DBI::errstr;
    return $record_id;
  }

}

sub delete_function_from_statslist
{
  my $stats = shift;

  foreach my $stat (@{$stats})
  {
    delete $stat->{Constants::STAT_FUNCTION_NAME};
  }
  return $stats;
}

sub get_lexicon_ref
{
  my $lexicon = shift;
  my $lexicon_ref = undef;

  if ($lexicon eq 'TWL98')
  {
    $lexicon_ref = TWL98::TWL98_LEXICON;
  }
  elsif ($lexicon eq 'TWL06')
  {
    $lexicon_ref = TWL06::TWL06_LEXICON;
  }
  elsif ($lexicon eq 'TWL15')
  {
    $lexicon_ref = American::AMERICAN_LEXICON;
  }
  elsif ($lexicon eq 'NSW18')
  {
    $lexicon_ref = NSW18::NSW18_LEXICON;
  }
  elsif ($lexicon eq 'CSW07')
  {
    $lexicon_ref = CSW07::CSW07_LEXICON;
  }
  elsif ($lexicon eq 'CSW12')
  {
    $lexicon_ref = CSW12::CSW12_LEXICON;
  }
  elsif ($lexicon eq 'CSW15')
  {
    $lexicon_ref = CSW15::CSW15_LEXICON;
  }
  elsif ($lexicon eq 'CSW19')
  {
    $lexicon_ref = CSW19::CSW19_LEXICON;
  }
  return $lexicon_ref;
}

sub sanitize
{
  my $string = shift;

  # Remove trailing and leading whitespace
  $string =~ s/^\s+|\s+$//g;

  # Replace spaces with underscores
  $string =~ s/ /_/g;

  # Remove anything that is not an
  # underscore, dash, letter, or number
  $string =~ s/[^\w\-]//g;

  # Capitalize
  $string = uc $string;

  return $string;
}

sub database_sanitize
{
  my $s = shift;

  $s =~ s/'/''/g;

  return $s;
}

1;
