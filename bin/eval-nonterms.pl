#!/usr/bin/perl
use lib $FindBin::Bin.'/../lib';
use Getopt::Std;
use Cwd 'abs_path';

use vars qw/$opt_a $opt_g $opt_h/;
getopt('ag');
getopts('h');

open (GIN, "<$opt_g") || die ("Could not open gold standard file ($opt_g)!");
open (AIN, "<$opt_a") || die ("Could not open align output (test) file ($opt_a)!");

$opt_g=abs_path($opt_g);
$opt_a=abs_path($opt_a);

(my $apath, my $gpath);

if ($opt_g =~ /(.*)\//) {
	$gpath=$1;
}
if ($opt_a =~ /(.*)\//) {
	$apath=$1;
}

#my $align1;
#my $align2;
#my $a1tree1;
#my $a1tree2;
#my $a2tree1;
#my $a2tree2;

## types of links: ntgood, ntfuzzy, tgood, tfuzzy (t=terminal, nt=nonterminal)
## G = gold standard; A = align output file
my $ntgoodcountG=0;
my $ntfuzzycountG=0;
my $tgoodcountG=0;
my $tfuzzycountG=0;
my $ntgoodcountA=0;
my $ntfuzzycountA=0;
my $tgoodcountA=0;
my $tfuzzycountA=0;

## making hashes of links
## The value one node ID (first line / source tree) is the key and the other ID to which it links (second line / target tree) is the value.
## The type of link (eg. terminal/fuzzy) is deduced by which hash it is in (i.e. %tfuzzy)
my %ntgoodG=();
my %ntfuzzyG=();
my %tgoodG=();
my %tfuzzyG=();
my %ntgoodA=();
my %ntfuzzyA=();
my %tgoodA=();
my %tfuzzyA=();

## making a hash of sentences to be included. If the key is 127 and the value is 1, then sentence 127 are in the output file and the corresponding sentence should be included in extracting the statistics from the gold standard file. This is because it is assumed that the gold standard file may contain sentences that are not in the align output file, but all sentences in the alignment output file are in the gold standard.
my %sents=();
my $begin=0; my $end=0; ## begin and end values recorded for sentence IDs in the output align file. From the $begin variable's value, every sentence in the gold standard file will be checked whether its ID has a value of 1 in %sents

## make hashes with node details (to be filled as soon as the paths are known (in sub getLinksA and sub getLinksG)
my %tree1A=();
my %tree2A=();
my %tree1G=();
my %tree2G=();
my $mainf;
my $secondf;
my $precision;
my $recall;
my $goodrecall;
my $fuzzyrecall;

## fill hashes with link details and make counts
getLinksA();

#print "BEGIN: $begin and END: $end\n";
getLinksG();

## tests if hashes were correctly filled by printing out their values
#testPrint();

getScores();
#my $precisionNT=getPrecision();
#my $recallNT=getRecall();

if (defined $opt_h) { ## if -h option is used
    print "Precision (all)\tRecall (all)\tRecall (good)\tRecall (fuzzy)\tF-score (P_all & R_all)\tF-score (P_all & R_good)\n";
}
## Periods in fractions are changed to commas since values were imported to a version of OpenOffice where only commas were recognised. If commas are not desired then then following series of ifs (until before the print command) can be commented out.
if ($precision =~ /^(.*)\.(.*)$/) {
	$precision=$1.",".$2;
}
if ($recall =~ /^(.*)\.(.*)$/) {
	$recall=$1.",".$2;
}
if ($goodrecall =~ /^(.*)\.(.*)$/) {
	$goodrecall=$1.",".$2;
}
if ($fuzzyrecall =~ /^(.*)\.(.*)$/) {
	$fuzzyrecall=$1.",".$2;
}
if ($mainf =~ /^(.*)\.(.*)$/) {
	$mainf=$1.",".$2;
}
if ($secondf =~ /^(.*)\.(.*)$/) {
	$secondf=$1.",".$2;
}
print "$precision\t$recall\t$goodrecall\t$fuzzyrecall\t$mainf\t$secondf\n";

