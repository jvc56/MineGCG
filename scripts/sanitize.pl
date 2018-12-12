#!/usr/bin/perl

use warnings;
use strict;

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

sub sanitize_filename
{
  my $filename = shift;
  chomp $filename;

  my @items = split /\./, $filename;

  my $new_file_name = join ".", (
                                 sanitize($items[0]),
                                 sanitize($items[1]),
                                 sanitize($items[2]),
                                 sanitize($items[3]),
                                 sanitize($items[4]),
                                 sanitize($items[5]),
                                 sanitize($items[6]),
                                 sanitize($items[7]),
                                 $items[8]
                                );

  return $new_file_name;
}

1;
