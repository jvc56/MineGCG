#!/usr/bin/perl
 
  use warnings;
  use strict;
  use CGI;
  
  sub sanitize_name
  {
    my $string = shift;
  
    $string = substr( $string, 0, 256);
  
    # Remove trailing and leading whitespace
    $string =~ s/^\s+|\s+$//g;
  
    # Replace spaces with underscores
    $string =~ s/ /_/g;
  
    # Remove anything that is not an
    # underscore, dash, letter, or number
    $string =~ s/[^\w-]//g;
  
    # Capitalize
    $string = uc $string;
  
    return $string;
  }
  
  sub sanitize_number
  {
    my $string = shift;
  
    $string = substr( $string, 0, 256);
  
    # Remove trailing and leading whitespace
    $string =~ s/^\s+|\s+$//g;
  
    # Remove anything that is not a number
    $string =~ s/[^\d]//g;
  
    return $string;
  }
  
  my $query = new CGI;
  
  my $name = $query->param('name');
  my $cort = $query->param('cort');
  my $tid  = $query->param('tid');
  my $gid  = $query->param('gid');
  my $opp  = $query->param('opp');
  my $start = $query->param('start');
  my $end  = $query->param('end');
  my $lexicon  = $query->param('lexicon');
  
  my $name_arg = '--name "' . sanitize_name($name) . '"';
  my $cort_arg = "";
  my $tid_arg = "";
  my $gid_arg = "";
  my $opp_arg = "";
  my $start_arg = "";
  my $end_arg = "";
  my $lexicon_arg = "";
  
  if ($cort)
  {
    $cort_arg = "--cort ". sanitize_name($cort);
  }
  
  if ($tid)
  {
    $tid_arg = "--tid " . sanitize_number($tid);
  }
  
  if ($gid)
  {
    $gid_arg = "--game ". sanitize_number($gid);
  }
  
  if ($opp)
  {
    $opp_arg = "--opponent " . sanitize_name($opp);
  }
  
  if ($start)
  {
    $start_arg = "--startdate " . sanitize_number($start);
  }
  
  if ($end)
  {
    $end_arg = "--enddate " . sanitize_number($end);
  }
  
  if ($lexicon)
  {
    $lexicon_arg = "--lexicon " . sanitize_name($lexicon);
  }
  
  my $dir_arg = " --directory MineGCGDEV ";

  my $output = "";
  my $cmd = "LANG=C ssh  -i /home/ubuntu/vm.pem -p 2222  -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jvc\@ocs.wgvc.com /home/jvc/minegcg_wrapper.pl $name_arg $cort_arg $tid_arg $gid_arg $opp_arg $start_arg $end_arg $lexicon_arg $dir_arg |";
  open(SSH, $cmd) or die "$!
";
  while (<SSH>)
  {
    $output .= $_;
  }
  close SSH;
  print "Content-type: text/html

";
  #print $cmd;
  #print CGI::header();
  print $output;
  
  