sub getLinksA {
	my $in;
	my @link=();
	my $linktype;
	my $node1type;
	my $node2type;
	my $tfile1; my $tfile2;
	my $temp;
	my $id1; my $id2;
	my $fullid;
	while ($in = <AIN>) {
		if ($in =~ /<treebank.*filename="(.*?)"/) {
			$temp=$1;
			if ($first == 0) {
				$tfile1=$temp;
				if ($tfile1 !~ /\//) { ## then we assume it's in the same path as the align file
					$tfile1=$apath."/".$tfile1;
				}
				open (TIN1A, "<$tfile1") || die ("Could not open first treebank file ($tfile1) specified in $opt_a!");
				$first=1;
				makeTree1A(); ## fill up hashes with node information
			}
			else {
				$tfile2=$temp;
				if ($tfile2 !~ /\//) { ## then we assume it's in the same path as the align file
					$tfile2=$apath."/".$tfile2;
				}
				open (TIN2A, "<$tfile2") || die ("Could not open second treebank file ($tfile2) specified in $opt_a!");
				makeTree2A();
			}
		}
		if ($in =~ /<align /) {
			while ($in !~ /<\/align>/) {
				push (@link, $in);
				$in=<AIN>;
			}
			if ($link[0] =~ /<align.*type="(.*?)"/) {
				$linktype=$1;
			}
			else {
				warn "Warning! Unexpected input line: $link[0]\n";
				die;
			}
			if ($link[1] =~ /<node.*node_id="(.*?)"/) {
				$id1=$1;
				if ($id1 =~ /s?([0-9]+)_/) {
					$temp=$1;
					if ($begin == 0) {
						$begin=$temp;
					}
					if ($temp > $end) {
						$end=$temp;
					}
				}
				else {
					warn "Warning! Unexpected ID value ($temp) encountered! on line: $link[1]\n";
					die;
				}
				if ($tree1A{$id1} eq "t") {
					$node1type="t";
				}
				elsif ($tree1A{$id1} eq "nt") {
					$node1type="nt";
				}
				else {
					warn "Warning! Node reference ($id1) in align file ($opt_a) does not exist in treebank file ($tfile1)!";
					die;
				}
			}
			else {
				warn "Warning! Unexpected input line: $link[1]\n";
				die;
			}
			if ($link[2] =~ /<node.*node_id="(.*?)"/) {
				$id2=$1;
				if ($tree2A{$id2} eq "t") {
					$node1type="t";
				}
				elsif ($tree2A{$id2} eq "nt") {
					$node1type="nt";
				}
				else {
					warn "Warning! Node reference ($id2) in align file ($opt_a) does not exist in treebank file ($tfile2)!";
					die;
				}
			}
			else {
				warn "Warning! Unexpected input line: $link[2]\n";
				die;
			}
			$fullid=$id1.";".$id2;
			if (($node1type eq "nt") || ($node2type eq "nt")) { ## only one needs to be nonterminal - for practical reasons we regard an alignment between a terminal and a nonterminal as a nonterminal alignment since in our case it was made by the constituent aligner and not by the word alignment software.
				if ($linktype eq "good") {
					$ntgoodA{$fullid}=1;
					$ntgoodcountA++;
				}
				elsif ($linktype eq "fuzzy") {
					$ntfuzzyA{$fullid}=1;
					$ntfuzzycountA++;
				}
				else {
					warn "Warning! Unexpected link type value ($linktype)! (\"good\" or \"fuzzy\" expected)\n";
					die;
				}
			}
			elsif (($node1type eq "t") && ($node1type eq "t")) {
				if ($linktype eq "good") {
					$tgoodA{$fullid}=1;
					$tgoodcountA++;
				}
				elsif ($linktype eq "fuzzy") {
					$tfuzzyA{$fullid}=1;
					$tfuzzycountA++;
				}
				else {
					warn "Warning! Unexpected link type value ($linktype)! (\"good\" or \"fuzzy\" expected)\n";
					die;
				}
			}
			else {
				warn "Warning! Unexpected node types encountered! (values of \"t\" and/or \"nt\" expected)\n";
				warn "Node type 1 value: $node1type\nNode type 2 value: $node2type\n";
				die;
			}
		}
		@link=();
	}
}

