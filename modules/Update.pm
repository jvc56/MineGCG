#!/usr/bin/perl

package Update;

use warnings;
use strict;
use Data::Dumper;
use Cwd;
use List::Util qw(shuffle);
use Scalar::Util qw(looks_like_number);

use lib './objects';
use lib './modules';

use Constants;
use Utils;
use Stats;

unless (caller)
{
  my $validation        = update_search_data();
  my $featured_mistakes = update_leaderboard();
  my $featured_notable  = update_notable();
  update_remote_cgi();
  update_html($validation, $featured_mistakes, $featured_notable);
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
    ['Game Type',     Constants::CORT_FIELD_NAME,          '', [Constants::GAME_TYPE_TOURNAMENT, Constants::GAME_TYPE_CASUAL]],
    ['Tournament ID', Constants::TOURNAMENT_ID_FIELD_NAME, '', Constants::GAME_CROSS_TABLES_TOURNAMENT_ID_COLUMN_NAME, $games_table],
    ['Lexicon',       Constants::LEXICON_FIELD_NAME,       '', ['CSW19', 'NSW18', 'CSW15', 'TWL15', 'CSW12', 'CSW07', 'TWL06', 'TWL98']],
    ['Game ID',       Constants::GAME_ID_FIELD_NAME,       '', Constants::GAME_CROSS_TABLES_ID_COLUMN_NAME, $games_table],
    ['Opponent',      Constants::OPPONENT_FIELD_NAME,      '', Constants::PLAYER_NAME_COLUMN_NAME, $players_table],
    ['Start Date',    Constants::START_DATE_FIELD_NAME,    '', Constants::GAME_DATE_COLUMN_NAME, 'date'],
    ['End Date',      Constants::END_DATE_FIELD_NAME,      '', Constants::GAME_DATE_COLUMN_NAME, 'date'],
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

    if ($table && $table ne 'date')
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
    elsif ($table && $table eq 'date')
    {
      my $datepicker = <<DATEPICKER
<div class="input-append date"  data-date-format="mm/dd/yyyy">
  <input name="$name" class="form-control mb-4" type="text"   placeholder="$title" >
  <span class="add-on"><i class="icon-th"></i></span>
</div>
DATEPICKER
      ;
      $html .= $datepicker;
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

      <div style="text-align: center">
        <a data-toggle="collapse" data-target="#collapseOptions"
          aria-expanded="false" aria-controls="collapseOptions" onclick='toggle_icon(this)'>
          <i class="fas fa-angle-down rotate-icon"></i>
        </a>
      </div>
      <div style="text-align: center">
        <button class="btn" type="submit">Submit</button>
      </div>
BUTTON
;

  Utils::write_string_to_file($html, Constants::HTML_DIRECTORY_NAME . '/' . Constants::SEARCH_DATA_FILENAME);
  return $validate;
}

sub make_select_input
{
  my $title    = shift;
  my $name     = shift;
  my $required = shift;
  my $data     = shift;

  my $options = "<option value='' disabled selected>$title</option>\n";

  for (my $i = 0; $i < scalar @{$data}; $i++)
  {
    my $val = $data->[$i];
    $options .= "<option value='$val'>$val</option>\n";
  }
  return "<select class='browser-default custom-select mb-4' name='$name' placeholder='$title'>$options</select>";
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
  <input class='form-control mb-4' $required name='$name' list='$html_id' id='$input_id' placeholder='$title' $input_function>
    <datalist id='$html_id'>
  ";

  my @data_array = @{$data};

  if (looks_like_number($data_array[0]))
  {
    @data_array = sort {$a <=> $b} @data_array;
  }
  else
  {
    @data_array = sort @data_array;
  }

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

  my @all_mistakes = ();
  my $total_mistakes = 0;
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
        elsif ($statlist->[$i]->{Constants::STAT_NAME} eq 'Mistakes List')
        {
          my $player_mistakes = $statlist->[$i]->{Constants::STAT_ITEM_OBJECT_NAME}->{'list'};  
          push @all_mistakes, $player_mistakes;
	  $total_mistakes += scalar @{$player_mistakes};
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


  my $num_featured_mistakes = Constants::MISTAKES_REEL_LENGTH;

  my %random_indexes = ();

  while (scalar (keys %random_indexes) < $num_featured_mistakes)
  {
    my $index = int(rand($total_mistakes));
    while ($random_indexes{$index})
    {
      $index = ($index + 1) % $total_mistakes;
    }
    $random_indexes{$index} = 1;
  }
  my @indexes = keys %random_indexes;
  my $current_mistake_list_ref = shift @all_mistakes;
  my @current_mistake_list = @{$current_mistake_list_ref}; 

  my @featured_mistakes = ();
  my $i = 0;
  while ($i < $total_mistakes)
  {
    foreach my $m (@current_mistake_list)
    {
      if ($random_indexes{$i})
      {
	push @featured_mistakes, $m;
      }
      $i++
    }
    $current_mistake_list_ref = shift @all_mistakes;
    @current_mistake_list = @{$current_mistake_list_ref}; 
  }
  @featured_mistakes = shuffle @featured_mistakes;
  return \@featured_mistakes;
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
  
  my @featured_notable_games;

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
	  push @featured_notable_games, [$statname, $notable_game];
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

  @featured_notable_games = shuffle @featured_notable_games;

  return \@featured_notable_games;
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
  my $validation        = shift;
  my $featured_mistakes = shift;
  my $featured_notable  = shift;

  my $cgibin_name = Constants::CGIBIN_DIRECTORY_NAME;
  $cgibin_name = substr $cgibin_name, 2;
  $cgibin_name = Utils::get_environment_name($cgibin_name);
  my $search_data_id = Constants::SEARCH_DATA_FILENAME;
  my $search_data_html = $search_data_id;

  $search_data_id =~ s/\..*//g;

  my $quotes_carousel_content   = make_quotes_carousel();
  my $mistakes_carousel_content = make_mistakes_carousel($featured_mistakes);
  my $notable_carousel_content  = make_notable_carousel($featured_notable);

  my $head_content = Constants::HTML_HEAD_CONTENT;
  my $nav          = Constants::HTML_NAV;
  my $default_scripts = Constants::HTML_SCRIPTS;
  my $toggle_icon_script = Constants::TOGGLE_ICON_SCRIPT;
  my $content_div_style = Constants::FRONT_PAGE_DIV_STYLE; 
  my $inner_content_padding = '5%';
  my $title_style       = "style='font-size: 20px;'";
  my $body_style        = Constants::HTML_BODY_STYLE;
  my $index_html = <<HTML

<!DOCTYPE html>
<html lang="en">

<head>
$head_content
</head>

<body $body_style>

$nav

<div $content_div_style>
  <b $title_style >Search</b>
    <div style="padding-bottom: $inner_content_padding; padding-top: $inner_content_padding">
      <form action="$cgibin_name/mine_webapp.pl" target="_blank" method="get" onsubmit="return nocacheresult()">

        <!-- <p class="h4 mb-4 text-center">Search for a Player</p> -->

        <div id="$search_data_id">
        </div>

      </form>
    </div>
</div>

<div $content_div_style>
  <b $title_style >Quotes</b>
  <div style="padding-bottom: $inner_content_padding; padding-top: $inner_content_padding" class="carousel slide" data-ride="carousel" data-interval="10000">
    <div id="quotes-carousel-content" class="carousel-inner">
      $quotes_carousel_content
    </div>
  </div>
</div>
  
<div $content_div_style>
  <b $title_style >Blooper Reel</b>
  <div style="padding-bottom: $inner_content_padding; padding-top: $inner_content_padding" class="carousel slide" data-ride="carousel" data-interval="15000">
    <div id="mistakes-carousel-content" class="carousel-inner">
      $mistakes_carousel_content
    </div>
  </div>
</div>
  
<div $content_div_style>
  <b $title_style >Notable games</b>
  <div style="padding-bottom: $inner_content_padding; padding-top: $inner_content_padding" class="carousel slide" data-ride="carousel" data-interval="5000">
    <div id="notable-carousel-content" class="carousel-inner">
      $notable_carousel_content
    </div>
  </div>
</div>
  

  $default_scripts
  $toggle_icon_script

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




    \$.fn.shuffleChildren = function() {
        \$.each(this.get(), function(index, el) {
            var \$el = \$(el);
            var \$find = \$el.children();

            \$find.sort(function() {
                return 0.5 - Math.random();
            });

            \$el.empty();
            \$find.appendTo(\$el);
        });
    };

    \$(function(){
      \$("#$search_data_id").load("$search_data_html",
      function()
      {
        \$('.input-append.date').datepicker({format: "mm/dd/yyyy"});
      });

      \$("#quotes-carousel-content").shuffleChildren();
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
    my $arrayref = $hashref->{$key};
    my $arrayref_string = '[';
    for (my $i = 0; $i < scalar @{$arrayref}; $i++)
    {
      $arrayref_string .= '"' . $arrayref->[$i] . '",';
    }
    chop($arrayref_string);
    $arrayref_string .= ']';
    $data .= "\n  '$key' => $arrayref_string,";
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

sub make_quotes_carousel
{
  my $cache_dir      = Constants::CACHE_DIRECTORY_NAME;
  my $quote_style = "text-align: center";
  my @content = 
  (
    ['This is waaaay cooler than my website.', 'Cesar Del Solar', ' (probably)'],
    ['This is waaaay cooler than my website.', 'Seth Lipkin',     ' (probably)'],
    ['This is waaaay cooler than my website.', 'Chris Lipe',      ' (probably)'],
    ['*ERRRTTT* ... *ERRRTTT* ... *ERRRTTT* ... ', 'Vince Castellano', '\'s QR scanner'],
    ['Turkey!', 'Robert Linn'],
    ['You stinker!', 'Robert Linn'],
    ['Was it something I said?', 'Robert Linn'],
    ['God damn!', 'Marlon Hill'],
    ['Don\'t phony me, don\'t give me an out, I\'m gonna go smoke.', 'Marlon Hill', ', when stuck with an unplayable tile'],
    ['NO!', 'Tim Weiss'],
    ['SAD!', 'Tim Weiss'],
    ['WETO!', 'Tim Weiss'],
    ['Hot!', 'Tim Weiss'],
    ['Mosey!', 'Tim Weiss'],
    ['Is that that sad acrodont.ru site?', 'Tim Weiss'],
    ['The sun is setting on this game.', 'Tim Weiss'],
    ['Don\'t mosey now, lest ye mosey to the grave.', 'Tim Weiss'],
    ['Are they splitsville?', 'Tim Weiss'],
    ['...', 'Karl Higby'],
    ['Whelp, can\'t complain about this start to the tournament!', 'Daniel Milton'],
    ['Whelp, I think that\'ll do it!', 'Daniel Milton', ', after being stuck with over 40 points on his rack'],
    ['The blank is an S as in Schenectady!', 'Kevin Gauthier'],
    ['Fucking fuck!', 'Evans Clinchy'],
    ['Let\'s play some scrabble!', 'Jason Broersma'],
    ['#KNOWLEDGESADDEST', 'Joshua Castellano'],
    ['Do you, like, hate everything?', 'Inae Bloom', ', shortly after meeting Tim Weiss'],
    ['That\'s notable!', 'Judy Cole'],
    ['It\'s not a big deal, but ...', 'Josh Greenway']
  );

  my $html_content = "";

  for (my $i = 0; $i < scalar @content; $i++)
  {
    my $active = "";
    if ($i == 0)
    {
      $active = 'active';
    }
    my $item = $content[$i];
    my $quote = $item->[0];
    my $name  = $item->[1];
    my $context = $item->[2];
    if (!$context)
    {
      $context = "";
    }
    my $name_with_underscores = Utils::sanitize($name);

    my $link = "<a href='/$cache_dir/$name_with_underscores.html' target='_blank'>$name</a>";

    my $div = <<QUOTE
      <div class="carousel-item $active" style="$quote_style">
        "$quote"<br>- $link$context
      </div>
QUOTE
;
    $html_content .= $div;
  }
  return $html_content;

}

sub make_mistakes_carousel
{
  my $mistakes_ref = shift;
  my $mistake_style = "text-align: center";
  my $html_content = "";

  for (my $i = 0; $i < scalar @{$mistakes_ref}; $i++)
  {
    my $active = "";
    if ($i == 0)
    {
      $active = 'active';
    }
    my $item = $mistakes_ref->[$i];
    my $type    = $item->[0];
    my $size    = $item->[1];
    my $link    = $item->[2];
    my $play    = $item->[3];
    my $comment = $item->[4];

    my $div = <<MISTAKE
      <div class="carousel-item $active" style="$mistake_style">
        $type $size<br>$play<br>$comment<br>$link
      </div>
MISTAKE
;
    $html_content .= $div;
  }
  return $html_content;
}

sub make_notable_carousel
{
  my $notable_ref = shift;
  my $notable_style = "text-align: center";
  my $html_content = "";

  for (my $i = 0; $i < scalar @{$notable_ref}; $i++)
  {
    my $active = "";
    if ($i == 0)
    {
      $active = 'active';
    }
    my $item    = $notable_ref->[$i];
    my $name    = $item->[0];
    my $game    = $item->[1];

    my $div = <<NOTABLE
      <div class="carousel-item $active" style="$notable_style">
        $name<br>$game
      </div>
NOTABLE
;
    $html_content .= $div;
  }
  return $html_content;
}


1;

