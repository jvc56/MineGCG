#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use lib '.';
use Game;
use Constants;
use Stats;

sub mine($)
{
  my $player_name = shift;
  my $dir_name = shift;
  my $torc = shift;
  my $verbose = shift;

  print "Processing game data...\n\n";

  opendir my $dir, $dir_name or die "Cannot open directory: $!";
  my @game_files = readdir $dir;
  closedir $dir;

  my $all_stats = Stats->new();
  my $single_game_stats = Stats->new();
  my %tourney_game_hash;
  outer: while (@game_files)
  {
    my $game_file_name = shift @game_files;
    if ($game_file_name eq '.' || $game_file_name eq '..'){next;}
    my $full_game_file_name = $dir_name . '/' . $game_file_name;
    
    # Check for repeat tournament games
    open(GAMEHTML, '<', $full_game_file_name);
    while(<GAMEHTML>)
    {
      if (/.*?tourney.php.t=(\d+).*?Round (\d+)/)
      {
      	my $key = $1.'+'.$2;
      	if($tourney_game_hash{$key})
      	{
      	  print "Repeat game $full_game_file_name found with tournament id $1 and round number $2. Skipping...\n";
          next outer;
      	}
        $tourney_game_hash{$key} = 1;
      }
    }

    my $game = Game->new($full_game_file_name, $player_name);
    if ( ($torc eq 't' && !$game->{'tourney_game'}) || ($torc eq 'c' && $game->{'tourney_game'}))
    {
      next;
    }
    if ($verbose)
    {
      print "\nData structures for $full_game_file_name\n\n";
      print $game->toString();
      $single_game_stats->addGame($game);
      print $single_game_stats->toString();
      $single_game_stats->resetStats();
    }

    $all_stats->addGame($game);
  }
  print $all_stats->toString();
}

1;


