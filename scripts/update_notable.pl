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
  
  opendir my $notables, $notable_dir or die "Cannot open directory: $!";
  my @notable_files = readdir $notables;
  closedir $notables;

  my %notable_hash;
  my %check_for_repeats_hash;
  my $notable_string = "";
  my $table_of_contents  = "<h1><a id='notable'></a>\"That's Notable!\"</h1>";
  my $init = 0;
  my @ordering = ();

  foreach my $notable_file (@notable_files)
  {
    if ($notable_file eq '.' || $notable_file eq '..')
    {
      next;
    }

    open(PLAYER_NOTABLES, '<', $notable_dir . "/" . $notable_file);
    while(<PLAYER_NOTABLES>)
    {
      $_ =~ /(.*):/;

      my $type = $1;

      $_ =~ s/(.*)://g;

      my @matches = ($_ =~ /([^,]+),/g);

      $notable_hash{$type} .= "</br>";

      foreach my $m (@matches)
      {
        $m =~ s/^\s+|\s+$//g;
        if ($check_for_repeats_hash{$type . $m})
        {
          next;
        }
        $check_for_repeats_hash{$type . $m} = 1;
        $m =~ /\(Game (\d+)\)/;
        my $id = $1;
        $notable_hash{$type} .= "<a href='$url$id' target='_blank'>$m</a></br>";
      }
      if (!$init)
      {
        push @ordering, $type;
      }
    }
    $init = 1;
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

  #system "rm -r $notable_dir";

  #system "scp -i /home/jvc/.ssh/randomracer.pem $notable_name jvc\@media.wgvc.com:/home/bitnami/htdocs/rracer/notable.html"
}

1;

