#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

use lib "./modules";
use Utils;

my $target;
my $dryrun;

GetOptions
(
  'target=s' => \$target,
  'dryrun'   => \$dryrun
);

if (!$target)
{
  die "Must specify target directory with -t option!\n";
}

if ($dryrun)
{
  print "This is a dry run. Commands will only be printed, not executed\n";
}

print "Press Enter to Continue ";
<>;

print "\n\n";

my $database = Constants::DATABASE_NAME;
my $dev_database = Utils::get_environment_name($database);

if ($dev_database eq $database)
{
  die "Only deploy from the development environment!\n";
}

my $dbh = Utils::connect_to_database;

execute_db_command("DROP DATABASE IF EXISTS $database");
execute_db_command("CREATE DATABASE $database WITH TEMPLATE $dev_database");
execute_command("rm -rf $target/data && cp -r data $target");
execute_command("rm -rf $target/cache");
execute_command("git -C $target pull origin master");

sub execute_command
{
  my $cmd = shift;
  print "$cmd\n";
  if (!$dryrun)
  {
    system $cmd;
  }
}

sub execute_db_command
{
  my $cmd = shift;
  print "database: $cmd\n";
  if (!$dryrun)
  {
    $dbh->do($cmd);
  }
}



