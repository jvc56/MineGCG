#!/usr/bin/perl

package Utils;

use warnings;
use strict;
use Data::Dumper;
use DBI;
use utf8;
use Encode;
use Cwd;
use Statistics::Standard_Normal;

use lib "./objects"; 
use lib "./lexicons";
use lib "./modules";

use Constants;
use Game;
use JSON::XS;

sub get_ordinal_suffix
{
  my $number = shift;

  my $last_digit = substr($number, -1);
  my $suffix;
  if ($number == 11)
  {
    $suffix = 'th';
  }
  elsif ($last_digit == 1)
  {
    $suffix = 'st';
  }
  elsif ($last_digit == 2)
  {
    $suffix = 'nd';
  }
  elsif ($last_digit == 3)
  {
    $suffix = 'rd';
  }
  else
  {
    $suffix = 'th';
  }
  return $suffix;
}

sub get_confidence_interval
{
  my $P           = shift;
  my $n           = shift;

  my $alpha       = 1 - Constants::CONFIDENCE_LEVEL;
  my $pct         = (1 - ($alpha/2)) * 100;
  my $z           = Statistics::Standard_Normal::pct_to_z($pct);
  my $interval    = $z * sqrt( ( $P * ( 1 - $P ) ) / $n);
  my $lower       = sprintf "%.4f", $P - $interval;
  my $upper       = sprintf "%.4f", $P + $interval;

  return ($lower, $upper);
}

