#!/usr/bin/perl

package Update;

use warnings;
use strict;
use Data::Dumper;
use Cwd;

use lib './objects';
use lib './modules';

use Constants;
use Utils;
use Stats;

unless (caller)
{
  my $validation = update_search_data();
  update_leaderboard();
  update_notable();
  update_remote_cgi();
  update_html($validation);
}

sub update_search_data
{
  my $dbh = Utils::connect_to_database();

  my $button_id = 'query_form';
  my $players_table = Constants::PLAYERS_TABLE_NAME;
  my $games_table   = Constants::GAMES_TABLE_NAME;

  my @inputs =
  (
    ['Player Name',   Constants::PLAYER_FIELD_NAME,        'required', Constants::PLAYER_NAME_COLUMN_NAME, $players_table],
    ['Game Type',     Constants::CORT_FIELD_NAME,          '', ['', Constants::GAME_TYPE_TOURNAMENT, Constants::GAME_TYPE_CASUAL]],
    ['Tournament ID', Constants::TOURNAMENT_ID_FIELD_NAME, '', Constants::GAME_CROSS_TABLES_TOURNAMENT_ID_COLUMN_NAME, $games_table],
    ['Lexicon',       Constants::LEXICON_FIELD_NAME,       '', ['', 'CSW19', 'NSW18', 'CSW15', 'TWL15', 'CSW12', 'CSW07', 'TWL06', 'TWL98']],
    ['Game ID',       Constants::GAME_ID_FIELD_NAME,       '', Constants::GAME_CROSS_TABLES_ID_COLUMN_NAME, $games_table],
    ['Opponent',      Constants::OPPONENT_FIELD_NAME,      '', Constants::PLAYER_NAME_COLUMN_NAME, $players_table],
    ['Start Date',    Constants::START_DATE_FIELD_NAME,    '', Constants::GAME_DATE_COLUMN_NAME, $games_table],
    ['End Date',      Constants::END_DATE_FIELD_NAME,      '', Constants::GAME_DATE_COLUMN_NAME, $games_table],
  );

  my $html = "";
  my $validate = "var input; var options; var relevantOptions;\n";
  for (my $i = 0; $i < scalar @inputs; $i++)
  {
    my $inp      = $inputs[$i];

    my $title    = $inp->[0];
    my $name     = $inp->[1];
    my $required = $inp->[2];
    my $field    = $inp->[3];
    my $table    = $inp->[4];
   
    my $input_id = $name . '_input';
    my $html_id  = $name . '_html';

    if ($table)
    {
      my $data = Utils::get_all_unique_values($dbh, $table, $field);
      $html .= make_datalist_input
      (
	$title,
	$name,
	$required,
        $field,
        $data,
        $button_id,
	$input_id,
	$html_id
      );
      $validate .= add_input_validation
      (
        $title,
        $field,
	$input_id,
	$html_id
      );
    }
    else
    {
      my $data = $field;
      $html .= make_select_input($title, $name, $required, $data);
    }

    if ($i == 0)
    {

      $html .= '<div class="collapse" id="collapseOptions">';
    }
  }


      $html .=
<<BUTTON
      </div>

      <div>
        <button class="btn btn-primary" type="button" data-toggle="collapse" data-target="#collapseOptions"
          aria-expanded="false" aria-controls="collapseOptions">
          Toggle More Options
        </button>
      </div>
BUTTON
;

  $html .= '<button class="btn btn-info btn-block my-4" type="submit">Submit</button>';
  Utils::write_string_to_file($html, Constants::HTML_DIRECTORY_NAME . '/' . Constants::SEARCH_DATA_FILENAME);
  return $validate;
}

sub make_select_input
{
  my $title    = shift;
  my $name     = shift;
  my $required = shift;
  my $data     = shift;

  my $options = "";

  for (my $i = 0; $i < scalar @{$data}; $i++)
  {
    my $val = $data->[$i];
    $options .= "<option value='$val'>$val</option>\n";
  }
  return "$title<select class='browser-default custom-select mb-4' name='$name'>$options</select>";
}

