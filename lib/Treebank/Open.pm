package Treebank::Open;
use Exporter;
@ISA = ('Exporter');
@EXPORT = qw($file $compressed);

my $compressed=0;
my $stem="";
my $file="";


sub openFile {
if ($_[1] =~ /.*\/(.*?)\.gz$/) {
  $stem=$1;
  $compressed=1;
}
elsif ($_[1] =~ /(.*)\.gz$/) {
  $stem=$1;
  $compressed=1;
}
else {
  $stem=$_[1];
}

if ($compressed == 1) {
  qx(gzip -cd $_[1] > $stem.tmp);
  $file=$stem.".tmp";
}
else {
  $file=$_[1];
}
open ($_[2], "<$file") || die ("Could not open treebank file ($file)!");

}

1;