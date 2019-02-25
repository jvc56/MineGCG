#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
use lib './objects';
use Constants;
use Pod::Usage qw(pod2usage);

my $regex;
my $help = 0;

GetOptions (
            'regex=s' => \$regex,
            'help|?'  => \$help
           );

pod2usage(1) if $help || !$regex;

my $games_dir = Constants::GAME_DIRECTORY_NAME;
my $names_dir = Constants::NAMES_DIRECTORY_NAME;

my $num_games_deleted = 0;
my $num_indexes_deleted = 0;


opendir my $names, $names_dir or die "Cannot open directory: $!";
my @name_files = readdir $names;
closedir $names;

foreach my $name_file (@name_files)
{
  if ($name_file eq '.' || $name_file eq "..")
  {
    next;
  }

  my $full_name = "$names_dir/$name_file";
  open(INDEXES, '<', $full_name);

  my $new_name_file_string = "";

  my $at_least_one_removed = 0;

  while (<INDEXES>)
  {
    if (!($_ =~ /$regex/))
    {
      $new_name_file_string .= $_;
    }
    else
    {
      $at_least_one_removed = 1;
      $num_indexes_deleted++;
    }
  }
  if ($at_least_one_removed)
  {
    system "rm $full_name";
    open(my $fh, '>', $full_name);
    print $fh $new_name_file_string;
    close $fh;
  }
}

opendir my $games, $games_dir or die "Cannot open directory: $!";
my @game_files = readdir $games;
closedir $games;

foreach my $game_file (@game_files)
{
  if ($game_file eq '.' || $game_file eq "..")
  {
    next;
  }
  if ($game_file =~ /$regex/)
  {
    system "rm $games_dir/$game_file";
    $num_games_deleted++;
  }
}

print "Games deleted:   $num_games_deleted\n";
print "Indexes deleted: $num_indexes_deleted\n";

__END__
 
=head1 SYNOPSIS
 
 Options:
   -h, --help   brief help message
   -r, --regex  any index or game matching this regex will be deleted

=cut