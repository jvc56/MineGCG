#!/usr/bin/perl

use warnings;
use strict;

my $dirname = "/home/jvc/Zyzzyva/words/saved/";

opendir my $dir, $dirname or die "Cannot open directory: $!";
my @files = readdir $dir;
closedir $dir;

my @unsorted_lines = ();

while(@files)
{
	my $filename = pop @files;
	my $fullname =  $dirname . $filename;
	open(TXT, '<', $fullname);
	while(<TXT>)
	{
		push @unsorted_lines, $_;
	}
	close $fullname;
}

my %word_line_hash = ();
my @unsorted_words = ();

while(@unsorted_lines)
{
	my $line = pop @unsorted_lines;
	$line =~ /[·\s](\w+)[·\s]/;
	#print $1 . "\n";
	push @unsorted_words, $1;
	$word_line_hash{$1} = $line;
}

my @sorted_words = sort {$b cmp $a} @unsorted_words;

open(AMERICAN, '>', '/home/jvc/Dropbox/american.txt');

while(@sorted_words)
{
	my $word = pop @sorted_words;
	print AMERICAN $word_line_hash{$word};
}
close AMERICAN;

