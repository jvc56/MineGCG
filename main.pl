#!/usr/bin/perl

use warnings;
use strict;

require "./retrieve_games.pl";

my ($name, $dir) = @ARGV;

retrieve($name, $dir);
