#!/usr/bin/perl

package Utils;

use warnings;
use strict;
use Data::Dumper;
use DBI;
use utf8;
use Encode;
use Cwd;

use lib "./objects"; 
use lib "./lexicons";
use lib "./modules";

use Constants;
use Game;
use JSON::XS;

sub make_datatable
{

  my $expander_id = shift;
  my $table_id    = shift;
  my $titles      = shift;
  my $titlestyles = shift;
  my $sortvalues  = shift;
  my $content     = shift;

  my $titlecontent = '';
  my $td_width = 100 / (scalar @{$titles});
  my $spacing_tr = "<tr>";
  for (my $m = 0; $m < scalar @{$titles}; $m++)
  {
    my $style = $titlestyles->[$m];
    my $sval  = $sortvalues->[$m];
    my $title = $titles->[$m];

    $style = "style='width: $td_width%; $style'";

    $titlecontent .= "<th $style onclick=\"sortTable($m, '$table_id', $sval)\">$title</th>\n";
    $spacing_tr .= "<td style='width: $td_width%;' ></td>";
  }
  $spacing_tr .= "</tr>";

  my $content_style =
  "
  style=
  '
    width: 100%;
    height: 100%;
    overflow-y: scroll;
    padding-right: 17px; /* Increase/decrease this value for cross-browser compatibility */
    box-sizing: content-box; /* So the width will be 100% + 17px */
  '
  "

  my $table = <<TABLE
<div class="collapse" id="$expander_id">
  <table style='width: 100%'>
    <tbody>
      <tr>
        <td>
          <table class='display' >
            <tbody>
              <tr>
                $titlecontent
              </tr>
            </tbody>
          </table>
        </td>
      </tr>
      <tr>
        <td>
          <div class='scrollwindow'>
            <table class='display' id='$table_id' $content_style>
              <tbody>
                $content
                $spacing_tr
              </tbody>
            </table>
          </div>
        </td>
      </tr>
    </tbody>
  </table>
</div>
TABLE
;
  return $table;
}

sub make_content_item
{
  my $expander   = shift;
  my $title      = shift;
  my $list_table = shift;
  my $div_style  = shift;

  if (!$div_style)
  {
    $div_style = '';
  }
  my $content = <<CONTENT
  <div $div_style>
$expander $title
$list_table
  </div>
CONTENT
;
  return $content;
}

sub make_expander
{
  my $id = shift;
  my $color = shift;

  my $button = <<BUTTON
<button type='button' id='button_$id'  class='btn btn-sm' data-toggle='collapse' data-target='#$id'>+</button>
BUTTON
;
  return $button;
}

sub write_string_to_file
{
  my $string   = shift;
  my $filename = shift;

  open(my $fh, '>', $filename);
  print $fh $string;
  close $fh;
}

sub get_all_unique_values
{
  my $dbh   = shift;
  my $table = shift;
  my $field = shift; 

  my @unique_fields = @{$dbh->selectall_arrayref("SELECT DISTINCT $field FROM $table WHERE $field IS NOT NULL", {"RaiseError" => 1})};

  @unique_fields = map {$_->[0]} @unique_fields;

  return \@unique_fields;
}

sub connect_to_database
{
  my $driver        = Constants::DATABASE_DRIVER;
  my $database_name = get_environment_name(Constants::DATABASE_NAME);
  my $hostname      = Constants::DATABASE_HOSTNAME;
  my $username      = Constants::DATABASE_USERNAME;
  my $password      = Constants::DATABASE_PASSWORD;

  my $dbh = DBI->connect("DBI:$driver:dbname = $database_name;host=$hostname",
                         $username, $password) or die $DBI::errstr;

  $dbh->do("SET client_min_messages TO WARNING");

  my $tables_hashref = Constants::DATABASE_TABLES;
  my $creation_order = Constants::TABLE_CREATION_ORDER;

  for(my $i = 0; $i < scalar @{$creation_order}; $i++)
  {
    my $key = $creation_order->[$i];
    my @columns = @{$tables_hashref->{$key}};
    my $columns_string = join ", ", @columns;
    my $statement = "CREATE TABLE IF NOT EXISTS $key ($columns_string);";
    $dbh->do($statement);
  }   
  return $dbh;
}