sub getLinksG {
    my $in;
    my @link=();
    my $linktype;
    my $node1type;
    my $node2type;
    my $tfile1; my $tfile2;
    my $temp;
    my $id1; my $id2; my $fullid;
    my $write=0;
    my $first=0;
    while ($in = <GIN>) {
                if ($in =~ /<treebank.*filename="(.*?)"/) {
                        $temp=$1;
                        if ($first == 0) {
			    $tfile1=$temp;
				if ($tfile1 !~ /\//) { ## then we assume it's in the same path as the align file
					$tfile1=$gpath."/".$tfile1;
				}
				open (TIN1G, "<$tfile1") || die ("Could not open first treebank file ($tfile1) specified in $opt_g!");
			    $first=1;
			    makeTree1G(); ## fill up hashes with node information
                        }
                        else {
			    $tfile2=$temp;
				if ($tfile2 !~ /\//) { ## then we assume it's in the same path as the align file
					$tfile2=$gpath."/".$tfile2;
				}
				open (TIN2G, "<$tfile2") || die ("Could not open second treebank file ($tfile2) specified in $opt_g!");
			    makeTree2G();
                        }
                }
                if ($in =~ /<align /) {
		    while ($in !~ /<\/align>/) {
			push (@link, $in);
			$in=<GIN>;
		    }
                        if ($link[0] =~ /<align.*type="(.*?)"/) {
			    $linktype=$1;
                        }
		    else {
			warn "Warning! Unexpected input line: $link[0]\n";
			die;
		    }
                        if ($link[1] =~ /<node.*node_id="(.*?)"/) {
			    $id1=$1;
                                if ($id1 =~ /s?([0-9]+)_/) {
				    $temp=$1;
				    if (($temp >= $begin) && ($temp <=$end)) {
					$write=1;
					if ($tree1G{$id1} eq "t") {
					    $node1type="t";
					}
					elsif ($tree1G{$id1} eq "nt") {
					    $node1type="nt";
					}
					else {
					    warn "Warning! Node reference ($id1) in gold standard file ($opt_g) does not exist in first treebank file ($tfile1)!";
					    die;
					}
				    }
				    else {
					$write=0;
				    }
                                }
			        else {
				    warn "Warning! Unexpected input line: $link[1]\n";
				    die;
				}
			}
			else {
			    warn "Warning! Unexpected input line: $link[1]\n";
			    die;
			}
                        if ($link[2] =~ /<node.*node_id="(.*?)"/) {
                                $id2=$1;
				if ($id2 =~ /s?([0-9]+)_/) {
				    $temp=$1;
				    if (($temp >= $begin) && ($temp <= $end)) {
					$write=1;
					if ($tree2G{$id2} eq "t") {
					    $node2type="t";
					}
					elsif ($tree2G{$id2} eq "nt") {
					    $node2type="nt";
					}
					else {
					    warn "Warning! Node reference ($id2) in gold standard file ($opt_g) does not exist in second treebank file ($tfile2)!";
					}
				    }
				    else {
					$write=0;
				    }
				}
                                else {
				    warn "Warning! Unexpected input line: $link[2]\n";
				    die;
				}
			}
		    else {
			warn "Warning! Unexpected input line: $link[2]\n";
			die;
		    }
		    if ($write == 1) {
		    $fullid=$id1.";".$id2;
		    if (($node1type eq "nt") || ($node2type eq "nt")) { ## only one needs to be nonterminal
			if ($linktype eq "good") {
			    $ntgoodG{$fullid}=1;
			    $ntgoodcountG++;
			}
			elsif ($linktype eq "fuzzy") {
			    $ntfuzzyG{$fullid}=1;
			    $ntfuzzycountG++;
			}
			else {
			    warn "Warning! Unexpected link type value ($linktype)! (\"good\" or \"fuzzy\" expected)\n";
			    die;
			}
		    }
		    elsif (($node1type eq "t") && ($node1type eq "t")) {
			if ($linktype eq "good") {
			    $tgoodG{$fullid}=1;
			    $tgoodcountG++;
			}
			elsif ($linktype eq "fuzzy") {
			    $tfuzzyG{$fullid}=1;
			    $tfuzzycountG++;
			}
			else {
			    warn "Warning! Unexpected link type value ($linktype)! (\"good\" or \"fuzzy\" expected)\n";
			    die;
			}
		    }
		    else {
			warn "Warning! Unexpected node types encountered! (values of \"t\" and/or \"nt\" expected)\n";
			warn "Node type 1 value: $node1type\nNode type 2 value: $node2type\n";
			die;
		    }
		    }
                }
                @link=();


    }
}

