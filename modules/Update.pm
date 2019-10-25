#!/usr/bin/perl

package Update;

use warnings;
use strict;
use Data::Dumper;
use Cwd;
use List::Util qw(shuffle min max);
use Scalar::Util qw(looks_like_number reftype);
use Statistics::LineFit;
use Statistics::Standard_Normal;

use lib './objects';
use lib './modules';
use lib './data';

use Constants;
use Utils;
use Stats;
use NameConversion;
use JSON::XS;

unless (caller)
{
  update_qualifiers();
  exit(0);
  update_typing_html();
  update_remote_typing_cgi();
  update_readme_and_about();
  my $validation        = update_search_data();
  my $featured_mistakes = update_leaderboard_legacy();
  my $featured_notable  = update_notable_legacy();
  update_leaderboard();
  update_notable();
  update_remote_cgi();
  update_html($validation, $featured_mistakes, $featured_notable);
}

sub update_qualifiers
{

  my $head_content                    = Constants::HTML_HEAD_CONTENT;
  my $html_styles                     = Constants::HTML_STYLES;
  my $body_style                      = Constants::HTML_BODY_STYLE;
  my $nav                             = Constants::HTML_NAV;
  my $collapse_scripts                = Constants::HTML_TABLE_AND_COLLAPSE_SCRIPTS;
  my $default_scripts                 = Constants::HTML_SCRIPTS;
  my $footer                          = Constants::HTML_FOOTER;



  my $canada_qualifiers = Constants::CANADA_QUALIFIERS;
  my $us_qualifiers     = Constants::US_QUALIFIERS;
  my @qualifying_countries =
  (
    ['Canada', $canada_qualifiers],
    ['United States', $us_qualifiers]
  );
  
  my $qualifierhtml = '';

  for (my $i = 0; $i < scalar @qualifying_countries; $i++)
  {
    my $country = $qualifying_countries[0];
    my $qualifiers_list = $qualifying_countries[1];

    $qualifierhtml .= "\n\n<div>Qualifiers for $country</div>\n\n";
    my @qualifier_data = ();
    my @sortdata = ();

    for (my $j = 0; $j < scalar @{$qualifiers_list}; $j++)
    {
      my $qualifier = $qualifiers_list->[$j];
      my ($qualifying_value, $qualifier_html) = get_qualifier_html($qualifier);
      push @qualifier_data, $qualifier_html;
      push @sortdata, [$qualifying_value, $j];
    }

    @sortdata = sort {$b->[0] <=> $a->[0]} @sortdata;

    for (my $j = 0; $j < scalar @sortdata; $j++)
    {
      $qualifierhtml .= $qualifier_data[$sortdata[$j][1]];
    }
  }

  my $qualifierpage =
  "
<!DOCTYPE html>
<html lang=\"en\">
  <head>
  $head_content
  $html_styles
  </head>
  <body $body_style>
  $nav
  <div style='text-align: center; vertical-align: middle; padding: 2%'>
    <h1>
      Alchemist Cup Qualifiers
    </h1>
  </div>
  $qualifierhtml
  $default_scripts
  $collapse_scripts
  $footer
  </body>
</html>
  "
;

  open(my $qfh, '>', Constants::HTML_DIRECTORY_NAME . '/' . Constants::QUALIFIERS_PAGE_NAME);
  print $qfh $qualifierpage;
  close $qfh;
}

sub get_qualifier_html
{
  my $qualifier = shift;

  my $wget_flags = Constants::WGET_FLAGS; 
  my $downloads_dir = Constants::DOWNLOADS_DIRECTORY_NAME;
  my $name_to_id_hash = Constants::NAME_ID_VARIABLE_NAME;
  my $qualifier_id = $name_to_id_hash->{Utils::sanitize($qualifier)};

  my $results_call = Constants::PLAYERS_RESULTS_API_CALL . $qualifier_id;
  my $filename     = $downloads_dir . "/qualifier_results_$qualifier_id.txt";

  my $json = '';

  system "wget $wget_flags $results_call -O $filename  >/dev/null 2>&1";

  open(INFO, "<", $filename);
  while (<INFO>)
  {
    $json .= $_;
  }
  $json = JSON::XS::decode_json($json);
  my @results = @{$json->{'results'}};
  @results = grep {$_->{'date'} ge '2018-06-18' } @results;
  @results = sort {$a->{'date'} cmp $b->{'date'}} @results;

  my $num_results = scalar @results;
  my $sum = 0;
  foreach my $res (@results)
  {
    $sum += $res->{'newrating'};
  }
  my $average = sprintf "%.2f", $sum / $num_results;
  return "$qualifier ($average)";
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
    [['Start Date', 'End Date'], [Constants::START_DATE_FIELD_NAME, Constants::END_DATE_FIELD_NAME],'', Constants::GAME_DATE_COLUMN_NAME, 'date']
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
      my $start_title = $title->[0];
      my $start_name  = $name->[0];
      my $end_title   = $title->[1];
      my $end_name    = $name->[1];
      my $style       = 'style="border-radius: .25em"';
      my $datepicker = <<DATEPICKER
      <div>
        <table style='width: 100%'>
          <tbody>
            <tr>
              <td>
                <div class="input-group date">
                  <input $style name="$start_name" type="text" class="form-control" placeholder="$start_title" >
                  <span class="input-group-addon"><i class="glyphicon glyphicon-th"></i></span>
                </div>
              </td>
              <td>
                <div class="input-group date">
                  <input $style name="$end_name" type="text" class="form-control" placeholder="$end_title" >
                  <span class="input-group-addon"><i class="glyphicon glyphicon-th"></i></span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
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
      my $aboutpage = Constants::ABOUT_PAGE_NAME;
      my $learnlink = "<a href='$aboutpage'>Learn More</a>";

      $html .=
<<BUTTON
      </div>

      <div style="text-align: center">
        <a data-toggle="collapse" data-target="#collapseOptions"
          aria-expanded="false" aria-controls="collapseOptions" onclick='toggle_icon(this, "collapseOptions", true)'>
          Show more<br><i class="fas fa-angle-down rotate-icon"></i>
        </a>
      </div>
      <div style="text-align: center">
        <button class="btn" type="submit">Submit</button>
      </div>
      <div style='text-align: center'>
	$learnlink
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
  my $download   = Constants::DATA_DOWNLOAD_ATTRIBUTE;

  $cache_dir = substr $cache_dir, 2;

  my %leaderboards  = ();
  my @name_order    = ();

  my $leaderboard_string = "";

  my $dbh = Utils::connect_to_database();

  my $playerstable = Constants::PLAYERS_TABLE_NAME;
  my $gamestable   = Constants::GAMES_TABLE_NAME;
  my $total_games_name = Constants::PLAYER_TOTAL_GAMES_COLUMN_NAME;

  my @player_data = @{$dbh->selectall_arrayref("SELECT * FROM $playerstable WHERE $total_games_name >= $min_games", {Slice => {}, "RaiseError" => 1})};

  my %player_tiles_played_percentages = ();
  my %player_win_percentages = ();
  my %player_total_games     = ();
  my %stat_descriptions      = ();

  foreach my $player_item (@player_data)
  {
    my $total_games  = $player_item->{Constants::PLAYER_TOTAL_GAMES_COLUMN_NAME};
    my $name         = $player_item->{Constants::PLAYER_NAME_COLUMN_NAME};
    $player_total_games{$name} = $total_games;
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

          if ($statname eq 'Wins')
          {
            $player_win_percentages{$name} = $statval / $total_games;
          }
	  elsif ($statname eq 'Tiles Played')
	  {
            $player_tiles_played_percentages{$name} = ($statval / $total_games) / 100;
	  }
          $stat_descriptions{$statname} = $statlist->[$i]->{Constants::STAT_DESCRIPTION_NAME};
          add_stat(\%leaderboards, $name, $statname, $statval, $total_games, $display_type, $is_int,\@name_order);
          my $subitems = $statitem->{'subitems'};
          if ($subitems)
          {
            my $order = $statitem->{'list'};
	    my $subdescriptions = $statitem->{'subitem_descriptions'};
            for (my $k = 0; $k < scalar @{$order}; $k++)
            {
              my $subitemname = $order->[$k];

              my $substatname = "$statname-$subitemname";

              my $substatval  = $subitems->{$subitemname};
	      if ($subdescriptions)
	      {
                $stat_descriptions{$substatname} = $subdescriptions->[$k];
	      }
	      else
	      {
                $stat_descriptions{$substatname} = ' ';
	      }
              add_stat(\%leaderboards, $name, $substatname, $substatval, $total_games, $display_type, $is_int,  \@name_order);
            }
          }
        }
      }
    }
  }

  my $previous_was_substat = 0;


  my $function_name     = 'openTab';
  my $tab_script = <<TABSCRIPT

