#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use lib $FindBin::Bin.'/../lib';
use Align;
use Tiger;
use Getopt::Std;

use vars qw/$opt_a $opt_s $opt_t $opt_A $opt_S $opt_T $opt_b $opt_n $opt_c/;
getopt('astASTbn');
getopts('c');

my $sentnr=$opt_b || die("Beginning sentence pair ID (-b) not specified!");
my $nr_of=$opt_n || die("Number of sentences (-n) not specified!");
my $alignfile=$opt_a || die ("No alignment file specified!");
my $ahead, my $abody, my $atail; my $ord_n_asents;

my $align=new Align(-filehandle=>"AIN",-file=>$alignfile);
(my $afile, my $acompressed)=$align->openFile();

($ahead, $abody, $atail)=$align->getHeadBodyTail($afile,$opt_S,$opt_T); ## we'll use the names of the output tree files to change the head of the output file so that it refers to the correct files

my $asents=$align->getSents($afile,$abody);
my $n_asents=$align->get_n_sents($asents,$opt_b,$opt_n);
if ($opt_c) {
  $ord_n_asents=$align->getCountingOrder($n_asents);
  $align->writeOrderedSet($ahead,$ord_n_asents,$atail,"AOUT",$opt_A);
}
else {
  $align->writeOrderedSet($ahead,$n_asents,$atail,"AOUT",$opt_A);
}

# print "afile: $afile\n";
# 
# print "size of asents: ";
# my $size=keys(%{$asents});
# print "$size\n";
# 
# print "size of n_asents: ";
# my $size=keys(%{$n_asents});
# print "$size\n";
# 
# print "size of ord_n_asents: ";
# my $size=keys(%{$ord_n_asents});
# print "$size\n";

## test
#  my $size=keys(%{$ord_n_asents});
#  for (my $i=1; $i<=50; $i++) {
#    foreach (@{$$n_asents{$i}}) {
#      print "$i\t$_";
#    }
#  }
$align->closeFile($acompressed,$afile);

if (defined $opt_s) {
  my $strees=new Tiger(-filehandle=>"SIN",-file=>$opt_s);
  (my $sfile, my $scompressed)=$strees->openFile();
  (my $shead, my $sbody, my $stail)=$strees->getHeadBodyTail($sfile);
  my $ssents=$strees->getSents($sfile,$sbody);
  my $n_ssents=$strees->get_n_sents($ssents,$opt_b,$opt_n);
  my $newhead=$strees->makeHead($shead,$n_ssents);
  $strees->writeOrderedSet($newhead,$n_ssents,$stail,"SOUT",$opt_S);
  $strees->closeFile($scompressed,"SIN",$sfile);
}

if (defined $opt_t) {
  my $ttrees=new Tiger(-filehandle=>"TIN",-file=>$opt_t);
  (my $tfile, my $tcompressed)=$ttrees->openFile();
  (my $thead, my $tbody, my $ttail)=$ttrees->getHeadBodyTail($tfile);
  my $tsents=$ttrees->getSents($tfile,$tbody);
  my $n_tsents=$ttrees->get_n_sents($tsents,$opt_b,$opt_n);
  my $newhead=$ttrees->makeHead($thead,$n_tsents);
  $ttrees->writeOrderedSet($newhead,$n_tsents,$ttail,"TOUT",$opt_T);
  $ttrees->closeFile($tcompressed,"TIN",$tfile);
}

__END__

=head1 NAME

get-n-align.pl

=head1 SYNOPSIS
perl get-n-align -a alignment_file [ -s source_treebank_file ] [ -t target_treebank_file ] -A output_alignment_file [ -S output_source_treebank_file ] [ -T output_target_treebank_file ] -b begin_ID -e nr_of_sents

head1 OPTIONS

=over

=item * -a alignment file: Stockholm TreeAligner XML file

=item * -s source treebank file

=item * -t target treebank file

=item * -A output alignment file (same format)

=item * -S output source treebank file

=item * -T output target treebank file

=item * -b beginning sentence ID (inclusive)

=item * -n number of sentences to be returned

=item * -c sentences are returned in counting order starting at 1 and not skipping numbers. If omitted, sentences are still returned in counting order but with all original IDs retained.

=back

=head1 DESCRIPTION

This script takes as input an alignment file set, consisting of a parallel treebank in Tiger-XML (two files) and a file in Stockholm TreeAligner (Lingua-Align) XML, and returns the specified number of sentences (-n), starting at the sentence ID specified by -b. The names of the files in the head of the output STA-XML file are replaced by the names of the new treebank output files.

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>g.j.kotze@rug.nlE<gt>

=cut