sub makeTree1A {
	my $in;
	while ($in=<TIN1A>) {
		if ($in =~ /<t id="(.*?)"/) {
			$tree1A{$1}="t";
		}
		if ($in =~ /<nt id="(.*?)"/) {
			$tree1A{$1}="nt";
		}
	}
}

sub makeTree2A {
	my $in;
	while ($in=<TIN2A>) {
		if ($in =~ /<t id="(.*?)"/) {
			$tree2A{$1}="t";
		}
		if ($in =~ /<nt id="(.*?)"/) {
			$tree2A{$1}="nt";
		}
	}
}

sub makeTree1G {
    my $in;
    while ($in=<TIN1G>) {
	if ($in =~ /<t id="(.*?)"/) {
	    $tree1G{$1}="t";
	}
	if ($in =~ /<nt id="(.*?)"/) {
	    $tree1G{$1}="nt";
	}
    }
}

sub makeTree2G {
    my $in;
    while ($in=<TIN2G>) {
	if ($in =~ /<t id="(.*?)"/) {
	    $tree2G{$1}="t";
	}
	if ($in =~ /<nt id="(.*?)"/) {
	    $tree2G{$1}="nt";
	}
    }
}

sub testPrint {
    print "Good terminal count in G: $tgoodcountG\n";
    print "Fuzzy terminal count in G: $tfuzzycountG\n";
    print "Good nonterminal count in G: $ntgoodcountG\n";
    print "Fuzzy nonterminal count in G: $ntfuzzycountG\n";
    print "Good terminal count in A: $tgoodcountA\n";
    print "Fuzzy terminal count in A: $tfuzzycountA\n";
    print "Good nonterminal count in A: $ntgoodcountA\n";
    print "Fuzzy nonterminal count in A: $ntfuzzycountA\n";
}

