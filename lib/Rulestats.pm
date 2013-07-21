package Rulestats;
use Exporter;
#use feature 'say';
use List::Util qw[min max];
use strict;
use warnings;
#@ISA = ('Exporter');
#@EXPORT =

sub new {
    my $class=shift;
    my %attr=@_;
    my $self={};
    
    bless $self,$class;
    foreach (keys %attr) {
       $self->{$_}=$attr{$_};
    }
    $self->{'fcount_punct'}=0;
    $self->{'gcount_punct'}=0;
    $self->{'fcount_nopunct'}=0;
    $self->{'gcount_nopunct'}=0;
    $self->{'ncount'}=0;
    return $self;
}

sub getWellformednessStats {
  my $self=shift;
  (my $snonterm, my $tnonterm)=@_;
  (my $scurchildren, my $scurchildren2, my $tcurchildren, my $tcurchildren2, my $childnode, my $curlinknode, my $curlinknode2, my $curlink, my $curlink2, my $nodetype);
  (my $ftotal, my $gtotal)=(0,0);
  my $schildren=$self->{-schildren};
  my $tchildren=$self->{-tchildren};
  my $slinks=$self->{-slink};
  my $tlinks=$self->{-tlink};
  my $stype=$self->{-stype};
  my $ttype=$self->{-ttype};
  my $linktype=$self->{-linktype};
  my $sword=$self->{-sword};
  my $tword=$self->{-tword};
  my $scat=$self->{-scat};
  my $tcat=$self->{-tcat};
  $self->{'fcount_punct'}=0;
  $self->{'gcount_punct'}=0;
  $self->{'fcount_nopunct'}=0;
  $self->{'gcount_nopunct'}=0;
  $self->{'ncount'}=0;

  my $size_s=keys(%{$$schildren{$snonterm}});
  my $size_t=keys(%{$$tchildren{$tnonterm}});
  $scurchildren=$$schildren{$snonterm};
  $tcurchildren=$$tchildren{$tnonterm};

  for (my $i=0; $i<$size_s; $i++) {
    if (defined $$scurchildren{$i}) {
      $childnode=$$scurchildren{$i};
      if (defined $$slinks{$childnode}) {
	if (defined $$stype{$childnode}) {
	  $nodetype=$$stype{$childnode};
	}
	else {
	  warn "No type for source node $childnode!";
	}
      	foreach (@{$$slinks{$childnode}}) {
	 $curlinknode=$_;
         $curlink=$childnode."__".$_;
         unless (defined $$linktype{$curlink}) {
           warn "Link expected for nodes $curlink";
         }
	 unless (($self->searchParent($curlinknode,$tnonterm,'t') == 1) || ($curlinknode eq $tnonterm)) {
#         say $curlinknode;
	  if ((defined $nodetype) && ($nodetype eq "nt")) {
	    $self->{'ncount'}++;
#  	      if (($snonterm eq "1_1002") && ($tnonterm eq "1_1")) {
# 		say "A ncount: $self->{'ncount'}";
# 		say "child node $childnode ($$scat{$childnode}) linked to $curlinknode ($$tcat{$curlinknode}) could not find target parent $tnonterm ($$tcat{$tnonterm})";
# 	      }
	  }
          elsif ((defined $nodetype) && ($nodetype eq "t")) {
            if (defined $$linktype{$curlink}) {
	      $self->addNonWellformedCounts($childnode,$curlinknode,$$linktype{$curlink},'s',\%{$sword},\%{$tword});
	    }
	  }
	 } ## unless (($self->searchParent($curlinknode,$tnonterm,'t') == 1) || ($curlinknode eq $tnonterm)) {
	} ## foreach (@{$$slinks{$childnode}}) {
       } ## if (defined $$slinks{$childnode}) {

      if ((defined $$stype{$childnode}) && ($$stype{$childnode} eq "nt")) {
	$scurchildren2=$$schildren{$childnode};
	if (defined $$scurchildren2{0}) {
	  foreach (keys %{$scurchildren2}) {
	    $self->getWellformednessStatsRecursive($snonterm,$tnonterm,$$scurchildren2{$_},'s',\%{$schildren},\%{$tchildren},\%{$slinks},\%{$tlinks},\%{$stype},\%{$ttype},\%{$linktype},\%{$sword},\%{$tword},\%{$scat},\%{$tcat});
	  }
	}
      }
    } ## if (defined $$scurchildren{$i})
  } ## for (my $i=0; $i<$size_s; $i++)

## after having checked the children, now we check the source node itself (whether its links have the target node as parent or not)
       if (defined $$slinks{$snonterm}) {
	foreach (@{$$slinks{$snonterm}}) {
	  $curlinknode2=$_;
	  $curlink2=$snonterm."__".$_;
	  unless (defined $$linktype{$curlink2}) {
	    warn "Link expected for nodes $curlink2";
	  }
	  unless (($self->searchParent($curlinknode2,$tnonterm,'t') == 1) || ($curlinknode2 eq $tnonterm)) {
	    $self->{'ncount'}++;
#  	      if (($snonterm eq "1_1002") && ($tnonterm eq "1_1")) {
# 	      say "B ncount: $self->{'ncount'}";
# 	      say "snonterm $snonterm ($$scat{$snonterm}) linked to $curlinknode2 ($$tcat{$curlinknode2}) could not find target parent $tnonterm ($$tcat{$tnonterm}) or $curlinknode2 is not equal to $tnonterm";
# 	    }
	  }
	 }
	}

  for (my $i=0; $i<$size_t; $i++) {
    if (defined $$tcurchildren{$i}) {
      $childnode=$$tcurchildren{$i};
      if (defined $$tlinks{$childnode}) {
	if (defined $$ttype{$childnode}) {
	  $nodetype=$$ttype{$childnode};
	}
	else {
	  warn "No type for target node $childnode!";
	}
      	foreach (@{$$tlinks{$childnode}}) {
	 $curlinknode=$_;
         $curlink=$_."__".$childnode;
         unless (defined $$linktype{$curlink}) {
           warn "Link expected for nodes $curlink";
         }
	 unless (($self->searchParent($curlinknode,$snonterm,'s') == 1) || ($curlinknode eq $snonterm)) {
	  if ((defined $nodetype) && ($nodetype eq "nt")) {
	    $self->{'ncount'}++;
#  	      if (($snonterm eq "1_1002") && ($tnonterm eq "1_1")) {
# 	      say "C ncount: $self->{'ncount'}";
# 	      say "C child node $childnode ($$tcat{$childnode}) linked to $curlinknode ($$scat{$curlinknode}) could not find source parent $snonterm ($$scat{$snonterm})";
# 	      say "C ncount: $self->{'ncount'}";
# 	    }
	  }
          elsif ((defined $nodetype) && ($nodetype eq "t")) {
            if (defined $$linktype{$curlink}) {
	      $self->addNonWellformedCounts($childnode,$curlinknode,$$linktype{$curlink},'t',\%{$sword},\%{$tword});
	    }
	  }
	 } ## unless (($self->searchParent($curlinknode,$snonterm,'s') == 1) || ($curlinknode eq $snonterm)) {
	} ## foreach (@{$$slinks{$childnode}}) {
       } ## if (defined $$slinks{$childnode}) {

      if ((defined $$ttype{$childnode}) && ($$ttype{$childnode} eq "nt")) {
	$tcurchildren2=$$tchildren{$childnode};
	if (defined $$tcurchildren2{0}) {
	  foreach (keys %{$tcurchildren2}) {
	    $self->getWellformednessStatsRecursive($snonterm,$tnonterm,$$tcurchildren2{$_},'t',\%{$schildren},\%{$tchildren},\%{$slinks},\%{$tlinks},\%{$stype},\%{$ttype},\%{$linktype},\%{$sword},\%{$tword},\%{$scat},\%{$tcat});
	  }
	}
      }
    } ## if (defined $$scurchildren{$i})
  } ## for (my $i=0; $i<$size_s; $i++)

## after having checked the children, now we check the target node itself (whether its links have the source node as parent or not)
       if (defined $$tlinks{$tnonterm}) {
	foreach (@{$$tlinks{$tnonterm}}) {
	  $curlinknode2=$_;
	  $curlink2=$_."__".$tnonterm;
	  unless (defined $$linktype{$curlink2}) {
	    warn "Link expected for nodes $curlink2";
	  }
	  unless (($self->searchParent($curlinknode2,$snonterm,'s') == 1) || ($curlinknode2 eq $snonterm)) {
	    $self->{'ncount'}++;
#  	      if (($snonterm eq "1_1002") && ($tnonterm eq "1_1")) {
# 		say "D tnonterm $tnonterm ($$tcat{$tnonterm}) linked to $curlinknode2 ($$scat{$curlinknode2}) could not find target parent $snonterm ($$scat{$snonterm}) or $curlinknode2 is not equal to $snonterm";
# 		say "D ncount: $self->{'ncount'}";
# 	      }
	  }
	 }
	}
  
#        say "snonterm: $snonterm (cat: $$scat{$snonterm})";
#        say "tnonterm: $tnonterm (cat: $$tcat{$tnonterm})";
#        say "ncount: $self->{'ncount'}";
#        say "gcount_nopunct: $self->{'gcount_nopunct'}";
#        say "fcount_nopunct: $self->{'fcount_nopunct'}";
#        say "gcount_punct: $self->{'gcount_punct'}";
#        say "fcount_punct: $self->{'fcount_punct'}\n";

  $curlink=$snonterm."__".$tnonterm;
  $gtotal=$self->{'gcount_punct'}+$self->{'gcount_nopunct'};
  $ftotal=$self->{'fcount_punct'}+$self->{'fcount_nopunct'};

  return ($gtotal,$ftotal,$self->{'gcount_nopunct'},$self->{'fcount_nopunct'},$self->{'ncount'});
}


