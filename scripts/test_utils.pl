#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use DBI;

use lib './objects';
use Constants;

require './scripts/utils.pl';

connect_to_database();


