#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use lib '.';
use Constants;

require "./sanitize.pl";

my $games_dir               = Constants::GAME_DIRECTORY_NAME;
my $names_dir               = Constants::NAMES_DIRECTORY_NAME;

# Delete malformed game names
opendir my $games, $games_dir or die "Cannot open directory: $!";
my @game_files = readdir $games;
closedir $games;
foreach my $game_file_name (@game_files)
{
  if ($game_file_name eq "." || $game_file_name eq "..")
  {
    next;
  }

  my $new_file_name = sanitize_filename($game_file_name);
  # >/dev/null 2>&1
  if ($new_file_name ne $game_file_name)
  {
    system "mv games/$game_file_name games/$new_file_name ";
  }
}

# Delete malformed games indexes
opendir my $names, $names_dir or die "Cannot open directory: $!";
my @name_files = readdir $names;
closedir $names;
foreach my $name_file_name (@name_files)
{

  if ($name_file_name eq "." || $name_file_name eq "..")
  {
    next;
  }

  my $cap_file_name = uc $name_file_name;

  system "mv $names_dir/$name_file_name $names_dir/$cap_file_name";
}