sub add_input_validation
{
  my $title    = shift;
  my $field    = shift;
  my $input_id = shift;
  my $html_id  = shift;


  my $function = <<FUNCTION

          input = document.getElementById('$input_id');
          options = Array.from(document.getElementById('$html_id').options).map(function(el)
          {
            return el.value;
          }); 
          relevantOptions = options.filter
          (
            function(option)
            {
              return option.toLowerCase().includes(input.value.toLowerCase());
            }
          );
          if (input.value != "" && input.value != relevantOptions[0])
          {
            alert('Invalid value for $title. Choose an option by typing in the box and selecting an option from the dropdown menu.');
	    return false;
          }

FUNCTION
;
  return $function;

}

sub make_datalist_input
{
  my $title     = shift;
  my $name      = shift;
  my $required  = shift;
  my $field     = shift;
  my $data      = shift;
  my $button_id = shift;
  my $input_id  = shift;
  my $html_id   = shift;

  my $escaped_char = "&quot;";

  my $function = <<FUNCTION

          var input = document.getElementById('$input_id');
          var options = Array.from(document.getElementById('$html_id').options).map(function(el)
          {
            return el.value;
          }); 
          var relevantOptions = options.filter
          (
            function(option)
            {
              return option.toLowerCase().includes(input.value.toLowerCase());
            }
          );
          if (relevantOptions.length > 0 && input.value != relevantOptions[0])
          {
            input.value = relevantOptions.shift();
	    event.preventDefault();
          }
          else if (relevantOptions.length == 0)
          {
            alert('Choose an option by typing in the box and selecting an option from the dropdown menu.');
	    event.preventDefault();
          }
FUNCTION
;

  my $input_function = <<FUNCTION

    onkeypress=
    "
      (function (event)
      {
        if (event.keyCode == 13)
        {
          $function
        }
      })(event)
    "
FUNCTION
;

  my $html =
  "

  $title

  <input class='form-control mb-4' $required name='$name' list='$html_id' id='$input_id' $input_function>
    <datalist id='$html_id'>
  ";

  my @data_array = @{$data};

  foreach my $item (@data_array)
  {
    $html .= "<option  value=\"$item\"></option>\n";
  }

  $html .= "    </datalist>\n";
  return $html
}

