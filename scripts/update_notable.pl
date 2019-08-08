#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use lib './objects';
use Constants;

sub update_notable
{
  my $notable_dir    = Constants::NOTABLE_DIRECTORY_NAME;
  my $url            = Constants::SINGLE_ANNOTATED_GAME_URL_PREFIX;
  my $stats_note     = Constants::STATS_NOTE;
  
  my $rr_host         = Constants::RR_HOSTNAME;
  my $rr_username     = Constants::RR_USERNAME;
  my $rr_notable_dest = Constants::RR_NOTABLE_DEST;
  my $ssh_args        = Constants::SSH_ARGS;
  
  my $dbh = connect_to_database();
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

    my @stat_keys = ('notable');
    
    foreach my $key (@stat_keys)
    {
      my $statitem = $player_stats->{$key}->{Constants::STAT_ITEM_OBJECT_NAME};
      my $statname = $player_stats->{$key}->{Constants::STAT_NAME};

      if (!$notable_hash{$statname})
      {
        push @ordering, $statname;
        $notable_hash{$statname} = "";
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

  open(my $new_notable, '>', $notable_name);
  print $new_notable $notable_string;
  close $new_notable;
}

1;