sub getScores {
## first precision
    my $total=0;
    my $totalntgoodA=0;
    my $totalntfuzzyA=0;
    my $totalntgoodG=0;
    my $totalntfuzzyG=0;
    my $precmatchntgood=0;
    my $precmatchntfuzzy=0;
    my $goodrecmatchnt=0;
    my $fuzzyrecmatchnt=0;
    my $match;
    my $precmatch;
    my $goodprecision;
    my $fuzzyprecision;
    my $allprecision=0;
    my $allrecmatchnt=0;
    my $k;
    my $allgold=0;
#    print "size of ntgoodA:" . keys( %ntgoodA ) . ".\n";

	## precision
    while ( $k = each (%ntgoodA)) {
	$total++;
	$totalntgoodA++;
	if ((defined $ntgoodG{$k}) || (defined $ntfuzzyG{$k})) { ## with overall precision, link type doesn't matter
#	  print "key $k MATCHES\n";
	    $allprecision++;
	    $precmatchntgood++;
	}
	else {
#	  print "key $k DOES NOT MATCH\n";
	}
    }
#    print "size of ntfuzzyA:" . keys( %ntfuzzyA ) . "\n";
    while ( $k = each (%ntfuzzyA)) {
	$total++;
	$totalntfuzzyA++;
#	print "FUZZY NT IN A, COUNT: $totalntfuzzyA\n";
#	print "Current match count (of matching in G): $matchntfuzzy\n";
	if (defined $ntgoodG{$k} || $ntfuzzyG{$k}) {
	    $allprecision++;
	    $precmatchntfuzzy++;
	}
    }
#     print "precmatchntgood: $precmatchntgood\n";
#     print "precmatchntfuzzy: $precmatchntfuzzy\n";
    $precmatch=$precmatchntgood+$precmatchntfuzzy;
    ## $precmatchntgood: Number of good links in automatic output that are also in the gold standard (whatever kind of link, precision count)
    ## $precmatchntfuzzy: Number of fuzzy links in automatic output that are also in the gold standard (whatever kind of link, precision count)
    ## $precmatch = Number of links in automatic output that are also in the gold standard (total precision count)
	if ($total > 0) {
	    $precision=$precmatch/$total*100;
	    $precision=decdigits($precision,2);
	    $precision=$allprecision/$total*100;
	    $precision=decdigits($precision,2);
	}
	else { $precision=0; }

    ## recall
    my $total=0;
    my $match=0;
    my $recmatch;
#    print "size of ntgoodG:" . keys( %ntgoodG ) . "\n";
    while ($k = each (%ntgoodG)) {
	$total++;
	$allgold++;
	$totalntgoodG++;
	if (defined $ntgoodA{$k} || $ntfuzzyA{$k}) {
	  $allrecmatchnt++;
	  $goodrecmatchnt++;
	}
    }
#    print "size of ntfuzzyG:" . keys( %ntfuzzyG ) . "\n";
#    print "allrecmatchnt: $allrecmatchnt\n";
#    print "goodrecmatchnt: $goodrecmatchnt\n";
    while ($k = each (%ntfuzzyG)) {
	$totalntfuzzyG++;
	$total++;
	$allgold++;
	if (defined $ntgoodA{$k} || $ntfuzzyA{$k}) {
		$allrecmatchnt++;
	}
	if (defined $ntfuzzyA{$k}) { ## fuzzy only recall is strict
		$fuzzyrecmatchnt++;
	}
   }
#   print "fuzzyrecmatchnt: $fuzzyrecmatchnt\n";
	if ($total>0) {
#	    $recall=$allrecmatchnt/$total*100;
	    $recall=$allrecmatchnt/$allgold*100;
	    $recall=decdigits($recall,2);
	}
	else {
		$recall=100; ## there are no good links in the gold standard, so no links were missed, so recall is 100
	}
    if ($totalntgoodA > 0) {
	$goodprecision=$precmatchntgood/$totalntgoodA*100; ## % of how many good links in the automatic output are also in the gold standard (whether good or fuzzy)
    }
    else { $goodprecision=0; }
#    print "Precision of good links: $precmatchntgood correct links out of $totalntgoodA proposed links: $goodprecision\n";
#	print "PRECMATCHNTGOOD: $precmatchntgood\nNTGOODCOUNTG: $ntgoodcountG\n";
    if ($totalntgoodG > 0) {
	$goodrecall=$goodrecmatchnt/$totalntgoodG*100; ## % of how many good links in the gold standard are also in the automatic output (whether good or fuzzy)
	## $goodrecmatchnt = number of good links in the gold standard that are also in the automatic output (good or fuzzy)
	## $totalntgood = number of good links in the gold standard
    }
    else {$goodrecall=100; }
    $goodrecall=decdigits($goodrecall,2);
#    print "Recall of good links: $precmatchntgood good links in A are in gold standard, totalling $ntgoodcountG good links: $goodrecall\n";

    if ($totalntfuzzyA > 0) {
	$fuzzyprecision=$precmatchntfuzzy/$totalntfuzzyA*100; ## % of how many fuzzy links in the automatic output are also in the gold standard (good or fuzzy)
    }
    else { $fuzzyprecision=0; }

#    print "Precision of fuzzy links: $precmatchntfuzzy correct links out of $totalntfuzzyA proposed links: $fuzzyprecision\n";
    if ($totalntfuzzyG > 0) {
	$fuzzyrecall=$fuzzyrecmatchnt/$totalntfuzzyG*100; ## % of how many fuzzy links in the gold standard are also in the automatic output (fuzzy links only)
	## $totalntfuzzyG = nr of fuzzy links in the gold standard
	## $fuzzyrecmatchnt = number of fuzzy links in the gold standard that is also in the automatic output (fuzzy only)
    }
    else { $fuzzyrecall=100; }
    $fuzzyrecall=decdigits($fuzzyrecall,2);
#    print "Recall of fuzzy links: $precmatchntfuzzy fuzzy links in A are in gold standard, totalling $ntfuzzycountG fuzzy links: $fuzzyrecall\n\n";
    my $fuzzyf;
    if (($fuzzyprecision+$fuzzyrecall) > 0) {
	$fuzzyf=2*$fuzzyprecision*$fuzzyrecall/($fuzzyprecision+$fuzzyrecall);
    }
    else {$fuzzyf=0;}
#    print "Balanced F of fuzzy links: $fuzzyf\n";
    my $goodf;
    if (($goodprecision+$goodrecall) > 0) {
	$goodf=2*$goodprecision*$goodrecall/($goodprecision+$goodrecall);
    }
    else {$goodf=0;}
#    print "Balanced F of good links: $goodf\n";
    if (($precision+$recall) > 0) {
	$mainf=2*$precision*$recall/($precision+$recall);
    }
    else {$mainf=0;}
    $mainf=decdigits($mainf,2);
#    print "Main F: (2 times $precision times $recall divided by ($precision plus $recall) = $mainf\n";
    if (($precision+$goodrecall) > 0) {
	$secondf=2*$precision*$goodrecall/($precision+$goodrecall);
    }
    else {$secondf=0;}
    $secondf=decdigits($secondf,2);
#    print "Second F: $secondf\n";
}