sub update_leaderboard
{
  my $cutoff         = Constants::LEADERBOARD_CUTOFF;
  my $min_games      = Constants::LEADERBOARD_MIN_GAMES;
  my $column_spacing = Constants::LEADERBOARD_COLUMN_SPACING;
  my $cache_dir      = Constants::CACHE_DIRECTORY_NAME;
  my $stats_note     = Constants::STATS_NOTE;

  $cache_dir = substr $cache_dir, 2;

  my %leaderboards  = ();
  my @name_order    = ();

  my $leaderboard_string = "";
  my $table_of_contents  = "<h1><a id='leaderboards'></a>LEADERBOARDS</h1>";

  my $dbh = Utils::connect_to_database();

  my $playerstable = Constants::PLAYERS_TABLE_NAME;
  my $gamestable   = Constants::GAMES_TABLE_NAME;
  my $total_games_name = Constants::PLAYER_TOTAL_GAMES_COLUMN_NAME;

  my @player_data = @{$dbh->selectall_arrayref("SELECT * FROM $playerstable WHERE $total_games_name >= $min_games", {Slice => {}, "RaiseError" => 1})};

  foreach my $player_item (@player_data)
  {
    my $total_games  = $player_item->{Constants::PLAYER_TOTAL_GAMES_COLUMN_NAME};
    my $name         = $player_item->{Constants::PLAYER_NAME_COLUMN_NAME};
    my $player_stats = Stats->new(1, $player_item->{Constants::PLAYER_STATS_COLUMN_NAME});
    my $player_stats_data = $player_stats->{Constants::STATS_DATA_KEY_NAME};

    my @stat_keys = (Constants::STATS_DATA_GAME_KEY_NAME, Constants::STATS_DATA_PLAYER_ONE_KEY_NAME);
    
    foreach my $key (@stat_keys)
    {
      my $statlist = $player_stats_data->{$key};
      for (my $i = 0; $i < scalar @{$statlist}; $i++)
      {
        if ($statlist->[$i]->{Constants::STAT_DATATYPE_NAME} eq Constants::DATATYPE_ITEM)
        {
          my $statitem = $statlist->[$i]->{Constants::STAT_ITEM_OBJECT_NAME};
          my $statname = $statlist->[$i]->{Constants::STAT_NAME};

          my $statval      = $statitem->{'total'};
	  my $display_type = $statitem->{Constants::STAT_OBJECT_DISPLAY_NAME};
          my $is_int       = $statitem->{'int'};

          add_stat(\%leaderboards, $name, $statname, $statval, $total_games, $display_type, $is_int,\@name_order);

          my $subitems = $statitem->{'subitems'};
          if ($subitems)
          {
            my $order = $statitem->{'list'};
            for (my $i = 0; $i < scalar @{$order}; $i++)
            {
              my $subitemname = $order->[$i];

              my $substatname = "$statname $subitemname";

              my $substatval  = $subitems->{$subitemname};

              add_stat(\%leaderboards, $name, $substatname, $substatval, $total_games, $display_type, $is_int,  \@name_order);
            }
          }
        }
      }
    }
  }

  for (my $i = 0; $i < scalar @name_order; $i++)
  {
    my $name = $name_order[$i];
    my @array = @{$leaderboards{$name}};
    my $array_length = scalar @array;
    my $sum = 0;

    for (my $j = 0; $j < $array_length; $j++)
    {
      $sum += $array[$j][0];
    }

    $sum = sprintf "%.4f", $sum / $array_length;

    $table_of_contents .= "<a href='#$name'>$name</a>\n";

    $leaderboard_string .= "<h2><a id='$name'></a>Average $name: $sum</h2>";

    for (my $j = 0; $j < 2; $j++)
    {
      my @ranked_array;
      my $title;
      if ($j == 0)
      {
        @ranked_array = sort { $b->[0] <=> $a->[0] } @array;
        $title = "<h3>Most $name</h3>";
      }
      else
      {
        @ranked_array = sort { $a->[0] <=> $b->[0] } @array;
        $title = "\n\n<h3>Least $name</h3>";
      }
      my $all_zeros = 1;
      for (my $k = 0; $k < $cutoff; $k++)
      {
        if ($ranked_array[$k] && $ranked_array[$k][0] != 0)
        {
          $all_zeros = 0;
          last;
        }
      }
      if ($all_zeros)
      {
        next;
      }

      $leaderboard_string .= $title;

      $title =~ />([^<]+)</g;

      $title = $1;

      for (my $k = 0; $k < $array_length; $k++)
      {
        my $name = $ranked_array[$k][1];
        my $name_with_underscores = Utils::sanitize($name);

        if ($k == $cutoff)
        { 
          $leaderboard_string .= "<div id='$title' style='display: none;'>";
        }

        my $link = "<a href='/$cache_dir/$name_with_underscores.html' target='_blank'>$name</a>";

        my $spacing = $column_spacing + (length $link) - (length $name);
        my $ranked_player_name = sprintf "%-" . $spacing . "s", $link;
        my $ranking = sprintf "%-5s", ($k+1) . ".";
        $leaderboard_string .= $ranking . $ranked_player_name . $ranked_array[$k][0] . "\n";
      }
      $leaderboard_string .= "</div>\n";
      $leaderboard_string .= "<button onclick='toggle(\"$title\")'>Toggle Full Standings for $title</button>\n";
    }
    $leaderboard_string .= "\n\n\n\n";
    $leaderboard_string .= "<a href='#leaderboards'>Back to Top</a>\n";
    $leaderboard_string .= "\n\n\n\n";
  }

  my $lt = localtime();

  my $expand_all_button = "\n<button onclick='toggle_all()'>Toggle Full Standings for all leaderboards</button>\n";

  $leaderboard_string = "\nUpdated on $lt\n\n" . $stats_note . $table_of_contents . $expand_all_button . $leaderboard_string;

  $leaderboard_string = "<pre style='white-space: pre-wrap;' > $leaderboard_string </pre>\n";

  my $javascript = Constants::LEADERBOARD_JAVASCRIPT;

  $leaderboard_string = $javascript . $leaderboard_string;

  my $logs = Constants::LOGS_DIRECTORY_NAME;

  my $leaderboard_name = "$logs/" . Constants::LEADERBOARD_NAME . ".log";
  my $leaderboard_html = Constants::HTML_DIRECTORY_NAME . '/' . Constants::RR_LEADERBOARD_NAME;

  open(my $log_leaderboard, '>', $leaderboard_name);
  print $log_leaderboard $leaderboard_string;
  close $log_leaderboard;

  open(my $rr_leaderboard, '>', $leaderboard_html);
  print $rr_leaderboard $leaderboard_string;
  close $rr_leaderboard;
}


