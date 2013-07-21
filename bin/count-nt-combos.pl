#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use lib $FindBin::Bin.'/../lib';

use Getopt::Std;
use vars qw /$opt_s $opt_t/;

getopt('st');

(my $localscount, my $localtcount, my $totalcount, my $localcombo, my $totalcombo, my $totalscount, my $totaltcount)=(0,0,0,0,0,0,0);
(my $sourcefile, my $targetfile, my $isdefined, my $scompressed, my $tcompressed)=("","",0,0,0);

unless (defined $opt_s) {
  die ("Source treebank file not specified!");
}
if ($opt_s =~ /\.gz$/) {
        qx(gzip -cd $opt_s > sourcefile.tmp);
        $sourcefile="sourcefile.tmp";
        $scompressed=1;
}
else {
	$sourcefile=$opt_s;
}
if ($opt_t =~ /\.gz$/) {
        qx(gzip -cd $opt_t > targetfile.tmp);
        $targetfile="targetfile.tmp";
        $tcompressed=1;
}
else {
	$targetfile=$opt_t;
}

open (SIN, "<$sourcefile") || die("Could not open source treebank file ($sourcefile)!");
open (TIN, "<$targetfile") || die("Could not open target treebank file ($targetfile)!");

my $sin=<SIN>;
my $tin=<TIN>;

if ((defined $sin) && (defined $tin)) {
	while ($isdefined == 0) {
		$localscount=0;
		$localtcount=0;
		while ((defined $sin) && ($sin !~ /<s id/)) {
			$sin=<SIN>;
		}
		while ((defined $tin) && ($tin !~ /<s id/)) {
			$tin=<TIN>;
		}
		## now pointers for both files are at the start of a new sentence
		while ((defined $sin) && ($sin !~ /<\/s>/)) {
			$sin=<SIN>;
			if ($sin =~ /<nt id/) { ## encountering a nonterminal ID
				$localscount++;
			}
		}
		while ((defined $tin) && ($tin !~ /<\/s>/)) {
			$tin=<TIN>;
			if ($tin =~ /<nt id/) { ## encountering a nonterminal ID
				$localtcount++;
			}
		}
		if (($localscount > 0) && ($localtcount > 0)) {
			$totalscount += $localscount;
			$totaltcount += $localtcount;
			$localcombo = $localscount*$localtcount;
			$totalcombo += $localcombo; 
		}
		else {
			unless (($localscount == 0) && ($localtcount == 0)) {
				if ($localscount == 0) {
					warn ("No nonterminals found for source side sentence - either malformed sentence or source and target sentences not evenly matched!");
				}
				if ($localtcount == 0) {
					warn ("No nonterminals found for target side sentence - either malformed sentence or source and target sentences not evenly matched!");
				}
			}
		}
		unless ((defined $sin) && (defined $tin)) {
			$isdefined = 1;
		}
		$sin=<SIN>;
		$tin=<TIN>;
	}
	$totalcount = $totalscount+$totaltcount;
	print "Number of possible alignments between nonterminal nodes: ".$totalcombo."\n";
	print "Total number of source side nonterminal nodes: ".$totalscount."\n";
	print "Total number of target side nonterminal nodes: ".$totaltcount."\n";
	print "Total number of nonterminal nodes: ".$totalcount."\n";
}
else {
	die("Either source or target file (or both) not defined - exiting!");
}

if ($scompressed == 1) {
  qx(rm sourcefile.tmp);
}
if ($tcompressed == 1) {
  qx(rm targetfile.tmp);
}

close (SIN);
close (TIN);

__END__

=head1 NAME

count-nt-combos.pl

=head1 SYNOPSIS

perl count-nt-combos.pl -s source_treebank_file -t target_treebank_file

=head1 OPTIONS

=over

=item * -s source treebank file file in TIGER-XML format

=item * -t target treebank file file in TIGER-XML format

=back

=head1 DESCRIPTION

This script takes as input a source and target-side treebank pair which may be or has been aligned. It provides the following statistics:

=over

=item * The total number of source-tree non-terminal nodes.

=item * The total number of target-tree non-terminal nodes.

=item * The total number of non-terminal nodes.

=item * The total number of non-terminal nodes that can be aligned. In other words, for every sentence pair, the source and target-side non-terminal counts are multiplied with each other, which is then added to the total for all sentence pairs.

=back

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>g.j.kotze@rug.nlE<gt>

=cut