<script>
function $function_name(evt, tabName, tabContentClass, tableid, n)
{
  changeSelector(tableid, 'dscclass', n);

  var i, tabcontent, tablinks;
  tabcontent = document.getElementsByClassName(tabContentClass);
  var n;
  for (i = 0; i < tabcontent.length; i++)
  {
    tabcontent[i].style.display = "none";
  }
  document.getElementById(tabName).style.display = "block";

}
</script>

TABSCRIPT
;
  my $even_style = Constants::DIV_STYLE_EVEN;
  my $odd_style  = Constants::DIV_STYLE_ODD;
  my $color_counter = 0;
  my $violations_content = '';
  my $num_violations = 0;
  for (my $i = 0; $i < scalar @name_order; $i++)
  {
    my $name = $name_order[$i];
    my $og_name = $name;
    my $learntext = $stat_descriptions{$name};
    my $expander_id = $name . '_expander_id';
    my $chart_id    = $name . '_chart_id';
    my $table_id    = $name . '_table_id';

    $table_id    =~ s/\s//g;
    $expander_id =~ s/\s//g;
    $chart_id    =~ s/\s//g;

    $table_id    =~ s/\?/blank/g;
    $expander_id =~ s/\?/blank/g;
    $chart_id    =~ s/\?/blank/g;

    my @ranked_array =  sort { $b->[0] <=> $a->[0] } @{$leaderboards{$name}};
    my $array_length = scalar @ranked_array;
    my $sum = 0;
    my $is_substat = 0;
    my $has_substats = 0;
    my $fullname     = $name;
    my $parent_name  = $name;

    if ($name =~ /(.*)-(.*)/)
    {
      $parent_name = $1;
      $name = $2;
      $is_substat = 1;
      $fullname = $1 . ' ' . $2;
    }
    $has_substats = !$is_substat && ($i + 1 < scalar @name_order) && $name_order[$i+1] =~ /-/;

 

    for (my $j = 0; $j < $array_length; $j++)
    {
      $sum += $ranked_array[$j][0];
    }

    my $average = sprintf "%.2f", $sum / $array_length;

    my $chart_data = "['Correlation of $fullname to Win Percentage', '$fullname', 'Win Percentage', [";
    my @xvalues = ();
    my @yvalues = ();
    my $minx = 10000000;
    my $maxx = -1;
    my $miny = 10000000;
    my $maxy = -1;
    my $statcontent = '';
    for (my $j = 0; $j < $array_length; $j++)
    {
      my $player  = $ranked_array[$j][1];
      my $name_with_underscores = Utils::sanitize($player);
      
      my $rank = $j + 1;
      my $link = "<a href='/$cache_dir/$name_with_underscores.html' target='_blank'>$player</a>";
      my $average = $ranked_array[$j][0];

      my $td_style = "style='width: 33.333333333%; text-align: center'";
      $statcontent .= "<tr $download ><td $td_style>$rank</td><td $td_style>$link</td><td $td_style>$average</td></tr>\n";

      my $win_percentage = $player_win_percentages{$player};
      $player =~ s/'/\\'/g;
      $chart_data .= "{'x': $average, 'y': $win_percentage, 'name': '$player'},";
      push @xvalues, $average;
      push @yvalues, $win_percentage;
      $minx = min($minx, $average);
      $maxx = max($maxx, $average);
      $miny = min($miny, $win_percentage);
      $maxy = max($maxy, $win_percentage);
    }
    my $stattable = Utils::make_datatable(
      0,
      $table_id,
      ['Rank', 'Player', 'Average'],
      ['text-align: center', 'text-align: center', 'text-align: center'],
      ['true', 'false', 'true'],
      $statcontent,
      'Average',
      'dscclass',
      $learntext
    );


    my @tab_titles  = ('Leaderboard'); 
    my @tab_content = ($stattable);

    if ($array_length > 1)
    {
    
      my $xcheck = $xvalues[0];
      my $xdiff  = 0;
      for (my $i = 1; $i < $array_length; $i++)
      {
        if ($xcheck != $xvalues[$i])
	{
          $xdiff = 1;
	}
      }
      if ($xdiff)
      {
        chop($chart_data);
        $chart_data .= '], ';
  
        my $r         = '';
        my @p1        = (0, 0);
        my @p2        = (0, 0);
        my $info      = '';
  
        my $lineFit = Statistics::LineFit->new();
        $lineFit->setData(\@xvalues, \@yvalues);
        if (defined $lineFit->rSquared())
        {
          my ($intercept, $slope) = $lineFit->coefficients();


	  @p1 = ($minx, $minx * $slope  + $intercept);
          @p2 = ($maxx, $maxx * $slope  + $intercept);

          $r = sqrt($lineFit->rSquared());
          if ($slope < 0)
	  {
	    $r = -$r;
	  }  
	  my $short_slope = sprintf "%.6f", $slope;
          my $info_style = "style='text-align: center;'";
          $info =
  	"<div $info_style>
  	   The slope of the least squares line of best fit shown on the graph is $short_slope. To learn more about this graph, check the 'Win Correlation Graphs' section of the <a href='/about.html'>about page</a>. 
  	 </div>
  	";
          $chart_data .= "$r, [$p1[0], $p1[1]], [$p2[0], $p2[1]], $slope]";
  
  
          my $chart = "<div style='width: 100%; height: 600px' id='$chart_id'></div>$info";
  
          push @tab_titles, Constants::CHART_TAB_NAME; 
          push @tab_content, $chart;
        }
      }
    }

    if (length $name == 1 && ($og_name =~ /Tiles Played/ || $parent_name =~ /Tiles Played/))
    {
      my $over_table_id = $table_id . '_over';
      my $overtable_content = ''; 
      my $tile_frequencies = Constants::TILE_FREQUENCIES; 
      for (my $j = 0; $j < $array_length; $j++)
      {
        my $player  = $ranked_array[$j][1];
  my $average = $ranked_array[$j][0];
        my $name_with_underscores = Utils::sanitize($player);
        
        my $link = "<a href='/$cache_dir/$name_with_underscores.html' target='_blank'>$player</a>";
 
        # Calculate binomial stuff
  my $P           = $player_tiles_played_percentages{$player};
  my $total_games = $player_total_games{$player};
  my $n           = $tile_frequencies->{$name} * $total_games;
  my ($lower, $upper) = Utils::get_confidence_interval($P, $n);

  my $prob        = sprintf "%.4f", $average / $tile_frequencies->{$name};

	my $confidence_interval = "($lower, $upper)";

	my $row_color = '';
	my $add_to_violations = 0;
	if ($prob > $upper)
	{
          $row_color = Constants::OVER_CONFIDENCE_COLOR;
	  $add_to_violations = 1;
	}
	elsif ($prob < $lower)
	{
          $row_color = Constants::UNDER_CONFIDENCE_COLOR;
	  $add_to_violations = 1;
	}
        #printf "%s,  %s,  %s,  %s,  %s,  %s,  %s,  %s,  %s, %s, %s  \n", $P, $total_games,
        #$n, $mean, $sigma, $outcome, $z, $actual_deviation, $pct, $name, $tile_frequencies->{$name};

	# $prob = (sprintf "%.2f", $prob) . '%';
        my $td_style = "style='width: 33.333333%; text-align: center; background-color: $row_color'";

	my $overrow =
	"
	<tr $download>
	  <td $td_style>$link</td>
	  <td $td_style>$prob</td>
	  <td $td_style>$confidence_interval</td>
	</tr>\n";

	$overtable_content .= $overrow;
	if ($add_to_violations && $parent_name eq 'Tiles Played')
	{
          my $v_td_style = "style='width: 25%; text-align: center; background-color: $row_color'";
          $violations_content .=
        "
	<tr $download>
	  <td $v_td_style>$link</td>
	  <td $v_td_style>$name</td>
	  <td $v_td_style>$prob</td>
	  <td $v_td_style>$confidence_interval</td>
	</tr>
	";
	$num_violations++;
        }
      }

      my $overtable = Utils::make_datatable(
        0,
        $over_table_id,
        ['Player', 'p', 'CI'],
        ['text-align: center', 'text-align: center', 'text-align: center'],
        ['false', 'true', 'disable'],
        $overtable_content,
	0,
	0,
	'To learn more about these statistics, check the \'Confidence Intervals\' section on the <a href="/about.html">about page</a>.'
      );

 
      push @tab_titles, 'Confidence Intervals';
      push @tab_content, $overtable;
    }

    my $tabbed_content = make_tabbed_content(
         \@tab_titles,
         \@tab_content,
         $chart_id,
         $chart_data,
         $function_name,
         $og_name,
         $average);

    if (!$is_substat)
    {
      $color_counter++;
    }

    my $div_style = $odd_style;

    if ($color_counter % 2 == 1)
    {
      $div_style = $even_style;
    }

    if ($previous_was_substat && !$is_substat)
    {
      $leaderboard_string .= "</div>\n";
      if ($parent_name eq 'Power Tiles Stuck With')
      {
        my $violations_table = Utils::make_datatable(
          0,
          'confidence_interval_violations_datatable',
          ['Player', 'Tile', 'p', 'CI'],
          ['text-align: center', 'text-align: center', 'text-align: center', 'text-align: center'],
          ['false', 'false', 'true', 'disable'],
          $violations_content,
	  0,
	  0,
	  'To learn more about these statistics, check the \'Confidence Intervals\' section on the <a href="/about.html">about page</a>.');
       my $tabbed_violations = make_tabbed_content(
         ["Confidence Interval Violations ($num_violations)"],
         [$violations_table],
         'violations_no_chart',
         '',
         $function_name,
         'confidence_interval_violations',
         undef);
       my $violation_expander_id = 'violations_expander';
       my $vexpander = Utils::make_expander($violation_expander_id);
      $tabbed_violations = <<TABBED
      <div class='collapse' id ='$violation_expander_id'>
        $tabbed_violations
      </div>
TABBED
;
       $leaderboard_string .= Utils::make_content_item(
	       $vexpander,
	       'Confidence Interval Violations',
	       $tabbed_violations,
	       $div_style);

      $color_counter++;
      if ($color_counter % 2 == 1)
      {
        $div_style = $even_style;
      }
      else
      {
        $div_style = $odd_style;
      }

      }
    }

    if ($has_substats)
    {
      my $super_expander_id = 'super_' . $expander_id;
      my $super_expander = Utils::make_expander($super_expander_id);
      $leaderboard_string .= <<SUPER
        <div $div_style>$super_expander $name</div>
  <div class='collapse' id='$super_expander_id'>
SUPER
;
      $name = 'All';
    }

    my $expander = Utils::make_expander($expander_id);
    $tabbed_content = <<TABBED
    <div class='collapse' id ='$expander_id'>
      $tabbed_content
    </div>
TABBED
;
    $leaderboard_string .= Utils::make_content_item($expander, $name, $tabbed_content, $div_style);

    $previous_was_substat = $is_substat;
  }

  $leaderboard_string .= '</div>';

  my $head_content                    = Constants::HTML_HEAD_CONTENT;
  my $html_styles                     = Constants::HTML_STYLES;
  my $body_style                      = Constants::HTML_BODY_STYLE;
  my $nav                             = Constants::HTML_NAV;
  my $default_scripts                 = Constants::HTML_SCRIPTS;
  my $html_table_and_collapse_scripts = Constants::HTML_TABLE_AND_COLLAPSE_SCRIPTS;
  my $table_sort_function             = Constants::TABLE_SORT_FUNCTION;
  my $csv_download_scripts            = Constants::CSV_DOWNLOAD_SCRIPTS;
  my $footer                          = Constants::HTML_FOOTER;

  $leaderboard_string = <<HTMLPAGE

