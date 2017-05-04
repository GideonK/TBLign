#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use lib $FindBin::Bin.'/../lib';
use Treebank;
use STA;
use Rulestats;

use Getopt::Std;
use vars qw /$opt_s $opt_t $opt_a $opt_r $opt_A $opt_M $opt_S $opt_T $opt_R $opt_L $opt_u $opt_b $opt_g/;

getopt('stabruAMSTRL');
getopts('g');

my $man_alignstatsfile; my $auto_alignstatsfile; my $srctreestatsfile; my $trgtreestatsfile; my $rulestatsfile; my $foundrulesfile; my $bestrulefile;

if ($opt_g) {
  $man_alignstatsfile=$opt_M || "../data/db/0/man_alignstats.txt";
  $foundrulesfile=$opt_u || "../data/db/0/foundrules.txt";
  $bestrulefile=$opt_b || "../data/db/0/bestrule.txt";
}

$auto_alignstatsfile=$opt_L || "../data/db/0/ling_alignstats.txt";
$srctreestatsfile=$opt_S || "../data/db/0/srctreestats.txt";
$trgtreestatsfile=$opt_T || "../data/db/0/trgtreestats.txt";
$rulestatsfile=$opt_R || "../data/db/0/rulestats.txt";

(my $srcstats_exists, my $trgstats_exists)=(0,0);

unless (defined $opt_s) {
  die ("No source treebank file specified!");
}
unless (defined $opt_t) {
  die ("No target treebank file specified!");
}

if ($opt_g) {
  unless (defined $opt_a) {
    die ("No gold standard file specified, although -g specified!");
  }
}
unless (defined $opt_A) {
  die ("No initial state annotator (automatic) alignment file specified!");
}

if ($opt_g) {
  open (MANALIGNSTATS, ">$man_alignstatsfile") || die ("Could not open manual alignment statistics file ($man_alignstatsfile)!");
}

open (AUTOALIGNSTATS, ">$auto_alignstatsfile") || die ("Could not open Lingua-Align alignment statistics file ($auto_alignstatsfile)!");
unless (-s $srctreestatsfile) {
  open (SRCTREESTATS, ">$srctreestatsfile") || die ("Could not open source treebank statistics file ($srctreestatsfile)!");
}
else { ## if it already exists, we read the stats
    open (SRCTREESTATS, "<$srctreestatsfile") || die ("Could not open source treebank statistics file ($srctreestatsfile)!");
    $srcstats_exists=1;
}
unless (-s $trgtreestatsfile) {
  open (TRGTREESTATS, ">$trgtreestatsfile") || die ("Could not open target treebank statistics file ($trgtreestatsfile)!");
}
else {
  open (TRGTREESTATS, "<$trgtreestatsfile") || die ("Could not open target treebank statistics file ($trgtreestatsfile)!");
  $trgstats_exists=1;
}
open (RULESTATS, ">$rulestatsfile") || die ("Could not open rule statistics file ($rulestatsfile)!");
#open (NONTERMCOMBOS, ">$nontermcombosfile") || die ("Could not create file for nonterminal node combinations ($nontermcombosfile)!");

if ($opt_g) {
  open (FOUNDRULES, ">$foundrulesfile") || die ("Could not open found rules file ($foundrulesfile)!");
  open (BESTRULE, ">$bestrulefile") || die ("Could not open best rule file ($bestrulefile)!");
}

(my $pos1, my $pos2, my $combopos, my $pos1match, my $pos2match, my $absheightthresh, my $rulenumber, my $rulekey, my $source_has_caps, my $target_has_caps, my $source_has_number, my $target_has_number, my $temp);
# my $count=0;
# (my $count, my $nonwellformed_exists, my $leafratio_exists, my $leafcountdiff_exists, my $linkedleafratio_exists, my $linkedleafcountdiff_exists, my $absheightdiff_exists)=(0,0,0,0,0,0,0);
my %exists=();
my @rulenumbers=();

## these values are either 0 or 1 depending on whether they conform to the requirement for a particular nonterminal node pair
my %rulekeys_number2key=();
my %rulekeys_key2number=();
my %nodepair=();
my @fullrule=();
my %fullrule=();
my %linkrulecounts=();
my %linkrulecount=();
my %correct=();
my %incorrect=();
my @addrules=();
my @removerules=();
my %addrules_exist=();
my %removerules_exist=();
(my $key, my $key2, my $height, my $index);
my %root_nodes_CAT=(); ## this hash structure can have several different values corresponding to a particular category label combination
my %treestats=(); ## all pure treebank statistics
my %alignstats=(); ## all pure alignment statistics
my %rulesvalues=(); ## all rule-related statistics drawing from both %treestats and %alignstats
# my $opt_leafratiothresh; my $opt_linkedleafratiothresh; my $opt_leafratiorange; my $opt_linkedleafratiorange; my $opt_absheightthresh; ## variables to be used if $opt_o is specified
my $absheight_equal=0;
my @absheight_equal=(); my @gcount_equal=(); my @fcount_equal=(); my @ncount_equal=(); my @gcountnp_equal=(); my @fcountnp_equal=();
my $wfgthresh=0; my $wffthresh=0; my $wfgnpthresh=0; my $wffnpthresh=0; my $wfnontthresh=0; my $wfg_equal=0; my $wff_equal=0; my $wfgnp_equal=0; my $wffnp_equal=0; my $wfnont_equal=0;
my $getleafratio=0; my $getlinkedleafratio=0;

# if (defined $opt_o) {
#   while (my $in=<OPTIMIZED>) {
#     if (defined $in) {
#       if ($in =~ /[0-9]/) {
# 	if ($in =~ /(\S+)\t(\S+)\t(\S+)\t(\S+)/) {
# 	  $opt_leafratiorange=$1;
# 	  $opt_leafratiothresh=$2;
# 	  $opt_linkedleafratiorange=$3;
# 	  $opt_linkedleafratiothresh=$4;
# #	  $opt_absheightthresh=$5;
# 	}
#       }
#     }
#   }
# }

getRuleKeys();

## getting all treebank and alignment statistics using objects STA and Treebank - not subroutined because we need the variables to be global

#print "man file: $opt_a\n";
#print "lingua file: $opt_A\n";

my $linktype; my $prob; my $link; my $author; my $slink; my $tlink;
my $man_alignments;
if ($opt_g) {
  $man_alignments=new STA(-filehandle=>"AIN",-file=>$opt_a);
  $opt_a=$man_alignments->getFile();
## basic alignment statistics
 ($linktype, $prob, $link, $author, $slink, $tlink)=$man_alignments->getStats($opt_a);
}

my $auto_alignments=new STA(-filehandle=>"AIN",-file=>$opt_A);
$opt_A=$auto_alignments->getFile();

(my $strees, my $sids, my $sword, my $spos, my $stype, my $scat, my $sterms, my $snonterms, my $ssentids, my $sparent, my $schildren, my $schildrenposition, my $sleaves, my $sedge, my $sheight, my $smaxheight, my $snodesonheight, my $src_has_nonterminal_unary_daughter, my $src_has_nonterminal_unary_daughter_except_punct);
(my $ttrees, my $tids, my $tword, my $tpos, my $ttype, my $tcat, my $tterms, my $tnonterms, my $tsentids, my $tparent, my $tchildren, my $tchildrenposition, my $tleaves, my $tedge, my $theight, my $tmaxheight, my $tnodesonheight, my $trg_has_nonterminal_unary_daughter, my $trg_has_nonterminal_unary_daughter_except_punct);

print "Getting statistics...\n";

if ($srcstats_exists == 0) { ## if the source treebank statistics file doesn't already exist, we read them from the treebanks
  $strees=new Treebank(-filehandle=>"SIN",-file=>$opt_s);
  $opt_s=$strees->getFile('s');
  ($sids, $sword, $spos, $stype, $scat, $sterms, $snonterms, $ssentids, $sparent, $schildren, $schildrenposition, $sleaves, $sedge, $sheight, $smaxheight, $snodesonheight, $src_has_nonterminal_unary_daughter, $src_has_nonterminal_unary_daughter_except_punct)=$strees->getAllStats($opt_s);
}
 else {
   ($sids, $sword, $spos, $stype, $scat, $sterms, $snonterms, $ssentids, $sparent, $schildren, $schildrenposition, $sleaves, $sedge, $sheight, $smaxheight, $snodesonheight, $src_has_nonterminal_unary_daughter, $src_has_nonterminal_unary_daughter_except_punct)=readStats('s');
#   print "size of spos: ".keys(%$spos)."\n";
  #print "size of src_has_nonterminal_unary_daughter_except_punct: ".keys(%$src_has_nonterminal_unary_daughter_except_punct)."\n";
 }

