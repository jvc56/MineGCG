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
    print "Invalid number of items in filename\n";
    $valid = 0;
  }
  if (!($items[0] =~ /(\d\d\d\d\-\d\d\-\d\d)/ || $items[0] eq "0"))
  {
    print "Item 0 invalid\n";
    $valid = 0;
  }
  if (!($items[1] =~ /^\d+$/))
  {
    print "Item 1 invalid\n";
    $valid = 0;
  }
  if (!($items[2] =~ /^\d+$/))
  {
    print "Item 2 invalid\n";
    $valid = 0;
  }
  if (!($items[3] =~ /^[\w\d\-_]+$/))
  {
    print "Item 3 invalid\n";
    $valid = 0;
  }
  if (!($items[4] =~ /^\w+\d+$/))
  {
    print "Item 4 invalid\n";
    $valid = 0;
  }
  if (!($items[5] =~ /^\d+$/))
  {
    print "Item 5 invalid\n";
    $valid = 0;
  }
  if (!($items[6] =~ /^\w+\-?\w*$/))
  {
    print "Item 6 invalid\n";
    $valid = 0;
  }
  if (!($items[7] =~ /^\w+\-?\w*$/))
  {
    print "Item 7 invalid\n";
    $valid = 0;
  }
  if ($items[8] ne "gcg")
  {
    print "Item 8 invalid\n";
    $valid = 0;
  }
  return $valid;
}

1;
