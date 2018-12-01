#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use lib '.';
use Constants;

my $games_dir               = Constants::GAME_DIRECTORY_NAME;
my $names_dir               = Constants::NAMES_DIRECTORY_NAME;
my $blacklisted_tournaments = Constants::BLACKLISTED_TOURNAMENTS;

my $num_deleted_games = 0;
my $num_deleted_indexes = 0;

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
  my @items = split /\./, $game_file_name;
  if (scalar @items != 9 ||
   $items[3] =~ /(>_vs)|[\(\)\*\+\.\?'"]/ ||
    $items[0] eq ""   ||
     $items[1] eq "" ||
      $items[2] eq "" ||
       $items[3] eq "" ||
        $items[4] eq "" ||
         $items[5] eq "" ||
          $items[6] eq "" ||
           $items[7] eq "" ||
            $items[8] eq "" ||
             $items[6] =~ /(^_)|(_$)/ ||
              $items[7] =~ /(^_)|(_$)/ ||
              $blacklisted_tournaments->{$items[1]})
  {
    system "rm '$games_dir/$game_file_name'";
    print "Deleted $games_dir/$game_file_name\n";
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
  my $old_file_name = "$names_dir/$name_file_name";
  open(NAME_FILE, '<', $old_file_name);
  my $new_file_name = "$names_dir/$name_file_name".".new";
  open(my $new_file, '>', $new_file_name);
  while(<NAME_FILE>)
  {
    my @items = split /\./, $_;
  if (!(scalar @items != 9 ||
   $items[3] =~ /(>_vs)|[\(\)\*\+\.\?'"]/ ||
    $items[0] eq ""   ||
     $items[1] eq "" ||
      $items[2] eq "" ||
       $items[3] eq "" ||
        $items[4] eq "" ||
         $items[5] eq "" ||
          $items[6] eq "" ||
           $items[7] eq "" ||
            $items[8] eq "" ||
             $items[6] =~ /(^_)|(_$)/ ||
              $items[7] =~ /(^_)|(_$)/ ||
              $blacklisted_tournaments->{$items[1]}))    {
      print $new_file $_;
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

print "Deleted $num_deleted_games games\n";
print "Deleted $num_deleted_indexes indexes\n";
