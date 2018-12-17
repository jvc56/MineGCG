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

1;
