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


  my %tile =
  (
  	char        => $c,
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

