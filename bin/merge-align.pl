#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use lib $FindBin::Bin.'/../lib';
use Tiger;
use Align;
use Getopt::Std;
use vars qw/$opt_a $opt_b $opt_c $opt_d $opt_e $opt_f $opt_g $opt_h $opt_i/;
getopt('abcdefghi');

my $align1=new Align(-filehandle=>"AIN1",-file=>$opt_a);
my $align2=new Align(-filehandle=>"AIN2",-file=>$opt_b);
my $strees1=new Tiger(-filehandle=>"SIN1",-file=>$opt_d);
my $strees2=new Tiger(-filehandle=>"SIN2",-file=>$opt_e);
my $ttrees1=new Tiger(-filehandle=>"TIN1",-file=>$opt_g);
my $ttrees2=new Tiger(-filehandle=>"TIN2",-file=>$opt_h);

## open files
(my $afile1, my $acompressed1)=$align1->openFile();
(my $afile2, my $acompressed2)=$align2->openFile();
(my $sfile1, my $scompressed1)=$strees1->openFile();
(my $sfile2, my $scompressed2)=$strees2->openFile();
(my $tfile1, my $tcompressed1)=$ttrees1->openFile();
(my $tfile2, my $tcompressed2)=$ttrees2->openFile();

## get info
(my $ahead1, my $abody1, my $atail1)=$align1->getHeadBodyTail($afile1,$opt_f,$opt_i); ## we'll use the names of the output tree files to change the head of the output file so that it refers to the correct files
(my $ahead2, my $abody2, my $atail2)=$align2->getHeadBodyTail($afile2,$opt_f,$opt_i);
(my $shead1, my $sbody1, my $stail1)=$strees1->getHeadBodyTail($sfile1);
(my $shead2, my $sbody2, my $stail2)=$strees2->getHeadBodyTail($sfile2);
(my $thead1, my $tbody1, my $ttail1)=$ttrees1->getHeadBodyTail($tfile1);
(my $thead2, my $tbody2, my $ttail2)=$ttrees2->getHeadBodyTail($tfile2);

my $asents1=$align1->getSents($afile1,$abody1);
my $asents2=$align2->getSents($afile2,$abody2);
my $ssents1=$strees1->getSents($sfile1,$sbody1);
my $ssents2=$strees2->getSents($sfile2,$sbody2);
my $tsents1=$ttrees1->getSents($tfile1,$tbody1);
my $tsents2=$ttrees2->getSents($tfile2,$tbody2);

mergeAlign();
mergeTrees();

$align1->closeFile($acompressed1,$afile1);
$align2->closeFile($acompressed2,$afile2);
$strees1->closeFile($scompressed1,$sfile1);
$strees2->closeFile($scompressed2,$sfile2);
$ttrees1->closeFile($tcompressed1,$tfile1);
$ttrees2->closeFile($tcompressed2,$tfile2);

sub mergeAlign {

  my $mergesents=$align1->mergeSets($asents1,$asents2);
  my $orderedsents=$align1->getCountingOrder($mergesents);
  $align1->writeOrderedSet($ahead1,$orderedsents,$atail1,"AOUT",$opt_c); ## assuming that the head and tail of both sets are the same
}

sub mergeTrees {

  my $mergesents=$strees1->mergeSets($ssents1,$ssents2);
  my $orderedsents=$strees1->writeCountingOrder($mergesents);
  my $newhead=$strees1->makeHead($shead1,$orderedsents);
  $strees1->writeOrderedSet($newhead,$orderedsents,$stail1,"SOUT",$opt_f); ## assuming that the tails of both sets are the same

  $mergesents=$ttrees1->mergeSets($tsents1,$tsents2);
  $orderedsents=$ttrees1->writeCountingOrder($mergesents);
  $newhead=$ttrees1->makeHead($thead1,$orderedsents);
  $ttrees1->writeOrderedSet($newhead,$orderedsents,$ttail1,"TOUT",$opt_i); ## assuming that the tails of both sets are the same
}

__END__

=head1 NAME

merge-align.pl - merges a set of alignment files

=head1 SYNOPSIS

perl merge-align.pl -a first_alignment_file -b second_alignment_file -c output_alignment_file [ -d first_source_treebank_file ] [ -e second_source_treebank_file ] [ -f output_source_treebank_file ] [ -g first_target_treebank_file ] [ -h second_target_treebank_file ] [ -i output_target_treebank_file ]

=head1 OPTIONS

=over

=item * -a first alignment file: Stockholm TreeAligner XML file which is to be merged with the file specified by -b. In the output, the files in the head are replaced by the files specified by -f and -i (or default values).

=item * -b second alignment file: Stockholm TreeAligner XML file which is to be merged with the file specified by -a. In the output, the files in the head are replaced by the files specified by -f and -i (or if not specified, by default values).

=item * -c output alignment file: Stockholm TreeAligner XML file which is the result of the merging of the files specified by -a and -b. All sentence IDs are normalized to be in counting order (see description).

=item * -d first source treebank file: Tiger-XML file to which the file specified by -a refers. The head of this file will be written, along with its contents, to the file specified by -f (or if not specified, a file created by default). If the file is not specified, the name will be extracted from the head of the file specified by -a.

=item * -e second source treebank file: Tiger-XML file to which the file specified by -b refers. The head of this file is skipped and only the body is written to the file specified by -f (or if not specified, a file created by default). If the file is not specified, the name will be extracted from the head of the file specified by -b.

=item * -f output source treebank file: A Tiger-XML file containing the merged contents of the files specified by -d and -e (or the files extracted from the heads of -a and -b), but only those sentences that are actually referred to by the alignment files. All sentence IDs are normalized to be in counting order (see description). If the file is not specified, a default value is chosen as a name.

=item * -g first target treebank file: similar to -d, but for target treebanks.

=item * -h second target treebank file: similar to -e, but for target treebanks.

=item * -i output target treebank file: similar to -f, but for target treebanks.

=back

=head1 DESCRIPTION

This script takes as input an alignment file set, consisting of a parallel treebank in Tiger-XML (two files) and a file in Stockholm TreeAligner (Lingua-Align) XML, and merges it with another such set in the following way:

=over

=item * The two STA-XML files are merged to produce a single new STA-XML file.

=item * The two source side treebank files are merged to produce a single source side treebank file corresponding to the above new STA-XML file.

=item * The two target side treebank files are merged to produce a single target side treebank file corresponding to the above new STA-XML file.

=back

Furthermore, the following occurs:

=over

=item * The names of the files in the head of the output STA-XML file are replaced by the names of the new treebank output files.

=item * As a convention, the heads of the first source and first target treebank files will be taken as the heads of the combined output source and target treebank files (meaning that the heads of the second source and second target treebanks are skipped).

=item * For convenience and simplicity, the sentence IDs in all output files are normalized to be in counting order.

=back

Merging a set of alignment files can be useful, for example, while creating gold standards or training data sets.

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>gidi8ster@gmail.comE<gt>

=cut