sub update_notable
{
  my $notable_dir    = Constants::NOTABLE_DIRECTORY_NAME;
  my $url            = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX;
  my $stats_note     = Constants::STATS_NOTE;
  
  my $dbh = Utils::connect_to_database();
  my $playerstable = Constants::PLAYERS_TABLE_NAME;

  my %notable_hash;
  my %check_for_repeats_hash;
  my $notable_string = "";
  my $table_of_contents  = "<h1><a id='notable'></a>\"That's Notable!\"</h1>";
  my $init = 0;
  my @ordering = ();

  my @player_data = @{$dbh->selectall_arrayref("SELECT * FROM $playerstable", {Slice => {}, "RaiseError" => 1})};

  foreach my $player_item (@player_data)
  {
    my $player_stats = Stats->new(1, $player_item->{Constants::PLAYER_STATS_COLUMN_NAME});
    my $player_stats_data = $player_stats->{Constants::STATS_DATA_KEY_NAME};

    my @stat_keys = (Constants::STATS_DATA_NOTABLE_KEY_NAME);
    
    foreach my $key (@stat_keys)
    {
      my $statlist = $player_stats_data->{$key};

      for (my $i = 0; $i < scalar @{$statlist}; $i++)
      {
        my $statitem = $statlist->[$i]->{Constants::STAT_ITEM_OBJECT_NAME};
        my $statname = $statlist->[$i]->{Constants::STAT_NAME};

        if (!$notable_hash{$statname})
        {
          push @ordering, $statname;
          $notable_hash{$statname} = "<br>";
        }
        my $list = $statitem->{'list'};
        my $ids  = $statitem->{'ids'};
        for (my $i = 0; $i < scalar @{$list}; $i++)
        {
          my $unique_name = $statname . $ids->[$i];
          if ($check_for_repeats_hash{$unique_name})
          {
            next;
          }
          my $notable_game = $list->[$i];
          $notable_hash{$statname} .= $notable_game . "<br>";
          $check_for_repeats_hash{$unique_name} = 1;
        }
      }
    }
  }

  for (my $i = 0; $i < scalar @ordering; $i++)
  {
    my $key             = $ordering[$i];
    $table_of_contents .= "<a href='#$key'>$key</a></br>";
    $notable_string    .= "</br></br></br><h3><a id='$key'></a>$key</h3>";
    $notable_string    .= $notable_hash{$key};
  }

  my $lt = localtime();

  $notable_string = "\nUpdated on $lt\n\n" . $stats_note . $table_of_contents . "</br></br></br>" . $notable_string;

  $notable_string = "<pre style='white-space: pre-wrap;' > $notable_string </pre>\n";

  my $logs = Constants::LOGS_DIRECTORY_NAME;

  my $notable_name = "$logs/" . Constants::NOTABLE_NAME . ".log";
  my $notable_html = Constants::HTML_DIRECTORY_NAME . '/' . Constants::RR_NOTABLE_NAME;

  open(my $new_notable, '>', $notable_name);
  print $new_notable $notable_string;
  close $new_notable;

  open(my $rr_notable, '>', $notable_html);
  print $rr_notable $notable_string;
  close $rr_notable;
}