<!DOCTYPE html>
<html lang="en">
  <head>
  $head_content
  $html_styles
  </head>
  <body $body_style>
  $nav
  <div style='text-align: center; vertical-align: middle; padding: 2%'>
    <h1>
      Leaderboards
    </h1>
  </div>
  $leaderboard_string
  $default_scripts
  $table_sort_function
  $csv_download_scripts
  <!-- Amchart JavaScript -->
  <script src="https://www.amcharts.com/lib/4/core.js"></script>
  <script src="https://www.amcharts.com/lib/4/charts.js"></script>
  <script src="https://www.amcharts.com/lib/4/themes/dark.js"></script>
  <script src="https://www.amcharts.com/lib/4/themes/animated.js"></script>

  <script>
  function make_chart(chart_id, chart_data)
  {
    var chart_div = document.getElementById(chart_id);
    if (chart_div.innerHTML)
    {
      return;
    }

    var title = chart_data[0];
    var xaxis = chart_data[1];
    var yaxis = chart_data[2];
    var data  = chart_data[3];
    var r     = chart_data[4];
    var p1    = chart_data[5];
    var p2    = chart_data[6];
    var slope = chart_data[7];

    // Themes begin
    am4core.useTheme(am4themes_dark);
    am4core.useTheme(am4themes_animated);
    // Themes end

    var chart = am4core.create(chart_id, am4charts.XYChart);

    chart.data = data;

    var chart_title = chart.titles.create();
    chart_title.text = title;
    
    chart.legend = new am4charts.Legend();
    var xrange = p2[0] - p1[0];
    // Create axes
    var valueAxisX = chart.xAxes.push(new am4charts.ValueAxis());
    valueAxisX.title.text = xaxis;
    valueAxisX.min = p1[0] - xrange/100;
    valueAxisX.max = p2[0] + xrange/100;
    valueAxisX.strictMinMax = true;
    //valueAxisX.renderer.minGridDistance = 40;
    
    // Create value axis
    var valueAxisY = chart.yAxes.push(new am4charts.ValueAxis());
    //valueAxisY.min = 0;
    //valueAxisY.max = 1;
    //valueAxisY.strictMinMax = true;
    valueAxisY.title.text = yaxis;
    
    // Create series
    var lineSeries = chart.series.push(new am4charts.LineSeries());
    lineSeries.dataFields.valueY = "y";
    lineSeries.dataFields.valueX = "x";
    lineSeries.strokeOpacity = 0;
    lineSeries.legendSettings.labelText = "Players";   
    // Add a bullet
    var bullet = lineSeries.bullets.push(new am4charts.CircleBullet());
    bullet.circle.radius        = 4;
    //bullet.circle.fill        = am4core.color('blue');
    //bullet.circle.stroke      = am4core.color('blue');
    //bullet.circle.fillOpacity = 1;
    bullet.tooltipText        = "{name}";
    
    //add the trendlines
    var trend = chart.series.push(new am4charts.LineSeries());
    trend.dataFields.valueY = "value2";
    trend.dataFields.valueX = "value";
    trend.strokeWidth = 2
    trend.stroke = chart.colors.getIndex(0);
    trend.strokeOpacity = 0.7;
    trend.data = [
      { "value": p1[0], "value2": p1[1] },
      { "value": p2[0], "value2": p2[1] }
    ];
    trend.legendSettings.labelText = "r = " + r;
    
    //scrollbars
    chart.scrollbarX = new am4core.Scrollbar();
    chart.scrollbarY = new am4core.Scrollbar();    
    
    // Make info downloadable
    chart.exporting.menu = new am4core.ExportMenu();
    chart.exporting.menu.align         = "left";
    chart.exporting.menu.verticalAlign = "top"; 
  }
  </script>
  $html_table_and_collapse_scripts
  $tab_script
  $footer
  </body>
