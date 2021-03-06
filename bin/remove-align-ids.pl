#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use lib $FindBin::Bin.'/../lib';
use Align;
use Tiger;
use Getopt::Std;
use vars qw /$opt_l $opt_a $opt_s $opt_t $opt_A $opt_S $opt_T/;

getopt('lastAST');

my $atemp; my $astem; my $stemp; my $tstem;
my %toskip=();

my $strees=new Tiger(-filehandle=>"SIN",-file=>$opt_s);
my $ttrees=new Tiger(-filehandle=>"TIN",-file=>$opt_t);
my $align=new Align(-filehandle=>"AIN",-file=>$opt_a);

## open files
(my $afile, my $acompressed)=$align->openFile();
(my $sfile, my $scompressed)=$strees->openFile();
(my $tfile, my $tcompressed)=$ttrees->openFile();
open (LIN, "<$opt_l") || die ("Could not open list with sentence IDs ($opt_l)!");

## get info
(my $shead, my $sbody, my $stail)=$strees->getHeadBodyTail($sfile);
(my $thead, my $tbody, my $ttail)=$ttrees->getHeadBodyTail($tfile);
(my $ahead, my $abody, my $atail)=$align->getHeadBodyTail($afile,$opt_S,$opt_T); ## we'll use the names of the output tree files to change the head of the output file so that it refers to the correct files
my $ssents=$strees->getSents($sfile,$sbody);
my $tsents=$ttrees->getSents($tfile,$tbody);
my $asents=$align->getSents($afile,$abody);

getSkipSents();

my $newshead=$strees->makeHead($shead,$ssents);
my $newthead=$ttrees->makeHead($thead,$tsents);

$align->writeAlignOrder($asents,\%toskip,"AOUT",$opt_A,$ahead,$atail);
$strees->writeTreeOrder($ssents,\%toskip,"SOUT",$opt_S,$newshead,$stail);
$ttrees->writeTreeOrder($tsents,\%toskip,"TOUT",$opt_T,$newthead,$ttail);

print "New files written.\n";
print "Looking for duplicates in original Tiger-XML files...\n";

$strees->findTigerDuplicates("SOUT",$opt_s,'s');
$ttrees->findTigerDuplicates("TOUT",$opt_s,'t');

$align->closeFile($acompressed,"AIN",$afile);
$strees->closeFile($scompressed,"SIN",$sfile);
$ttrees->closeFile($tcompressed,"TIN",$tfile);

sub getSkipSents {
  while (my $in=<LIN>) {
    if ($in =~ /([0-9]+)/) { ## assuming one number per line
      $toskip{$1}=1;
    }
  }
}

close (LIN);

__END__

=head1 NAME

remove-align-ids.pl - writes to output a subset of an tree alignment set (one alignment file and two treebank files) containing sentences with IDs NOT specified in a given text file (in other words, we want to exclude these IDs)

=head1 SYNOPSIS

perl remove-align-ids.pl -l remove.txt -a alignment_file -s source_treebank_file -t target_treebank_file -A output_alignment_file -S output_source_treebank_file -T output_target_treebank_file

=head1 OPTIONS

=over

=item * -l text file containing IDs of sentence pairs to be removed. For now, we assume that they are the same for source and target sides. However, sentence pairs do not need to be in counting order, we only look for matches.

=item * -a input alignment file in Stockholm TreeAligner format

=item * -s source treebank file in Tiger-XML format

=item * -t source treebank file in Tiger-XML format

=item * -A output alignment file

=item * -S output source treebank file

=item * -T output target treebank file

=back

=head1 DESCRIPTION

This script takes as input an XML alignment file in Stockholm TreeAligner format, extracts the head and all sentences NOT specified in a provided text file (one ID per line) and writes each sentence to a specified output file in counting order. It also takes as input the corresponding treebank files (source and target, in Tiger-XML format) and does the same.

This means that some sentence IDs will CHANGE for some sentences - beware!

This can be useful if the user would like to exclude some sentence pairs if they are, for example, not suitable for use in the creating of a gold standard or for training a tree aligner.

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>gidi8ster@gmail.comE<gt>
