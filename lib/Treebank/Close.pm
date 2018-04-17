package Treebank::Close;
use Exporter;
@ISA = ('Exporter');

my $stem="";
my $compressed="";
my $file="";

sub closeFile {
if ($_[1] =~ /.*\/(.*?)\.gz$/) {
  $stem=$1;
  $compressed=1;
}
elsif ($_[1] =~ /(.*)\.gz$/) {
  $stem=$1;
  $compressed=1;
}

if (-e "$stem.tmp") {
  qx(rm -f $stem.tmp);
}

if ($compressed == 1) {
  $file=$stem.".tmp";
}
else {
  $file=$_[1];
}

close ($_[2]);

}

1;