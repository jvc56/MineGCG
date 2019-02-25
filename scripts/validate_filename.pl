#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

sub validate_textfilename
{
  my $filename = shift;

  return $filename =~ /^\w+\-?\w*.txt/;
}

sub validate_filename
{
  my $filename = shift;

  my @items = split /\./, $filename;

  my $valid = 1;

  if (scalar @items != 9)
  {
    $valid = 0;
  }
  if (!($items[0] =~ /(\d\d\d\d\-\d\d\-\d\d)/ || $items[0] eq "0"))
  {
    $valid = 0;
  }
  if (!($items[1] =~ /^\d+$/))
  {
    $valid = 0;
  }
  if (!($items[2] =~ /^\d+$/))
  {
    $valid = 0;
  }
  if (!($items[3] eq "0" || $items[3] eq "1"))
  {
    $valid = 0;
  }
  if (!($items[4] =~ /^\w+\d+$/))
  {
    $valid = 0;
  }
  if (!($items[5] =~ /^\d+$/))
  {
    $valid = 0;
  }
  if (!($items[6] =~ /^\w+\-?\w*$/))
  {
    $valid = 0;
  }
  if (!($items[7] =~ /^\w+\-?\w*$/))
  {
    $valid = 0;
  }
  if ($items[8] ne "gcg")
  {
    $valid = 0;
  }
  return $valid;
}

1;
