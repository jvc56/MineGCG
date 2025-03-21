#!/usr/bin/perl

package Square;

use warnings;
use strict;
use Data::Dumper;
use lib './modules';
use Constants;

sub new
{
  my $this = shift;

  my $position = shift;
  my $turn = shift;

  my $bonus = substr(Constants::BONUS_SQUARE_STRING, $position, 1);

  my %square =
  (
  	position => $position,
  	bonus    => $bonus,
  	has_tile => 0,
  	tile     => undef
  );

  my $self = bless \%square, $this;
  return $self;
}

sub addTile
{
	my $this = shift;
	my $tile = shift;
  $this->{'has_tile'} = 1;
	$this->{'tile'} = $tile;
}

sub removeTile
{
	my $this = shift;
	$this->{'tile'} = undef;
}

sub toString
{
  my $this = shift;

  if ($this->{'tile'})
  {
    return $this->{'tile'}->{'char'};
  }
  else
  {
    return $this->{'bonus'};
  }
}
1;

