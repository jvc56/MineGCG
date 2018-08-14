#!/usr/bin/perl

use warnings;
use strict;

sub retrieve($$)
{
  my $name = shift;
  my $dir = shift;

  my $results_page_name = "anno_page.html";

  # name -> url

  my $url = 'http://www.cross-tables.com/anno.php?p=20411';
  if (!(-e $dir and -d $dir))
  {
  	mkdir $dir;
  }
  system "wget $url -O ./$results_page_name";
  open(RESULTS, '<', $results_page_name);
  while (<RESULTS>)
  {

  }

}


1;
