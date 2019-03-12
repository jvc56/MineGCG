#!/usr/bin/perl

package Tile;

use warnings;
use strict;

sub new
{
  my $this = shift;

  my $c = shift;
  my $placed_by = shift;
  my $play_number = shift;

  my $value = $this->charToValue($c);

  my $is_blank = 0;
  if (!$value || $value == 0)
  {
  	$is_blank = 1;
  }

  my %tile =
  (
  	char        => $c,
    value       => $value,
    is_blank    => $is_blank,
    placed_by   => $placed_by,
    play_number => $play_number
  );

  my $self = bless \%tile, $this;
  return $self;
}

sub charToValue
{
  my $this = shift;
  
  my $c = shift;

  return Constants::CHAR_TO_VALUE->{$c};
}

1;