sub update_remote_cgi
{
  my $vm_ip_address = Constants::VM_IP_ADDRESS;
  my $vm_username   = Constants::VM_USERNAME;
  my $vm_ssh_args   = Constants::VM_SSH_ARGS;
  my $dirname       = cwd();

  $dirname =~ s/.*\///g;

  my $target = $vm_username . '\@' . $vm_ip_address;


  my $name  = Constants::PLAYER_FIELD_NAME         ;
  my $cort  = Constants::CORT_FIELD_NAME           ;
  my $gid   = Constants::GAME_ID_FIELD_NAME        ;
  my $tid   = Constants::TOURNAMENT_ID_FIELD_NAME  ;
  my $opp   = Constants::OPPONENT_FIELD_NAME       ;
  my $start = Constants::START_DATE_FIELD_NAME     ;
  my $end   = Constants::END_DATE_FIELD_NAME       ;
  my $lex   = Constants::LEXICON_FIELD_NAME        ;
  my $dir   = Constants::DIRECTORY_FIELD_NAME      ;

  my $cgi_script = <<SCRIPT
#!/usr/bin/perl
 
  use warnings;
  use strict;
  use CGI;
  
  sub sanitize_name
  {
    my \$string = shift;
  
    \$string = substr( \$string, 0, 256);
  
    # Remove trailing and leading whitespace
    \$string =~ s/^\\s+|\\s+\$//g;
  
    # Replace spaces with underscores
    \$string =~ s/ /_/g;
  
    # Remove anything that is not an
    # underscore, dash, letter, or number
    \$string =~ s/[^\\w\-]//g;
  
    # Capitalize
    \$string = uc \$string;
  
    return \$string;
  }
  
  sub sanitize_number
  {
    my \$string = shift;
  
    \$string = substr( \$string, 0, 256);
  
    # Remove trailing and leading whitespace
    \$string =~ s/^\\s+|\\s+\$//g;
  
    # Remove anything that is not a number
    \$string =~ s/[^\\d]//g;
  
    return \$string;
  }
  
  my \$query = new CGI;
  
  my \$name = \$query->param('$name');
  my \$cort = \$query->param('$cort');
  my \$tid  = \$query->param('$tid');
  my \$gid  = \$query->param('$gid');
  my \$opp  = \$query->param('$opp');
  my \$start = \$query->param('$start');
  my \$end  = \$query->param('$end');
  my \$lexicon  = \$query->param('$lex');
  
  my \$name_arg = '--$name "' . sanitize_name(\$name) . '"';
  my \$cort_arg = "";
  my \$tid_arg = "";
  my \$gid_arg = "";
  my \$opp_arg = "";
  my \$start_arg = "";
  my \$end_arg = "";
  my \$lexicon_arg = "";
  
  if (\$cort)
  {
    \$cort_arg = "--$cort ". sanitize_name(\$cort);
  }
  
  if (\$tid)
  {
    \$tid_arg = "--$tid " . sanitize_number(\$tid);
  }
  
  if (\$gid)
  {
    \$gid_arg = "--$gid ". sanitize_number(\$gid);
  }
  
  if (\$opp)
  {
    \$opp_arg = "--$opp " . sanitize_name(\$opp);
  }
  
  if (\$start)
  {
    \$start_arg = "--$start " . sanitize_number(\$start);
  }
  
  if (\$end)
  {
    \$end_arg = "--$end " . sanitize_number(\$end);
  }
  
  if (\$lexicon)
  {
    \$lexicon_arg = "--$lex " . sanitize_name(\$lexicon);
  }
  
  my \$dir_arg = " --$dir $dirname ";

  my \$output = "";
  my \$cmd = "LANG=C ssh $vm_ssh_args -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $target /home/jvc/minegcg_wrapper.pl \$name_arg \$cort_arg \$tid_arg \$gid_arg \$opp_arg \$start_arg \$end_arg \$lexicon_arg \$dir_arg |";
  open(SSH, \$cmd) or die "\$!\n";
  while (<SSH>)
  {
    \$output .= \$_;
  }
  close SSH;
  print "Content-type: text/html\n\n";
  #print \$cmd;
  #print CGI::header();
  print \$output;
  
  
SCRIPT
;
   
  open(my $fh, '>', Constants::CGIBIN_DIRECTORY_NAME . '/' . Constants::CGI_SCRIPT_FILENAME);
  print $fh $cgi_script;
  close $fh;
}