if ($trgstats_exists == 0) {
  $ttrees=new Treebank(-filehandle=>"TIN",-file=>$opt_t);
  $opt_t=$ttrees->getFile('t');
  ($tids, $tword, $tpos, $ttype, $tcat, $tterms, $tnonterms, $tsentids, $tparent, $tchildren, $tchildrenposition, $tleaves, $tedge, $theight, $tmaxheight, $tnodesonheight, $trg_has_nonterminal_unary_daughter, $trg_has_nonterminal_unary_daughter_except_punct)=$ttrees->getAllStats($opt_t);
}
else {
  ($tids, $tword, $tpos, $ttype, $tcat, $tterms, $tnonterms, $tsentids, $tparent, $tchildren, $tchildrenposition, $tleaves, $tedge, $theight, $tmaxheight, $tnodesonheight, $trg_has_nonterminal_unary_daughter, $trg_has_nonterminal_unary_daughter_except_punct)=readStats('t');
#   print "size of tleaves: ".keys(%$tleaves)."\n";
#  print "size of trg_has_nonterminal_unary_daughter_except_punct: ".keys(%$trg_has_nonterminal_unary_daughter_except_punct)."\n";
}

## basic alignment statistics
(my $llinktype, my $lprob, my $llink, my $lauthor, my $lslink, my $ltlink)=$auto_alignments->getStats($opt_A);

my $rulestats;
## for this, we first need to read the treebank statistics from the tree stats files if they existed before
$rulestats=new Rulestats(-sword=>$sword,-tword=>$tword,-schildren=>$schildren,-tchildren=>$tchildren,-sleaves=>$sleaves,-tleaves=>$tleaves,-scat=>$scat,-tcat=>$tcat,-slink=>$lslink,-tlink=>$ltlink,-sparent=>$sparent,-tparent=>$tparent,-stype=>$stype,-ttype=>$ttype,-linktype=>$llinktype);
(my $cursent_s, my $cursent_t, my $snonterm, my $tnonterm, my $curlink);
(my $wfgood, my $wffuzzy, my $wfgood_nopunct, my $wffuzzy_nopunct, my $wfnonterm, my $absheightdiff);

my $norules=0; ## set this to 1 if no rules can be found, so we can delete $bestrulefile

getRuleStats(); ## get rule statistics based on treebank and alignment statistics
printTreeStats(); ## print treebank statistics to output files
printAlignStats(); ## print alignment statistics to output files
if ($opt_g) {
  iterate(); ## for every found rule, iterate through nonterminal combinations and keep track of whether they can be applied or not. We do this for both the gold standard and the Lingua Align file.
  getBestRule(); ## Now we have correct and incorrect counts for all rules and for both actions, ADD and REMOVE. We proceed to iterate the counts and choose the one with the best performance and print it to output.
}

sub getBestRule {

    my $bestdiff=0;
    my $bestrule="";

   for (my $i=0; $i<@addrules; $i++) {
     unless (defined $correct{$addrules[$i]}) {
       $correct{$addrules[$i]}=0;
     }
     unless (defined $incorrect{$addrules[$i]}) {
       $incorrect{$addrules[$i]}=0;
     }
#     print "$addrules[$i]\tADD\t$correct{$addrules[$i]}\t$incorrect{$addrules[$i]}\n";
#     	if ($addrules[$i] =~ "0000000001100000") {
#        print "Rule: $addrules[$i]\n\t";
#        print "Correct: $correct{$addrules[$i]} and incorrect: $incorrect{$addrules[$i]}\n";
#   }
     if ($correct{$addrules[$i]}-$incorrect{$addrules[$i]} > $bestdiff) {
       $bestdiff=$correct{$addrules[$i]}-$incorrect{$addrules[$i]};
       $bestrule=$addrules[$i]."\t$correct{$addrules[$i]}\t$incorrect{$addrules[$i]}\t$bestdiff";
     }
   }

   for (my $i=0; $i<@removerules; $i++) {
     unless (defined $correct{$removerules[$i]}) {
       $correct{$removerules[$i]}=0;
     }
     unless (defined $incorrect{$removerules[$i]}) {
       $incorrect{$removerules[$i]}=0;
     }
  #   	if ($removerules[$i] eq "0000000001100000") {
   #    print "Rule: $removerules[$i]\n\t";
   #    print "Correct: $correct{$removerules[$i]} and incorrect: $incorrect{$removerules[$i]}\n";
  # }
     if ($correct{$removerules[$i]}-$incorrect{$removerules[$i]} > $bestdiff) {
       $bestdiff=$correct{$removerules[$i]}-$incorrect{$removerules[$i]};
       $bestrule=$removerules[$i]."\t$correct{$removerules[$i]}\t$incorrect{$removerules[$i]}\t$bestdiff";
     }
   }
   
   if (($norules == 0) && ($bestrule ne "")) {
#     print "Best rule: $bestrule\n";
     print BESTRULE "$bestrule\n";
   }
   elsif ($norules == 1) {
     print "No best rule found!\n";
     qx(rm $bestrulefile);
   }
   else {
     qx(rm $bestrulefile);
     die("No best rule found!\n");
   }

}

sub iterate { ## if -g is specified and we are looking for a best rule
# 	unless (defined $linkrulecount{$fullrule}) {
# 	  $linkrulecount{$fullrule}=0;
# 	  $linkrulecounts{$fullrule}{0}=$curlink;
# 	}
# 	else {
# 	  $linkrulecount{$fullrule}++;
# 	  $linkrulecounts{$fullrule}{$linkrulecount{$fullrule}}=$curlink;
# 	}
  (my $currule, my $curlink, my $curcount, my $fullrule);
  for (my $i=0; $i<@fullrule; $i++) {
    if ($fullrule[$i] =~ /\t(.*)/) {
      $currule=$1;
#      print "fullrule of $i: $fullrule[$i] and currule: $currule\n";
    }
    else { die ("Unexpected \"fullrule\" variable content! ($fullrule[$i])"); }
    if (defined $linkrulecounts{$currule}) {
#      print "linkrulecounts of $currule is defined\n";
      foreach (keys %{$linkrulecounts{$currule}}) { ## iterating through counts (total number of times $currule could have been applied)
	$fullrule=$fullrule[$i];
	$curcount=$_;
#	print "$fullrule\t$curcount\n";
	$curlink=$linkrulecounts{$currule}{$_}; ## for a specific number in the count, we have a specific node pair when it could have been applied
## Now we check if $curlink is linked or not, and we check the same in the gold standard. If one is linked and the other one is not, then the rule is successful, since after application of the rule they are the same. We can add one to "correct" for this rule, and either add the value ADD or REMOVE depending on what we did with the Lingua Align (automatic output) node pair. If not, we add one to "incorrect" for this rule.
## llinktype is automatic output (Lingua Align) and linktype is manual output (gold standard). Checking if the link type exists is for practical purposes the same as checking if the link itself exists.
#print "fullrule: $fullrule\tcurcount: $curcount\tcurlink: $curlink\n";
	if (defined $$llinktype{$curlink}) {
	   if (defined $$linktype{$curlink}) { ## the link exists in both the automatic and the manual data sets - application of the rule (REMOVE) would be incorrect.
	    $fullrule=$fullrule."\tREMOVE";
	    if (defined $incorrect{$fullrule}) {
	      $incorrect{$fullrule}++;
	    }
	    else {
	      $incorrect{$fullrule}=1;
	    }
	   }
	   else { ## the automatic link exists but the manual link doesn't. Therefore application of the rule would REMOVE an alignment which is correct in this case.
	     $fullrule=$fullrule."\tREMOVE";
	     if (defined $correct{$fullrule}) {
	       $correct{$fullrule}++;
	     }
	     else {
	       $correct{$fullrule}=1;
	     }
	   }
	}
	else {
	   if (defined $$linktype{$curlink}) { ## the automatic link does not exist but the manual link does. Therefore application of the rule would ADD an alignment which is correct in this case.
	    $fullrule=$fullrule."\tADD";
	    if (defined $incorrect{$fullrule}) {
	      $correct{$fullrule}++;
	    }
	    else {
	      $correct{$fullrule}=1;
	    }
	   }
	   else { ## Both links do not exist. Therefore application of the rule would ADD an alignment which is incorrect in this case.
	     $fullrule=$fullrule."\tADD";
	     if (defined $incorrect{$fullrule}) {
	       $incorrect{$fullrule}++;
	     }
	     else {
	       $incorrect{$fullrule}=1;
	     }
# 	     if ($fullrule =~ /^0\t/) {
# 	       print "Rule 0 - curlink $curlink. Does not exist in both treebanks\n";
# 	     }
	   }
	}
	if ($fullrule =~ /ADD/) {
	  unless (defined $addrules_exist{$fullrule}) {
	    $addrules_exist{$fullrule}=1;
	    push(@addrules,$fullrule);
	  }
	}
	elsif ($fullrule =~ /REMOVE/) {
	  unless (defined $removerules_exist{$fullrule}) {
	    $removerules_exist{$fullrule}=1;
	    push(@removerules,$fullrule);
	  }
	}
#	print "$fullrule\n";
      }
    }
  }
}