</html>

HTMLPAGE
;


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

sub make_tabbed_content
{
  my $titles_ref    = shift;
  my $content_ref   = shift;
  my $chart_id      = shift;
  my $chart_data    = shift;
  my $func_name     = shift;
  my $stat_name     = shift;
  my $average       = shift;
  my $num_tabs      = scalar @{$titles_ref};
  my $width         = 100 / $num_tabs;

  my $link_class    = $stat_name . '_link';
  my $content_class = $stat_name . '_content';
  my $tableid       = $chart_id . '_actually_title_table_id';

  $link_class =~ s/\s//g;
  $content_class =~ s/\s//g;

  my $average_text = '';
  if ($average)
  {
    my $average_style =
    "
    style=
    '
      font-size: 20px;
      background-color: black;
      margin: 1px auto;
      padding: 5px;
      border-radius: 10px;
      display: inline-block;
    '
    ";
    $average_text = "<div $average_style ><b>Overall Average: $average</b></div>";
  }



  my $tab_div     =
  "
  <div style='text-align: center'>
    $average_text
    <table class='titledisplay' id='$tableid'>
      <tbody>
        <tr>
  ";
  my $tab_content = '';
  for (my $i = 0; $i < $num_tabs; $i++)
  {
    my $title   = $titles_ref->[$i];
    my $content = $content_ref->[$i];
    my $id = $title . $stat_name . '_tab_id';
    my $display_style = '';
    if ($i != 0)
    {
      $display_style = 'style="display: none"';
    }
    $id =~ s/\s//g;

    my $is_chart = 'false';
    my $make_chart_function_call = '';
    if ($title eq Constants::CHART_TAB_NAME)
    {
      $make_chart_function_call = "make_chart('$chart_id', $chart_data);";  
      $is_chart = 'true';
    }
    my $selectclass = '';
    if ($i == 0)
    {
      $selectclass = 'dscclass';
    }

    $tab_div .= <<BUTTON
    <th
       style='width: $width%'
       class='$selectclass'
       onclick="$func_name(event, '$id', '$content_class', '$tableid', $i); $make_chart_function_call"
       >
      $title
    </th>
BUTTON
;
    $tab_content .= "<div id='$id' class='$content_class' $display_style>$content</div>\n";
  }
  $tab_div .= '</tr></tbody></table></div>';
  return $tab_div  . $tab_content;
}

sub update_leaderboard_legacy
{
  my $cutoff         = Constants::LEADERBOARD_CUTOFF;
  my $min_games      = Constants::LEADERBOARD_MIN_GAMES;
  my $column_spacing = Constants::LEADERBOARD_COLUMN_SPACING;
  my $cache_dir      = Constants::CACHE_DIRECTORY_NAME;

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

  $leaderboard_string = "\nUpdated on $lt\n\n" . $table_of_contents . $expand_all_button . $leaderboard_string;

  $leaderboard_string = "<pre style='white-space: pre-wrap;' > $leaderboard_string </pre>\n";

  my $javascript = Constants::LEADERBOARD_JAVASCRIPT;

  $leaderboard_string = $javascript . $leaderboard_string;

  my $logs = Constants::LOGS_DIRECTORY_NAME;

  my $leaderboard_name = "$logs/" . Constants::LEADERBOARD_NAME . ".legacy.log";
  my $leaderboard_html = Constants::LEGACY_DIRECTORY_NAME . '/' . Constants::RR_LEADERBOARD_NAME;

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
  my $notable_dir         = Constants::NOTABLE_DIRECTORY_NAME;
  my $url                 = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX;
  my $download   = Constants::DATA_DOWNLOAD_ATTRIBUTE;
  
  my $dbh = Utils::connect_to_database();
  my $playerstable = Constants::PLAYERS_TABLE_NAME;

  my %notable_hash;
  my %check_for_repeats_hash;
  my $notable_string = "";
  my $init = 0;
  my @ordering = ();

  my @player_data = @{$dbh->selectall_arrayref("SELECT * FROM $playerstable", {Slice => {}, "RaiseError" => 1})};
  my %stat_descriptions = (); 
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
        $stat_descriptions{$statname} = $statlist->[$i]->{Constants::STAT_DESCRIPTION_NAME};
        if (!$notable_hash{$statname})
        {
          push @ordering, $statname;
          $notable_hash{$statname} = [];
        }
        my $list = $statitem->{'list'};
  # my $ids  = $statitem->{'ids'};
        for (my $i = 0; $i < scalar @{$list}; $i++)
        {
          my $unique_name = $statname . $list->[$i];
          if ($check_for_repeats_hash{$unique_name})
          {
            next;
          }
          push @{$notable_hash{$statname}}, $list->[$i];
          $check_for_repeats_hash{$unique_name} = 1;
        }
      }
    }
  }

  my $even_style = Constants::DIV_STYLE_EVEN;
  my $odd_style  = Constants::DIV_STYLE_ODD;

  for (my $i = 0; $i < scalar @ordering; $i++)
  {
    my $key             = $ordering[$i];
    my $learntext       = $stat_descriptions{$key};
    my $notables        = $notable_hash{$key};
    my $expander_id     = $key . '_expander';
    $expander_id =~ s/\s//g;

    my $div_style = $odd_style;

    if ($i % 2 == 0)
    {
      $div_style = $even_style;
    }

    my $notable_length = scalar @{$notables};
    my $content = '';
    for (my $k = 0; $k < $notable_length; $k++)
    {
      my $game = $notables->[$k];
      $content .= "<tr $download ><td style='text-align: center'>$game</td></tr>\n";
    }

    if (!$content)
    {
      next;
    }
    my $notable_table = Utils::make_datatable(
      $expander_id,
      $key . '_table_id',
      ["Game ($notable_length)"],
      ['text-align: center'],
      ['false'],
      $content,
      0,
      0,
      $learntext
    );

    my $expander = Utils::make_expander($expander_id);

    $notable_string .= Utils::make_content_item($expander, $key, $notable_table, $div_style);
  }

  my $head_content                    = Constants::HTML_HEAD_CONTENT;
  my $html_styles                     = Constants::HTML_STYLES;
  my $body_style                      = Constants::HTML_BODY_STYLE;
  my $nav                             = Constants::HTML_NAV;
  my $default_scripts                 = Constants::HTML_SCRIPTS;
  my $table_sort_function             = Constants::TABLE_SORT_FUNCTION;
  my $html_table_and_collapse_scripts = Constants::HTML_TABLE_AND_COLLAPSE_SCRIPTS;
  my $csv_download_scripts            = Constants::CSV_DOWNLOAD_SCRIPTS;
  my $footer                          = Constants::HTML_FOOTER;
  $notable_string = <<HTMLPAGE

