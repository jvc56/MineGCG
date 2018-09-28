#!/usr/bin/perl

use warnings;
use strict;

my $r1 = "<tr class='row1' id='row9'><td><a href='annotated.php?u=8267'>View</a></td><td class='nowrap'><a href='results.php?p=796'>Evan Berofsky</a></td><td><a href='tourney.php?t=7165'>Cambridge, ON</a></td><td>2011-03-26</td><td>4</td><td></td><td>TWL06</td></tr>";
my $r2 = "<tr class='row0' id='row10'><td><a href='annotated.php?u=27350'>View</a></td><td class='nowrap'><a href='results.php?p=11232'>Joshua Sokol</a></td><td><a href='tourney.php?t=-2'></a></td><td></td><td>---</td><td></td><td>TWL15</td></tr>";

my @a = ($r1, $r2);
for (my $i = 0; $i < 2; $i++)
{
    my $r = $a[$i];
	if ($r =~ /href=.annotated.php.u=(\d+).>.*?href=.tourney.php.t=(.+?).>([^<]*)<.a><.td><td>([^<]*)<.td><td>([^<]*)<.td><td><.td><td>([^<]*)</g)
	{
	print "$i\n";
	}
}

