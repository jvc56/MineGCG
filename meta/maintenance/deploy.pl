#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

use lib "./modules";
use Utils;

my $target;

GetOptions
(
  'target' => \$target
);

if (!$target)
{
  die "Must specify target directory with -t option!\n";
}

my $database = Constants::DATABASE_NAME;
my $dev_database = Utils::get_environment_name($database);

if ($dev_database eq $database)
{
  die "Only deploy from the development environment!\n";
}

my $dbh = Utils::connect_to_database;

$dbh->do("DROP DATABASE IF EXISTS $database");
$dbh->do("CREATE DATABASE $database WITH TEMPLATE $dev_database");

system "rm -rf $target/cache";
system "rm -rf $target/data && cp -r data $target";

system "git -C $target pull origin master";







