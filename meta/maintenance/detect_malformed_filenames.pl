#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

require "./scripts/validate_filename.pl";

use lib './objects';
use Constants;

use Getopt::Long;

my $delete = '';
GetOptions ('delete' => \$delete);
my $games_dir               = Constants::GAME_DIRECTORY_NAME;
my $names_dir               = Constants::NAMES_DIRECTORY_NAME;
my $blacklisted_tournaments = Constants::BLACKLISTED_TOURNAMENTS;
my $num_deleted_games       = 0;
my $num_deleted_indexes     = 0;
my $malformed_name_filenames = 0;
# Delete malformed game names
print "\n\n\nMalformed filenames:\n\n";
opendir my $games, $games_dir or die "Cannot open directory: $!";
my @game_files = readdir $games;
closedir $games;
foreach my $game_file_name (@game_files)
{
  if ($game_file_name eq "." || $game_file_name eq "..")
  {
    next;
  }
  if (!(validate_filename($game_file_name)))
  {
    print "Game: $game_file_name\n";
    if ($delete)
    {
      system "rm '$games_dir/$game_file_name'";
      print "Deleted $games_dir/$game_file_name\n";
    }
    $num_deleted_games++;
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
  
  if (!(validate_textfilename($name_file_name)))
  {
    print "Name filename: $name_file_name\n";
    $malformed_name_filenames++;
  }

  my $old_file_name = "$names_dir/$name_file_name";
  open(NAME_FILE, '<', $old_file_name);

  if ($delete)
  {
    my $new_file_name = "$names_dir/$name_file_name".".new";
    open(my $new_file, '>', $new_file_name);
    while(<NAME_FILE>)
    {
      chomp $_;
      if (validate_filename($_))
      {
        print $new_file $_ . "\n";
      }
      else
      {
        print "Removed $_";
        $num_deleted_indexes++;
      }
    }
    system "cp $new_file_name $old_file_name";
    system "rm '$new_file_name'";
  }
  else
  {
    while(<NAME_FILE>)
    {
      chomp $_;
      if (!(validate_filename($_)))
      {
        print "Index in $old_file_name: $_\n";
        $num_deleted_indexes++;
      }
    }
  }
}

print "\n\n";

if ($delete)
{
  print "Deleted $num_deleted_games malformed games\n";
  print "Deleted $num_deleted_indexes malformed indexes\n";
}
else
{
  print "Detected $num_deleted_games malformed games\n";
  print "Detected $num_deleted_indexes malformed indexes\n";  
  print "Detected $malformed_name_filenames malformed name filenames\n";  
}