sub query_table
{
  my $dbh       = shift;
  my $tablename = shift;
  my $fieldname = shift;
  my $value     = shift;

  my $arrayref =  $dbh->selectall_arrayref("SELECT * FROM $tablename WHERE $fieldname = '$value'", {Slice => {}}) or die DBI::errstr;
  return $arrayref;
}

sub get_all_annotated_game_info
{
  my $wget_flags   = Constants::WGET_FLAGS;
  my $query_url    = Constants::ANNOTATED_GAMES_API_CALL;
  my $download_dir = Constants::DOWNLOADS_DIRECTORY_NAME;
  my $filename     = "$download_dir/allanno.php";

  system "wget $query_url -O $filename";

  open (ANNOS, '<', $filename);
  my $header = <ANNOS>;
  my @annos = ();
  while (<ANNOS>)
  {
    chomp $_;
    my @data = split /,/, $_;
    if (scalar @data > 9)
    {
      my $crap_data = $_;
      @data = ();
      my $item;
      while ($crap_data)
      {
        if (substr($crap_data, 0, 1) eq '"')
	{
	  $crap_data =~ /^"(.*?)",?/;
	  $item = $1;
          $crap_data =~ s/^"(.*?)",?//;
        }
	else
	{
	  $crap_data =~ /^([^,]*),?/;
	  $item = $1;
	  $crap_data =~ s/^([^,]*),?//;
	}
	if (! defined $item)
	{
	  die "Uncaptured crap: $_\nRemaining:'$crap_data'\n";
	}
	push @data, $item;
      }
      if (scalar @data != 9)
      {
        die "Too many elements: $_\n" . Dumper(\@data);
      }
    }
    push @annos, \@data;
  }
  return @annos;
}

sub get_player_cross_tables_id
{
  my $query_url_prefix           = Constants::QUERY_URL_PREFIX;
  my $downloads_dir              = Constants::DOWNLOADS_DIRECTORY_NAME;
  my $query_results_page_name    = Constants::QUERY_RESULTS_PAGE_NAME;
  my $wget_flags                 = Constants::WGET_FLAGS;

  my $player_name = shift;
  my $raw_name    = shift;

  system "mkdir -p $downloads_dir";

  # Prepare name for cross-tables query
  # by replacing ' ' with '+'
  my $query_name = $player_name;
  $query_name =~ s/_/+/g;

  # Run a query using the name to get the player ID
  my $query_url = $query_url_prefix . $query_name;
  my $cmd = "wget $wget_flags $query_url -O ./$downloads_dir/$query_results_page_name 2>&1 |";
  open (CMDOUT, $cmd);
  my $player_cross_tables_id;
  while (<CMDOUT>)
  {
    if (/^Location: results\.php\?p=(\d+).*/)
    {
      $player_cross_tables_id = $1;
      last;
    }
  }
  if (!$player_cross_tables_id)
  {
    open(QUERY_RESULT, '<', "$downloads_dir/$query_results_page_name");
    while (<QUERY_RESULT>)
    {
      if (/href=.results.php.playerid=(\d+).>([^<]+)<.a>/)
      {
        my $captured_name = sanitize($2);
        if ($captured_name eq $player_name)
        {
          $player_cross_tables_id = $1;
        }
      }
    }
  }
  if (!$player_cross_tables_id)
  {
    print "No player named $raw_name found\n";
  }
  return $player_cross_tables_id;
}

