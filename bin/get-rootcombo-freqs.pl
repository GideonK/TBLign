#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Std;
use lib $FindBin::Bin.'/../lib';
#use lib '../lib'
use feature 'say';
use Treebank;
use STA;
use vars qw /$opt_s $opt_t $opt_a/;

getopt('sta');

unless (defined $opt_s) {
  die ("No source treebank file specified!");
}
unless (defined $opt_t) {
  die ("No target treebank file specified!");
}
unless (defined $opt_a) {
  die ("No alignment file specified!");
}

my $strees=new Treebank(-filehandle=>"SIN",-file=>$opt_s);
my $ttrees=new Treebank(-filehandle=>"TIN",-file=>$opt_t);
my $alignments=new STA(-filehandle=>"AIN",-file=>$opt_a);

$opt_s=$strees->getFile('s');
$opt_t=$ttrees->getFile('t');
$opt_a=$alignments->getFile();

(my $sids, my $spos, my $stype, my $scat)=$strees->getBasicStats($opt_s);
(my $tids, my $tpos, my $ttype, my $tcat)=$ttrees->getBasicStats($opt_t);
(my $linktype, my $prob, my $link, my $author)=$alignments->getStats($opt_a);

#my $size=keys(%$link);

getCombos();

sub getCombos {
  my %combocount=();
  my ($sid,$tid,$combo);
  foreach(%$link) {
    if (/(.*)__(.*)/) {
      $sid=$1;
      $tid=$2;
      if ((defined $$scat{$sid}) && (defined $$tcat{$tid})) {
        $combo=$$scat{$sid}."__".$$tcat{$tid};
        if (defined $combocount{$combo}) {
          $combocount{$combo}++;
        }
        else {
          $combocount{$combo}=0;
        }
      }
    }
  }

  foreach my $key (sort { $combocount{$a} <=> $combocount{$b}} keys %combocount) {
    say "$key: $combocount{$key}";
  }
}

$strees->cleanUp();
$ttrees->cleanUp();
$alignments->cleanUp();

__END__

=head1 NAME

get-rootcombo-freqs.pl - returns a sorted list of category label pairs according to how frequently the nodes to which they refer are aligned to each other in a specified alignment set

=head1 DESCRIPTION

This script takes as input a reference to an tree-to-tree alignment set of files:

=over

=item * -s A treebank file (the source file) in Tiger-XML format

=item * -t As above, but the target side treebank file

=item * -a An alignment file with references to the treebank files, in STA (Stockholm TreeAligner) XML format

=back

A count is made for the category label combination of every linked node pair. In this way, we can see how often certain combinations of category labels are linked to each other. This may be useful for purposes such as checking the consistency of manual alignment or devising features to be used in training for tree alignment software.

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>gidi8ster@gmail.comE<gt>

=cut

