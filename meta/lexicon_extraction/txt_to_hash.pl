#!/usr/bin/perl

use warnings;
use strict;

my $file_loc = './meta/lexicon_extraction/nsw18.txt';
my $mod_name = 'NSW18';

open(LEX, '<', $file_loc);
open(MOD, '>', 'lexicons/'.$mod_name.'.pm');

print MOD "#!/usr/bin/perl\n\n";
print MOD "package $mod_name;\n\n";
print MOD "use warnings;\n";
print MOD "use strict;\n\n";
print MOD "use constant ".$mod_name."_LEXICON =>\n";
print MOD "{\n";

while (<LEX>)
{
	chomp $_;
	/(\w+)\t(\d+)/;
    print MOD "'".$1 . "' => " . $2 . ",\n";
}
print MOD "};\n\n1;\n";