sub addNonWellformedCounts {
  (my $self, my $childnode, my $curlinknode, my $linktype, my $fromside, my $sword, my $tword)=@_;
  if ($fromside eq 's') {
    if (defined $$sword{$childnode}) {
      if (defined $$tword{$curlinknode}) {
	if (($$sword{$childnode} =~ /[^\^\[\]!@.,?!'"{}|\\\/#$%&*()_+-=<>~`;:]/) || ($$tword{$curlinknode} =~ /[^\^\[\]!@.,?!'"{}|\\\/#$%&*()_+-=<>~`;:]/) || ($$sword{$childnode} =~ /[0-9]+/) || ($$tword{$curlinknode} =~ /[0-9]+/)) { ## because for some reason, numbers are seen as part of the first two sets
	  if ($linktype eq "good") {  
	    $self->{'gcount_nopunct'}++; ## only one or none of the two tokens in question is a punctuation mark, and the link is good (not fuzzy)
	  }
	  elsif ($linktype eq "fuzzy") {
	    $self->{'fcount_nopunct'}++; ## only one or none of the two tokens in question is a punctuation mark, and the link is fuzzy (not good)
	  }
	}
	else {
	  if ($linktype eq "good") {  
	    $self->{'gcount_punct'}++; ## both tokens are punctuation marks, and the link is good (not fuzzy)
	  }
	  elsif ($linktype eq "fuzzy") {
	    $self->{'fcount_punct'}++; ## both tokens are punctuation marks, and the link is fuzzy (not good)
	  }
	}
      }
      else {
	warn "No word for target terminal node $curlinknode!";
      }
    }
    else {
      warn "No word for source terminal node $childnode!";
    }
  }

  elsif ($fromside eq 't') {
    if (defined $$tword{$childnode}) {
      if (defined $$sword{$curlinknode}) {
	if (($$tword{$childnode} =~ /[^\^\[\]!@.,?!'"{}|\\\/#$%&*()_+-=<>~`;:]/) || ($$sword{$curlinknode} =~ /[^\^\[\]!@.,?!'"{}|\\\/#$%&*()_+-=<>~`;:]/) || ($$tword{$childnode} =~ /[0-9]+/) || ($$sword{$curlinknode} =~ /[0-9]+/)) { ## because for some reason, numbers are seen as part of the first two sets
	  if ($linktype eq "good") {  
	    $self->{'gcount_nopunct'}++; ## only one or none of the two tokens in question is a punctuation mark, and the link is good (not fuzzy)
	  }
	  elsif ($linktype eq "fuzzy") {
	    $self->{'fcount_nopunct'}++; ## only one or none of the two tokens in question is a punctuation mark, and the link is fuzzy (not good)
#	    say "fcount_nopunct: $self->{'fcount_nopunct'}";
	  }
	}
	else {
	  if ($linktype eq "good") {  
	    $self->{'gcount_punct'}++; ## both tokens are punctuation marks, and the link is good (not fuzzy)
	  }
	  elsif ($linktype eq "fuzzy") {
	    $self->{'fcount_punct'}++; ## both tokens are punctuation marks, and the link is fuzzy (not good)
	  }
	}
      }
      else {
	warn "No word for source terminal node $curlinknode!";
      }
    }
    else {
      warn "No word for target terminal node $childnode!";
    }
  }

}

sub searchParent {
  my ($self,$curnode,$soughtfornode,$side)=@_;
  my $parent="";
  my $sparent=$self->{-sparent};
  my $tparent=$self->{-tparent};

  if ($side eq 's') {
    $parent=$$sparent{$curnode};
    if (defined $parent) {
      $parent=$$sparent{$curnode};
    }
  }
  elsif ($side eq 't') {
    if (defined $parent) {
      $parent=$$tparent{$curnode};
    }
  }
  if ((defined $parent) && ($parent eq $soughtfornode)) {
    return 1;
  }
  else {
    while ((defined $parent) && ($parent ne $soughtfornode)) {
     if ($side eq 's') {
	$parent=$$sparent{$parent};
      }
      elsif ($side eq 't') {
	$parent=$$tparent{$parent};
      }
    }
    if ((defined $parent) && ($parent eq $soughtfornode)) {
      return 1;
    }
    else {
      return 0;
    }
  }
}

sub getWellformednessStatsRecursive {
  my ($self,$snonterm,$tnonterm,$childnode,$side,$schildren,$tchildren,$slinks,$tlinks,$stype,$ttype,$linktype,$sword,$tword,$scat,$tcat)=@_;
  (my $scurchildren, my $tcurchildren, my $curlinknode, my $curlinknode2, my $curlink, my $curlink2, my $nodetype);

## test
# say "self: $self";
# say "snonterm: $snonterm";
# say "tnonterm: $tnonterm";
# say "childnode: $childnode";
# say "side: $side";
# say "size of schildren: ".keys(%{$schildren});
# say "size of tchildren: ".keys(%{$tchildren});
# say "size of slinks: ".keys(%{$slinks});
# say "size of tlinks: ".keys(%{$tlinks});
# say "size of stype: ".keys(%{$stype});
# say "size of ttype: ".keys(%{$ttype});
# say "size of linktype: ".keys(%{$linktype});
# say "size of sword: ".keys(%{$sword});
# say "size of tword: ".keys(%{$tword});
# say "size of scat: ".keys(%{$scat});
# say "size of tcat: ".keys(%{$tcat});
# print "\n";

   if ($side eq 's') {
     if (defined $$slinks{$childnode}) {
       if (defined $$stype{$childnode}) {
 	$nodetype=$$stype{$childnode};
       }
      else {
 	warn "No type for source node $childnode!";
       }
       foreach (@{$$slinks{$childnode}}) {
 	$curlinknode=$_;
 	$curlink=$childnode."__".$_;
 	unless (defined $$linktype{$curlink}) {
 	  warn "Link expected for nodes $curlink";
	}
 	unless (($self->searchParent($curlinknode,$tnonterm,'t') == 1) || ($curlinknode eq $tnonterm)) {
 	  if ((defined $nodetype) && ($nodetype eq "nt")) {
 	    $self->{'ncount'}++;
 	  }
 	  elsif ((defined $nodetype) && ($nodetype eq "t")) {
 	    if (defined $$linktype{$curlink}) {
 	      $self->addNonWellformedCounts($childnode,$curlinknode,$$linktype{$curlink},'s',\%{$sword},\%{$tword});
 	    }
 	  }
 	} ## unless (($self->searchParent($curlinknode,$tnonterm,'t') == 1) || ($curlinknode eq $tnonterm)) {
       } ## foreach (@{$$slinks{$childnode}}) {
     } ## if (defined $$slinks{$childnode}) {
 
     if ((defined $$stype{$childnode}) && ($$stype{$childnode} eq "nt")) {
       $scurchildren=$$schildren{$childnode};
       if (defined $$scurchildren{0}) {
 	foreach (keys %{$scurchildren}) {
 	  $self->getWellformednessStatsRecursive($snonterm,$tnonterm,$$scurchildren{$_},'s',\%{$schildren},\%{$tchildren},\%{$slinks},\%{$tlinks},\%{$stype},\%{$ttype},\%{$linktype},\%{$sword},\%{$tword},\%{$scat},\%{$tcat});
 	}
       }
       else {
 	return;
       }
     }
     else {
       return;
     }
  }

   elsif ($side eq 't') {
     if (defined $$tlinks{$childnode}) {
       if (defined $$ttype{$childnode}) {
 	$nodetype=$$ttype{$childnode};
       }
       else {
 	warn "No type for target node $childnode!";
       }
       foreach (@{$$tlinks{$childnode}}) {
 	$curlinknode=$_;
 	$curlink=$_."__".$childnode;
 	unless (defined $$linktype{$curlink}) {
 	  warn "Link expected for nodes $curlink";
 	}
 	unless (($self->searchParent($curlinknode,$snonterm,'s') == 1) || ($curlinknode eq $snonterm)) {
 	  if ((defined $nodetype) && ($nodetype eq "nt")) {
 	    $self->{'ncount'}++;
#  	      if (($snonterm eq "1_1002") && ($tnonterm eq "1_1")) {
# 		say "F with childnode $childnode";
# 		say "F target child node $childnode ($$tcat{$childnode}) linked to $curlinknode ($$scat{$curlinknode}) could not find source parent $snonterm ($$scat{$snonterm}) or $curlinknode is not equal to $snonterm";
# 		say "F ncount: $self->{'ncount'}";
# 	      }
 	  }
 	  elsif ((defined $nodetype) && ($nodetype eq "t")) {
 	    if (defined $$linktype{$curlink}) {
	      $self->addNonWellformedCounts($childnode,$curlinknode,$$linktype{$curlink},'t',\%{$sword},\%{$tword});
 	    }
 	  }
 	} ## unless (($self->searchParent($curlinknode,$snonterm,'s') == 1) || ($curlinknode eq $snonterm)) {
       } ## foreach (@{$$slinks{$childnode}}) {
     } ## if (defined $$tlinks{$childnode}) {

     if ((defined $$ttype{$childnode}) && ($$ttype{$childnode} eq "nt")) {
       $tcurchildren=$$tchildren{$childnode};
       if (defined $$tcurchildren{0}) {
 	foreach (keys %{$tcurchildren}) {
 	  $self->getWellformednessStatsRecursive($snonterm,$tnonterm,$$tcurchildren{$_},'t',\%{$schildren},\%{$tchildren},\%{$slinks},\%{$tlinks},\%{$stype},\%{$ttype},\%{$linktype},\%{$sword},\%{$tword},\%{$scat},\%{$tcat});
 	}
       }
       else {
 	return;
       }
     }
     else {
       return;
     }
  }

  return;
}

sub getLeafRatioScore {
  (my $self, my $snonterm, my $tnonterm, my $sleafcount, my $tleafcount, my $range)=@_;
  my $maximum, my $similarity, my $diffpenalty, my $difference;
# my $sleaves=$self->{-sleaves};
# my tleaves=$self->{-tleaves};

  # if (defined @{$$sleaves{$snonterm}}) {
  #   foreach (@{$$sleaves{$snonterm}}) {
  #     $sleafcount++;
  #   }
  # }

  # if (defined @{$$tleaves{$tnonterm}}) {
  #   foreach (@{$$tleaves{$tnonterm}}) {
  #     $tleafcount++;
  #   }
  # }

  # if ($sleafcount == 0) {
  #   warn "Unexpected count of 0 children for source nonterminal node $snonterm!";
  # }
  # if ($tleafcount == 0) {
  #   warn "Unexpected count of 0 children for target nonterminal node $tnonterm!";
  # }

  if ($sleafcount<$tleafcount) {
    $maximum=$tleafcount;
  }
  else {
    $maximum=$sleafcount;
  }

  $difference=abs($sleafcount-$tleafcount);
  if ($difference > $range) {
    $similarity=0;
  }
  else {
    $diffpenalty=$difference/$range*100;
    if ($maximum != 0) {
      $similarity=100-($difference/$maximum*100)-$diffpenalty;
    }
    else { return 0; }
  }

  return $similarity;
}

sub getLeafRatio {
  (my $self, my $snonterm, my $tnonterm, my $sleafcount, my $tleafcount)=@_;
  my $maximum; my $minimum; my $ratio;
  my $sleaves=$self->{-sleaves};
  my $tleaves=$self->{-tleaves};

#   if (defined @{$$sleaves{$snonterm}}) {
#     foreach (@{$$sleaves{$snonterm}}) {
#       $sleafcount++;
#     }
#   }
# 
#   if (defined @{$$tleaves{$tnonterm}}) {
#     foreach (@{$$tleaves{$tnonterm}}) {
#       $tleafcount++;
#     }
#   }

  if ($sleafcount == 0) {
    warn "Unexpected count of 0 children for source nonterminal node $snonterm!";
  }
  if ($tleafcount == 0) {
    warn "Unexpected count of 0 children for target nonterminal node $tnonterm!";
  }

  if ($sleafcount<$tleafcount) {
    $maximum=$tleafcount;
    $minimum=$sleafcount;
  }
  else {
    $maximum=$sleafcount;
    $minimum=$tleafcount;
  }

  if ($maximum > 0) {
    $ratio=$minimum/$maximum;
  }
  else {
    $ratio=0;
    warn ("Maximum leaf count is 0 for node pair $snonterm and $tnonterm!");
  }

  if (defined $ratio) {
    return $ratio;
  }

  else {
    warn("Leaf link ratio not defined for node pair $snonterm and $tnonterm!");
    return 0;
  }

}

sub getLeafDifference {
  (my $self, my $snonterm, my $tnonterm)=@_;
  my $sleaves=$self->{-sleaves};
  my $tleaves=$self->{-tleaves};
  my $difference;
  (my $sleafcount, my $tleafcount)=(0,0);

  if (defined @{$$sleaves{$snonterm}}) {
    foreach (@{$$sleaves{$snonterm}}) {
      $sleafcount++;
    }
  }

  if (defined @{$$tleaves{$tnonterm}}) {
    foreach (@{$$tleaves{$tnonterm}}) {
      $tleafcount++;
    }
  }

  if ($sleafcount == 0) {
    warn "Unexpected count of 0 children for source nonterminal node $snonterm!";
  }
  if ($tleafcount == 0) {
    warn "Unexpected count of 0 children for target nonterminal node $tnonterm!";
  }

  $difference=abs($sleafcount-$tleafcount);

  return $difference;
}


sub getLinkedLeafRatioScore {
  (my $self, my $snonterm, my $tnonterm, my $linkedleafcount, my $leafcount, my $range)=@_;
  (my $similarity, my $diffpenalty, my $difference, my $childnode);
  # my $slinks=$self->{-slink};
  # my $tlinks=$self->{-tlink};
  # my $sleaves=$self->{-sleaves};
  # my $tleaves=$self->{-tleaves};

#  say "size of tleaves: ".keys(%{$tleaves});

 #  foreach (@{$$sleaves{$snonterm}}) {
 #    $childnode=$_;
 #    $leafcount++;
 #    $alreadycounted=0;
 #    if (defined $$slinks{$childnode}) {
 #      foreach (@{$$slinks{$childnode}}) {
	# if ($alreadycounted == 0) {
	#   if ($self->searchParent($_,$tnonterm,'t') == 1) {
	#     $linkedleafcount++;
	#     $alreadycounted=1;
	#   }
 #        }
 #      }
 #    }
 #  }

 #  foreach (@{$$tleaves{$tnonterm}}) {
 #    $childnode=$_;
 #    $leafcount++;
 #    $alreadycounted=0;
 #    if (defined $$tlinks{$childnode}) {
 #      foreach (@{$$tlinks{$childnode}}) {
	# if ($alreadycounted == 0) {
	#   if ($self->searchParent($_,$snonterm,'s') == 1) {
	#     $linkedleafcount++;
	#     $alreadycounted=1;
	#   }
	# }
  #     }
  #   }
  # }

  $difference=abs($linkedleafcount-$leafcount);
  if ($difference > $range) {
    $similarity=0;
  }
  else {
    $diffpenalty=$difference/$range*100;
    if ($leafcount != 0) {
      $similarity=100-($difference/$leafcount*100)-$diffpenalty;
    }
    else { return 0; }
  }
  return $similarity;
}


sub getLinkedLeafRatio {
  (my $self, my $snonterm, my $tnonterm)=@_;
  my $slinks=$self->{-slink};
  my $tlinks=$self->{-tlink};
  my $sleaves=$self->{-sleaves};
  my $tleaves=$self->{-tleaves};
  my $childnode; my $alreadycounted; my $ratio;
  (my $leafcount, my $linkedleafcount, my $minimum, my $maximum)=(0,0,0,0);

#  say "size of tleaves: ".keys(%{$tleaves});

  foreach (@{$$sleaves{$snonterm}}) {
    $childnode=$_;
    $leafcount++;
    $alreadycounted=0;
    if (defined $$slinks{$childnode}) {
      foreach (@{$$slinks{$childnode}}) { ## because a terminal node can have more than one link
	if ($alreadycounted == 0) {
	  if ($self->searchParent($_,$tnonterm,'t') == 1) {
	    $linkedleafcount++;
	    $alreadycounted=1; ## we only count once per linked node, not the links themselves
	  }
        }
      }
    }
  }

  foreach (@{$$tleaves{$tnonterm}}) {
    $childnode=$_;
    $leafcount++;
    $alreadycounted=0;
    if (defined $$tlinks{$childnode}) {
      foreach (@{$$tlinks{$childnode}}) {
	if ($alreadycounted == 0) {
	  if ($self->searchParent($_,$snonterm,'s') == 1) {
	    $linkedleafcount++;
	    $alreadycounted=1;
	  }
	}
      }
    }
  }

  if ($leafcount == 0) {
    warn "Unexpected count of 0 leaves for node pair $snonterm and $tnonterm!";
  }

  $maximum=$leafcount;
  $minimum=$linkedleafcount;

  if ($maximum > 0) {
    $ratio=$minimum/$maximum;
  }
  else {
    $ratio=0;
  }

  if (defined $ratio) {
    return ($ratio,$linkedleafcount);
  }

  else {
    warn("Linked leaf link ratio not defined for node pair $snonterm and $tnonterm!");
    return (0,$linkedleafcount);
  }

}

sub getPOScombos {
  (my $self, my $snonterm, my $tnonterm, my $sleaves, my $tleaves, my $allspos, my $alltpos, my $spos, my $tpos)=@_;
  (my $smatch, my $tmatch)=(0,0);
  my $part1; my $part2;

  if (defined @{$$sleaves{$snonterm}}) {
   foreach (@{$$sleaves{$snonterm}}) {
     if ($spos =~ /(\S+)\*$/) {
	$part1=$1;
	if ($$allspos{$_} =~ /^$part1/) { ## eg. if VBD matches VB (which it does)
	  $smatch=1;
	}
     }
     else {
      if ($$allspos{$_} eq $spos) {
	$smatch=1;
      }
     }
   }
  }
  else {
    warn "No leaves defined for source node $snonterm!";
  }

  if (defined @{$$tleaves{$tnonterm}}) {
   foreach (@{$$tleaves{$tnonterm}}) {
     if ($tpos =~ /(\S+)\*$/) {
	$part2=$1;
	if ($$alltpos{$_} =~ /^$part2/) { ## eg. if VBD matches VB (which it does)
	  $tmatch=1;
	}
     }
     else {
      if ($$alltpos{$_} eq $tpos) {
	$tmatch=1;
      }
     }
   }
  }
  else {
    warn "No leaves defined for target node $snonterm!";
  }

  return ($smatch,$tmatch);
}

sub getCapsCombos {
  (my $self, my $snonterm, my $tnonterm, my $sleaves, my $tleaves, my $sword, my $tword)=@_;
  (my $source_has_caps, my $target_has_caps)=(0,0);

  if (defined @{$$sleaves{$snonterm}}) {
    foreach (@{$$sleaves{$snonterm}}) {
      if (defined $$sword{$_}) {
	if ($$sword{$_} =~ /[A-Z]/) {
	  $source_has_caps=1;
	}
      }
      else {
	warn "Source side terminal node (ID $_) has no token!";
      }
    }
  }

  if (defined @{$$tleaves{$tnonterm}}) {
    foreach (@{$$tleaves{$tnonterm}}) {
      if (defined $$tword{$_}) {
	if ($$tword{$_} =~ /[A-Z]/) {
	  $target_has_caps=1;
	}
      }
      else {
	warn "Target side terminal node (ID $_) has no token!";
      }
    }
  }

  return ($source_has_caps,$target_has_caps);
}

sub getNumberCombos {
  (my $self, my $snonterm, my $tnonterm, my $sleaves, my $tleaves, my $sword, my $tword)=@_;
  (my $source_has_number, my $target_has_number)=(0,0);

  if (defined @{$$sleaves{$snonterm}}) {
    foreach (@{$$sleaves{$snonterm}}) {
      if (defined $$sword{$_}) {
	if ($$sword{$_} =~ /[0-9]/) {
	  $source_has_number=1;
	}
      }
      else {
	warn "Source side terminal node (ID $_) has no token!";
      }
    }
  }

  if (defined @{$$tleaves{$tnonterm}}) {
    foreach (@{$$tleaves{$tnonterm}}) {
      if (defined $$tword{$_}) {
	if ($$tword{$_} =~ /[0-9]/) {
	  $target_has_number=1;
	}
      }
      else {
	warn "Target side terminal node (ID $_) has no token!";
      }
    }
  }

  return ($source_has_number,$target_has_number);
}

sub basicParentAlign {
  ## takes as input a Treebank and STA object as well as a linked node pair (terminals or nonterminals) with unlinked parents and returns "good" if both nodes are exclusively linked to each other and both parents have only these nodes as children (i.e. unary relations on both sides); returns "fuzzy" if these conditions hold but they are also not exclusively linked, and "none" if these conditions do not hold.
  (my $self, my $link, my $slink, my $tlink, my $sparent, my $tparent, my $schildren, my $tchildren)=@_;
  (my $parentpair, my $snode, my $tnode, my $sparnode, my $tparnode, my $childrensize);

#  my $size=keys(%{$tchildren});
#  print "size of tchildren: $size\n";
  
  if (defined $$sparent{$slink}) {
    $sparnode=$$sparent{$slink};
    if (defined $$tparent{$tlink}) {
      $tparnode=$$tparent{$tlink};
      $parentpair=$sparnode."__".$tparnode;
      unless (defined $$link{$parentpair}) { ## i.e. current pair ($slink and $tlink) is linked but their parents ($sparnode and $tparnode) are not
        $childrensize=keys(%{$$schildren{$sparnode}});
        if ($childrensize == 1) {
          $childrensize=keys(%{$$tchildren{$tparnode}});
          if ($childrensize == 1) {
            return (1,$parentpair);
          }
        }
      }
    }
  }
  return (0,"");
}

sub parentAlign {
    (my $self, my $link, my $slink, my $tlink, my $sparent, my $tparent, my $schildren, my $tchildren)=@_;
    (my $parentpair, my $snode, my $tnode, my $sparnode, my $tparnode, my $childrensize, my $ssisterslinked, my $tsisterslinked, my $child);
    (my @sourcechildren, my @targetchildren)=((),());
    (my %is_source_child, my %is_target_child)=((),());

#    my $size=keys(%{$tlink});
#    print "size: $size\n";

  if (defined $$sparent{$slink}) {
    $sparnode=$$sparent{$slink};
    if (defined $$tparent{$tlink}) {
      $tparnode=$$tparent{$tlink};
      $parentpair=$sparnode."__".$tparnode;
      if ((%{$$schildren{$sparnode}}) && (%{$$tchildren{$tparnode}})) {
        foreach (keys(%{$$schildren{$sparnode}})) {
          $child=$$schildren{$sparnode}{$_};
          $is_source_child{$child}=1;
          push(@sourcechildren,$child);
        }
       foreach (keys(%{$$tchildren{$tparnode}})) {
          $child=$$tchildren{$tparnode}{$_};
          $is_target_child{$child}=1;
          push(@targetchildren,$child);
       }
       foreach(@sourcechildren) {
          $child=$_;
#          foreach (keys(%{$slink})) {
#            print "key: $_ and value: $$slink{$_}\n";
#          }
#         if (defined $$slink{$child}) {
#           print "slink of $_: $$slink{$_}\n";
#         }
       }
      }
    }
  }
    return (0,"");
}

sub shareIdenticalSpecialWords { ## returns 1 if the current node pair share at least one identical word containing capital letters or numbers
  (my $self, my $snonterm, my $tnonterm)=@_;
  my $sleaves=$self->{-sleaves};
  my $tleaves=$self->{-tleaves};
  my $sword=$self->{-sword};
  my $tword=$self->{-tword};
  my %swords=();
  my $word;

  if (defined @{$$sleaves{$snonterm}}) {
    foreach(@{$$sleaves{$snonterm}}) {
      if (defined $$sword{$_}) {
	$word=$$sword{$_};
	if (($word =~ /[0-9]/) || ($word =~ /[A-Z]/)) {
	  $swords{$word}=1;
	}
      }
    }
  }

  if (defined @{$$tleaves{$tnonterm}}) {
    foreach(@{$$tleaves{$tnonterm}}) {
      if (defined $$tword{$_}) {
	$word=$$tword{$_};
	if (defined $swords{$word}) {
	  return 1;
	}
      }
    }
  }
 
  return 0;  
}

sub hasIdenticalStrings { ## ignoring punctuation
  (my $self, my $snonterm, my $tnonterm)=@_;
  my $sleaves=$self->{-sleaves};
  my $tleaves=$self->{-tleaves};
  my $sword=$self->{-sword};
  my $tword=$self->{-tword};
  
  (my $sstring, my $tstring)=("","");
  
  if (defined @{$$sleaves{$snonterm}}) {
    foreach(@{$$sleaves{$snonterm}}) {
      $sstring=$sstring." ".$$sword{$_};
    }
  }

  if (defined @{$$tleaves{$tnonterm}}) {
    foreach(@{$$tleaves{$tnonterm}}) {
      $tstring=$tstring." ".$$tword{$_};
    }
  }

  $sstring =~ tr/A-Z/a-z/;
  $tstring =~ tr/A-Z/a-z/;

  if ($sstring eq $tstring) {
    return 1;
  }
  else {
    return 0;
  }
}

sub shareGoodAlignments { ## only looking at word alignments
  (my $self, my $snonterm, my $tnonterm)=@_;
  
  my $linktype=$self->{-linktype};
  my $slink=$self->{-slink};
  my $tlink=$self->{-tlink};
  my $sleaves=$self->{-sleaves};
  my $tleaves=$self->{-tleaves};
  my $leaf; my $sourcelinked; my $link;
  my %exists=();
  
  if (defined @{$$sleaves{$snonterm}}) {
    foreach(@{$$sleaves{$snonterm}}) {
      $leaf=$_;
      if (defined $$slink{$leaf}) {
	$exists{$leaf}=1;
      }
    }
  }

  if (defined @{$$tleaves{$tnonterm}}) {
    foreach(@{$$tleaves{$tnonterm}}) {
      $leaf=$_;
      if (defined $$tlink{$leaf}) {
	$sourcelinked=$$tlink{$leaf};
	foreach (@{$sourcelinked}) {
	  $link=$_."__".$leaf;
	  if (defined $$linktype{$link}) {
	    if ((defined $exists{$_}) && ($$linktype{$link} eq "good")) {
	      return 1;
	    }
	  }
	}
      }
    }
  }

  return 0;
}

sub hasSpecialCharacterOneSide { ## currently, checking if < or > or & or = or * or ^ or $ or # or @ or + or _ or / or \ or ~ or { or } or [ or ] or | or a number occurs on only one side (not regular punctuation)
  (my $self, my $snonterm, my $tnonterm)=@_;
  my $sleaves=$self->{-sleaves};
  my $tleaves=$self->{-tleaves};
  my $sword=$self->{-sword};
  my $tword=$self->{-tword};
  (my $sstring, my $tstring)=("","");
  (my $source_has_special, my $target_has_special, my $found, my $i)=(0,0,0,0);
  my $curnode;

  if (defined @{$$sleaves{$snonterm}}) {
    $i=0;
    if (defined $$sleaves{$snonterm}[$i]) {
      while (($found == 0)  && (defined $$sleaves{$snonterm}[$i])) {
	$curnode=$$sleaves{$snonterm}[$i];
	if (defined $$sword{$curnode}) {
	  if ($$sword{$curnode} =~ /[@#\$%*[{}\\+=|<>~\]_&\^]/) {
	    $source_has_special=1;
	    $found=1;
	  }
	}
	$i++;
      }
    }
  }
      
  $found=0;

  if (defined @{$$tleaves{$tnonterm}}) {
    $i=0;
    if (defined $$tleaves{$tnonterm}[$i]) {
      while (($found == 0)  && (defined $$tleaves{$tnonterm}[$i])) {
	$curnode=$$tleaves{$tnonterm}[$i];
	if (defined $$tword{$curnode}) {
	  if ($$tword{$curnode} =~ /[@#\$%*[{}\\+=|<>~\]_&\^]/) {
	    $target_has_special=1;
	    $found=1;
	  }
	}
	$i++;
      }
    }
  }
  
  return ($source_has_special,$target_has_special);

}

sub hasPunctAtEitherEnd {
  (my $self, my $snonterm, my $tnonterm, my $side)=@_;
  my $sleaves=$self->{-sleaves};
  my $tleaves=$self->{-tleaves};
  my $sword=$self->{-sword};
  my $tword=$self->{-tword};
  my $has_punct=0;
  my $size; my $end; my $leaf;

  if ($side eq 's') {
    if (defined @{$$sleaves{$snonterm}}) {
      if (defined $$sleaves{$snonterm}[0]) {
	$leaf=$$sleaves{$snonterm}[0];
	if (defined $$sword{$leaf}) {
	  if (($$sword{$leaf} =~ /[[:punct:]]/) && ($$sword{$leaf} !~ /[^[:punct:]]/)) {
	    $has_punct=1;
	  }
	}
	$size=@{$$sleaves{$snonterm}};
	$end=$size-1;
	$leaf=$$sleaves{$snonterm}[$end];
	if (defined $$sword{$leaf}) {
	  if (($$sword{$leaf} =~ /[[:punct:]]/) && ($$sword{$leaf} !~ /[^[:punct:]]/)) {
	    $has_punct=1;
	  }
	}
      }
    }
  }

  elsif ($side eq 't') {
    if (defined @{$$tleaves{$tnonterm}}) {
      if (defined $$tleaves{$tnonterm}[0]) {
	$leaf=$$tleaves{$tnonterm}[0];
	if (defined $$tword{$leaf}) {
	  if (($$tword{$leaf} =~ /[[:punct:]]/) && ($$tword{$leaf} !~ /[^[:punct:]]/)) {
	    $has_punct=1;
	  }
	}
	$size=@{$$tleaves{$tnonterm}};
	$end=$size-1;
	$leaf=$$tleaves{$tnonterm}[$end];
	if (defined $$tword{$leaf}) {
	  if (($$tword{$leaf} =~ /[[:punct:]]/) && ($$tword{$leaf} !~ /[^[:punct:]]/)) {
	    $has_punct=1;
	  }
	}
      }
    }
  }

  return $has_punct;
}

sub getGeoScore { ## geometric averages of (linked) leaf ratio and difference between well-formed linked leaves and number of leaves
  (my $self, my $snonterm, my $tnonterm, my $count1, my $count2)=@_;
  my $difference; my $ratio;
  (my $maxcount, my $mincount)=(0,0);
  

  if (defined $count1 && $count2) {
    $difference=abs($count1-$count2);
    if ($count1 > $count2) {
      $maxcount=$count1;
    }
    else { $maxcount=$count2; }

    if ($maxcount != 0) {
      $ratio=$mincount/$maxcount;
    }
    else { return 1000; }

    return sqrt($difference*$ratio);
  }
  else { return 1000; }
}

sub wordsLinkedBothEnds {
  (my $self, my $snonterm, my $tnonterm)=@_;
  my $slink=$self->{-slink};
  my $tlink=$self->{-tlink};
  my $sleaves=$self->{-sleaves};
  my $tleaves=$self->{-tleaves};
#   my $sword=$self->{-sword};
#   my $tword=$self->{-tword};
  my $leaf; my $sourcelinked; my $targetlinked; my $link; my $size; my $end;
  my %s_exists=(); my %t_exists=();
  my $found=0;
#   my $sstring=""; my $tstring="";

  if (defined @{$$sleaves{$snonterm}}) {
    foreach(@{$$sleaves{$snonterm}}) {
      $s_exists{$_}=1;
#       $sstring=$sstring." ".$$sword{$_};
    }
  }

  if (defined @{$$tleaves{$tnonterm}}) {
    foreach(@{$$tleaves{$tnonterm}}) {
      $t_exists{$_}=1;
#       $tstring=$tstring." ".$$tword{$_};
    }
  }

  ## we check the first word on the source side
  if (defined $$sleaves{$snonterm}[0]) {
    $leaf=$$sleaves{$snonterm}[0];
    if (defined $$slink{$leaf}) {
      $sourcelinked=$$slink{$leaf};
      $found=0;
      foreach (@{$sourcelinked}) {
	if ($t_exists{$_}) {
	  $found=1;
	}
      }
      if ($found == 0) { ## if none of the links from the first source tree word link to any of the target tree spans, we return 0
	return 0;
      }
    } ## if the first word on the source side is not linked, we return 0
    else {
      return 0;
    }
  }
  else {
    warn ("First element of subtree of source side nonterminal $snonterm does not exist!");
    return 0;
  }
  
  ## now same for the last word on the source side
  $size=@{$$sleaves{$snonterm}};
  $end=$size-1;

  if (defined $$sleaves{$snonterm}[$end]) {
    $leaf=$$sleaves{$snonterm}[$end];
    if (defined $$slink{$leaf}) {
      $sourcelinked=$$slink{$leaf};
      $found=0;
      foreach (@{$sourcelinked}) {
	if ($t_exists{$_}) {
	  $found=1;
	}
      }
      if ($found == 0) { ## if none of the links from the last source tree word link to any of the target tree spans, we return 0
	return 0;
      }
    } ## if the last word on the source side is not linked, $endlinked is 0
    else {
      return 0;
    }
  }
  else {
    warn ("Last element of subtree of source side nonterminal $snonterm does not exist!");
    return 0;
  }

  ## now the same but for the first word on the target side
  if (defined $$tleaves{$tnonterm}[0]) {
    $leaf=$$tleaves{$tnonterm}[0];
    if (defined $$tlink{$leaf}) {
      $targetlinked=$$tlink{$leaf};
      $found=0;
      foreach (@{$targetlinked}) {
	if ($s_exists{$_}) {
	  $found=1;
	}
      }
      if ($found == 0) { ## if none of the links from the first target tree word link to any of the source tree spans, we return 0
	return 0;
      }
    } ## if the first word on the target side is not linked, $beginlinked is 0
    else {
      return 0;
    }
  }
  else {
    warn ("First element of subtree of target side nonterminal $tnonterm does not exist!");
    return 0;
  }
  
  ## now same for the last word on the target side
  $size=@{$$tleaves{$tnonterm}};
  $end=$size-1;

  if (defined $$tleaves{$tnonterm}[$end]) {
    $leaf=$$tleaves{$tnonterm}[$end];
    if (defined $$tlink{$leaf}) {
      $targetlinked=$$tlink{$leaf};
      $found=0;
      foreach (@{$targetlinked}) {
	if ($s_exists{$_}) {
	  $found=1;
	}
      }
      if ($found == 0) { ## if none of the links from the last target tree word link to any of the target tree spans, we return 0
	return 0;
      }
    } ## if the last word on the target side is not linked, $endlinked=0
    else {
      return 0;
    }
  }
  else {
    warn ("Last element of subtree of target side nonterminal $tnonterm does not exist!");
    return 0;
  }

#   print "Words are linked at either end.\n";
#   print "Sstring: $sstring\n";
#   print "Tstring: $tstring\n";
  return 1;
}

1;