<!DOCTYPE html>
<html lang="en">
  <head>
  $head_content
  $html_styles
  </head>
  <body $body_style>
  $nav
  <div style='text-align: center; vertical-align: middle; padding: 2%'>
    <h1>
      All Time Notable Games
    </h1>
  </div>
  $notable_string
  $default_scripts
  $table_sort_function
  $html_table_and_collapse_scripts
  $csv_download_scripts
  $footer
  </body>
</html>

HTMLPAGE
;

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



sub update_notable_legacy
{
  my $notable_dir    = Constants::NOTABLE_DIRECTORY_NAME;
  my $url            = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX;
  
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

  $notable_string = "\nUpdated on $lt\n\n" . $table_of_contents . "</br></br></br>" . $notable_string;

  $notable_string = "<pre style='white-space: pre-wrap;' > $notable_string </pre>\n";

  my $logs = Constants::LOGS_DIRECTORY_NAME;

  my $notable_name = "$logs/" . Constants::NOTABLE_NAME . ".legacy.log";
  my $notable_html = Constants::LEGACY_DIRECTORY_NAME . '/' . Constants::RR_NOTABLE_NAME;

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

sub update_typing_html
{
  my $cgibin_name = Constants::CGIBIN_DIRECTORY_NAME;
  $cgibin_name = substr $cgibin_name, 2;
  $cgibin_name = Utils::get_environment_name($cgibin_name);

  my $head_content          = Constants::HTML_HEAD_CONTENT;
  my $html_styles           = Constants::HTML_STYLES;
  my $nav                   = Constants::HTML_NAV;
  my $default_scripts       = Constants::HTML_SCRIPTS;
  my $footer                =  Constants::HTML_FOOTER;
  my $toggle_icon_script    = Constants::TOGGLE_ICON_SCRIPT;
  my $odd_div_style         = Constants::DIV_STYLE_ODD; 
  my $even_div_style        = Constants::DIV_STYLE_EVEN; 
  my $inner_content_padding = '5%';
  my $title_style           = "style='font-size: 20px;'";
  my $title_div_style       = "style='text-align: center'";
  my $body_style            = Constants::HTML_BODY_STYLE;
  my $typing_script         = Constants::TYPING_CGI_SCRIPT;

  my $min_length_option = Constants::TYPING_MIN_LENGTH_FIELD_NAME;
  my $max_length_option = Constants::TYPING_MAX_LENGTH_FIELD_NAME;
  my $min_prob_option   = Constants::TYPING_MIN_PROB_FIELD_NAME;
  my $max_prob_option   = Constants::TYPING_MAX_PROB_FIELD_NAME;
  my $num_words_option  = Constants::TYPING_NUM_WORDS_FIELD_NAME;


  my $formid     = 'typing_form_id';
  my $typingid   = 'typing_content_id';
  my $typinghtml =
  "
<!DOCTYPE html>
<html lang=\"en\">
  <head>
  $head_content
  $html_styles
  </head>
  <body $body_style>
  $nav
  <div style='text-align: center; vertical-align: middle; padding: 2%'>
    <h1>
      Typing Practice
    </h1>
  </div>
  <div>
    <form onsubmit='return retrievePassage()' id='$formid'>
     Min word length: <input name='$min_length_option' type='text' value=''><br>
     Max word length: <input name='$max_length_option' type='text' value=''><br>
     Number of words: <input name='$num_words_option'  type='number' value=''><br>
     <input type='submit'>
    </form>
    <div id='$typingid'>
    </div>
  </div>

  <script>
  function retrievePassage()
  {
    var XHR = new XMLHttpRequest();
    var formData = new FormData(document.getElementById('$formid'));
    var args = '';
    for (var [key, value] of formData.entries())
    { 
      args += key + '=' + value + '&';
      console.log(key, value);
    }
    if (args)
    {
      args = args.substring(0, args.length - 1);
    }
    XHR.addEventListener('load', function(event)
    {
      document.getElementById('$typingid').innerHTML = event.target.responseText;
    });
    var gettarget = '/$cgibin_name/$typing_script?' + args;
    console.log(gettarget);
    XHR.open('GET', gettarget);
    XHR.send(formData);
    return false;
  }
  </script>
  </body>
</html>
  "
;
  open(my $fh, '>', Constants::HTML_DIRECTORY_NAME . '/' . Constants::TYPING_HTML_FILENAME);
  print $fh $typinghtml;
  close $fh;
}

sub update_remote_typing_cgi
{
  my $vm_ip_address = Constants::VM_IP_ADDRESS;
  my $vm_username   = Constants::VM_USERNAME;
  my $vm_ssh_args   = Constants::VM_SSH_ARGS;
  my $dirname       = cwd();

  $dirname =~ s/.*\///g;

  my $target = $vm_username . '\@' . $vm_ip_address;

  my $min_length  = Constants::TYPING_MIN_LENGTH_FIELD_NAME;
  my $max_length  = Constants::TYPING_MAX_LENGTH_FIELD_NAME;
  my $min_prob    = Constants::TYPING_MIN_PROB_FIELD_NAME;
  my $max_prob    = Constants::TYPING_MAX_PROB_FIELD_NAME;
  my $num_words   = Constants::TYPING_NUM_WORDS_FIELD_NAME;
  my $dir   = Constants::DIRECTORY_FIELD_NAME      ;
  my $script_name = Constants::TYPING_CGI_SCRIPT;


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
  
  my \$min_length = \$query->param('$min_length'); 
  my \$max_length = \$query->param('$max_length');
  my \$min_prob   = \$query->param('$min_prob');
  my \$max_prob   = \$query->param('$max_prob');
  my \$num_words  = \$query->param('$num_words');

  my \$min_length_arg = "";
  my \$max_length_arg = "";
  my \$min_prob_arg   = "";
  my \$max_prob_arg   = "";
  my \$num_words_arg  = "";
  
  if (\$min_length)
  {
    \$min_length_arg = "--$min_length ". sanitize_name(\$min_length);
  }
  
  if (\$max_length)
  {
    \$max_length_arg = "--$max_length " . sanitize_number(\$max_length);
  }
  
  if (\$min_prob)
  {
    \$min_prob_arg = "--$min_prob ". sanitize_number(\$min_prob);
  }
  
  if (\$max_prob)
  {
    \$max_prob_arg = "--$max_prob " . sanitize_name(\$max_prob);
  }
  
  if (\$num_words)
  {
    \$num_words_arg = "--$num_words " . sanitize_number(\$num_words);
  }

  my \$dir_arg = " --$dir $dirname ";

  my \$output = "";
  my \$cmd = "LANG=C ssh $vm_ssh_args -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $target /home/jvc/typing_wrapper.pl \$min_length_arg \$max_length_arg \$min_prob_arg \$max_prob_arg \$num_words_arg \$dir_arg |";
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
   
  open(my $fh, '>', Constants::CGIBIN_DIRECTORY_NAME . "/$script_name");
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
  my $html_styles  = Constants::HTML_STYLES;
  my $nav          = Constants::HTML_NAV;
  my $default_scripts = Constants::HTML_SCRIPTS;
  my $footer          = Constants::HTML_FOOTER;
  my $toggle_icon_script = Constants::TOGGLE_ICON_SCRIPT;
  my $odd_div_style = Constants::DIV_STYLE_ODD; 
  my $even_div_style = Constants::DIV_STYLE_EVEN; 
  my $inner_content_padding = '5%';
  my $title_style       = "style='font-size: 20px;'";
  my $title_div_style   = "style='text-align: center'";
  my $body_style        = Constants::HTML_BODY_STYLE;
  my $index_html = <<HTML

<!DOCTYPE html>
<html lang="en">

<head>
$head_content
$html_styles
</head>

<body $body_style>

$nav

<div $odd_div_style>
   <div $title_div_style> <b $title_style >Search</b></div>
    <div style="padding-bottom: $inner_content_padding; padding-top: $inner_content_padding">
      <form action="$cgibin_name/mine_webapp.pl" target="_blank" method="get" onsubmit="return nocacheresult()">

        <!-- <p class="h4 mb-4 text-center">Search for a Player</p> -->

        <div id="$search_data_id">
        </div>

      </form>
    </div>
</div>

<div $even_div_style>
   <div $title_div_style> <b $title_style >Quotes</b></div>
  <div style="padding-bottom: $inner_content_padding; padding-top: $inner_content_padding" class="carousel slide" data-ride="carousel" data-interval="10000">
    <div id="quotes-carousel-content" class="carousel-inner">
      $quotes_carousel_content
    </div>
  </div>
</div>
  
<div $odd_div_style>
  <div $title_div_style><b $title_style >Blooper Reel</b></div>
  <div style="padding-bottom: $inner_content_padding; padding-top: $inner_content_padding" class="carousel slide" data-ride="carousel" data-interval="10000">
    <div id="mistakes-carousel-content" class="carousel-inner">
      $mistakes_carousel_content
    </div>
  </div>
</div>
  
<div $even_div_style>
   <div $title_div_style> <b $title_style >Notable games</b></div>
  <div style="padding-bottom: $inner_content_padding; padding-top: $inner_content_padding" class="carousel slide" data-ride="carousel" data-interval="5000">
    <div id="notable-carousel-content" class="carousel-inner">
      $notable_carousel_content
    </div>
  </div>
</div>
  

  $footer
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
        \$('.input-group.date').datepicker({});
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
    #my $id     = $item->[2];
    my $play    = $item->[3];
    my $comment = $item->[4];
    my $link    = $item->[5];
 
    my $div = <<MISTAKE
      <div class="carousel-item $active" style="$mistake_style">
        $type $size<br><br>$play<br><br>$comment<br><br>$link
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


sub update_readme_and_about
{
  my $statslist = Stats::statsList();
  my @statcomments = ();

  for (my $i = 0; $i < scalar @{$statslist}; $i++)
  {
    push @statcomments, [$statslist->[$i]->{Constants::STAT_NAME}, $statslist->[$i]->{Constants::STAT_DESCRIPTION_NAME}];
  }

  my @about =
  (
    [
      'RandomRacer',
      '<a href="/">RandomRacer.com</a> is a site that collects and presents statistics and comments from annotated scrabble games on <a href="http://cross-tables.com">cross-tables.com</a>. All content is updated daily starting at midnight (EST). Updates usually finish in 3.5 hours. Initial development began August 2018 and in February 2019 the first version was released.
<br><br>
In October 2019, the site underwent major updates which include:
<br><br>
<ul>
<li>Mobile-friendly bootstrap reskin.</li>
<li>Front page quote, mistake, and notable games carousels.</li>
<li>Player pictures on player results pages.</li>
<li>Sortable, filterable, and downloadable datatables for all results.</li>
<li>Win Correlation graphs for every statistic on the leaderboard.</li>
<li>Confidence intervals for all Tiles Played statistics.</li>
<li>Dynamic mistake tagging.</li>
</ul>

You can learn more about some of these features in later sections. Please report any bugs to joshuacastellano7@gmail.com'
    ],
    [
      'Usage',
'Simply enter a name in the \'Player Name\' field on the main page and hit submit.
There are other parameters you can use to narrow your search:

<h5>Game Type</h5>
An optional parameter used to search for only casual and club games or only tournament games.
Games are considered tournament games if they are associated with a tournament and a round number.
Games tagged as \'Tournament Game\' in cross-tables with no specific tournament are not considered tournament games.

<h5>Tournament ID</h5>
An optional parameter used to search for only games of a specific tournament.
To find a tournament\'s ID, go to that tournament\'s page on cross-tables.com
and look for the number in the address bar. For example, the address of the 29th National Championship Main Event is
<br><br>
https://www.cross-tables.com/tourney.php?t=10353&div=1
<br><br>
which has a tournament ID of 10353.
<h5>Lexicon</h5>
An optional parameter used to search for only games of a specific lexicon.
<h5>Game ID</h5>
An optional parameter used to search for only one game. To find a game\'s ID,
go to that game\'s page on cross-tables.com and look for the number in the address bar.
For example, the following game:
<br><br>
https://www.cross-tables.com/annotated.php?u=31231#0#
<br><br>
has a game ID of 31231.
<h5>Opponent Name</h5>
An optional parameter used to search for only games against a specific opponent.
<h5>Start Date</h5>
An optional parameter used to search for only games beyond a certain date.
<h5>End Date</h5>
An optional parameter used to search for only games before a certain date.
      '
    ],
    [
      'Statistics, Lists, and Notable Games',
      \@statcomments
    ],
    [
      'Errors and Warnings',
'
Errors are (most likely) the result of malformed GCG files.
Common errors are described below:

<h5>No moves found</h5>
This error appears when an empty GCG file is detected.
<h5>Disconnected play detected</h5>
This error appears when a play is made that does not connect to other tiles on the board.
<h5>Both players have the same name</h5>
This error appears when both players have the exact same name. In this case the program cannot distinguish who is making which plays.
<h5>No valid lexicon found</h5>
This error appears when the game is not tagged with a lexicon or the game uses an unrecognized lexicon, such as THTWL85.
<h5>Game is incomplete</h5>
This error appears when the GCG file is incomplete.
<br><br>
The errors above are relatively common and well-tested.
If you encounter any of these errors, it probably means
that the GCG file of the game is somehow malformed or tagged incorrectly.
To correct these errors, update the game on cross-tables.com and
the corrected version should appear in your stats the next day.
<br><br>
Any other errors that appear are rare and likely due to a bug.
If you see an error or warning that was not described above,
please email them to joshuacastellano7@gmail.com.
<br><br><br><br>
Warnings are for letting players know that they
might want to correct certain GCG files. The complete
list of warnings is below:

<h5>Duplicate game detected</h5>
This appears when two games with the same tournament
and round number are detected. The duplicate game is
not included in statistics or leaderboards. It probably
means that both you and your opponent uploaded the same
game. In this case the racks that you recorded might
have been overwritten when you opponent uploaded their game.

<h5>Note before moves detected</h5>
Notes that appear before moves are not associated with
either player, so mistakes tagged in these notes will
not be recorded.
<br><br><br><br>
To correct any errors or warnings, simply update the game with the corrected GCG file on cross-tables.com. Your new game will be retrieved by RandomRacer in the daily midnight updates.
'
    ],
    [
      'Challenge Heuristics',
'The Challenge statistics may not be completely accurate for games using a double challenge rule (TWL or NSW games) as passes and lost challenges in a double challenge game are indistinguishable in the GCG file. If the following criteria are met, the play is considered a lost challenge:
<br><br>
<ul>
<li>The play is a pass</li>
<li>The previous play formed at least one word</li>
<li>The game is played with a TWL or NSW lexicon</li>
<li>The game has less than 20 turns</li>
</ul>
<br>
If you think you can improve these heuristics, please contact joshuacastellano7@gmail.com.'
    ],
    [
      'Mistakes',
'There are two kinds of mistakes: standard mistakes (simply called \'mistakes\' on the stats pages and leaderboards) and dynamic mistakes.
<br>
<h5>Standard Mistakes</h5>
The Standard mistakes statistic is a self-reported statistic that is divided into 7 categories (knowledge, finding, vision, tactics, strategy, time, and endgame). To mark a move as a standard mistake in your annotated game, include the tag of the standard mistake in the comment of the move. You can also tag the magnitude (large, medium, or small) of the standard mistake which will organize your standard mistakes by magnitude in the standard mistakes table. For example, if you missed a bingo because you haven\'t studied it yet, that would probably be a large mistake due to word knowledge (called \'knowledge\' in this case) which you can tag by adding the following in your comment of the move:
<br><br>
#knowledgelarge
<br><br>
The large, medium, and small magnitudes can also be denoted by \'saddest\', \'sadder\', and \'sad\' respecitvely. For example, to tag a standard mistake as a large time mistake, you can write:
<br><br>
#timeSADDEST
<br><br>
If you do not want to specify the magnitude of the standard mistake you can omit the magnitude part of the tag:
<br><br>
#knowledge
<br><br>
If you tag the standard mistake like this the mistake will appear under the \'Unspecified\' category in the mistakes table. Standard mistakes are case insensitive, so the following standard mistake tags would be equivalent:
<br><br>
#findingSMALL<br>
#FiNdINGsmAlL
<br><br>
<h5>Dynamic Mistakes</h5>
The dynamic mistakes statistic is a self-reported statistic for which the player can create their own categories. To mark a move as a dynamic mistake use two hashtags instead of just one, for example:
<br><br>
##thisisaveryverbosedynamicmistakecategory
<br><br>
Dynamic mistakes can be any alphanumeric string that the player places after \'##\'. Dynamic mistakes cannot contain anything other than numbers or letters.
<br><br>
There are some key differences between dynamic mistakes and standard mistakes. Dynamic mistakes do not have magnitudes, so if you tagged a move with these dynamic mistakes:
<br><br>
##findingparallelsmall<br>
##findingparallellarge
<br><br>
They would count as completely distinct categories and would not be grouped together in any way.
<br><br>
Unlike mistakes, dynamic mistakes are case sensitive, so if you tagged a move with these dynamic mistakes:
<br><br>
##Yikes<br>
##yikes
<br><br>
They would count as separate dynamic mistake categories.
<br><br>
Dynamic mistake tags that are identical to standard mistake tags are completely valid, but are only counted as dynamic mistakes, not standard mistakes. For example, the following tags are dynamic mistakes:
<br><br>
##finding<br>
##strategylarge<br>
##timeSaddest
<br><br>
While confusing, you are completely free to make these dynamic tags, which will not appear in the standard mistakes section.
<br><br>
<h5>Notes on Both Standard and Dynamic Mistakes</h5>
The tags for all mistakes can appear anywhere in any order in the comment. Keep in mind that all mistakes are associated with moves, and moves are associated with players, so be sure to tag your mistakes on your moves only. For example, if you don\'t challenge a phony play, you can write the commentary on your opponent\'s move, but include the tags on your succeeding move to make sure they appear as your mistakes and not your opponents\'.
You can also mark a move with more than one mistake:
<br><br>
#findingmedium blah blah blah #tacticslarge ##dynamicsomething ##moredynamic
<br><br>
Mistakes and dynamic mistakes are completely distinct categories. Standard mistakes are never counted as dynamic mistakes and dynamic mistakes are never counted as standard mistakes. If you see this happen on RandomRacer, please contact joshuacastellano7#gmail.com.
'
    ],
    [
      'Win Correlation Graphs',
'For each statistic on the leaderboard there is an associated scatter plot of the win correlation for that statistic.
The statistic is plotted on the X axis and the win percentage is plotted on the Y axis. Each dot represents a player. You can hover over the dot to see which player it is. The \'r\' in the legend is the coefficient of correlation. An r value of 1 means that the statistic and win percentage are directly correlated. An r value of -1 means that the statistic and win percentage are inversely correlated. An r value of 0 means that there is no correlation. The slope is the rate of change of win percentage proportional to the statistic. So if the graph has a slope of m, an increase of x in the statistic is proportional to an increase of m*x in win percentage.'
    ],
    [
      'Confidence Intervals',
'
Confidence intervals are a bounded estimation of the probability that a player will play a particular tile. The p and CI on the confidence interval tables are the observed probability and the confidence interval, respecitvely. All confidence intervals are calculated with a 99% confidence level. If a player\'s observed probability of drawing a given tile exceeds the upper bound of the confidence interval, their row is highlighted red. If a player\'s observed probability of drawing a given tile is below the lower bound of the confidence interval, their row is highlighted green. Observed probabilities are calculated by dividing the average number of tiles played per game by the tile frequency. The equations used to calculate the confidence intervals for a tile \(t\) are as follows:
<br><br>
<div style="text-align: center">
First establish a confidence level, given by \( c \). This is always 99%.
\[c = 0.99\]
Using the confidence level, calculate a normally distributed \(z\)-score where \(a\) is the error, \(K\) is the percentile, and CDF() is the cumulative distribution function of the normal distribution:
\[a = 1 - c\]
\[K = 1 - {a \over 2} \]
\[z = \mathrm{CDF}(K) \]
Let \(P\) be the percentage of all tiles played by the player. For example, if the player averages playing 49 tiles a game, \(P\) would take a value of \(0.49\), since there are 100 tiles in the bag. Let \(n\) be the maximum possible number of tile \(t\) which the player could have played in all of their games. For example, if the player played 100 games and there are \(f\) tiles  of type \(t\) in the bag, \(n\) would take a value of \(100 * f \). Now we can calculate the upper and lower bounds of the confidence interval, where \(l\) is the lower bound and \(u\) is the upper bound:
\[I = z * \sqrt{P * ( 1 - P ) \over n} \]
\[l = P - I \]
\[u = P + I \]
As mentioned above, the observed probability, which we will denote as \(p\), is simply the average number of times that the player plays tile \(t\) per game, divided by how many tiles \(t\) are in the bag. If the observed probability \(p\) is less than \(l\), it is considered below the confidence interval and the row will be highlighted green. If the observed probability \(p\) is greater than \(u\), it is considered above the confidence interval and the row will be highlighted green. If the distribution of tiles played is completely random, as our observations of the random variable \(p\) increases, we should expect to see \(p\) fall within the confidence interval for 99% of those observations. Keep in mind that the leaderboards only give a single observation of \(p\) for a given tile and player.
</div>
<br><br>
Please note that probabilities that fall outside the confidence interval are in no way suspect. The sample of games analyzed by RandomRacer is subject to a heavy selection bias. Sometimes people tend to only post their good or their bad games. This can cause more probabilities than expected to fall outside the confidence interval. Also, with 26 tiles and about 200 players on the leaderboard and a 99% confidence interval, we can reasonably expect that about 26 * 200 * .01 = 52 probabilities will fall outside the given confidence interval. This is exactly in line with the approximately 50 probabilities that have done so in reality.'
    ],
    [
      'Leaderboards',
      'Leaderboards are updated every midnight (EST). Only players with 50 or more games are included in the leaderboards. More information about the statistics on the leaderboards can be found under \'Statistics, Lists, and Notable Games\'.'
    ],

    [
      'Omitted Games',
'You might notice that there are some annotated games that are
not included in your statistics or in the leaderboards. Games
are omitted if they meet any of the following criteria:
<br><br>
<ul>
<li>The game does not appear on your annotated games page on cross-tables.com</li>
<li>The game gives an error</li>
<li>The game does not have any associated lexicon</li>
</ul>

Games with no lexicons are omitted because the lexicons are necessary for
computing several statistics and the resulting inaccuracies could be
misleading and introduce error (or more error anyway) into the leaderboards.

Contact joshuacastellano7@gmail.com if you think a game was omitted by mistake.'
    ],
    [
      'Development Team',
      'RandomRacer is maintained by Joshua Castellano, but many people have suggested new features. Contributors
      are listed in the Contributions section.'
    ],
    [
      'Contributions',
'The following lists the intellectual contributions made to RandomRacer in reverse chronological (roughly) order.
<br><br>
<ul>
<li>Tiles Played Confidence Intervals (James Curley)</li>
<li>Win Correlations (James Curley)</li>
<li>Dynamic Mistakes (Kenji Matsumoto)</li>
<li>Vertical Play statistics (Matthew O\'Connor)</li>
<li>Mistakeless Turns statistic (César Del Solar)</li>
<li>Saddest/Sadder/Sad mistake magnitudes aliases (Jackson Smylie)</li>
<li>Highest Scoring Play statistic (Will Anderson)</li>
<li>Discovery of a bug in the Full Rack per Turn statistic (Will Anderson)</li>
<li>Notable games (Matthew O\'Connor)</li>
<li>Firsts statistic (Ben Schoenbrun)</li>
<li>Turns with a blank statistic (Marlon Hill)</li>
<li>Discovery of GCG mining bug in the preload script (Ben Schoenbrun)</li>
<li>Bingo lists, bingo probabilities, and various statistics (Joshua Sokol)</li>
<li>Initial idea (Matthew O\'Connor)</li>
</ul>'
    ]
  );

  my $abouthtml = '';
  my $readme    = '';

  my @styles = (Constants::DIV_STYLE_ODD, Constants::DIV_STYLE_EVEN);
  my $scount = 0;
  for (my $i = 0; $i < scalar @about; $i++)
  {
    my $item = $about[$i];
    my $title = $item->[0];
    my $content = $item->[1];
    my $style = $styles[$scount];
    my $id = $title;
    $id =~ s/\?/blank/g;
    $id =~ s/\W//g;
    $id .= '_about';

    $readme .= "\n\n# $title\n\n";
    my $htmlcontent   = $content;
    my $readmecontent = $content;
    if (ref($content) eq 'ARRAY')
    {
      $htmlcontent   = '';
      $readmecontent = '';
      for (my $k = 0; $k < scalar @{$content}; $k++)
      {
        my $subitem = $content->[$k];
        my $subtitle = $subitem->[0];
        my $subcontent = $subitem->[1];
        my $nospacesubtitle = $subtitle;
        $nospacesubtitle =~ s/\s//g;
        $nospacesubtitle =~ s/\?/blank/g;
        my $subid = $id . '_' . $nospacesubtitle;
        my $subexpander = Utils::make_expander($subid);
	$subexpander =~ s/\n//g;
	$subtitle    =~ s/\n//g;
        $readmecontent .= "<h3>$subtitle</h3>\n\n$subcontent";
        $htmlcontent .=
        "<div style='text-align: left'>$subexpander $subtitle<div class='collapse' id='$subid'><div style='padding: 20px'>$subcontent</div></div></div>";
      }
    }
    else
    {
      $htmlcontent = "<div style='padding: 20px'>$htmlcontent</div>";
    }
    $readmecontent =~ s/^\s+|\s+$//g;
    chomp($readmecontent);
    
    $readmecontent =~ s/(<ul>)|(<\/ul>)|(<\/li>)//g; 
    $readmecontent =~ s/<li>/ - /g;
    $readmecontent =~ s/<br>//g; 
    $readmecontent =~ s/(<h.>)/\n\n$1/g;
    $htmlcontent   =~ s/(<h.>)/<br><br>\n$1/g;

    $readme .= $readmecontent;
    my $expander = Utils::make_expander($id);
    $abouthtml .=
    "
    <div $style>
    $expander $title
      <div class='collapse' id='$id'>
         $htmlcontent
      </div>
    </div>
    ";
    $scount = 1 - $scount;
  }

  open(my $readmefh, '>', 'README.md');
  print $readmefh $readme;
  close $readmefh;

  my $head_content                    = Constants::HTML_HEAD_CONTENT;
  my $html_styles                     = Constants::HTML_STYLES;
  my $body_style                      = Constants::HTML_BODY_STYLE;
  my $nav                             = Constants::HTML_NAV;
  my $collapse_scripts                = Constants::HTML_TABLE_AND_COLLAPSE_SCRIPTS;
  my $default_scripts                 = Constants::HTML_SCRIPTS;
  my $footer                          = Constants::HTML_FOOTER;
  $abouthtml =
  "
<!DOCTYPE html>
<html lang=\"en\">
  <head>
  $head_content
  $html_styles
  <script src=\"https://polyfill.io/v3/polyfill.min.js?features=es6\"></script>
  <script id=\"MathJax-script\" async src=\"https://cdn.jsdelivr.net/npm/mathjax\@3/es5/tex-mml-chtml.js\"></script>
  </head>
  <body $body_style>
  $nav
  <div style='text-align: center; vertical-align: middle; padding: 2%'>
    <h1>
      About RandomRacer
    </h1>
  </div>
  $abouthtml
  $default_scripts
  $collapse_scripts
  $footer
  </body>
</html>
  "
;
  open(my $aboutfh, '>', Constants::HTML_DIRECTORY_NAME . '/' . Constants::ABOUT_PAGE_NAME);
  print $aboutfh $abouthtml;
  close $aboutfh;
}

1;