sub getRuleStats {

(my %sleavesprinted, my %tleavesprinted, my %src_unary, my %trg_unary, my %src_unary_punct, my %trg_unary_punct, my %tsentidsprinted) =((),(),(),(),());
my $fullrule; my $sign; my $threshold; my $minthresh; my $maxthresh; my $range_exists; my $difference; my $ratio; my $has_nonwf_stats;
my $sleafcount; my $tleafcount; my $totalleafcount; my $total; my $leafratio; my $linkedleafratio; my $linkedleafcount; my $similarityrange; my $leafratioscore; my $linkedleafratioscore; my $source_has_special; my $target_has_special; my $geolinkedleafsimilarityscore; my $geoleafsimilarityscore;


# if (defined $opt_o) {
#   $leafratiorange=$opt_leafratiorange;
# }
# else {
#   $leafratiorange=80;
# }
# if (defined $opt_o) {
#   $linkedleafratiorange=$opt_linkedleafratiorange;
# }
# else {
#   $linkedleafratiorange=80;
# }

for (my $i=0; $i<@{$ssentids}; $i++) { ## assuming ssentids and tsentids have the same size, which they should
#  print "sentid $i\n";
  if ((defined $$ssentids[$i]) && (defined $$tsentids[$i])) {
    $cursent_s=$$ssentids[$i];
    $cursent_t=$$tsentids[$i];
    if ($srcstats_exists == 0) {
      print SRCTREESTATS "SENTID\t$i\t$cursent_s\n";
    }
#    print "Extracting well-formedness and threshold statistics from sentences $cursent_s and $cursent_t...\n";
    if ((defined $cursent_s) && (defined $cursent_t)) {
      foreach (@{$$snonterms{$cursent_s}}) {
	     $snonterm=$_;
	     $sleafcount=0;
	     if (defined $$sleaves{$snonterm}) {
	       foreach (@{$$sleaves{$snonterm}}) {
		 $sleafcount++;
	       }
	     }
	     else { warn ("No leaves defined for target node $tnonterm!"); }

	     if ($trgstats_exists == 0) {
	       unless (defined $tsentidsprinted{$cursent_t}) {
		 print TRGTREESTATS "SENTID\t$i\t$cursent_t\n";
		 $tsentidsprinted{$cursent_t}=1;
	       }
	     }

	     foreach (@{$$tnonterms{$cursent_t}}) { ## for each nonterminal node on the source side, investigate every nonterminal node on the target side and extract statistics concerning this node pair
	       $tnonterm=$_;
	       $curlink=$snonterm."__".$tnonterm;
	       $fullrule="";
	       $has_nonwf_stats=0;
	       $tleafcount=0;
	       if (defined $$tleaves{$tnonterm}) {
		 foreach (@{$$tleaves{$tnonterm}}) {
		   $tleafcount++;
		 }
	       }
	       else { warn ("No leaves defined for source node $snonterm!"); }
	       
        $totalleafcount=$sleafcount+$tleafcount;

         if ($getleafratio == 1) {
## get linked leaf stats
          $leafratio=$rulestats->getLeafRatio($snonterm,$tnonterm,$sleafcount,$tleafcount);
         }

         if ($getlinkedleafratio == 1) {
    	       ($linkedleafratio,$linkedleafcount)=$rulestats->getLinkedLeafRatio($snonterm,$tnonterm);
#	       print "llr: $linkedleafratio\n";
          }

	       if ($srcstats_exists == 0) {
		 unless (defined $sleavesprinted{$snonterm}) {
		   for (my $j=0; $j<@{$$sleaves{$snonterm}}; $j++) {
		     if (defined $$sleaves{$snonterm}[$j]) {
		       print SRCTREESTATS "LEAVES\t$snonterm\t$j\t$$sleaves{$snonterm}[$j]\n";
		     }
		     $sleavesprinted{$snonterm}=1;
		   }
		 }
	       }
	       
	       if ($trgstats_exists == 0) {
		 unless (defined $tleavesprinted{$tnonterm}) {
		   for (my $j=0; $j<@{$$tleaves{$tnonterm}}; $j++) {
		     if (defined $$tleaves{$tnonterm}[$j]) {
		       print TRGTREESTATS "LEAVES\t$tnonterm\t$j\t$$tleaves{$tnonterm}[$j]\n";
		     }
		     $tleavesprinted{$tnonterm}=1;
		   }
		 }
	       }
	       
	       if ($srcstats_exists == 0) {
		 unless (defined $src_unary{$snonterm}) {
		   if (defined $$src_has_nonterminal_unary_daughter{$snonterm}) {
		     print SRCTREESTATS "HAS_NONTERMINAL_UNARY_DAUGHTER\t$snonterm\t$$src_has_nonterminal_unary_daughter{$snonterm}\n";
		     $src_unary{$snonterm}=1;
		   }
		 }
	       }
	       
	       if ($trgstats_exists == 0) {
		 unless (defined $trg_unary{$tnonterm}) {
		   if (defined $$trg_has_nonterminal_unary_daughter{$tnonterm}) {
		     print TRGTREESTATS "HAS_NONTERMINAL_UNARY_DAUGHTER\t$tnonterm\t$$trg_has_nonterminal_unary_daughter{$tnonterm}\n";
		     $trg_unary{$tnonterm}=1;
		   }
		 }
	       }
	       
	       if ($srcstats_exists == 0) {
		 unless (defined $src_unary_punct{$snonterm}) {
		   if (defined $$src_has_nonterminal_unary_daughter_except_punct{$snonterm}) {
		     print SRCTREESTATS "HAS_NONTERMINAL_UNARY_DAUGHTER_EXCEPT_PUNCT\t$snonterm\t$$src_has_nonterminal_unary_daughter_except_punct{$snonterm}\n";
		     $src_unary_punct{$snonterm}=1;
		   }
		 }
	       }
	       if ($trgstats_exists == 0) {
		 unless (defined $trg_unary_punct{$tnonterm}) {
		   if (defined $$trg_has_nonterminal_unary_daughter_except_punct{$tnonterm}) {
		     print TRGTREESTATS "HAS_NONTERMINAL_UNARY_DAUGHTER_EXCEPT_PUNCT\t$tnonterm\t$$trg_has_nonterminal_unary_daughter_except_punct{$tnonterm}\n";
		     $trg_unary_punct{$tnonterm}=1;
		   }
		 }
	       }

	    foreach(@rulenumbers) {
	      $rulenumber=$_;
#	      print "rulenumber: $rulenumber\n";
	      
	      if (defined $rulekeys_number2key{$rulenumber}) {
		$rulekey=$rulekeys_number2key{$rulenumber};
#		print "$rulekey\n";
     
## Rule: source-has-nonterminal-unary-daughter
	       if ($rulekey =~ /source-has-nonterminal-unary-daughter$/) {
		if (defined $$src_has_nonterminal_unary_daughter{$snonterm}) {
#		  print RULESTATS "$rulenumber\t$curlink\t$$src_has_nonterminal_unary_daughter{$snonterm}\n";
		  $fullrule=$fullrule.$$src_has_nonterminal_unary_daughter{$snonterm};
		}
		else {
		  warn "No value for variable src_has_nonterminal_unary_daughter for source node $snonterm!";
		}
	       }

## Rule: target-has-nonterminal-unary-daughter
	       if ($rulekey =~ /target-has-nonterminal-unary-daughter$/) {
		if (defined $$trg_has_nonterminal_unary_daughter{$tnonterm}) {
#		  print RULESTATS "$rulenumber\t$curlink\t$$trg_has_nonterminal_unary_daughter{$tnonterm}\n";
		  $fullrule=$fullrule.$$trg_has_nonterminal_unary_daughter{$tnonterm};
		}
		else {
		  warn "No value for variable trg_has_nonterminal_unary_daughter for target node $tnonterm!";
		}
	       }

## Rule: source-has-nonterminal-unary-daughter-except-punct
	       if ($rulekey =~ /source-has-nonterminal-unary-daughter-except-punct/) {
		if (defined $$src_has_nonterminal_unary_daughter_except_punct{$snonterm}) {
#		  print RULESTATS "$rulenumber\t$curlink\t$$src_has_nonterminal_unary_daughter_except_punct{$snonterm}\n";
		  $fullrule=$fullrule.$$src_has_nonterminal_unary_daughter_except_punct{$snonterm};
		}
		else {
		  warn "No value for variable src_has_nonterminal_unary_daughter-except-punct for source node $snonterm!";
		}
	       }

## Rule: target-has-nonterminal-unary-daughter-except-punct
	       if ($rulekey =~ /target-has-nonterminal-unary-daughter-except-punct/) {
		if (defined $$trg_has_nonterminal_unary_daughter_except_punct{$tnonterm}) {
#		  print RULESTATS "$rulenumber\t$curlink\t$$trg_has_nonterminal_unary_daughter_except_punct{$tnonterm}\n";
		  $fullrule=$fullrule.$$trg_has_nonterminal_unary_daughter_except_punct{$tnonterm};
		}
		else {
		  warn "No value for variable trg_has_nonterminal_unary_daughter-except-punct for target node $tnonterm!";
		}
	       }

	       if (($rulekey =~ /nonwellformed__/) && ($has_nonwf_stats == 0)) {

		($wfgood,$wffuzzy,$wfgood_nopunct,$wffuzzy_nopunct,$wfnonterm)=$rulestats->getWellformednessStats($snonterm,$tnonterm);
		$has_nonwf_stats=1;
	       }

## Rules: nonwellformed__gcount
		if ($rulekey =~ /nonwellformed__gcount(\S{1,2})([0-9]+)/) {
		  $sign=$1;
		  $threshold=$2;
      $range_exists=0;
		  if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0-2, 0 is included but not 2, because count is never more than 0. Therefore the lower value is always included but not the higher value.
		    $minthresh=$1;
		    $maxthresh=$2;
		    $range_exists=1;
		  }
		  if ($sign eq ">") {
		    if ($wfgood > $threshold) {
			  $fullrule=$fullrule."1";
		    }
		    else {
			  $fullrule=$fullrule."0";
		    }
		  }
      if ($sign eq ">=") {
        if ($wfgood >= $threshold) {
        $fullrule=$fullrule."1";
        }
        else {
        $fullrule=$fullrule."0";
        }
      }
		  elsif ($sign eq "<") {
		    if ($wfgood < $threshold) {
			  $fullrule=$fullrule."1";
		    }
		    else {
			  $fullrule=$fullrule."0";
		    }
		  }
      elsif ($sign eq "<=") {
        if ($wfgood <= $threshold) {
        $fullrule=$fullrule."1";
        }
        else {
        $fullrule=$fullrule."0";
        }
      }
		  elsif ($sign eq "=") {
		    if ($range_exists == 1) {
		      if (($wfgood >= $minthresh) && ($wfgood < $maxthresh)) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    else {
		      if($wfgood == $threshold) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		  }

		} ## if ($rulekey =~ /nonwellformed__gcount(\S{1,2})([0-9]+)/) {

## now exactly the same but with fcount
		if ($rulekey =~ /nonwellformed__fcount(\S{1,2})([0-9]+)/) {
		  $sign=$1;
		  $threshold=$2;
      $range_exists=0;
		  if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0-2, 0 is included but not 2, because count is never more than 0. Therefore the lower value is always included but not the higher value.
		    $minthresh=$1;
		    $maxthresh=$2;
		    $range_exists=1;
		  }
		  if ($sign eq ">") {
		    if ($wffuzzy > $threshold) {
			  $fullrule=$fullrule."1";
		    }
		    else {
			  $fullrule=$fullrule."0";
		    }
		  }
      elsif ($sign eq ">=") {
        if ($wffuzzy >= $threshold) {
        $fullrule=$fullrule."1";
        }
        else {
        $fullrule=$fullrule."0";
        }
      }
		  elsif ($sign eq "<") {
		    if ($wffuzzy < $threshold) {
			  $fullrule=$fullrule."1";
		    }
		    else {
			  $fullrule=$fullrule."0";
		    }
		  }
      elsif ($sign eq "<=") {
        if ($wffuzzy <= $threshold) {
        $fullrule=$fullrule."1";
        }
        else {
        $fullrule=$fullrule."0";
        }
      }
		  elsif ($sign eq "=") {
		    if ($range_exists == 1) {
		      if (($wffuzzy >= $minthresh) && ($wffuzzy < $maxthresh)) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    else {
		      if($wffuzzy == $threshold) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		  }

		} ## if ($rulekey =~ /nonwellformed__fcount(\S{1,2})([0-9]+)/) {

## and with ncount
		if ($rulekey =~ /nonwellformed__ncount(\S{1,2})([0-9]+)/) {
		  $sign=$1;
		  $threshold=$2;
      $range_exists=0;
		  if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0-2, 0 is included but not 2, because count is never more than 0. Therefore the lower value is always included but not the higher value.
		    $minthresh=$1;
		    $maxthresh=$2;
		    $range_exists=1;
		  }
		  if ($sign eq ">") {
		    if ($wfnonterm > $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
      if ($sign eq ">=") {
        if ($wfnonterm >= $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
		  elsif ($sign eq "<") {
		    if ($wfnonterm < $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
      elsif ($sign eq "<=") {
        if ($wfnonterm <= $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
		  elsif ($sign eq "=") {
		    if ($range_exists == 1) {
		      if (($wfnonterm >= $minthresh) && ($wfnonterm < $maxthresh)) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    else {
		      if($wfnonterm == $threshold) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		  }

		} ## if ($rulekey =~ /nonwellformed__ncount(\S{1,2})([0-9]+)/) {
		
## and now exactly the same but with punct - TO DO: compress all these into a subroutine

## Rules: nonwellformed__gcount__nopunct
		if ($rulekey =~ /nonwellformed__gcount__nopunct(\S*)([0-9]+)/) {
		  $sign=$1;
		  $threshold=$2;
		  $range_exists=0;
		  if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0-2, 0 is included but not 2, because count is never more than 0. Therefore the lower value is always included but not the higher value.
		    $minthresh=$1;
		    $maxthresh=$2;
		    $range_exists=1;
		  }
		  if ($sign eq ">") {
		    if ($wfgood_nopunct > $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq "<") {
		    if ($wfgood_nopunct < $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq "=") {
		    if ($range_exists == 1) {
		      if (($wfgood_nopunct >= $minthresh) && ($wfgood_nopunct < $maxthresh)) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    else {
		      if($wfgood_nopunct == $threshold) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		  }
		} ## if ($rulekey =~ /nonwellformed__gcount__nopunct(\S*)([0-9]+)/) {

## nonwellformed__fcount__nopunct
		if ($rulekey =~ /nonwellformed__fcount__nopunct(\S*)([0-9]+)/) {
		  $sign=$1;
		  $threshold=$2;
		  $range_exists=0;
		  if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0-2, 0 is included but not 2, because count is never more than 0. Therefore the lower value is always included but not the higher value.
		    $minthresh=$1;
		    $maxthresh=$2;
		    $range_exists=1;
		  }
		  if ($sign eq ">") {
		    if ($wffuzzy_nopunct > $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq "<") {
		    if ($wffuzzy_nopunct < $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq "=") {
		    if ($range_exists == 1) {
		      if (($wffuzzy_nopunct >= $minthresh) && ($wffuzzy_nopunct < $maxthresh)) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    else {
		      if ($wffuzzy_nopunct == $threshold) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		  }
		  
		} ## if ($rulekey =~ /nonwellformed__fcount__nopunct(\S*)([0-9]+)/) {

## Rule: leaf-ratio
	      if ($rulekey =~ /^leaf-ratio(\S{1,2})([0-9]+.*)/) { ## matches greedily from the first number onwards to get ranges such as 0.8-1
		  $sign=$1;
		  $threshold=$2;
#		  print "$rulekey\tsign: $sign threshold: $threshold\n";
		  $range_exists=0;
		  if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0.8-1, 1 is included but not 0.8, because ratio is never more than 1. Therefore the higher value is always included but not the lower value.
		    $minthresh=$1;
		    $maxthresh=$2;
		    $range_exists=1;
		  }
		  if ($sign eq "=") {
		    if ($range_exists == 1) {
		      if (($minthresh < $leafratio) && ($maxthresh >= $leafratio)) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    else {
		      if ($threshold == $leafratio) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		  }
		  elsif ($sign eq "<") {
		    if ($leafratio < $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq ">") {
		    if ($leafratio > $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq "<=") {
		    if ($leafratio <= $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq ">=") {
		    if ($leafratio >= $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  
		} ## if ($rulekey =~ /^leaf-ratio([^[0-9]*?)([0-9]+.*)/) {

      if ($rulekey =~ /^leaf-ratio-score(\D+)(.*?);range=([0-9]+)/) {
        $sign=$1;
        $threshold=$2;
        $similarityrange=$3;
        $range_exists=0;
#        print "$sign\t$threshold\t$similarityrange";
        if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0.8-1, 1 is included but not 0.8, because a similarity score is never more than 1. Therefore the higher value is always included but not the lower value.
          $minthresh=$1;
          $maxthresh=$2;
          $range_exists=1;
        }
        $leafratioscore=$rulestats->getLeafRatioScore($snonterm,$tnonterm,$sleafcount,$tleafcount,$similarityrange);
#         print $snonterm."__".$tnonterm."\trange: $similarityrange\tscore: $leafratioscore\n";
             if ($sign eq "=") {
        if ($range_exists == 1) {
          if (($minthresh < $leafratioscore) && ($maxthresh >= $leafratioscore)) {
      $fullrule=$fullrule."1";
          }
          else {
      $fullrule=$fullrule."0";
          }
        }
        else {
          if ($threshold == $leafratioscore) {
      $fullrule=$fullrule."1";
          }
          else {
      $fullrule=$fullrule."0";
          }
        }
      }
      elsif ($sign eq "<") {
        if ($leafratioscore < $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      elsif ($sign eq ">") {
        if ($leafratioscore > $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      elsif ($sign eq "<=") {
        if ($leafratioscore <= $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      elsif ($sign eq ">=") {
        if ($leafratioscore >= $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      
    } ## if ($rulekey =~ /^leaf-ratio-score(\D+)(.*?);range=([0-9]+)/) {

      if ($rulekey =~ /^linkedleaf-ratio-score(\D+)(.*?);range=([0-9]+)/) {
        $sign=$1;
        $threshold=$2;
        $similarityrange=$3;
        $range_exists=0;
#        print "$sign\t$threshold\t$similarityrange";
        if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0.8-1, 1 is included but not 0.8, because a similarity score is never more than 1. Therefore the higher value is always included but not the lower value.
          $minthresh=$1;
          $maxthresh=$2;
          $range_exists=1;
        }
        $linkedleafratioscore=$rulestats->getLinkedLeafRatioScore($snonterm,$tnonterm,$linkedleafcount,$totalleafcount,$similarityrange);
#         print $snonterm."__".$tnonterm."\trange: $similarityrange\tscore: $leafratioscore\n";
             if ($sign eq "=") {
        if ($range_exists == 1) {
          if (($minthresh < $leafratioscore) && ($maxthresh >= $leafratioscore)) {
      $fullrule=$fullrule."1";
          }
          else {
      $fullrule=$fullrule."0";
          }
        }
        else {
          if ($threshold == $leafratioscore) {
      $fullrule=$fullrule."1";
          }
          else {
      $fullrule=$fullrule."0";
          }
        }
      }
      elsif ($sign eq "<") {
        if ($leafratioscore < $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      elsif ($sign eq ">") {
        if ($leafratioscore > $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      elsif ($sign eq "<=") {
        if ($leafratioscore <= $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      elsif ($sign eq ">=") {
        if ($leafratioscore >= $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }

    } ## if ($rulekey =~ /^linkedleaf-ratio-score(\D+)(.*?);range=([0-9]+)/) {
    
## Rule: geometric average of leaf count and leaf count difference
      if ($rulekey =~ /^geo-leaf-ratio-score(\D+)(\S+)/) {
        $sign=$1;
        $threshold=$2;
        $range_exists=0;
        $geoleafsimilarityscore=$rulestats->getGeoScore($snonterm,$tnonterm,$sleafcount,$tleafcount);
        if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0.8-1, 1 is included but not 0.8, because a similarity score is never more than 1. Therefore the higher value is always included but not the lower value.
          $minthresh=$1;
          $maxthresh=$2;
          $range_exists=1;
        }
              if ($sign eq "=") {
        if ($range_exists == 1) {
          if (($minthresh < $geoleafsimilarityscore) && ($maxthresh >= $geoleafsimilarityscore)) {
      $fullrule=$fullrule."1";
          }
          else {
      $fullrule=$fullrule."0";
          }
        }
        else {
          if ($threshold == $geoleafsimilarityscore) {
      $fullrule=$fullrule."1";
          }
          else {
      $fullrule=$fullrule."0";
          }
        }
      }
      elsif ($sign eq "<") {
        if ($geoleafsimilarityscore < $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      elsif ($sign eq ">") {
        if ($geoleafsimilarityscore > $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      elsif ($sign eq "<=") {
        if ($geoleafsimilarityscore <= $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      elsif ($sign eq ">=") {
        if ($geoleafsimilarityscore >= $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      
    }


## Rule: geometric average of well-formed linked leaf count and difference between linked leaf count and total leaf count
      if ($rulekey =~ /^geo-linkedleaf-ratio-score(\D+)(\S+)/) {
        $sign=$1;
        $threshold=$2;
        $range_exists=0;
        $geolinkedleafsimilarityscore=$rulestats->getGeoScore($snonterm,$tnonterm,$linkedleafcount,$totalleafcount);
        if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0.8-1, 1 is included but not 0.8, because a similarity score is never more than 1. Therefore the higher value is always included but not the lower value.
          $minthresh=$1;
          $maxthresh=$2;
          $range_exists=1;
        }
              if ($sign eq "=") {
        if ($range_exists == 1) {
          if (($minthresh < $geolinkedleafsimilarityscore) && ($maxthresh >= $geolinkedleafsimilarityscore)) {
      $fullrule=$fullrule."1";
          }
          else {
      $fullrule=$fullrule."0";
          }
        }
        else {
          if ($threshold == $geolinkedleafsimilarityscore) {
      $fullrule=$fullrule."1";
          }
          else {
      $fullrule=$fullrule."0";
          }
        }
      }
      elsif ($sign eq "<") {
        if ($geolinkedleafsimilarityscore < $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      elsif ($sign eq ">") {
        if ($geolinkedleafsimilarityscore > $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      elsif ($sign eq "<=") {
        if ($geolinkedleafsimilarityscore <= $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      elsif ($sign eq ">=") {
        if ($geolinkedleafsimilarityscore >= $threshold) {
          $fullrule=$fullrule."1";
        }
        else {
          $fullrule=$fullrule."0";
        }
      }
      
    }

## Rule: leafcount-total
	      if ($rulekey =~ /^leafcount-total(\S*?)([0-9]+.*)/) { ## matches greedily from the first number onwards to get ranges such as 0.8-1
		  $sign=$1;
		  $threshold=$2;
		  $range_exists=0;
		  if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0-2, 0 is included but not 2, because difference is never less than 0. Therefore the lower value is always included but not the higher value.
		    $minthresh=$1;
		    $maxthresh=$2;
		    $range_exists=1;
		  }
		  $total=$totalleafcount;
		  if ($sign eq "=") {
		    if ($range_exists == 1) {
		      if (($minthresh <= $total) && ($maxthresh > $total)) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    else {
		      if ($threshold == $total) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		  }
		  elsif ($sign eq "<") {
		    if ($total < $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq ">") {
		    if ($total > $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq "<=") {
		    if ($total <= $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq ">=") {
		    if ($total >= $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  
		}

	      if ($rulekey =~ /^leafcount-diff(\S*?)([0-9]+.*)/) { ## matches greedily from the first number onwards to get ranges such as 0.8-1
		  $sign=$1;
		  $threshold=$2;
		  $range_exists=0;
		  if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0-2, 0 is included but not 2, because difference is never less than 0. Therefore the lower value is always included but not the higher value.
		    $minthresh=$1;
		    $maxthresh=$2;
		    $range_exists=1;
		  }
		  $difference=abs($sleafcount-$tleafcount);
		  if ($sign eq "=") {
		    if ($range_exists == 1) {
		      if (($minthresh <= $difference) && ($maxthresh > $difference)) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    else {
		      if ($threshold == $difference) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		  }
		  elsif ($sign eq "<") {
		    if ($difference < $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq ">") {
		    if ($difference > $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq "<=") {
		    if ($difference <= $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq ">=") {
		    if ($difference >= $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  
		} ## if ($rulekey =~ /^leaf-ratio([^[0-9]*?)([0-9]+.*)/) {
		

## Rule: linked-leaf-ratio
	      if ($rulekey =~ /^linkedleaf-ratio(\S*?)([0-9]+.*)/) { ## matches greedily from the first number onwards to get ranges such as 0.8-1
		  $sign=$1;
		  $threshold=$2;
		  $range_exists=0;
		  if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0.8-1, 1 is included but not 0.8, because ratio is never more than 1. Therefore the higher value is always included but not the lower value.
		    $minthresh=$1;
		    $maxthresh=$2;
		    $range_exists=1;
		  }
		  if ($sign eq "=") {
		    if ($range_exists == 1) {
		      if (($minthresh < $linkedleafratio) && ($maxthresh >= $linkedleafratio)) {
      			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    else {
		      if ($threshold == $linkedleafratio) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		  }
		  elsif ($sign eq "<") {
		    if ($linkedleafratio < $threshold) {
			$fullrule=$fullrule."1";
		    }
		    else {
			  $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq ">") {
		    if ($linkedleafratio > $threshold) {
			$fullrule=$fullrule."1";
		    }
		    else {
			$fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq "<=") {
		    if ($linkedleafratio <= $threshold) {
			$fullrule=$fullrule."1";
		    }
		    else {
			$fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq ">=") {
		    if ($linkedleafratio >= $threshold) {
			$fullrule=$fullrule."1";
		    }
		    else {
			$fullrule=$fullrule."0";
		    }
		  }
		  
		}

## Rule: linkedleafcount-total
	      if ($rulekey =~ /^linkedleafcount-total(\S*?)([0-9]+.*)/) { ## matches greedily from the first number onwards to get ranges such as 0.8-1
		  $sign=$1;
		  $threshold=$2;
		  $range_exists=0;
		  if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0-2, 0 is included but not 2, because difference is never less than 0. Therefore the lower value is always included but not the higher value.
		    $minthresh=$1;
		    $maxthresh=$2;
		    $range_exists=1;
		  }
		  $total=$totalleafcount;
		  if ($sign eq "=") {
		    if ($range_exists == 1) {
		      if (($minthresh <= $linkedleafcount) && ($maxthresh > $linkedleafcount)) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    else {
		      if ($threshold == $linkedleafcount) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		  }
		  elsif ($sign eq "<") {
		    if ($linkedleafcount < $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq ">") {
		    if ($linkedleafcount > $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq "<=") {
		    if ($linkedleafcount <= $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  elsif ($sign eq ">=") {
		    if ($linkedleafcount >= $threshold) {
		      $fullrule=$fullrule."1";
		    }
		    else {
		      $fullrule=$fullrule."0";
		    }
		  }
		  
		}

## Rules: abs-height-diff
	      if ($rulekey =~ /^abs-height-diff([^[0-9]*?)([0-9]+.*)/) {
		$sign=$1;
		$threshold=$2;
		$range_exists=0;
		if ($threshold =~ /(\S+)-(\S+)/) { ## if we have something like 0-2, 0 is included but not 2, because difference is never less than 0. Therefore the lower value is always included but not the higher value.
		  $minthresh=$1;
		  $maxthresh=$2;
		  $range_exists=1;
		}
		if (defined $$sheight{$snonterm}) {
		  if (defined $$theight{$tnonterm}) {
		    $difference=abs($$sheight{$snonterm}-$$theight{$tnonterm});
		    
		    if ($sign eq "=") {
		      if ($range_exists == 1) {
			if (($minthresh <= $difference) && ($maxthresh > $difference)) {
			  $fullrule=$fullrule."1";
			}
			else {
			  $fullrule=$fullrule."0";
			}
		      }
		      else {
			if ($threshold == $difference) {
			  $fullrule=$fullrule."1";
			}
			else {
			  $fullrule=$fullrule."0";
			}
		      }
		    }
		    elsif ($sign eq "<") {
		      if ($difference < $threshold) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    elsif ($sign eq ">") {
		      if ($difference > $threshold) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    elsif ($sign eq "<=") {
		      if ($difference <= $threshold) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		    elsif ($sign eq ">=") {
		      if ($difference >= $threshold) {
			$fullrule=$fullrule."1";
		      }
		      else {
			$fullrule=$fullrule."0";
		      }
		    }
		  }
		}
	
	      } ## if ($rulekey =~ /^abs-height-diff([^[0-9]*?)([0-9]+.*)/) {

## Rule: $pos1=true__$pos2=false___OR___$pos1=false__$pos2=true
      if ($rulekey =~ /POSCOMBO:\s+(\S+)__(\S+)/) {
  		  $pos1=$1;
  		  $pos2=$2;
  		  ($pos1match,$pos2match)=$rulestats->getPOScombos($snonterm,$tnonterm,$sleaves,$tleaves,$spos,$tpos,$pos1,$pos2);
  		  if ((($pos1match == 0) && ($pos2match == 1)) || (($pos1match == 1) && ($pos2match == 0))) {
  		    $fullrule=$fullrule."1";
  		  }
  		  else {
  		    $fullrule=$fullrule."0";
  		  }

		  } ## if ($rulekey =~ /POSCOMBO:\s+(\S+)__(\S+)/) {

## Rule: source-target-has-only-one-capitalization
	     if ($rulekey =~ /source-target-has-only-one-capitalization/) {
	       ($source_has_caps,$target_has_caps)=$rulestats->getCapsCombos($snonterm,$tnonterm,$sleaves,$tleaves,$sword,$tword);
	       if ((($source_has_caps == 0) && ($target_has_caps == 1)) || (($source_has_caps == 1) && ($target_has_caps == 0))) {
		$fullrule=$fullrule."1";
	       }
	       else {
		$fullrule=$fullrule."0";
	       }
	   }
## Rule: source-target-has-only-one-number
	    if ($rulekey =~ /source-target-has-only-one-number/) {
	       ($source_has_number,$target_has_number)=$rulestats->getNumberCombos($snonterm,$tnonterm,$sleaves,$tleaves,$sword,$tword);
	       if ((($source_has_number == 0) && ($target_has_number == 1)) || (($source_has_number == 1) && ($target_has_number == 0))) {
		$fullrule=$fullrule."1";
	       }
	       else {
		$fullrule=$fullrule."0";
	       }
	   }
	   
## Rule: Node pair shares at least one identical word containing a number or capital letter
	  if ($rulekey =~ /share-identical-words-special/) {
	    if ($rulestats->shareIdenticalSpecialWords($snonterm,$tnonterm) == 1) {
	      $fullrule=$fullrule."1";
	    }
	    else {
	      $fullrule=$fullrule."0";
	    }
	  }

## sharing identical strings. Capitalization ignored.
	  if ($rulekey =~ /has-identical-strings/) {
	    if ($rulestats->hasIdenticalStrings($snonterm,$tnonterm) == 1) {
	      $fullrule=$fullrule."1";
	    }
	    else {
	      $fullrule=$fullrule."0";
	    }
	  }

## sharing good word alignments
	  if ($rulekey =~ /share-good-alignments/) {
	    if ($rulestats->shareGoodAlignments($snonterm,$tnonterm) == 1) {
	      $fullrule=$fullrule."1";
	    }
	    else {
	      $fullrule=$fullrule."0";
	    }
	  } ## if ($rulekey =~ /share-good-alignments/) {

## if a special character only occurs on one side
	  if ($rulekey =~ /has-special-character-one-side/) {
	    ($source_has_special,$target_has_special)=$rulestats->hasSpecialCharacterOneSide($snonterm,$tnonterm);
	    if ((($source_has_special == 0) && ($target_has_special == 1)) || (($source_has_special == 1) && ($target_has_special == 0))) {
	      $fullrule=$fullrule."1";
	    }
	    else {
	      $fullrule=$fullrule."0";
	    }
	  }

## if only punctuation occurs on either end at the source side
	  if ($rulekey =~ /source-has-punct-at-either-end/) {
	    if ($rulestats->hasPunctAtEitherEnd($snonterm,$tnonterm,'s') == 1) {
	      $fullrule=$fullrule."1";
	    }
	    else {
	      $fullrule=$fullrule."0";
	    }
	  }

## if only punctuation occurs on either end at the target side
	  if ($rulekey =~ /target-has-punct-at-either-end/) {
	    if ($rulestats->hasPunctAtEitherEnd($snonterm,$tnonterm,'t') == 1) {
	      $fullrule=$fullrule."1";
	    }
	    else {
	      $fullrule=$fullrule."0";
	    }
	  }

## if the words on both sides of the subtree spans (beginning or end) are linked well-formedly (not necessarily to each other)
	  if ($rulekey =~ /words-linked-both-ends/) {
	    if ($rulestats->wordsLinkedBothEnds($snonterm,$tnonterm,'t') == 1) {
	      $fullrule=$fullrule."1";
	    }
	    else {
	      $fullrule=$fullrule."0";
	    }
	  }


	   } ## if (defined $rulekeys_number2key{$rulenumber}) {
	   else { warn ("No rule associated with rule number $rulenumber!\n"); }
	 } ## foreach (@rulenumbers) {
	print RULESTATS "$curlink\t$fullrule\n";
	unless (defined $fullrule{$fullrule}) {
		push(@fullrule,$fullrule);
		$fullrule{$fullrule}=1;
	}
	unless (defined $linkrulecount{$fullrule}) {
	  $linkrulecount{$fullrule}=1;
	  $linkrulecounts{$fullrule}{1}=$curlink;
#	  print "linkrulecounts of fullrule $fullrule of count $linkrulecount{$fullrule} equals to link $curlink\n";
	}
	else {
	  $linkrulecount{$fullrule}++;
	  $linkrulecounts{$fullrule}{$linkrulecount{$fullrule}}=$curlink;
	}

	} ## foreach (@{$$tnonterms{$cursent_t}}) {
      } ## foreach (@{$$snonterms{$cursent_s}}) {
    } ## if ((defined $cursent_s) && (defined $cursent_t)) {
  } ## if ((defined $$ssentids[$i]) && (defined $$tsentids[$i])) {
} ## for (my $i=0; $i<@{$ssentids}; $i++) {

  my $size=@fullrule;
  if (@fullrule > 0) {
    for (my $i=0; $i<@fullrule; $i++) {
      $fullrule[$i]="$i\t$fullrule[$i]";
	if ($opt_g) {
	  print FOUNDRULES "$fullrule[$i]\n";
	}
    }
  }
  else {
    $norules=1;
  }
}



sub printTreeStats {

if ($srcstats_exists == 0) {
  foreach (keys %{$sids}) {
    print SRCTREESTATS "IDS\t$_\t$$sids{$_}\n";
  }
  foreach (keys %$spos) {
    print SRCTREESTATS "POS\t$_\t$$spos{$_}\n";
  }
  foreach (keys %$stype) {
    print SRCTREESTATS "TYPE\t$_\t$$stype{$_}\n";
  }
  foreach (keys %$scat) {
    print SRCTREESTATS "CAT\t$_\t$$scat{$_}\n";
  }
  foreach (keys %$sword) {
    print SRCTREESTATS "WORD\t$_\t$$sword{$_}\n";
  }
  foreach (keys %$sterms) {
    $index=0;
    $key="TERMS\t$_";
    foreach (@{$$sterms{$_}}) {
      $key2=$key."\t$index";
      print SRCTREESTATS "$key2\t$_\n";
      $index++;
    }
  }
  foreach (keys %$snonterms) {
    $index=0;
    $key="NONTERMS\t$_";
    foreach (@{$$snonterms{$_}}) {
      $key2=$key."\t$index";
      print SRCTREESTATS "$key2\t$_\n";
      $index++;
    }
  }
  foreach (keys %$sparent) {
    print SRCTREESTATS "PARENT\t$_\t$$sparent{$_}\n";
  }
  foreach (keys %$schildren) {
    $key=$_;
    foreach (keys %{$$schildren{$key}}) {
      $key2="CHILDREN\t$key\t$_";
      print SRCTREESTATS "$key2\t$$schildren{$key}{$_}\n";
    }
  }
  foreach (keys %$schildrenposition) {
    print SRCTREESTATS "CHILDRENPOSITION\t$_\t$$schildrenposition{$_}\n";
  }
  foreach (keys %$sedge) {
    print SRCTREESTATS "EDGE\t$_\t$$sedge{$_}\n";
  }
  foreach (keys %$sheight) {
    $key=$_;
    if (defined $$sheight{$key}) {
      print SRCTREESTATS "HEIGHT\t$key\t$$sheight{$key}\n";
    }
  }
  foreach (keys %$smaxheight) {
    $key=$_;
    if (defined $$smaxheight{$key}) {
      print SRCTREESTATS "MAXHEIGHT\t$key\t$$smaxheight{$key}\n";
    }
  }
  foreach (keys %$snodesonheight) {
    $key=$_;
    foreach (keys %{$$snodesonheight{$key}}) {
      $height=$_;
      $index=0;
      foreach(@{$$snodesonheight{$key}{$height}}) {
	print SRCTREESTATS "NODESONHEIGHT\t$key\t$height\t$index\t$_\n";
	$index++;
      }
    }
  }

} ## if ($srcstats_exists == 0) {

if ($trgstats_exists == 0) {

foreach (keys %$tids) {
  print TRGTREESTATS "IDS\t$_\t$$tids{$_}\n";
}
foreach (keys %$tpos) {
  print TRGTREESTATS "POS\t$_\t$$tpos{$_}\n";
}
foreach (keys %$ttype) {
  print TRGTREESTATS "TYPE\t$_\t$$ttype{$_}\n";
}
foreach (keys %$tcat) {
  print TRGTREESTATS "CAT\t$_\t$$tcat{$_}\n";
}
foreach (keys %$tword) {
  print TRGTREESTATS "WORD\t$_\t$$tword{$_}\n";
}
foreach (keys %$tterms) {
  $index=0;
  $key="TERMS\t$_";
  foreach (@{$$tterms{$_}}) {
    $key2=$key."\t$index";
    print TRGTREESTATS "$key2\t$_\n";
    $index++;
  }
}
foreach (keys %$tnonterms) {
  $index=0;
  $key="NONTERMS\t$_";
  foreach (@{$$tnonterms{$_}}) {
    $key2=$key."\t$index";
    print TRGTREESTATS "$key2\t$_\n";
    $index++;
  }
}
foreach (keys %$tparent) {
  print TRGTREESTATS "PARENT\t$_\t$$tparent{$_}\n";
}
foreach (keys %$tchildren) {
  $key=$_;
  foreach (keys %{$$tchildren{$key}}) {
    $key2="CHILDREN\t$key\t$_";
    print TRGTREESTATS "$key2\t$$tchildren{$key}{$_}\n";
  }
}
foreach (keys %$tchildrenposition) {
  print TRGTREESTATS "CHILDRENPOSITION\t$_\t$$tchildrenposition{$_}\n";
}

foreach (keys %$tedge) {
  print TRGTREESTATS "EDGE\t$_\t$$tedge{$_}\n";
}
foreach (keys %$theight) {
  $key=$_;
  if (defined $$theight{$key}) {
    print TRGTREESTATS "HEIGHT\t$key\t$$theight{$key}\n";
  }
}
foreach (keys %$tmaxheight) {
  $key=$_;
  if (defined $$tmaxheight{$key}) {
    print TRGTREESTATS "MAXHEIGHT\t$key\t$$tmaxheight{$key}\n";
  }
}
foreach (keys %$tnodesonheight) {
  $key=$_;
  foreach (keys %{$$tnodesonheight{$key}}) {
    $height=$_;
    $index=0;
    foreach(@{$$tnodesonheight{$key}{$height}}) {
      print TRGTREESTATS "NODESONHEIGHT\t$key\t$height\t$index\t$_\n";
      $index++;
    }
  }
}
}
}


sub printAlignStats {
foreach (keys %$linktype) {
  if (defined $$linktype{$_}) {
    print MANALIGNSTATS "LINKTYPE\t$_\t$$linktype{$_}\n";
  }
}

foreach (keys %$prob) {
  if (defined $$prob{$_}) {
    print MANALIGNSTATS "PROB\t$_\t$$prob{$_}\n";
  }
}

foreach (keys %$author) {
  if (defined $$author{$_}) {
    print MANALIGNSTATS "AUTHOR\t$_\t$$author{$_}\n";
  }
}

foreach (keys %$llinktype) {
  if (defined $$llinktype{$_}) {
    print AUTOALIGNSTATS "LINKTYPE\t$_\t$$llinktype{$_}\n";
  }
}

foreach (keys %$lprob) {
  if (defined $$lprob{$_}) {
    print AUTOALIGNSTATS "PROB\t$_\t$$lprob{$_}\n";
  }
}
}

sub readStats { ## read statistics from a file containing treebank statistics
  my $side=shift;
  my $in;
  (my %ids, my %word, my %pos, my %type, my %cat, my %terms, my %nonterms, my @sentids, my %parent, my %children, my %childrenposition, my %leaves, my %edge, my %height, my %maxheight, my %nodesonheight, my %has_nonterminal_unary_daughter, my %has_nonterminal_unary_daughter_except_punct);
  
  if (($side eq 's') || ($side eq 't')) {
    if ($side eq 's') {
      $in=<SRCTREESTATS>;
    }
    elsif ($side eq 't') {
      $in=<TRGTREESTATS>;
    }
    while (defined $in) {
      if ($in =~ /^IDS\t(\S+)\t([0-9]+)/) {
	$ids{$1}=$2;
      }
      if ($in =~ /^WORD\t(\S+)\t(\S+)/) {
	$word{$1}=$2;
      }
      if ($in =~ /^POS\t(\S+)\t(\S+)/) {
	$pos{$1}=$2;
      }
      if ($in =~ /^TYPE\t(\S+)\t(\S+)/) {
	$type{$1}=$2;
      }
      if ($in =~ /^CAT\t(\S+)\t(\S+)/) {
	$cat{$1}=$2;
      }
      if ($in =~ /^TERMS\t([0-9]+)\t([0-9]+)\t(\S+)/) {
	$terms{$1}[$2]=$3;
      }
      if ($in =~ /^NONTERMS\t([0-9]+)\t([0-9]+)\t(\S+)/) {
	$nonterms{$1}[$2]=$3;
      }
      if ($in =~ /^SENTID\t([0-9]+)\t(\S+)/) {
	$sentids[$1]=$2;
#	print "sentids of $1 is 2\n";
      }
      if ($in =~ /^PARENT\t(\S+)\t(\S+)/) {
	$parent{$1}=$2;
      }
      if ($in =~ /^CHILDREN\t(\S+)\t([0-9]+)\t(\S+)/) {
	$children{$1}{$2}=$3;
      }
      if ($in =~ /^CHILDRENPOSITION\t(\S+)\t([0-9]+)/) {
	$childrenposition{$1}=$2;
      }
      if ($in =~ /^LEAVES\t(\S+)\t([0-9]+)\t(\S+)/) {
	$leaves{$1}[$2]=$3;
      }
      if ($in =~ /^EDGE\t(\S+)\t(\S+)/) {
	$edge{$1}=$2;
      }
      if ($in =~ /^HEIGHT\t(\S+)\t([0-9]+)/) {
	$height{$1}=$2;
      }
      if ($in =~ /^HEIGHT\t([0-9]+)\t([0-9]+)/) {
	$maxheight{$1}=$2;
      }
      if ($in =~ /^NODESONHEIGHT\t([0-9]+)\t([0-9]+)\t([0-9]+)\t(\S+)/) {
	$nodesonheight{$1}{$2}[$3]=$4;
      }
      if ($in =~ /^HAS_NONTERMINAL_UNARY_DAUGHTER\t(\S+)\t([0-9]+)/) {
	$has_nonterminal_unary_daughter{$1}=$2;
      }
      if ($in =~ /^HAS_NONTERMINAL_UNARY_DAUGHTER_EXCEPT_PUNCT\t(\S+)\t([0-9]+)/) {
	$has_nonterminal_unary_daughter_except_punct{$1}=$2;
      }
      if ($side eq 's') {
	$in=<SRCTREESTATS>;
      }
      elsif ($side eq 't') {
	$in=<TRGTREESTATS>;
      }
    }
#    print "size of sentids: ".@sentids."\n";
    return (\%ids,\%word,\%pos,\%type,\%cat,\%terms,\%nonterms,\@sentids,\%parent,\%children,\%childrenposition,\%leaves,\%edge,\%height,\%maxheight,\%nodesonheight,\%has_nonterminal_unary_daughter,\%has_nonterminal_unary_daughter_except_punct);
  }
}

sub getRuleKeys {
  my $temp; my $leafratiovalue; my $linkedleafratiovalue; my $leafcountdiffvalue; my $linkedleafcountdiffvalue; my $absheightdiffvalue; my $value;
  my $linecount=0;

unless (defined $opt_r) {
  die ("Rule keys file not defined!");
}
open (RULEKEYS, "<$opt_r") || die ("Could not open rule keys file ($opt_r)!");

while (my $rin=<RULEKEYS>) {
  $linecount++;
  if ($rin =~ /^(\S+)/) {
#     $rulekeys_number2key{$linecount}=$2;
#     $rulekeys_key2number{$2}=$linecount;
    push(@rulenumbers,$linecount);
#    print "rulekeys_number2key of $1 is $2\n";

## obtain thresholds and type for every nonwellformedness line found in template

      if ($rin =~ /(source-has-nonterminal-unary-daughter)$/) {
	$rulekeys_number2key{$linecount}=$1;
	$rulekeys_key2number{$1}=$linecount;
      }

      if ($rin =~ /(target-has-nonterminal-unary-daughter)$/) {
	$rulekeys_number2key{$linecount}=$1;
	$rulekeys_key2number{$1}=$linecount;
      }

      elsif ($rin =~ /(source-has-nonterminal-unary-daughter-except-punct)/) {
	$rulekeys_number2key{$linecount}=$1;
	$rulekeys_key2number{$1}=$linecount;
      }

      elsif ($rin =~ /(target-has-nonterminal-unary-daughter-except-punct)/) {
	$rulekeys_number2key{$linecount}=$1;
	$rulekeys_key2number{$1}=$linecount;
      }

## gcount
      elsif ($rin =~ /^(nonwellformed__gcount)([^_]\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
      }
## fcount
      elsif ($rin =~ /^(nonwellformed__fcount)([^_]\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
      }
## ncount
      elsif ($rin =~ /^(nonwellformed__ncount)(\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
      }
## gcount__nopunct
      elsif ($rin =~ /^(nonwellformed__gcount__nopunct)(\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
      }
## fcount_nopunct
      elsif ($rin =~ /^(nonwellformed__fcount__nopunct)(\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
      }

      elsif ($rin =~ /^(leaf-ratio-score)(\S+)/) {
        $temp=$1.$2;
        $rulekeys_number2key{$linecount}=$temp;
        $rulekeys_key2number{$temp}=$linecount;
        $getleafratio=1;
      }

## leaf ratio
       elsif ($rin =~ /^(leaf-ratio)(\S{1,2}[0-9]+.*)/) {
	 $temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
	$getleafratio=1;
# 	if (defined $opt_o && $opt_leafratiothresh) {
# 	  $leafratiothresh=$opt_leafratiothresh;
# 	}
	}

## leaf count difference
      elsif ($rin =~ /^(leaf-count-diff)(\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
      }

## total leaf count
      elsif ($rin =~ /^(leaf-count-total)(\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
      }
      
## geometric average of leaf count and leaf difference
      elsif ($rin =~ /^(geo-leaf-ratio-score)(\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
      }

## linked leaf ratio
      elsif ($rin =~ /^(linkedleaf-ratio)(\S{1,2}[0-9]+.*)/) {
	 $temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
	$getlinkedleafratio=1;
      }

## linked leaf ratio score
      elsif ($rin =~ /^(linkedleaf-ratio-score)(\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
	$getlinkedleafratio=1;
      }

## linked leaf count difference
      elsif ($rin =~ /^(linkedleafcount-diff)(\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
      }

## total linked leaf count
      elsif ($rin =~ /^(linkedleaf-count-total)(\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
      }

## geometric average of leaf count and difference between leaf count and well-formed linked leaves
      elsif ($rin =~ /^(geo-linkedleaf-ratio-score)(\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
      }

## absolute height difference
      elsif ($rin =~ /^(abs-height-diff)(\S+)/) {
	$temp=$1.$2;
	$rulekeys_number2key{$linecount}=$temp;
	$rulekeys_key2number{$temp}=$linecount;
      }

## POS on only one side
      elsif ($rin =~ /^(\S*?)=true.*?_([^_]*)=false/) {
#POSCOMBO:\s+(\S+)__(\S+)
        $combopos="POSCOMBO: $1"."__".$2;
        $rulekeys_number2key{$linecount}=$combopos;
        $rulekeys_key2number{$combopos}=$linecount;
      }

## capitalized word on only one side
      elsif ($rin =~ /^(source-target-has-only-one-capitalization)/) {
        $rulekeys_number2key{$linecount}=$1;
        $rulekeys_key2number{$temp}=$linecount;
      }

## word containing number on only one side
      elsif ($rin =~ /^(source-target-has-only-one-number)/) {
        $rulekeys_number2key{$linecount}=$1;
        $rulekeys_key2number{$1}=$linecount;
      }

## sharing identical at least one identical word containing a number or capitalized word      
      elsif ($rin =~ /^(share-identical-words-special)/) {
        $rulekeys_number2key{$linecount}=$1;
        $rulekeys_key2number{$1}=$linecount;
      }

## sharing identical strings. Capitalization ignored.
      elsif ($rin =~ /(has-identical-strings)/) {
	$rulekeys_number2key{$linecount}=$1;
        $rulekeys_key2number{$1}=$linecount;
      }

## sharing good word alignments
      elsif ($rin =~ /(share-good-alignments)/) {
	$rulekeys_number2key{$linecount}=$1;
        $rulekeys_key2number{$1}=$linecount;
      }

## if a special character only occurs on one side
      elsif ($rin =~ /(has-special-character-one-side)/) {
	$rulekeys_number2key{$linecount}=$1;
        $rulekeys_key2number{$1}=$linecount;
      }

## if only punctuation occurs on either end at the source side
      elsif ($rin =~ /(source-has-punct-at-either-end)/) {
	$rulekeys_number2key{$linecount}=$1;
        $rulekeys_key2number{$1}=$linecount;
      }

## if only punctuation occurs on either end at the target side
      elsif ($rin =~ /(target-has-punct-at-either-end)/) {
	$rulekeys_number2key{$linecount}=$1;
        $rulekeys_key2number{$1}=$linecount;
      }

## if the words on both sides of the subtree spans (beginning or end) are linked well-formedly (not necessarily to each other)
      elsif ($rin =~ /(words-linked-both-ends)/) {
	$rulekeys_number2key{$linecount}=$1;
        $rulekeys_key2number{$1}=$linecount;
      }

  }
}

close (RULEKEYS);

}

if ($srcstats_exists == 0) {
  $strees->cleanUp();
}
if ($trgstats_exists == 0) {
  $ttrees->cleanUp();
}
if ($opt_g) {
  $man_alignments->cleanUp();
}
$auto_alignments->cleanUp();

close (MANALIGNSTATS);
close (AUTOALIGNSTATS);
close (SRCTREESTATS);
close (TRGTREESTATS);
close (RULESTATS);
if ($opt_g) {
  close (BESTRULE);
  close (FOUNDRULES);
}

__END__

=head1 DESCRIPTION

This script is part of the tree alignment tool TBLign, which implements the transformation-based learning algorithm. It takes as input a reference to a tree-to-tree alignment set of files:

=over

=item * -s A treebank file (the source file) in Tiger-XML format.

=item * -t As above, but the target side treebank file.

=item * -a An alignment file with references to the treebank files, in STA (Stockholm TreeAligner) format. This is the gold standard file. Required if -g is also specified.

=item * -A An alignment file with references to the treebank files, in STA (Stockholm TreeAligner) format. This is the file that will be updated with the best rule (if -g is specified) after comparison with the gold standard file.

=item * -o (currently obsolete) Include this with an argument if a file exists with optimized values for similarity scores (leaf and linked leaf).

=item * -g Include this (with no argument) if we intend to find and apply a best rule to the file specified by -A. If -g is specified, a gold standard file (-a) is also needed in order to find the best rule to be applied.

=item * -r This is a file containing an instantiation of a set of rule templates.

=item * -M Statistics on the gold standard alignment file are written to this file.

=item * -L Statistics on the automatic alignment file are written to this file.

=item * -S Statistics on the source treebank file are written to this file.

=item * -T Statistics on the target treebank file are written to this file.

=item * -R Rule statistics, derived from the automatic output file (-A) and the treebank files (-s and -t) are written to this file.

=item * -u All rules found to be applicable to node pairs are written to this file (if -g is specified).

=item * -b The best rule found is written to this file (if -g is specified).

=back

We extract all kinds of statistics about the treebanks and the alignments and write them to text files. We use these statistics and some pre-specified features to create sets of complex rules. We iterate through all non-terminal node pairs and find out which of these rules apply, either adding or removing a link depending on whether the current node pair is aligned or not (the alignments are not physically changed but statistics of eventual adding or deletion are kept). If -g is specified, we compare the results against a gold standard and find the best rule to be applied, writing it to output. If the intent is to just extract statistics so that an already existing rule can be applied, -g is not specified, so in this case we do not look for a best rule.

In TBLign, this script is called by a few different Bash scripts depending on whether we are training (learning a new set of rules) or testing (applying a learned set of rules).

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>gidi8ster@gmail.comE<gt>

=cut

