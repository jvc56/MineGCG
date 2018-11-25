#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use lib '.';
use Constants;

my $games_dir = Constants::GAME_DIRECTORY_NAME;
my $names_dir = Constants::NAMES_DIRECTORY_NAME;

my $invalid_indexes = 0;
my $malformed_indexes = 0;
my $invalid_games = 0;
my $malformed_games = 0;
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
      print "Index $_ in file $name_file has no game file\n";
      $invalid_indexes++;
    }
    else
    {
      $existing_games{$_} = 1;
    }
    my @items = split /\./, $_;
    if (scalar @items != 9 || $items[0] eq ""  || $items[1] eq "" || $items[2] eq "" || $items[3] eq "" || $items[4] eq ""  || $items[5] eq "" || $items[6] eq "" || $items[7] eq "" || $items[8] eq "")
    {
      print "Index $_ in file $name_file is malformed\n";
      $malformed_indexes++;
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
    print "Game $game_file has no index\n";
    $invalid_games++;
  }
  my @items = split /\./, $game_file;

  if (scalar @items != 9 || $items[0] eq ""  || $items[1] eq "" || $items[2] eq "" || $items[3] eq "" || $items[4] eq ""  || $items[5] eq "" || $items[6] eq "" || $items[7] eq "" || $items[8] eq "")
  {
    print "Game $game_file is malformed\n";
    $malformed_games++;
  }
}

print "\n\nInvalid indexes:     $invalid_indexes\n";
print "Malformed indexes:   $malformed_indexes\n";
print "Invalid games:       $invalid_games\n";
print "Malformed games:     $malformed_games\n";
#print Dumper(\%existing_games);




 








