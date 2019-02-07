#!/usr/bin/perl

use warnings;
use strict;

require "./scripts/sanitize.pl";
require "./scripts/validate_filename.pl";

use lib './objects';
use Constants;

sub retrieve
{
  # Constants
  my $wget_flags                 = Constants::WGET_FLAGS;
  my $cross_tables_url           = Constants::CROSS_TABLES_URL;
  my $query_url_prefix           = Constants::QUERY_URL_PREFIX;
  my $annotated_games_url_prefix = Constants::ANNOTATED_GAMES_URL_PREFIX;
  my $annotated_games_page_name  = Constants::ANNOTATED_GAMES_PAGE_NAME;
  my $query_results_page_name    = Constants::QUERY_RESULTS_PAGE_NAME;
  my $blacklisted_tournaments    = Constants::BLACKLISTED_TOURNAMENTS;
  my $dir                        = Constants::GAME_DIRECTORY_NAME;
  my $names_dir                  = Constants::NAMES_DIRECTORY_NAME;

  my $name              = shift;
  my $raw_name          = shift;
  my $option            = shift;
  my $tourney_id        = shift;
  my $tourney_or_casual = shift;
  my $single_game_id    = shift;
  my $opponent_name     = shift;
  my $startdate         = shift;
  my $enddate           = shift;
  my $verbose           = shift;
  my $resolve           = shift;

  my $full_index_list_name = "$names_dir/$name.txt";

  if (!$option && -e $full_index_list_name)
  {
    return;
  }

  system "mkdir -p downloads";

  if ($verbose) {print "Retrieving games...\n";}
  if ($option eq "reset" && -e $dir)
  {
    system "rm -r $dir";
    if ($verbose) {print "Deleted $dir\n";}
    system "rm -r $names_dir";
    if ($verbose) {print "Deleted $names_dir\n";}
  }

  # Prepare name for cross-tables query
  # by replacing ' ' with '+'
  my $query_name = $name;
  $query_name =~ s/_/+/g;

  # Run a query using the name to get the player id
  my $query_url = $query_url_prefix . $query_name;
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
      if (/href=.results.php.playerid=(\d+).>([^<]+)<.a>/)
      {
        my $captured_name = sanitize($2);
        if ($captured_name eq $name)
        {
          $player_id = $1;
        }
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
    my @matches = ($_ =~ /href=.annotated.php.u=(\d+).>\w+<.a><.td><td class=.nowrap.><a href=.results.php.p=\d+.>(.+?)<.a><.td><td><a href=.tourney.php.t=(.+?).>([^<]*)<.a><.td><td>([^<]*)<.td><td>([^<]*)<.td><td><.td><td>([^<]*)</g);
    #game_id, opponent, tourney_id, tourney_name, date, round_number, dictionary
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
  my $games_to_download = (scalar @game_ids) / 7;
  my $count = 0;
  my $game_with_no_index    = 0;
  my $index_with_no_game    = 0;
  my $num_invalid_filenames = 0;
  my $invalid_filenames     = "";
  while (@game_ids)
  {

    #game_id, tourney_id, tourney_name, date, round_number, dictionary
    my $id              = shift @game_ids;
    my $this_opponent   = shift @game_ids;
    $this_opponent = sanitize($this_opponent);
    my $game_tourney_id = shift @game_ids;
    my $tourney_name    = shift @game_ids;
    my $date            = shift @game_ids;
    my $date_sanitized = $date;
    $date_sanitized =~ s/[^\d]//g;
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
    if (!$round_number || !($round_number =~ /^\d+$/))
    {
      $round_number = 0;
    }
    if (!$game_tourney_id || !($game_tourney_id =~ /^\d+$/))
    {
      $game_tourney_id = 0;
    }
    if (!$lexicon)
    {
      $lexicon = Constants::DEFAULT_LEXICON;
    }

    # Check if game needs to be downloaded

    if ($tourney_id && $tourney_id ne $game_tourney_id)
    {
      if ($verbose) {print "$num_str Game with id $id was not played in the specified tournament\n";}
      next;
    }
    if ($single_game_id && $single_game_id ne $id)
    {
      if ($verbose) {print "$num_str Game with id $id is not the specified game\n";}
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
    if ($opponent_name && $this_opponent ne $opponent_name)
    {
      if ($verbose) {print "$num_str Game with id $id is not against the specified opponent\n";}
      next;
    }
    if (($startdate && $date_sanitized < $startdate) || ($enddate && $date_sanitized > $enddate))
    {
      if ($verbose) {print "$num_str Game with id $id is not in the specified timeframe\n";}
      next;  
    }
    if ($blacklisted_tournaments->{$game_tourney_id})
    {
      if ($verbose) {print "$num_str Game with id $id is from a blacklisted tournament\n";}
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
        chomp $_;
        if (!$_){next;}
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
      if ($verbose){print "$num_str Game and Index with id $id already exist\n";}
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
      }
    }
    system "rm $dir/$html_game_name";


    my $gcg_name = join ".", (
                              sanitize($date),
                              sanitize($game_tourney_id),
                              sanitize($round_number),
                              sanitize($tourney_name),
                              sanitize($lexicon),
                              sanitize($id),
                              sanitize($player_one_name),
                              sanitize($player_two_name),
                              "gcg"
                             );

    if (!validate_filename($gcg_name))
    {
      print "$num_str Invalid file name: $gcg_name\n";  
      $invalid_filenames .= "$gcg_name\n";
      $num_invalid_filenames++;
      next;
    }

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
      if ($verbose) {print "$num_str Indexed    game $gcg_name in $full_index_list_name\n";}
    }

    # Download the game
    if (!$file_exists)
    {
      my $gcg_url = $cross_tables_url . $gcg_url_suffix;
      system "wget $wget_flags $gcg_url -O '$dir/$gcg_name' >/dev/null 2>&1";
      if ($verbose) {print "$num_str Downloaded game $gcg_name to $dir\n";}
    }
  }
  
  if ($verbose) {print "Number of invalid filenames: $num_invalid_filenames\n";}
  if ($num_invalid_filenames > 0)
  {
    print "Invalid filenames:\n$invalid_filenames\n";
  }

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