sub get_player_annotated_game_data
{
  my $annotated_games_url_prefix = Constants::ANNOTATED_GAMES_URL_PREFIX;
  my $wget_flags                 = Constants::WGET_FLAGS;
  my $downloads_dir              = Constants::DOWNLOADS_DIRECTORY_NAME;
  my $annotated_games_page_name  = Constants::ANNOTATED_GAMES_PAGE_NAME;

  my $player_cross_tables_id = shift;

  my $annotated_games_url = $annotated_games_url_prefix . $player_cross_tables_id;

  # Get the player's annotated games page
  system "wget $wget_flags $annotated_games_url -O ./$downloads_dir/$annotated_games_page_name  >/dev/null 2>&1";

  # Parse the annotated games page html to get the game IDs
  # of the player's annotated games
  my @game_ids = ();
  open(RESULTS, '<', $downloads_dir . '/' . $annotated_games_page_name);
  while (<RESULTS>)
  {
    my @matches = ($_ =~ /href=.annotated.php.u=(\d+).>\w+<.a><.td><td class=.nowrap.><a href=.results.php.p=\d+.>(.+?)<.a><.td><td><a href=.tourney.php.t=(.+?).>([^<]*)<.a><.td><td>([^<]*)<.td><td>([^<]*)<.td><td><.td><td>([^<]*)</g);
    #game_id, opponent, tourney_id, tourney_name, date, round_number, dictionary
    while (@matches)
    {
      my @item = ();
      for (my $i = 0; $i < 7; $i++)
      {
        push @item, shift @matches;
      }
      push @game_ids, \@item;
    }
  }
  return \@game_ids;
}

sub update_player_record
{
  my $dbh                    = shift;
  my $player_cross_tables_id = shift;
  my $raw_name               = shift;
  my $player_name            = shift;
  my $stats                  = shift;
  my $total_games            = shift;

  my $search_col;
  my $search_val;

  if ($player_cross_tables_id)
  {
    $search_col = Constants::PLAYER_CROSS_TABLES_ID_COLUMN_NAME;
    $search_val = $player_cross_tables_id;
  }
  else
  {
    $search_col = Constants::PLAYER_SANITIZED_NAME_COLUMN_NAME;
    $search_val = sanitize($player_name);
  }
  
  my @player_query = @{query_table($dbh, Constants::PLAYERS_TABLE_NAME, $search_col, $search_val)};
  
  my $player_record_id;

  my $update_gcg = 0;

  my $queried_name     = $player_query[0]->{Constants::PLAYER_SANITIZED_NAME_COLUMN_NAME};
  my $queried_raw_name = $player_query[0]->{Constants::PLAYER_NAME_COLUMN_NAME};

  if (@player_query)
  {
    $player_record_id = $player_query[0]->{Constants::PLAYER_ID_COLUMN_NAME};
  }

  if (!$player_cross_tables_id)
  {
    $player_cross_tables_id = $player_query[0]->{Constants::PLAYER_CROSS_TABLES_ID_COLUMN_NAME};
  }
  if (!$raw_name)
  {
    $raw_name = $queried_raw_name;
  }
  if (!$player_name)
  {
    $player_name = $queried_name;
  }
  elsif ($queried_name && $player_name ne $queried_name)
  {
    $update_gcg = 1;
    $raw_name = $queried_raw_name;
    $player_name = $queried_name;
  }
  if (!$stats)
  {
    $stats = $player_query[0]->{Constants::PLAYER_STATS_COLUMN_NAME};
  }
  if (!$total_games)
  {
    $total_games = $player_query[0]->{Constants::PLAYER_TOTAL_GAMES_COLUMN_NAME};
  }

  my $player_record =
  {
    Constants::PLAYER_CROSS_TABLES_ID_COLUMN_NAME => $player_cross_tables_id,
    Constants::PLAYER_NAME_COLUMN_NAME            => $raw_name,
    Constants::PLAYER_SANITIZED_NAME_COLUMN_NAME  => $player_name,
    Constants::PLAYER_STATS_COLUMN_NAME           => $stats,
    Constants::PLAYER_TOTAL_GAMES_COLUMN_NAME     => $total_games
  };

  insert_or_set_hash_into_table($dbh, Constants::PLAYERS_TABLE_NAME, $player_record, $player_record_id);
  return $update_gcg;
}

sub download_gcg
{
  my $game_xt_id = shift;
  
  my $wget_flags       = Constants::WGET_FLAGS;
  my $downloads_dir    = Constants::DOWNLOADS_DIRECTORY_NAME;
  my $cross_tables_url = Constants::CROSS_TABLES_URL;

  my $gcg_name = "annotated_game.gcg";
  my $gcg_fullname = "$downloads_dir/$gcg_name";

  my $gcg_url = $cross_tables_url . get_gcg_url_suffix($game_xt_id);
  system "wget $wget_flags $gcg_url -O '$gcg_fullname' >/dev/null 2>&1";

  my $gcgtext = "";

  open(GCG, '<',  $gcg_fullname);
  while(<GCG>)
  {
    $gcgtext .= $_;
  }
  return $gcgtext;
}