sub update_html
{
  my $validation = shift;

  my $cgibin_name = Constants::CGIBIN_DIRECTORY_NAME;
  $cgibin_name = substr $cgibin_name, 2;
  $cgibin_name = Utils::get_environment_name($cgibin_name);

  my $name_option = Constants::PLAYER_FIELD_NAME         ;
  my $cort_option = Constants::CORT_FIELD_NAME           ;
  my $gid_option = Constants::GAME_ID_FIELD_NAME        ;
  my $tid_option = Constants::TOURNAMENT_ID_FIELD_NAME  ;
  my $opp_option = Constants::OPPONENT_FIELD_NAME       ;
  my $start_option = Constants::START_DATE_FIELD_NAME     ;
  my $end_option = Constants::END_DATE_FIELD_NAME       ;
  my $lex_option = Constants::LEXICON_FIELD_NAME        ;

  my $search_data_id = Constants::SEARCH_DATA_FILENAME;
  my $search_data_html = $search_data_id;

  $search_data_id =~ s/\..*//g;

  my $quote_style = "text-align: center";

  my $index_html = <<HTML

<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <meta http-equiv="x-ua-compatible" content="ie=edge">
  <title>RandomRacer</title>
  <!-- Font Awesome -->
  <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.2/css/all.css">
  <!-- Bootstrap core CSS -->
  <link href="css/bootstrap.min.css" rel="stylesheet">
  <!-- Material Design Bootstrap -->
  <link href="css/mdb.min.css" rel="stylesheet">
  <!-- Your custom styles (optional) -->
  <link href="css/style.css" rel="stylesheet">

  <link href="https://fonts.googleapis.com/css?family=VT323" rel="stylesheet">
</head>

<body>

<!--Navbar-->
<nav class="navbar navbar-expand-lg navbar-dark primary-color">

  <!-- Navbar brand -->
  <a class="navbar-brand" href="/" style="font-family: 'VT323', monospace;">RandomRacer</a>

  <!-- Collapse button -->
  <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#basicExampleNav"
    aria-controls="basicExampleNav" aria-expanded="false" aria-label="Toggle navigation">
    <span class="navbar-toggler-icon"></span>
  </button>

  <!-- Collapsible content -->
  <div class="collapse navbar-collapse" id="basicExampleNav">

    <!-- Links -->
    <ul class="navbar-nav mr-auto">
      <li class="nav-item">
        <a class="nav-link" href="/leaderboards.html">Leaderboards</a>
      </li>
      <li class="nav-item">
        <a class="nav-link" href="/notable.html">Notable</a>
      </li>

      <!-- Dropdown 
      <li class="nav-item dropdown">
        <a class="nav-link dropdown-toggle" id="navbarDropdownMenuLink" data-toggle="dropdown"
          aria-haspopup="true" aria-expanded="false">Dropdown</a>
        <div class="dropdown-menu dropdown-primary" aria-labelledby="navbarDropdownMenuLink">
          <a class="dropdown-item" href="#">Action</a>
          <a class="dropdown-item" href="#">Another action</a>
          <a class="dropdown-item" href="#">Something else here</a>
        </div>
      </li>
      -->
    </ul>
    <!-- Links -->
  </div>
  <!-- Collapsible content -->

</nav>
<!--/.Navbar-->

<div style="padding-bottom: 5%; padding-top: 5%" id="carouselExampleSlidesOnly" class="carousel slide" data-ride="carousel">
  <div class="carousel-inner">
    <div class="carousel-item active" style="$quote_style">
      Yeet 1
    </div>
    <div class="carousel-item" style="$quote_style">
      Yeet 2
    </div>
    <div class="carousel-item" style="$quote_style">
      Yeet 3
    </div>
  </div>
</div>


  <div style="width: 98%; margin: auto;">
    <form class="border border-light p-5" action="$cgibin_name/mine_webapp.pl" target="_blank" method="get" onsubmit="return nocacheresult()">

      <p class="h4 mb-4 text-center">Search for a Player</p>

      <div id="$search_data_id">
      </div>

    </form>
  </div>

  <!-- SCRIPTS -->
  <!-- JQuery -->
  <script type="text/javascript" src="js/jquery-3.4.1.min.js"></script>
  <!-- Bootstrap tooltips -->
  <script type="text/javascript" src="js/popper.min.js"></script>
  <!-- Bootstrap core JavaScript -->
  <script type="text/javascript" src="js/bootstrap.min.js"></script>
  <!-- MDB core JavaScript -->
  <script type="text/javascript" src="js/mdb.min.js"></script>

  <script>
    function nocacheresult()
    {
      $validation
      var inputs = document.getElementsByTagName("input");
      for (i = 0; i < inputs.length; i++)
      {
        if (inputs[i].value != "Submit" && inputs[i].name != "name" && inputs[i].value != "")
        {
          // debug.innerHTML = inputs[i].name + " -  "  + inputs[i].value;
          return true;
        }
      }
      var selects = document.getElementsByTagName("select");
      for (i = 0; i < selects.length; i++)
      {
        if (selects[i].value != "")
        {
          // debug.innerHTML = selects[i].name + " -s-  "  + selects[i].value;
          return true;
        }
      }
      var name = document.getElementsByName("name")[0].value;
      // Sanitize exactly as MineGCG does
      name = name.trim();
      name = name.replace(/ /g, "_");
      name = name.replace(/[^\\w\\-]/g, "");
      name = name.toUpperCase();
      window.open("/cache/" + name + ".html", "_blank");
      return false;
    }

    \$(function(){
      \$("#$search_data_id").load("$search_data_html");
    });

  </script>

</body>

</html>


HTML
;
  open(my $fh, '>', Constants::HTML_DIRECTORY_NAME . '/' . Constants::INDEX_HTML_FILENAME);
  print $fh $index_html;
  close $fh;
}

