#!/usr/bin/perl
use FindBin qw($Bin);

open (IN, "<$ARGV[0]") || die ("Could not open input file ($ARGV[0])!");

my @link;
my $write1=1; ## write link by default
my $write2=1;
my $id1="";
my $id2="";
my $file1;
my $file2;
my $temp1;
my $temp2;
my %nonterms1=();
my %nonterms2=();

my $in=<IN>;

## prints out align head and also attempts to open the treebank files in the head
while ($in !~ /<alignments/) {
	if ($in =~ /<treebank.*id="(.*?)"/) {
		$temp1=$1;
		if ($in =~ /filename="(.*?)"/) {
			$temp2=$1;
			if ($id1 eq "") {
				$id1=$temp1;
				$file1=$temp2;
				open (TREE1, "<$file1") || die ("Could not open first treebank file ($file1)!");
#print STDERR "file1: $file1\n";
			}
			else {
				$id2=$temp1;
				$file2=$temp2;
#print STDERR "file2: $file2\n";
				open (TREE2, "<$file2") || die ("Could not open second treebank file ($file2)!");
			}
		}
	}
	print $in;
	$in=<IN>;
}
print $in;
if (($id1 eq "") || ($id2 eq "")) {
	print STDERR "One or both IDs not readable!";
	die;
}

## makes hashes of nonterminal nodes
## ((This is not done in this version of the script, since the links in the align file should indicate whether the nodes are terminals or nonterminals.))
makeNonTerms();

my $treeid;
my $nodeid;
my $type;
while ($in=<IN>) {
	@link=();
	if ($in =~ /<align.*type="(.*?)"/) {
		$write1=0;
		$write2=0;
		push (@link, $in);
		do {
			$in=<IN>;
			push (@link, $in);
			if ($in =~ /<node.*treebank_id="(.*?)"/) {
				$treeid=$1;
				if ($in =~ /node_id="(.*?)"/) {
					$nodeid=$1;
					if ($in =~ /type="(.*?)"/) {
					  $type=$1;
					}
					else {
					  if ($treeid eq $id1) {
					    if ($nonterms1{$nodeid} == 1) {
					      $type="nt";
					    }
					    else {
					      $type="t";
					    }
					  }
					  elsif ($treeid eq $id2) {
					    if ($nonterms2{$nodeid} == 1) {
					      $type="nt";
					    }
					    else {
					      $type="t";
					    }
					  }
					}
						if ($treeid eq $id1) {
							if ($type eq "nt") {
								$write1=0;
							}
							elsif ($type eq "t") {
								$write1=1;
							}
							else {
								print STDERR "Erroneous node type in current line! (\"t\" or \"nt\" expected).\nLine: $in";
								close IN;
								die;
							}
						}
						elsif ($treeid eq $id2) {
							if ($type eq "nt") {
								$write2=0;
							}
							elsif ($type eq "t") {
								$write2=1;
							}
							else {
								print STDERR "Erroneous node type in current line! (\"t\" or \"nt\" expected).\nLine: $in";
								close IN;
								die;
							}
						}
						else {
							print STDERR "Error! Encountered treebank id ($treeid) not matching with any of the file treebank IDs ($id1) ($id2)! Exiting...";
							close IN;
							die;
						}
				}
				else { die ("Node ID expected on this line: $in"); }
			}
		}
		until ($in =~ /<\/align>/);
		if (($write1==1) && ($write2==1)) {
			foreach (@link) {
				print $_;
			}
		}
	}
	elsif ($in =~ /<\/alignments/) {
		print $in;
		$in=<IN>;
		print $in;
		close IN;
		exit;
	}
}

sub makeNonTerms
## traverses the two treebanks and generates two hashes giving values of 1 for all found nonterminal nodes.
## Afterwards, if an ID is encountered in the align file and at least one ID has a value of 1 in its respective hash (which means there is at least one nonterminal node in the link), the link is written to output. If not (i.e. when both nodes are terminal nodes), that link is not written. In this way, terminal-to-terminal links are left out in the output align file.
{
	while (my $in1=<TREE1>) {
		if ($in1 =~ /<nt.*id="(.*?)"/) {
			$nonterms1{$1}=1;
		}
	}
	close TREE1;
	while (my $in2=<TREE2>) {
		if ($in2 =~ /<nt.*id="(.*?)"/) {
			$nonterms2{$1}=1;
		}
	}
	close TREE2;
}

__END__

=head1 NAME

write-wordalign.pl - takes a tree alignment set and write only the word alignments to output

=head1 SYNOPSIS

perl write-wordalign.pl alignment_file

=head1 DESCRIPTION

This script takes as input a tree alignment file in Stockholm TreeAligner XML (also used in Lingua-Align and TBLign) format and writes those links where both node references refer to terminal nodes to standard output in STA-XML format. In other words, it writes only the word alignments to output.

It also assumes that the alignment file refers to existing treebanks. If no paths are given in the XML, they should be in the current directory.

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>gidi8ster@gmail.comE<gt>

=cut