sub get_gcg_url_suffix
{
  my $id = shift;
  my $group = int($id / 100);
  return "annotated/selfgcg/$group/anno$id.gcg";
}

sub insert_or_set_hash_into_table
{
  my $dbh       = shift;
  my $table     = shift;
  my $hashref   = shift;
  my $record_id = shift;

  if (!(keys %{$hashref}))
  {
    return $record_id;
  }

  my $row_id_column_name = Constants::PLAYER_ID_COLUMN_NAME;

  if ($table eq Constants::GAMES_TABLE_NAME)
  {
    $row_id_column_name = Constants::GAME_ID_COLUMN_NAME;
  }

  my $stmt;

  if (!$record_id)
  {
    my $keys_string   = "("; 
    my $values_string = "("; 

    foreach my $key (keys %{$hashref})
    {
      $keys_string   .= "$key,";
      my $value = $hashref->{$key};
      if (defined $value)
      {
	$value = database_sanitize($value);
        $values_string .= "'$value',";
      }
      else
      {
        $values_string .= "NULL,";
      }
    }

    chop($keys_string);
    chop($values_string);

    if (!$keys_string || !$values_string)
    {
      return undef;
    }

    $keys_string   .= ")"; 
    $values_string .= ")"; 

    $stmt = "INSERT INTO $table $keys_string VALUES $values_string;";
    $dbh->do($stmt) or die DBI::errstr;
    return $dbh->last_insert_id(undef, undef, $table, undef);
  }
  else
  {
    my $set_stmt   = ""; 
    foreach my $key (keys %{$hashref})
    {
      my $value = $hashref->{$key};
      if (defined $value)
      {    
	$value = database_sanitize($value);
        $value = "'$value'";
      }
      else
      {
        $value = "NULL";
      }
      $set_stmt .= "$key = $value,";
    }
    chop($set_stmt);
    $stmt = "UPDATE $table SET $set_stmt WHERE $row_id_column_name = '$record_id'";
    $dbh->do($stmt) or die DBI::errstr;
    return $record_id;
  }

}