sub update_name_id_hash
{
  my $hashref = shift;

  my $datadir               = Constants::DATA_DIRECTORY_NAME;
  my $name_id_data_filename = Constants::NAME_ID_DATA_FILENAME;
  my $var_name              = Constants::NAME_ID_VARIABLE_NAME;

  my $data = "{";

  foreach my $key (keys %{$hashref})
  {
    my $value = $hashref->{$key};
    $data .= "\n  '$key' => '$value',";
  }

  chop($data);

  $data .= "\n}";
  
  my $file_string =
"
#!/usr/bin/perl
 
package NameConversion;

use strict;
use warnings;

use constant $var_name => 
$data
;

1;
";

  open (my $fh, '>', "$datadir/$name_id_data_filename");
  print $fh $file_string;
  close $fh;
}

sub add_stat
{
  my $leaderboards = shift;
  my $playername   = shift;
  my $statname     = shift;
  my $statvalue    = shift;
  my $total_games  = shift;
  my $display_name = shift;
  my $is_int       = shift;
  my $name_order   = shift;
  
  if (!$display_name)
  {
    $statvalue /= $total_games
  }
  $statvalue = sprintf "%.4f", $statvalue;
  if ($is_int)
  {
    $statvalue = int($statvalue);
  }
  if ($leaderboards->{$statname})
  {
    push @{$leaderboards->{$statname}}, [$statvalue, $playername];
  }
  else
  {
    push @{$name_order}, $statname;
    $leaderboards->{$statname} = [[$statvalue, $playername]];
  }
}



1;

