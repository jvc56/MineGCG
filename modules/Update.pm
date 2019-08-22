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

  my $total_players = 0;

  foreach my $player_item (@player_data)
  {
    my $total_games  = $player_item->{Constants::PLAYER_TOTAL_GAMES_COLUMN_NAME};
    if (!$total_games || $total_games < $min_games)
    {
      next;
    }
    $total_players++;
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
          my $is_single    = $statitem->{'single'};
          my $is_int       = $statitem->{'int'};

          add_stat(\%leaderboards, $name, $statname, $statval, $total_games, $is_single, $is_int,\@name_order);

          my $subitems = $statitem->{'subitems'};
          if ($subitems)
          {
            my $order = $statitem->{'list'};
            for (my $i = 0; $i < scalar @{$order}; $i++)
            {
              my $subitemname = $order->[$i];

              my $substatname = "$statname $subitemname";

              my $substatval  = $subitems->{$subitemname};

              add_stat(\%leaderboards, $name, $substatname, $substatval, $total_games, $is_single, $is_int,  \@name_order);
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

    my $sum = 0;

    for (my $j = 0; $j < $total_players; $j++)
    {
      $sum += $array[$j][0];
    }

    $sum = sprintf "%.4f", $sum / $total_players;

    $table_of_contents .= "<a href='#$name'>$name</a>\n";

    $leaderboard_string .= "<h2><a id='$name'></a>AVERAGE $name: $sum</h2>";

    for (my $j = 0; $j < 2; $j++)
    {
      my @ranked_array;
      my $title;
      if ($j == 0)
      {
        @ranked_array = sort { $b->[0] <=> $a->[0] } @array;
        $title = "<h3>MOST $name</h3>";
      }
      else
      {
        @ranked_array = sort { $a->[0] <=> $b->[0] } @array;
        $title = "\n\n<h3>LEAST $name</h3>";
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

      for (my $k = 0; $k < $total_players; $k++)
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

  my $leaderboard_name = "./logs/" . Constants::LEADERBOARD_NAME . ".log";
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

  my $notable_name = "./logs/" . Constants::NOTABLE_NAME . ".log";
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

  my $target = $vm_username . "\\@" . $vm_ip_address;

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
  
  my \$name = \$query->param('name');
  my \$cort = \$query->param('cort');
  my \$tid  = \$query->param('tid');
  my \$gid  = \$query->param('gid');
  my \$opp  = \$query->param('opp');
  my \$start = \$query->param('start');
  my \$end  = \$query->param('end');
  my \$lexicon  = \$query->param('lexicon');
  
  my \$name_arg = '--name "' . sanitize_name(\$name) . '"';
  my \$cort_arg = "";
  my \$tid_arg = "";
  my \$gid_arg = "";
  my \$opp_arg = "";
  my \$start_arg = "";
  my \$end_arg = "";
  my \$lexicon_arg = "";
  
  if (\$cort)
  {
    \$cort_arg = "--cort ". sanitize_name(\$cort);
  }
  
  if (\$tid)
  {
    \$tid_arg = "--tid " . sanitize_number(\$tid);
  }
  
  if (\$gid)
  {
    \$gid_arg = "--game ". sanitize_number(\$gid);
  }
  
  if (\$opp)
  {
    \$opp_arg = "--opponent " . sanitize_name(\$opp);
  }
  
  if (\$start)
  {
    \$start_arg = "--startdate " . sanitize_number(\$start);
  }
  
  if (\$end)
  {
    \$end_arg = "--enddate " . sanitize_number(\$end);
  }
  
  if (\$lexicon)
  {
    \$lexicon_arg = "--lexicon " . sanitize_name(\$lexicon);
  }
  
  my \$dir_arg = " --directory $dirname ";

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

  my $cgibin_name = Constants::CGIBIN_DIRECTORY_NAME;
  $cgibin_name = substr $cgibin_name, 2;
  $cgibin_name = Utils::get_environment_name($cgibin_name);

  my $index_html = <<HTML

<script>

function nocacheresult()
{

  // var debug = document.getElementById("debug");

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

</script>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8">
<title>RandomRacer</title>
<link rel="stylesheet" href="style.css" />
<link rel=icon href=/favicon.png>
<link rel="stylesheet" href="https://www.amcharts.com/lib/3/plugins/export/export.css" type="text/css" media="all" />
<link href="https://fonts.googleapis.com/css?family=Francois+One|Iceland|Monofett|Orbitron|Press+Start+2P|Source+Code+Pro|VT323" rel="stylesheet">
</head>
<body id="body">


<div class="typingdiv">
 <table class="typingdivtable">
  <tbody>
   <tr>
    <td class="webtitletd">
     <a href="/" class="webtitle">RandomRacer</a>
    </td>
    <td class="externallinks">
      <table>
  <tbody>
   <tr>

   <td class="alink">
      <a href="/leaderboard.html" title="Leaderboards">Leaderboards</a>
   </td>


   <td class="alink">
      <a href="/notable.html" title="That's Notable!">Notable Games</a>
   </td>

        <td class="alink"  >
      <a href="http://cross-tables.com/results.php?playerid=20411" title="Get to know me">About Me</a>
   </td>
  </tr>
  </tbody>
    </table>
    </td>
   </tr>
  </tbody>
 </table>
</div>
<div id="container" class="container">
<div class="minegcgform">
<form action="$cgibin_name/mine_webapp.pl" target="_blank" method="get" onsubmit="return nocacheresult()">

  <table class="minegcgforminput">
  <tbody>

  <tr>
    <td>Player Name (required):</td>
    <td><input type="text" name="name" class="minegcgforminput" required></td>
  </tr>

  <tr>
   <td>Game Type (optional):</td>
   <td>


      <select name="cort" class="minegcgforminput">
      <option value=""></option>
      <option value="t">Tournament</option>
      <option value="c">Casual</option>
      </select>

   </td>
  </tr>

  <tr>
          <td>Tournament ID (optional):</td>
          <td><input type="number" name="tid" class="minegcgforminput"></td>
  </tr>

  <tr>
    <td>Lexicon (optional):</td>
    <td>
      <select name="lexicon" class="minegcgforminput">
      <option value=""></option>
      <option value="CSW19">CSW19</option>
      <option value="CSW15">CSW15</option>
      <option value="CSW15">NSW18</option>
      <option value="TWL15">TWL15</option>
      <option value="CSW12">CSW12</option>
      <option value="TWL06">TWL06</option>
      <option value="CSW07">CSW07</option>
      <option value="TWL98">TWL98</option>
      </select>
    </td>
  </tr>
  <tr>
    <td>Game ID (optional):</td>
    <td><input type="number" name="gid" class="minegcgforminput"></td>
  </tr>


  <tr>
    <td>Opponent (optional):</td>
    <td><input type="text" name="opp" class="minegcgforminput"></td>
  </tr>


  <tr>
    <td>Start Date (optional YYYY-MM-DD):</td>
    <td><input type="text" name="start" class="minegcgforminput"></td>
  </tr>


  <tr>
    <td>End Date (optional YYYY-MM-DD):</td>
    <td><input type="text" name="end" class="minegcgforminput"></td>
  </tr>


  </tbody>
  </table>

  <div class="minegcgform"><input type="submit" value="Submit" class="minegcgforminput"></div>


</form>
</div>

</div>
</body>
</html>

HTML
;
  open(my $fh, '>', Constants::HTML_DIRECTORY_NAME . '/' . Constants::INDEX_HTML_FILENAME);
  print $fh $index_html;
  close $fh;
}

sub add_stat
{
  my $leaderboards = shift;
  my $playername   = shift;
  my $statname     = shift;
  my $statvalue    = shift;
  my $total_games  = shift;
  my $is_single    = shift;
  my $is_int       = shift;
  my $name_order   = shift;
  
  if (!$is_single)
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