sub update_stats
{
  my $dbh                    = shift;
  my $game_result            = shift;
  my $annotated_game_data    = shift;
  my $update                 = shift;

  my $game_xt_id       = $annotated_game_data->[0];
  my $player_one_xt_id = $annotated_game_data->[1];
  my $player_two_xt_id = $annotated_game_data->[2];
  my $player_one_name  = $annotated_game_data->[3];
  my $player_two_name  = $annotated_game_data->[4];
  my $tournament_xt_id = $annotated_game_data->[5];
  my $round            = $annotated_game_data->[6];
  my $lexicon          = $annotated_game_data->[7];
  my $upload_date      = $annotated_game_data->[8];
  my $lexicon_ref      = $annotated_game_data->[9];
  my $date             = $annotated_game_data->[10];

  my $game_name        = "";
  my $error            = "";
  my $warning          = "";

  if (!$game_result)
  {
    $game_result = {};
  }

  my $game_record_id = $game_result->{Constants::GAME_ID_COLUMN_NAME};

  if (!$game_result->{Constants::GAME_GCG_COLUMN_NAME} || $update eq Constants::UPDATE_OPTION_GCG)
  {
     $game_result->{Constants::GAME_GCG_COLUMN_NAME} = download_gcg($game_xt_id);
  }

  if (!$player_one_xt_id)
  {
    $player_one_xt_id = undef;
  }
  if (!$player_two_xt_id)
  {
    $player_two_xt_id = undef;
  }


  my $game = Game->new(
                        $game_result->{Constants::GAME_GCG_COLUMN_NAME},
                        $lexicon_ref,
                        $player_one_name,
                        $player_two_name,
                        $lexicon,
                        $game_xt_id
                      );

  if (ref($game) ne "Game")
  {
    $error = $game;
  }
  elsif ($game->{Constants::GAME_WARNING_COLUMN_NAME})
  {
    $warning = $game->{Constants::GAME_WARNING_COLUMN_NAME};
  }



  my $unblessed_stat = {};

  if (!$error)
  {
    $game_name = $game->{'readable_name'};

    my $stats = Stats->new(1);

    my $stat_warnings = $stats->addGame($game);

    if ($stat_warnings)
    {
      $warning .= $stat_warnings;
    }
    $unblessed_stat = prepare_stats($stats);
  }

  my $game_record =
  {
    Constants::GAME_PLAYER_ONE_CROSS_TABLES_ID_COLUMN_NAME  => $player_one_xt_id,
    Constants::GAME_PLAYER_TWO_CROSS_TABLES_ID_COLUMN_NAME  => $player_two_xt_id,
    Constants::GAME_PLAYER_ONE_NAME_COLUMN_NAME             => $player_one_name,
    Constants::GAME_PLAYER_TWO_NAME_COLUMN_NAME             => $player_two_name,
    Constants::GAME_CROSS_TABLES_ID_COLUMN_NAME             => $game_xt_id,
    Constants::GAME_GCG_COLUMN_NAME                         => $game_result->{Constants::GAME_GCG_COLUMN_NAME},
    Constants::GAME_STATS_COLUMN_NAME                       => JSON::XS::encode_json($unblessed_stat),
    Constants::GAME_CROSS_TABLES_TOURNAMENT_ID_COLUMN_NAME  => $tournament_xt_id,
    Constants::GAME_DATE_COLUMN_NAME                        => $date,
    Constants::GAME_LEXICON_COLUMN_NAME                     => $lexicon,
    Constants::GAME_ROUND_COLUMN_NAME                       => $round,
    Constants::GAME_NAME_COLUMN_NAME                        => $game_name,
    Constants::GAME_ERROR_COLUMN_NAME                       => $error,
    Constants::GAME_WARNING_COLUMN_NAME                     => $warning
  };

  insert_or_set_hash_into_table($dbh, Constants::GAMES_TABLE_NAME, $game_record, $game_record_id);
}

sub prepare_stats
{
  my $stats = shift;
  return
  {
     Constants::STATS_DATA_KEY_NAME =>
    {
       Constants::STATS_DATA_PLAYER_ONE_KEY_NAME => delete_function_from_statslist($stats->{Constants::STATS_DATA_KEY_NAME}->{ Constants::STATS_DATA_PLAYER_ONE_KEY_NAME}),
       Constants::STATS_DATA_PLAYER_TWO_KEY_NAME => delete_function_from_statslist($stats->{Constants::STATS_DATA_KEY_NAME}->{ Constants::STATS_DATA_PLAYER_TWO_KEY_NAME}),
       Constants::STATS_DATA_GAME_KEY_NAME       => delete_function_from_statslist($stats->{Constants::STATS_DATA_KEY_NAME}->{ Constants::STATS_DATA_GAME_KEY_NAME      }),
       Constants::STATS_DATA_NOTABLE_KEY_NAME    => delete_function_from_statslist($stats->{Constants::STATS_DATA_KEY_NAME}->{ Constants::STATS_DATA_NOTABLE_KEY_NAME   }),
       Constants::STATS_DATA_ERROR_KEY_NAME      => delete_function_from_statslist($stats->{Constants::STATS_DATA_KEY_NAME}->{ Constants::STATS_DATA_ERROR_KEY_NAME     }),
    }
  };
}

sub prepare_anno_data
{
  my $data                       = shift;
  my $id_name_hashref            = shift;
  my $tournament_id_date_hashref = shift;

  for (my $i = 0; $i < scalar @{$data}; $i++)
  {
    my $item = $data->[$i];
    if (!$item || $item =~ /^\-\d*$/)
    {
      $data->[$i] = undef;
    }
  }

  my @id_indexes = (1, 2);

  foreach my $index (@id_indexes)
  {
    my $xt_id = $data->[$index];
    if ($xt_id)
    {
      my $player_info = $id_name_hashref->{$xt_id};
      if (!$player_info )
      {
        $player_info = get_player_info($xt_id);
        $id_name_hashref->{$xt_id} = $player_info;
      }
      $data->[$index + 2] = $player_info->[0]; # Name index of the player xt index
    }
  }

  my $tournament_id = $data->[5];
  my $date;
  if ($tournament_id)
  {
    $date = $tournament_id_date_hashref->{$tournament_id};
    if (!$date)
    {
      $date = get_tournament_date($tournament_id);
      $tournament_id_date_hashref->{$tournament_id} = $date;
    }
  }
  $data->[10] = $date;
}

