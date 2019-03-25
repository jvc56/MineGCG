#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use lib './objects';
use Constants;

require "./scripts/validate_filename.pl";

my $games_dir = Constants::GAME_DIRECTORY_NAME;
my $names_dir = Constants::NAMES_DIRECTORY_NAME;

my $num_invalid_indexes = 0;
my $invalid_indexes = "";
my $num_malformed_indexes = 0;
my $malformed_indexes = "";
my $num_invalid_games = 0;
my $invalid_games = "";
my $num_malformed_games = 0;
my $malformed_games = "";

my %existing_games = ();

# Check that every index points to a game
# and is valid

opendir my $names, $names_dir or die "Cannot open directory: $!";
my @name_files = readdir $names;
closedir $names;

foreach my $name_file (@name_files)
{
  if ($name_file eq '.' || $name_file eq "..")
  {
    next;
  }

  my $full_name = "$names_dir/$name_file";
  open(INDEXES, '<', $full_name);

  while (<INDEXES>)
  {

    chomp $_;
    my $corresp_game = "$games_dir/$_";
    
    if (!(-e $corresp_game))
    {
      $invalid_indexes .= "$_\n";
      $num_invalid_indexes++;
    }
    else
    {
      $existing_games{$_} = 1;
    }
    if (!validate_filename($_))
    {
      $malformed_indexes .= "$_\n";
      $num_malformed_indexes++;
    }
  } 
}

opendir my $games, $games_dir or die "Cannot open directory: $!";
my @game_files = readdir $games;
closedir $games;

foreach my $game_file (@game_files)
{
  if ($game_file eq '.' || $game_file eq "..")
  {
    next;
  }
  if (!$existing_games{$game_file})
  {
    $invalid_games .= "$game_file\n";
    $num_invalid_games++;
  }
  if (!validate_filename($game_file))
  {
    $malformed_games .= "$game_file\n";
    $num_malformed_games++;
  }
}

print "\n\nInvalid indexes:     $num_invalid_indexes\n";
print "\n$invalid_indexes\n";
print "Malformed indexes:   $num_malformed_indexes\n";
print "\n$malformed_indexes\n";
print "Invalid games:       $num_invalid_games\n";
print "\n$invalid_games\n";
print "Malformed games:     $num_malformed_games\n";
print "\n$malformed_games\n";




 