sub make_datatable
{
  my $expander_id = shift;
  my $table_id    = shift;
  my $titles      = shift;
  my $titlestyles = shift;
  my $sortvalues  = shift;
  my $content     = shift;
  my $initcol     = shift;
  my $initclass   = shift;
  my $learntext   = shift;

  if (!$learntext)
  {
    printf "%s %s %s %s", $expander_id, $table_id, Dumper($titles), Dumper($sortvalues);
    exit(0);
  }

  my $title_row_id    = $table_id . '_title_row_id';
  my $moreid          = $table_id . '_toggle_show';
  my $divid           = $table_id . '_scrollwindow';
  my $titlecontent = '';
  my $td_width = 100 / (scalar @{$titles});
  my $span_style = "style='border-radius: 10px; background-color: #555555; padding: 5px'";
  for (my $m = 0; $m < scalar @{$titles}; $m++)
  {
    my $style = $titlestyles->[$m];
    my $sval  = $sortvalues->[$m];
    my $title = $titles->[$m];

    $style = '';
    my $class = '';
    if ($initcol && $title eq $initcol)
    {
      $class = "class='$initclass'";
    }

    my $clickfunc = '';

    if ($sval ne 'disable')
    {
      $clickfunc = "onclick=\"sortTable($m, '$table_id', $sval)\"";
      $style = "style='width: $td_width%; $style'";
    }
    else
    {
      $style = "style='width: $td_width%; cursor: inherit; $style'";
    }

    $titlecontent .= "<th $style $class $clickfunc>$title</th>\n";
  }

  my $table = <<TABLE
  <table style='width: 100%'>
    <tbody>
      <tr>
        <td>
          <table class='titledisplay' >
            <tbody>
              <tr id='$title_row_id'>
                $titlecontent
              </tr>
            </tbody>
          </table>
        </td>
      </tr>
      <tr>
        <td>
          <div class='scrollwindow' id='$divid'>
            <table class='display' id='$table_id'>
              <tbody>
                $content
              </tbody>
            </table>
          </div>
        </td>
      </tr>
    </tbody>
  </table>
  <div style='text-align: center'>
    <i class="fas fa-angle-down rotate-icon" id='$moreid' style='cursor: pointer' onclick="toggleMaxHeight('$divid', '$moreid')"></i>
  </div>
  <div style='padding: 10px ; text-align: center'>
    <table style='width: 100%'>
      <tbody>
        <td style='width: 50%; text-align: center'>
          <input oninput="filterTable(this, '$table_id')" style='border-radius: .25em' placeholder='Filter'>
        </td>
        <td style='width: 50%; text-align: center'>
          <button class="btn btn-sm waves-effect waves-light" style='color: white' onclick="exportTableToCSV('$table_id', '$table_id')">Download</button>
        </td>
      </tbody>
    </table>
    $learntext
  </div>
TABLE
;
  if ($expander_id)
  {
    $table = "<div class=\"collapse\" id=\"$expander_id\">$table</div>";
  }
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
  my $isarrow = shift;
  my $nobr      = shift;


  my $br = '<br>';
  if ($nobr)
  {
    $br = '';
  }
  my $button;
  if ($isarrow)
  {
    $button = <<BUTTON
        <a data-toggle="collapse" data-target="#$id"
          aria-expanded="false" aria-controls="collapseOptions" onclick='toggle_icon(this, "$id", false)'>
          $br<i class="fas fa-angle-down rotate-icon"></i>
        </a>
BUTTON
    ;   
  }
  else
  {
    $button = <<BUTTON
  <button type='button' id='button_$id'  class='btn btn-sm' data-toggle='collapse' data-target='#$id'>+</button>
BUTTON
  ;
  }
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

sub connect_to_typing_database
{
  my $driver        = Constants::DATABASE_DRIVER;
  my $database_name = get_environment_name(Constants::TYPING_DATABASE_NAME);
  my $hostname      = Constants::DATABASE_HOSTNAME;
  my $username      = Constants::DATABASE_USERNAME;
  my $password      = Constants::DATABASE_PASSWORD;

  my $dbh = DBI->connect("DBI:$driver:dbname = $database_name;host=$hostname",
                         $username, $password) or die $DBI::errstr;

  $dbh->do("SET client_min_messages TO WARNING");

  my $tables_hashref = Constants::TYPING_DATABASE_TABLES;
  my $creation_order = Constants::TYPING_TABLE_CREATION_ORDER;

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

  system "wget $wget_flags $query_url -O $filename";

  open my $fh, '<', $filename or die "Could not open '$filename': $!";

  my @rows;

  while (my $line = <$fh>) {
      chomp $line;

      my @fields;
      my $field = '';
      my $in_quotes = 0;
      my @chars = split //, $line;

      for (my $i = 0; $i < @chars; $i++) {
          my $c = $chars[$i];

          if ($c eq '"') {
              # If we're in quotes and the next char is also a quote,
              # this is an escaped quote ("")
              if ($in_quotes && $chars[$i + 1] && $chars[$i + 1] eq '"') {
                  $field .= '"';
                  $i++;  # skip the escaped quote
              } else {
                  # Toggle quoted state, do not include the outer quotes
                  $in_quotes = !$in_quotes;
              }
          }
          elsif ($c eq ',' && !$in_quotes) {
              push @fields, $field;
              $field = '';
          }
          else {
              $field .= $c;
          }
      }

      # Add the final field
      push @fields, $field;

      push @rows, \@fields;
  }

  close $fh;
  return \@rows;
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
  my $player_photo_url       = shift;
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

  my $queried_name      = $player_query[0]->{Constants::PLAYER_SANITIZED_NAME_COLUMN_NAME};
  my $queried_raw_name  = $player_query[0]->{Constants::PLAYER_NAME_COLUMN_NAME};
  my $queried_photo_url = $player_query[0]->{Constants::PLAYER_PHOTO_URL_COLUMN_NAME};

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
  if (!$player_photo_url)
  {
    $player_photo_url = $queried_photo_url;
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
    Constants::PLAYER_PHOTO_URL_COLUMN_NAME       => $player_photo_url,
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
        $id_name_hashref->{$xt_id} = [$data->[$index + 2], $data->[$index + 10]];
      }
    }
  }

  my $tournament_id = $data->[5];
  my $date;
  if ($tournament_id)
  {
    $date = $tournament_id_date_hashref->{$tournament_id};
    if (!$date)
    {
      $tournament_id_date_hashref->{$tournament_id} =$data->[10];
    }
  }

  if ($data->[7] && $data->[7] eq 'NSW18')
  {
    $data->[7] = 'NWL18';
  }
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