sub get_tournament_date
{
  my $id = shift;

  my $wget_flags = Constants::WGET_FLAGS; 
  my $query_url = Constants::TOURNAMENT_INFO_API_CALL . $id;
  my $filename  = Constants::DOWNLOADS_DIRECTORY_NAME . "/tournament_info_$id.txt";
  my $month_to_num_hashref = Constants::MONTH_TO_NUMBER_HASHREF;

  system "wget $wget_flags $query_url -O $filename  >/dev/null 2>&1";
  # Capture 
  # 		"date": "Feb 23, 2004",

  open(INFO, "<", $filename);
  while (<INFO>)
  {
    if (/"date":\s*"(\w+)\s+(\d+),\s*(\d+)"/)
    {
      # print $_;
      my $date = join "-", ($3, $month_to_num_hashref->{$1}, (sprintf "%02s", $2));
      # print "$date\n";
      return $date;
    }
  }
  die "Date not found in $filename for id : $id\n";
}

sub get_player_info
{
  my $xt_id = shift;
 
  my $wget_flags = Constants::WGET_FLAGS; 
  my $query_url = Constants::PLAYER_INFO_API_CALL . $xt_id;
  my $filename  = Constants::DOWNLOADS_DIRECTORY_NAME . "/player_info_$xt_id.txt";

  system "wget $wget_flags $query_url -O $filename  >/dev/null 2>&1";
  # Capture 
  # 		"name": "Seth Lipkin",

  my $name;
  my $photo;

  open(INFO, "<", $filename);
  while (<INFO>)
  {
    if (/"name":\s*"([^"]*)"/)
    {
      $name = $1;
    }
    elsif (/"photourl":\s*"([^"]*)"/)
    {
      $photo = $1;
    }
  }
  return [$name, $photo];
}

sub get_color_dot_style
{
  my $color = shift;
    my $style = <<STYLE
style='
  height: 10px;
  width: 10px;
  background-color: $color;
  border-radius: 50%;
  display: inline-block;
  vertical-align: middle;
'
STYLE
;
  return $style; 
}

sub delete_function_from_statslist
{
  my $stats = shift;

  foreach my $stat (@{$stats})
  {
    delete $stat->{Constants::STAT_ADD_FUNCTION_NAME};
    delete $stat->{Constants::STAT_COMBINE_FUNCTION_NAME};
  }
  return $stats;
}

sub sanitize
{
  my $string = shift;

  if (!$string)
  {
    return $string;
  }

  # Remove trailing and leading whitespace
  $string =~ s/^\s+|\s+$//g;

  # Replace spaces with underscores
  $string =~ s/ /_/g;

  # Remove anything that is not an
  # underscore, dash, letter, or number
  $string =~ s/[^\w\-]//g;

  # Capitalize
  $string = uc $string;

  return $string;
}

sub database_sanitize
{
  my $s = shift;

  $s =~ s/'/''/g;

  $s = encode( "UTF-8", $s );

  return $s;
}

sub format_error
{
  my $description = shift;

  my $error = (sprintf "%-20s", "ERROR:") . "$description\n";
  while (@_)
  {
    my $object = shift;
    if (ref($object) eq "Stats")
    {
      $error .= Dumper($object);
    }
    else
    {
      $error .= Dumper($object);
    }
  }
  return $error;
}

sub get_environment_name
{
  my $name = shift;
  my $keyword = Constants::DEV_ENV_KEYWORD;
  my $dir = cwd();
  if ($dir =~ /$keyword/i)
  {
    return $name . $keyword;
  }
  return $name;
}

1;