sub decdigits {
    my $num=shift;#the number to work on
    my $digs_to_cut=shift;# the number of digits after
                            # the decimal point to cut
                #(eg: $digs_to_cut=3 will leave
                # two digits after the decimal point)

    if ($num=~/\d+\.(\d){$digs_to_cut,}/) {
    # there are $digs_to_cut or
    # more digits after the decimal point
      $num=sprintf("%.".($digs_to_cut-1)."f", $num);
    }
    return $num;
}


close TIN1A;
close TIN2A;

__END__

=head1 NAME

eval-nonterms.pl

=head1 SYNOPSIS

perl eval-nonterms.pl -a auto_align -g gold_align [ -h ]

=head1 OPTIONS

=over

=item * -a automatic alignment file: Stockholm TreeAligner / Lingua-Align style XML file - the file of which the constituent alignment accuracy you would like to evaluate.

=item * -g gold standard file (Stockholm TreeAligner / Lingua-Align style XML)

=item * -s source treebank file in TIGER-XML

=item * -t target treebank file in TIGER-XML

=item * -h If present, displays a header stating which evaluation scores are being displayed.

=back

=head1 DESCRIPTION

This script takes as input two XML output files in the style used by the manual tree alignment tool Stockholm TreeAligner and the automatic tree aligner Lingua-Align and calculates the precision, recall and F-scores (with both recall=good and recall=fuzzy) of all links containing at least one nonterminal node.

=over

=item * It assumes that the links to the treebanks are valid and are used to determine whether or not the nodes are nonterminals. It also assumes the treebank names in both files are the same and gives a warning when they are different.

=item * Evaluation results are written to standard output and consists of a row of header values and the corresponding values on the second row. Displaying the header can be switched off by omitting the -h option. This is for in case the script is called more than once to add values to a table, for example.

=item * NOTE: It is assumed that the sentences in the automatic alignment file are to be compared with the sentences in the gold standard that have the same sentence IDs. Links between terminal and nonterminal nodes are regarded as nonterminal node links.

=back

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>gidi8ster@gmail.comE<gt>

=cut

