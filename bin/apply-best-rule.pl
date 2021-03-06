#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use lib $FindBin::Bin.'/../lib';
use Treebank;

use Getopt::Std;
use vars qw /$opt_a $opt_s $opt_t $opt_A $opt_b $opt_n $opt_l/;

getopt('staApbnl');

(my $do, my $rulefile, my $rulenumber, my $rule)=("","","","");
my @rulevalues=();

unless (defined $opt_l) {
  die ("File with automatic alignment statistics (-l) not specified!");
}
else{
  open (AUTOSTATS, "<$opt_l") || die ("Could not open rule file with statistics about the automatic alignment file ($opt_l)!");
}
unless (defined $opt_A) {
  die ("Output alignment file (-A) not specified!");
}
else{
  open (AOUT, ">$opt_A") || die ("Could not open output alignment file ($opt_A)!");
}
 unless (defined $opt_n) {
     die ("File with node pair combinations (-n) not specified!");
 }
 else {
     open (NODEPAIRRULES, "<$opt_n") || die ("Could not open file with node pairs and rules ($opt_n)!");
 }

open (BRULE, "<$opt_b") || die ("Could not open rule file containing best rule to be applied ($opt_b)!");
my $in;
$in=<BRULE>;
if (defined $in) {
    while (defined $in) {
	if ($in =~ /^([0-9]+)\t([0-9]+)\t([A-Z]+)/) {
	    $rulenumber=$1;
	    $rule=$2;
	    $do=lc($3);
	    @rulevalues=split(//,$rule);
      print "Best rule to be applied:\n$in";                       
	}
	$in=<BRULE>;
    }
}
unless ($rulenumber ne "") {
    die ("No rule number found in best rules file ($opt_b)!");
}
close (BRULE);

(my %rulelinks, my %applyto, my %linktype) = ((),(),());
(my @links, my @rulesents)=((),());
(my $idprefix, my $nodepair)=("","");

buildStructures();
applyRule();

sub buildStructures {
  (my $in, my $nodepair, my $sentid, my $temp, my $value, my $cursent,my $currule);
   
  unless ($rulenumber ne "") {
    die ("No rule number found in best rules file ($opt_b)!");
  }

  if (($do eq "add") || ($do eq "remove")) {
  my $in=<NODEPAIRRULES>;
  if (defined $in) {
      while (defined $in) {
	  if ($in =~ /$rule/) {
    if ($in =~ /^(\S+)\s/) {
	      $nodepair=$1;
	      push(@links,$nodepair);
	      if ($nodepair =~ /.*__([0-9]+)_/) { ## taking the target side sentence ID as default sentence ID (not assuming it's the same as source, but it's only necessary to search for where to insert one of them, since it'll always be the same as the source side (assuming non-crossing 1:1 sentences)
		$cursent=$1;
		  push(@{$applyto{$cursent}},$nodepair);
		  $rulelinks{$nodepair}=1;
#		  print "Rulelinks of $nodepair is 1\n";
	      }
	      else {
		  die("Alignment link not in a readable format! Should be sentid_nodeid__sentid_nodeid.\nLine: $in");
	      }
#	      print $in;
      }
	  }
	  $in=<NODEPAIRRULES>;
      }
  }

  $in=<AUTOSTATS>;
  if (defined $in) {
      while (defined $in) {
	  if ($in =~ /^LINKTYPE\t(\S+)/) {
	      $linktype{$1}=1;
	  }
	  $in=<AUTOSTATS>;
      }
  }
  close (AUTOSTATS);
}

sub applyRule {
  (my $in, my $sentid, my $oldsentid, my $curlink)=("","","","");
  my $sourcewritten=0;
  my @link=();

  unless (defined $opt_s) {
    die ("Input source treebank file not specified!");
  }
  unless (defined $opt_t) {
    die ("Input target treebank file not specified!");
  }
  unless (-e $opt_s) {
    die ("Source treebank file ($opt_s) does not exist!");
  }
  unless (-e $opt_t) {
    die ("Target treebank file ($opt_t) does not exist!");
  }
  unless (defined $opt_a) {
    die ("Input alignment file not specified!");
  }
  else {
    open (AIN, "<$opt_a") || die ("Could not open input alignment file ($opt_a)!");
	$in=<AIN>;
	if (defined $in) {
	  while ((defined $in) && ($in !~ /<alignments>/)) {
	    if ($in =~ /(.*<treebank.*filename=").*?(".*)/) {
	      if ($sourcewritten == 0) {
		$in = $1.$opt_s.$2."\n";
	      }
	      else {
		$in = $1.$opt_t.$2."\n";
	      }
	      $sourcewritten++;
	    }
	    print AOUT $in;
	    $in=<AIN>;
#	    print $in;
	  }
	}
    ## we have now printed out <alignments> and the pointer is still on it
    print AOUT $in;
    while ((defined $in) && ($in !~ /<align.*author/)) {
      $in=<AIN>;
    }
    ## now at the first line of the first link
    while (defined $in) {
      @link=();

      if ($do eq "add") {
#print "do: $do\n";
      	if ($in =~ /<align.*author/) {
      	  while ((defined $in) && ($in !~ /<\/align>/)) {
      	    push(@link,$in);
      	    $in=<AIN>;
      	  }
      	  push(@link,$in);
## test
      #   	print "This is link:\n";
      #   	foreach (@link) {
      #   	  print $_;
      #   	}
      	  ## pushed whole link and pointer is at </align>
      	  if ((defined $link[2]) && ($link[2] =~ /node_id="(s?)([0-9]+)_/)) {
            $idprefix=$1;
      	    $sentid=$2;
      	    if ($sentid ne $oldsentid) { ## meaning we are now at a new sentence. Now we check if there are any node pair links to be added here before we continue writing the rest
      	      if (defined $applyto{$sentid}) {
#      		print "There are links to be written for sentence $sentid\n";
#      my $size=@{$applyto{$sentid}};
#        print "size: $size\n";
            	  writeLinks(\$applyto{$sentid});
      	      }
      	    }
## new alignments written, now we write the current alignment
      	    foreach(@link) {
      	      print AOUT $_;
      	    }
      	    $oldsentid=$sentid;
      	  }
      	  else {
      	    if (defined $link[1]) {
      	      die ("Source sentence ID expected on this line: $link[1]");
      	    }
      	    else {
      	      die ("Second line of link node not defined!");
      	    }
      	  }
      	}
        $in=<AIN>;
      } ## if ($do eq "add")

      elsif ($do eq "remove") {
        @link=();
        if ($in =~ /<align.*author/) {
          while ((defined $in) && ($in !~ /<\/align>/)) {
            push(@link,$in);
            $in=<AIN>;
          }
          push(@link,$in);
          if ((defined $link[1]) && ($link[1] =~ /node_id="(s?)([0-9]+.*?)"/)) {
            $idprefix=$1;
            $curlink=$2."__";
            if ((defined $link[2]) && ($link[2] =~ /node_id="(s?)([0-9]+.*?)"/)) {
              $curlink=$curlink.$2;
            }

            unless (defined $rulelinks{$curlink}) { ## if this node pair is not flagged for removal, we print the link to output

              foreach (@link) {
                print AOUT $_;
              }
            }
else {
#print "curlink: $curlink\n";
}
          } ## if ((defined $link[1]) && ($link[1]
        } ## if ($in =~ /<align.*author/) {
        $in=<AIN>;
      } ## elsif ($do eq "remove") {
  }
  print AOUT "</alignments>\n";
  print AOUT "</treealign>\n";
  close (AIN);
}
}
}
 
sub writeLinks {
  my $links=shift;
  my $size=@{$$links};
  (my $sourceid, my $targetid);
  
  foreach(@{$$links}) {
    if (defined $linktype{$_}) {
#      warn "Unexpected: link for node pair $_ already exists\n";
    }
    else {
#      print "New link to be added: $_\n";
      if ($_ =~ /(.*)__(.*)/) {
	$sourceid=$1;
	$targetid=$2;
	print AOUT "    <align author=\"TBL\" prob=\"0.8\" type=\"good\">\n";
	print AOUT "      <node node_id=\"$idprefix$sourceid\" type=\"nt\" treebank_id=\"1\"/>\n";
	print AOUT "      <node node_id=\"$idprefix$targetid\" type=\"nt\" treebank_id=\"2\"/>\n";
	print AOUT "    </align>\n";
    }
  }
} ## foreach(@{$$links}) {
} ## sub writeLinks {


close (AOUT);
close (AUTOSTATS);
close (NODEPAIRRULES);

__END__

=head1 NAME

apply-best-rule.pl

=head1 SYNOPSIS

perl apply-best-rule.pl -a input_alignment_file -s input_source_treebank_file -t input_target_treebank_file -A output_alignment_file -b best_rule_file -n node_pair_combinations_file -l automatic_alignment_statistics_file

=over

=item * -s A treebank file (the source file) in Tiger-XML format

=item * -t As above, but the target side treebank file

=item * -a An alignment file with references to the treebank files, in STA (Stockholm TreeAligner) format

=item * -A as -a above, but updated with a rule, to be written to output

=item * -b File containing a best rule as determined by the training process of TBLign, to be applied on the set in -a.

=item * -n File containing node pair combinations, produced by the training process of TBLign and applied in this script.

=item * -l File containing the alignment statistics of the file in -a. This is used to check if an alignment already exists, before updating the file in -A with the link.

=back

=head1 DESCRIPTION

This script is, at the time of writing, used automatically as part of the TBLign tree-to-tree alignment and alignment correction system. In the transformation-based learning approach, an iteration is made over the whole data set, extracting rules. Comparing the rules to the gold standard, the one that leads to the best improvement is applied by this script to the current data set. The new set in -A will be used in a subsequent iteration, unless there is no improvement or training is otherwise finished.

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>gidi8ster@gmail.comE<gt>

=cut

