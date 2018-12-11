#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

sub sanitize
{
  my $string = shift;
  my $type   = shift;

  # Remove trailing and leading whitespace
  $string =~ s/^\s+|\s+$//g;

  # Remove all special characters
  $string =~ s/\^\$\.\*\+\?\|\(\)\[\]\{\}\\//g;

  # Replace spaces with underscores
  $string =~ s/ /_/g;

  # Capitalize names
  if ($type && $type eq "name")
  {
    $string = uc $string;
  }

  return $string;
}


sub sanitize_filename
{
  my $filename = shift;
  chomp $filename;

  my @items = split /\./, $filename;

  my $sanitized_tourney_name    = sanitize($items[3]);
  my $sanitized_player_one_name = sanitize($items[6], "name");
  my $sanitized_player_two_name = sanitize($items[7], "name");

  my $new_file_name = join ".", (
                                 $items[0],
                                 $items[1],
                                 $items[2],
                                 $sanitized_tourney_name,
                                 $items[4],
                                 $items[5],
                                 $sanitized_player_one_name,
                                 $sanitized_player_two_name,
                                 $items[8]
                                );

  return $new_file_name;
}

1;
