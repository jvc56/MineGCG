#!/usr/bin/perl

use warnings;
use strict;
use lib '.';
use Constants;

sub retrieve($$$$$$)
{
  # Constants
  my $wget_flags                 = Constants::WGET_FLAGS;
  my $cross_tables_url           = Constants::CROSS_TABLES_URL;
  my $query_url_prefix           = Constants::QUERY_URL_PREFIX;
  my $annotated_games_url_prefix = Constants::ANNOTATED_GAMES_URL_PREFIX;
  my $annotated_games_page_name  = Constants::ANNOTATED_GAMES_PAGE_NAME;
  my $query_results_page_name    = Constants::QUERY_RESULTS_PAGE_NAME;
  my $dir                        = Constants::GAME_DIRECTORY_NAME;
  my $names_dir                  = Constants::NAMES_DIRECTORY_NAME;

  my $name              = shift;
  my $option            = shift;
  my $tourney_id        = shift;
  my $tourney_or_casual = shift;
  my $verbose           = shift;
  my $resolve           = shift;

  my $raw_name      = $name;
  my $textfile_name = $name;
  $textfile_name =~ s/ /_/g;
  $textfile_name =~ s/'//g; # Name is now no longer raw
  my $full_index_list_name = "$names_dir/$textfile_name.txt";

  if (!$option && -e $full_index_list_name)
  {
    return;
  }
  print "Retrieving games...\n";
  if ($option eq "reset" && -e $dir)
  {
    system "rm -r $dir";
    if ($verbose) {print "Deleted $dir\n";}
  }

  # Prepare name for cross-tables query
  # by replacing ' ' with '+'
  $name =~ s/ /+/g;
  $name =~ s/'//g;

  # Run a query using the name to get the player id
  my $query_url = $query_url_prefix . $name;
  open (CMDOUT, "wget $wget_flags $query_url -O ./$query_results_page_name 2>&1 |");
  my $player_id;
  while (<CMDOUT>)
  {
  	if (/^Location: results\.php\?p=(\d+).*/)
  	{
      $player_id = $1;
  	  last;
  	}
  }
  if (!$player_id)
  {
    open(QUERY_RESULT, '<', "$query_results_page_name");
    while (<QUERY_RESULT>)
    {
      if (/href=.results.php.playerid=(\d+).>$raw_name<.a>/)
      {
        $player_id = $1;
      }
    }
  }
  if (!$player_id){print "No player named $raw_name found\n"; return;}
  # Use the player id to get the address of the annotated games page
  my $annotated_games_url = $annotated_games_url_prefix . $player_id;

  # Get the player's annotated games page
  system "wget $wget_flags $annotated_games_url -O ./$annotated_games_page_name  >/dev/null 2>&1";

  # Parse the annotated games page html to get the game ids
  # of the player's annotated games
  my @game_ids = ();
  open(RESULTS, '<', $annotated_games_page_name);
  while (<RESULTS>)
  {
    my @matches = ($_ =~ /href=.annotated.php.u=(\d+).>.*?href=.tourney.php.t=(.+?).>([^<]*)<.a><.td><td>([^<]*)<.td><td>([^<]*)<.td><td><.td><td>([^<]*)</g);
    #game_id, tourney_id, tourney_name, date, round_number, dictionary
    push @game_ids, @matches;
  }
  # Create the directory to store the GCGs
  # if one doesn't already exist
  if (!(-e $dir && -d $dir))
  {
  	system "mkdir $dir";
    if ($verbose) {print "Created $dir\n";}
  }
  # Create the directory to store the player index files
  # if one doesn't already exist
  if (!(-e $names_dir))
  {
    system "mkdir $names_dir";
    if ($verbose) {print "Created $names_dir\n";}
  }

  # Iterate through the annotated game ids to fetch all of
  # the player's annotated games
  my $games_to_download = (scalar @game_ids) / 6;
  my $count = 0;
  my $game_with_no_index = 0;
  my $index_with_no_game = 0;
  while (@game_ids)
  {

    #game_id, tourney_id, tourney_name, date, round_number, dictionary
    my $id              = shift @game_ids;
    my $game_tourney_id = shift @game_ids;
    my $tourney_name    = shift @game_ids;
    $tourney_name =~ s/ /_/g;
    $tourney_name =~ s/[\^\$\*\+\?\|\[\]\{\}\\\.\(\)'"]//g;
    my $date            = shift @game_ids;
    my $round_number    = shift @game_ids;
    my $lexicon         = shift @game_ids;

    $count++;
    my $num_str = (sprintf "%-4s", $count) . " of $games_to_download:";

    if (!$tourney_name)
    {
      $tourney_name = Constants::NON_TOURNAMENT_GAME;
    }
    if (!$date)
    {
      $date = 0;
    }
    if (!$round_number)
    {
      $round_number = 0;
    }
    if (!$lexicon)
    {
      $lexicon = Constants::DEFAULT_LEXICON;
    }

    # Check if game needs to be downloaded

    if ($tourney_id && $tourney_id ne $game_tourney_id)
    {
      if ($verbose) {print "$num_str Game with id $id wasn't played in the specified tournament\n";}
      next;
    }
    if ($tourney_name eq Constants::NON_TOURNAMENT_GAME && uc $tourney_or_casual eq 'T')
    {
      if ($verbose) {print "$num_str Game with id $id is not a tournament game\n";}
      next;
    }
    if ($tourney_name ne Constants::NON_TOURNAMENT_GAME && uc $tourney_or_casual eq 'C')
    {
      if ($verbose) {print "$num_str Game with id $id is a tournament game\n";}
      next;
    }

    # Check if game or game index already exists

    # Check if index exists
    my $index_exists = 0;
    if (-e $full_index_list_name)
    {
      open(PLAYER_INDEXES, '<', $full_index_list_name);
      while (<PLAYER_INDEXES>)
      {
        my @items = split /\./, $_;
        if ($items[5] eq $id)
        {
          $index_exists = 1;
          last;
        }
      }
    }

    # Check if file exists
    my $file_exists = 0;
    opendir my $games_dir, $dir or die "Cannot open directory: $!";
    my @game_files = readdir $games_dir;
    closedir $games_dir;
    foreach my $game_file_name (@game_files)
    {
      if ($game_file_name eq "." || $game_file_name eq "..")
      {
        next;
      }
      my @items = split /\./, $game_file_name;
      if (!$items[5])
      {
        print "items is not defined\n";
        print Dumper(\@items)."\n";
        print "the game is called $game_file_name\n";
        print $_;
      }
      if (!$id)
      {
        print "id is not defined\n";
        print "$id $game_tourney_id $tourney_name $date $round_number $lexicon\n";
        print $_;
      }
      if ($items[5] eq $id)
      {
        $file_exists = 1;
        last;
      }
    }

    if ($file_exists && !$index_exists && !$resolve)
    {
      if ($verbose){print "$num_str Game with id $id already exists but does not have an index\n";}
      $game_with_no_index++;
      next;
    }
    if (!$file_exists && $index_exists && !$resolve)
    {
      if ($verbose){print "$num_str Game with id $id does not exist but has an index\n";}
      $index_with_no_game++;
      next;
    }
    if ($file_exists && $index_exists)
    {
      if ($verbose){print "$num_str Game with id $id already exists\n";}
      next;
    }

    my $html_game_name = "$id.html";

  	my $html_game_url = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX . $id;

    # All this just to see who goes first
  	system "wget $wget_flags $html_game_url -O '$dir/$html_game_name' >/dev/null 2>&1";
    my $gcg_url_suffix  = '';
    my $player_one_name = '';
    my $player_two_name = '';
    open(ANNOHTML, '<', "$dir/$html_game_name");
    while(<ANNOHTML>)
    {
      if (/href=.(annotated.selfgcg.\d+.anno\d+.gcg)./)
      {
        $gcg_url_suffix = $1;
      }
      if (/^([^<]*)(?:<a.*a>)?\s+vs\.\s+([^<]*)/) # How bout ^([^<]*)<a.*a>\s+vs.([^<]*)<a
      {
        $player_one_name = $1;
        $player_two_name = $2;
        $player_one_name =~ s/^\s+|\s+$//g;
        $player_two_name =~ s/^\s+|\s+$//g;
        $player_one_name =~ s/ /_/g;
        $player_two_name =~ s/ /_/g;
        $player_one_name =~ s/[\(\)\+\?\*\.'"]//g;
        $player_two_name =~ s/[\(\)\+\?\*\.'"]//g;
      }
    }
    system "rm $dir/$html_game_name";


    my $gcg_name = join ".", ($date, $game_tourney_id, $round_number, $tourney_name, $lexicon, $id, $player_one_name, $player_two_name, "gcg");

    # Write the index
    if (!$index_exists)
    {
      my $write_mode = '>>';
      if (!(-e $full_index_list_name))
      {
        my $write_mode = '>';
      }
      open(my $fh, $write_mode, $full_index_list_name) or die "$!\n";
      print $fh $gcg_name."\n";
      close $fh;
    }

    # Download the game
    if (!$file_exists)
    {
      my $gcg_url = $cross_tables_url . $gcg_url_suffix;
      system "wget $wget_flags $gcg_url -O '$dir/$gcg_name' >/dev/null 2>&1";
      if ($verbose) {print "$num_str Downloaded game $gcg_name to $dir\n";}
    }
  }
  
  print "\nDone retrieving\n";
  if (!$resolve)
  {
    print "Games with no indexes: $game_with_no_index\n";
    print "Indexes with no games: $index_with_no_game\n";
    if ($game_with_no_index || $index_with_no_game)
    {
      print "\nInconsistencies have been detected!\nRun with the --resolve flag to resolve the inconsistencies\n";
    }
  }
}
1;
