#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

my $lexicon = '';

GetOptions (
          'lexicon=s' => \$lexicon
         );

if (!$lexicon)
{
  print "Must specify a lexicon\n";
  exit(0);
}

my $file_loc = "$lexicon.txt";

my $mod_name = uc $lexicon;

open(LEX, '<', $file_loc) or die "Cannot open $file_loc: $!";
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
