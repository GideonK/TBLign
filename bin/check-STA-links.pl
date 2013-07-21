#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Std;

use vars qw/$opt_a $opt_s $opt_t/;
getopt('ast');

my %strees=();
my %ttrees=();
my $spath=$opt_s;
my $tpath=$opt_t;
my $sid;
my $tid;
my $curnode;
my $ain;
my $alinecount=1;
my $sformat="alpino"; ## default value
my $tformat="alpino"; ## default value

my $lfile=$opt_s;
my $rfile=$opt_t;
my $afile=$opt_a;
my $stem;
my $suncomp=0;
my $tuncomp=0;
my $auncomp=0;
my $all_nodes_found=1;

if ((defined $lfile) && ($lfile =~ /.*\/([^.]*)\..*/)) {
	$stem=$1;
}
elsif ((defined $lfile) && ($lfile =~ /([^.]*)\./)) {
	$stem=$1;
}
else {
  if (defined $lfile) { 
	$stem=$lfile;
  }
  else {
    die ("Source treebank file not defined!");
  }
}
if ((defined $rfile) && ($rfile =~ /.*\/([^.]*)\..*/)) {
	$stem=$1;
}
elsif ((defined $rfile) && ($rfile =~ /([^.]*)\./)) {
	$stem=$1;
}
else {
  if (defined $rfile) { 
	$stem=$rfile;
  }
  else {
    die ("Target treebank file not defined!");
  }
}

if ($lfile =~ /^(.*)\.gz$/) {
        qx(gzip -cd $lfile > $stem.s);
        $lfile=$stem.".s";
	$suncomp=1;
}
if ($rfile =~ /([^.]*)\.gz/) {
        qx(gzip -cd $rfile > $stem.t);
        $rfile=$stem.".t";
	$tuncomp=1;
}
if ($afile =~ /([^.]*)\.gz/) {
        qx(gzip -cd $afile > $stem.a);
        $afile=$stem.".a";
	$auncomp=1;
}

open (AIN, "<$afile") || die ("Could not open align file ($afile)!");

makeTrees();
checkLinks();

sub makeTrees {
	open (SIN, "<$lfile") || die ("Could not open source treebank file ($lfile)!");
	while (my $sin=<SIN>) {
		if ($sin =~ /<body>/) {
			$sformat="tiger";
		}
	if ($sformat eq "tiger") {
		if ($sin =~ /<t.*word="/) {
			if ($sin =~ /id="s?(.*?)"/) {
				$strees{$1}=1;
			}
		}
		elsif ($sin =~ /<nt.*id="s?(.*?)"/) {
			$strees{$1}=1;
		}
	}
	else {
		if ($sin =~ /<node.*id="s?(.*?)"/) {
			$strees{$1}=1;
		}
	}
	}
	open (TIN, "<$rfile") || die ("Could not open target treebank file ($rfile)!");
	while (my $tin=<TIN>) {
		if ($tin =~ /<body>/) {
			$tformat="tiger";
		}
	if ($tformat eq "tiger") {
		if ($tin =~ /<t.*word="/) {
			if ($tin =~ /id="s?(.*?)"/) {
				$ttrees{$1}=1;
			}
		}
		elsif ($tin =~ /<nt.*id="s?(.*?)"/) {
			$ttrees{$1}=1;
		}
	}
	else {
		if ($tin =~ /<node.*id="s?(.*?)"/) {
			$ttrees{$1}=1;
		}
	}
	}
}

sub checkLinks {
	my @node=();
	my $tempcount=0;
	while ($ain=<AIN>) {
	if ($ain =~ /<\/align>/) {
		$alinecount++;
		if ($node[1] =~ /node_id="s?(.*?)"/) {
			$curnode=$1;
			unless (defined $strees{$curnode} ) {
			  $all_nodes_found=0;
			  $tempcount=$alinecount-2;
			  print STDERR "No match in source treebank for source tree node ID encountered in tree align file: '$curnode'\non line $tempcount in $opt_a. Line: $node[1]";
			  $all_nodes_found=0;
			}
			else {
			if ($strees{$curnode} != 1) {
				$tempcount=$alinecount-2;
				$all_nodes_found=0;
				print STDERR "No match in source treebank for source tree node ID encountered in tree align file: '$curnode'\non line $tempcount in $opt_a. Line: $node[1]";
			}
			}
		}
		if ($node[2] =~ /node_id="s?(.*?)"/) {
			$curnode=$1;
			unless (defined $ttrees{$curnode} ) {
			  $all_nodes_found=0;
			  $tempcount=$alinecount-2;
			  print STDERR "No match in target treebank for target tree node ID encountered in tree align file: '$curnode'\non line $tempcount in $opt_a. Line: $node[2]";
			}
			else {
			if ($ttrees{$curnode} != 1) {
				$tempcount=$alinecount-2;
				$all_nodes_found=0;
				print STDERR "No match in target treebank for target tree node ID encountered in tree align file: '$curnode'\non line $tempcount in $opt_a. Line: $node[2]";
			}
			}
		}
		@node=();
	}
	elsif ($ain =~ /<align.*author/) {
		push (@node, $ain);
		$alinecount++;
	}
	elsif ($ain =~ /<node.*node_id/) {
		push (@node, $ain);
		$alinecount++;
	}
	else {
		$alinecount++;
	}
	}
}

if ($suncomp == 1) {
        qx(rm $stem.s);
}
if ($tuncomp == 1) {
	qx(rm $stem.t);
}
if ($auncomp == 1) {
	qx(rm $stem.a);
}

if ($all_nodes_found == 1) {
  print STDERR "Success! All node references are valid.\n";
}
else {
  print STDERR "Unfortunately, at least one node is referenced that does not exist! One or more of the files do not match with the others. Check if the correct files were specified and if so, how the alignment file was created.\n";
}

close SIN;
close TIN;
close AIN;

__END__

=head1 NAME

check-STA-links.pl

=head1 SYNOPSIS

perl check-STA-links.pl -a Stockholm_Treealigner_XML_file -s source_treebank_file -t target_treebank_file

=head1 OPTIONS

=over

=item * -a Stockholm TreeAligner XML file containing alignments (references to IDs in treebank files)

=item * -s source treebank file

=item * -t target treebank file

=back

=head1 DESCRIPTION

This script takes as input a Stockholm TreeAligner (Lingua-Align) tree alignment file and two treebanks (source and target), and checks if all the node references in the alignment file exist in the treebanks. If a node is not found, a warning is written to standard error output for that node.

It is automatically discovered whether the treebank files are in Alpino-XML or Tiger-XML, and whether they, as well as the alignment file, are compressed or not.

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>g.j.kotze@rug.nlE<gt>

=cut

