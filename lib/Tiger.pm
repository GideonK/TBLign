#!/usr/bin/perl
package Tiger;
use Exporter;
use Text;

sub new {
    my $class=shift;
    my %attr=@_;
    my $self={};
    
    bless $self,$class;
    foreach (keys %attr) {
       $self->{$_}=$attr{$_};
    }
    return $self;
}

sub openFile {
  ## files are opened and alignment head is written to an array
  my $self=shift;
  my $stem; my $temp;
  my $compressed=0;
  my $file=$self->{-file};

  if ($file =~ /(.*)\.gz$/) {
    $temp=$1;
    if ($temp =~ /(.*)\./) {
	$stem=$1;
    }
    else { $stem=$temp; }
    qx(gzip -cd $file > $stem.tmp);
    $file=$stem.".tmp";
    $compressed=1;
  }

  return ($file,$compressed);
}

sub getHeadBodyTail {
  my $self=shift;
  my $file=shift;
  my $handle=$self->{-filehandle};

  my $in;
  my @head=(); my @body=(); my @tail=();

  open ($handle, "<$file");

  $in=<$handle>;

## get head 
  while ((defined $in) && ($in !~ /<body>/)) {
    push(@head,$in);
    $in=<$handle>;
  }
  if (defined $in) {
    push(@head,$in);
  }
  $in=<$handle>;

## get body
  while ((defined $in) && (($in =~ /<body>/) || ($in =~ /^\s*$/) || ($in =~ /<s\s+/) || ($in =~ /<t\s+/) || ($in =~ /<t\s+/) || ($in =~ /<nt\s+/) || ($in =~ /<edge\s+/) || ($in =~ /<graph\s+/) || ($in =~ /<terminals/) || ($in =~ /<\/terminals/) || ($in =~ /<nonterminals/) || ($in =~ /<\/nt>/) || ($in =~ /<\/nonterminals>/) || ($in =~ /<\/graph>/) || ($in =~ /<\/s>/))) {
    push(@body,$in);
    $in=<$handle>;
  }

## get tail
  while (defined $in) {
    push(@tail,$in);
    $in=<$handle>;
  }

  return(\@head,\@body,\@tail);
}

sub getSents {
  my $self=shift;
  my $file=shift;
  my $body=shift;

  my %sents=();
  my $in; my $cursent;

  foreach(@{$body}) {
    $in=$_;
    if ($in =~ /<s\s+id=".?([0-9]+)"/) {
      $cursent=$1;
    }
    if (defined $cursent) {
      push(@{$sents{$cursent}},$in);
    }
  }

  return \%sents;
}

sub makeHead {
  (my $self, my $oldhead, my $sents)=@_;
  my $sent; my $sentid; my $element; my $value; my $oldelement; my $label; my $topush; my $t1; my $t2; my $t3; my $size;
  my $leafcount=0;
  my @newhead=(); my @telements=(); my @telementslist=(); my @ntelements=(); my @ntelementslist=(); my @labelslist=();
  my %is_telements=(); my %telements=(); my %has_telements=(); my %is_ntelements=(); my %has_ntelements=(); my %myntelements=(); my %is_label=();
  
  foreach (keys %{$sents}) {
    $sentid=$_;
    foreach (@{$$sents{$sentid}}) {
      $sent=$_;
## check for empty sentence so we can skip it, also warning because it is erroneous
      if ($sent =~ /<\/s>/) {
	  if ($leafcount > 0) {
	      push(@leafcounts,$leafcount);
	  }
	  else {
	      warn ("Empty sentence!");
	  }
	  $leafcount=0;
      }
      
## getting the elements from terminal nodes
      if ($sent =~ /^\s*<t\s+/) {
	  $leafcount++;
	  @telements=split(/ /,$sent);
	  foreach(@telements) {
	      if ($_ =~ /(.*?)="(.*?)"/) {
		  $element=$1;
		  $value=$2;
		  if ( $element =~ /[^0-9A-Za-z_]/) { # anything else is an illegal character
		      my $oldelement=$element;
		      $element =~ s/[^0-9A-Za-z_]/_/g;
  		    unless (defined $t_changes{$oldelement}) {
  			$t_changes{$oldelement}=1;
  			$old_telement{$oldelement}=$element;
  		    }
		     }
		  unless (defined $is_telements{$element}) {
		    $is_telements{$element}=1; # this element now exists
		    push(@telementslist,$element); # new element, so we push them to a list
		  }
		  unless (defined $has_telements{$element}{$value}) {
		    push(@{$mytelements{$element}},$value); # pushing the specific value into an array of a hash for this element   
		    $has_telements{$element}{$value}=1;
		  }
		  
	      }
	  }
      }
  ## getting the elements from nonterminal nodes
      elsif ($sent =~ /<nt /) {
	  @ntelements=split(/ /,$sent);
	  foreach (@ntelements) {
	      if ($_ =~ /(.*?)="(.*?)"/) {
		  $element=$1;
		  $value=$2;
		  if ( $element =~ /[^0-9A-Za-z_]/) {
		      my $oldelement=$element;
		      $element =~ s/[^0-9A-Za-z_]/_/g;
  		    unless (defined $nt_changes{$oldelement}) {
  			$nt_changes{$oldelement}=1;
  			$old_ntelement{$oldelement}=$element;
  		    }
		     }
		  unless (defined $is_ntelements{$element}) {
		      $is_ntelements{$element}=1;
		      push(@ntelementslist,$element);
		  }
		  unless (defined $has_ntelements{$element}{$value}) {
		      push(@{$myntelements{$element}},$value); # pushing the specific value into an array of a hash for this element
		      $has_ntelements{$element}{$value}=1;
		  }
		  
	      }

	  }
      }
  ## getting the elements from node references
      elsif ($sent =~ /<edge /) {
	  if ($sent =~ /label="(.*?)"/) {
	      $label=$1;
	      if (defined $is_label{$label}) {
	      }
	      else {
		  $is_label{$label}=1;
		  push(@labelslist,$label);
	      }
	  }
      }
      
    } ## foreach (@{$$sents{$sent}}) {
    
    foreach (@{$oldhead}) {
#      print $_;
    }
  } ## foreach (keys %{$sents}) {
  
## creating new head

  my $i=0;
  if (defined $$oldhead[$i]) {
    while ($$oldhead[$i] !~ /<annotation>/) {
## checking for illegal characters and replacing them
      if ($$oldhead[$i] =~ /(.*id=")(.*?)(".*)/) {
	$t1=$1;
	$t2=$2;
	$t3=$3;
	$t2 =~ s/::/-/g;
	$t2 =~ s/:/-/g;
	$t2 =~ s/\s+/-/g;
	$topush = $t1.$t2.$t3."\n";
      }
      else {
	$topush=$$oldhead[$i];
      }
      push(@newhead,$topush);
      $i++;
    }
  }
## now $$oldhead of $i is on the line <annotation>, if it is defined
  push(@newhead,$$oldhead[$i]); ## <annotation>

## now adding terminal node elements
  foreach (@telementslist) {
	$size=@{$mytelements{$_}};
	if ($size > 200) {
	    push(@newhead, "     <feature name=\"".$_."\" domain=\"T\" />\n");
	}
	else {
	  push(@newhead, "      <feature name=\"".$_."\" domain=\"T\" >\n");
	$element=$_;
	foreach (@{$mytelements{$element}}) {
	  push(@newhead, "        <value name=\"".$_."\">--</value>\n");
	}
	  push(@newhead, "      </feature>\n");
	}    
  }

## Now we print features in nonterminal domain
  foreach (@ntelementslist) {
	  $size=@{$myntelements{$_}};
	  if ($size > 200) {
	      push(@newhead, "      <feature name=\"".$_."\" domain=\"NT\" />\n");
	  }
	  else {
	  $element=$_;
	  push(@newhead, "      <feature name=\"".$_."\" domain=\"NT\">\n");
	  foreach (@{$myntelements{$element}}) {
	    push(@newhead, "        <value name=\"".$_."\">--</value>\n");
	  }
	  push(@newhead, "      </feature>\n");
	  }
  }

  ## edge labels
  push(@newhead, "      <edgelabel>\n");
  foreach(@labelslist) {
    push(@newhead, "        <value name=\"".$_."\">--</value>\n");
  }
  push(@newhead, "      </edgelabel>\n");
  
  $i++;
  if ((defined $$oldhead[$i]) && ($$oldhead[$i] !~ /<\/annotation>/)) {
    while ((defined $$oldhead[$i]) && ($$oldhead[$i] !~ /<\/annotation>/)) {
      $i++;
    }
    ## now on </edgelabel>
    if ((defined $$oldhead[$i]) && ($$oldhead[$i] !~ /<s\s+id=/)) {
      while ((defined $$oldhead[$i]) && ($$oldhead[$i] !~ /<s\s+id=/)) {
	push(@newhead,$$oldhead[$i]);
	$i++;
      }
    }
  }

  return \@newhead;
}

sub writeTreeOrder {
  (my $self, my $sents, my $toskip, my $handle, my $outfile, my $head, my $tail)=@_;
  
  my $count=1;
  my $sent; my $size; my $towrite; my $in;

  open ($handle, ">$outfile") || die ("Could not open output file ($outfile)!");

  foreach (@{$head}) {
    print $handle $_;
  }

## writing body, without the sentences to be skipped and in counting order
  $size=keys(%{$sents});
  for ($sent=1; $sent<=$size; $sent++) { ## assuming that original sentences are in counting order and starting at 1
    if (defined $$sents{$sent}) {
      unless (defined $$toskip{$sent}) { ## we write the following unless it occurs in the list   
	if ($count == $sent) {
	  foreach (@{$$sents{$sent}}) {
	    print $handle $_;
	  }
	}
	else {
	  foreach (@{$$sents{$sent}}) {
	    $towrite="";
	    $in=$_;
## count doesn't match current sentence ID, so we have to replace all occurrences in the output in order to preserve counting order
 	    if ($in =~ /(.*<s\s+id=".?)([0-9]+)(.*)/) {
 	      $towrite=$1.$count.$3."\n";
 	    }
 	    elsif ($in =~ /(.*<graph\s+root=".?)([0-9]+)(.*)/) {
 	      $towrite=$1.$count.$3."\n";
 	    }
 	    elsif ($in =~ /(.*<t\s+id=".?)([0-9]+)(_.*)/) {
 	      $towrite=$1.$count.$3."\n";
 	    }
 	    elsif ($in =~ /(.*<nt\s+id=".?)([0-9]+)(_.*)/) {
 	      $towrite=$1.$count.$3."\n";
 	    }
 	    elsif ($in =~ /(.*idref=".?)([0-9]+)(_.*)/) {
 	      $towrite=$1.$count.$3."\n";
 	    }
 	    else {
	      $towrite=$in;
 	    }
 	    if ($towrite ne "") {
	      print $handle $towrite;
	    }
	  }
	}
      $count++; ## we only count when a sentence is written;
      }
    }
  }
  
## writing tail
  foreach(@{$tail}) {
    print $handle $_;
  }

## test
#    $size=keys(%ssents_count);
#    for ($sent=1; $sent<=$size; $sent++) {
#      foreach (@{$ssents_count{$sent}}) {
#        print $_;
#      }
#    }
  
  close ($handle);
}

sub findTigerDuplicates {
  (my $self, my $handle, my $infile, my $side)=@_;
  my %words=(); my %sent_exists=();
  my $in; my $word; my $cursent=0;
  
  open ($handle, "<$infile") || die ("Could not open TIGER-XML input file ($infile)!");
  
  $in=<$handle>;
  
  if (defined $in) {
    while (defined $in) {
      if ($in =~ /<s\s+id=".?([0-9]+)/) {
	if (defined $words{$cursent}) {
	  chop($words{$cursent});
	}
	$cursent=$1;
      }
      if ($in =~ /<t\s+.*id=".*/) {
	if ($in =~ /<t\s+.*word="(.*?)"/) {
	  $word=$1;
	  if (defined $words{$cursent}) {
	    $words{$cursent}=$words{$cursent}." ".$word;
	  }
	  else {
	    $words{$cursent}=$word;
	  }
	}
      }
      $in=<$handle>;
    }
  }
  
  close ($handle);

## test
#    %words=();
#    $words{1}="One sentence.";
#    $words{2}="One sentence.";
#    $words{3}="One sentence.";
#    $words{4}="Five sentence.";
#    $words{5}="Two sentence.";
#    $words{6}="Five sentence.";
  my $text=new Text();
#  $text->findHashDuplicates(\%words,\$side);
  $text->findHashDuplicates(\%words,\$side);
}

sub mergeSets {
  (my $self, my $sents1, my $sents2)=@_;
  my %mergesents=();
  my $size;
  my $sentcount=1;

  $size=keys(%{$sents1});
  for (my $sents=0; $sents<=$size; $sents++) {
    if (defined $$sents1{$sents}) {
      foreach(@{$$sents1{$sents}}) {
	push(@{$mergesents{$sentcount}},$_);
      }
      $sentcount++;
    }
  }

  $size=keys(%{$sents2});
  for (my $sents=0; $sents<=$size; $sents++) {
    if (defined $$sents2{$sents}) {
      foreach(@{$$sents2{$sents}}) {
	push(@{$mergesents{$sentcount}},$_);
      }
      $sentcount++;
    }
  }

  return (\%mergesents);
}

sub writeCountingOrder {
  (my $self, my $sents)=@_;
  my $in; my $curid; my $sent; my $sentid; my $size;
  my $sentcount=1; my $maxvalue=0;
  my %orderedsents=();
  
  $size=keys(%{$sents});

  foreach $sentid (keys %{$sents}) {
    if ($sentid > $maxvalue) {
      $maxvalue=$sentid;
    }
  }

  for (my $sentid=0; $sentid<=$maxvalue; $sentid++) {
    if (defined $$sents{$sentid}) {
      foreach(@{$$sents{$sentid}}) {
	$in=$_;
#  	    elsif ($in =~ /(.*<graph\s+root=".?)([0-9]+)(.*)/) {
#  	      $towrite=$1.$count.$3."\n";
#  	    }
#  	    elsif ($in =~ /(.*<t\s+id=".?)([0-9]+)(_.*)/) {
#  	      $towrite=$1.$count.$3."\n";
#  	    }
#  	    elsif ($in =~ /(.*<nt\s+id=".?)([0-9]+)(_.*)/) {
#  	      $towrite=$1.$count.$3."\n";
#  	    }
#  	    elsif ($in =~ /(.*idref=".?)([0-9]+)(_.*)/) {
#  	      $towrite=$1.$count.$3."\n";
#  	    }
	if ($in =~ /.*<s\s+id=".?([0-9]+).*/) {
	  $curid=$1;
	  if ($curid != $sentcount) {
	    $in =~ s/(.*<s\s+id=".?)[0-9]+(.*)/$1$sentid$2/;
	  }
	}
	elsif ($in =~ /.*<graph\s+root=".?([0-9]+).*/) {
	  $curid=$1;
	  if ($curid != $sentcount) {
	    $in =~ s/(.*<graph\s+root=".?)[0-9]+(.*)/$1$sentid$2/;
	  }
	}
	elsif ($in =~ /.*<t\s+id=".?([0-9]+)_.*/) {
	  $curid=$1;
	  if ($curid != $sentcount) {
	    $in =~ s/(.*<t\s+id=".?)[0-9]+(_.*)/$1$sentid$2/;
	  }
	}
	elsif ($in =~ /.*<nt\s+id=".?([0-9]+)_.*/) {
	  $curid=$1;
	  if ($curid != $sentcount) {
	    $in =~ s/(.*<nt\s+id=".?)[0-9]+(_.*)/$1$sentid$2/;
	  }
	}
	elsif ($in =~ /.*idref=".?([0-9]+)_.*/) {
	  $curid=$1;
	  if ($curid != $sentcount) {
	    $in =~ s/(.*idref=".?)[0-9]+(_.*)/$1$sentid$2/;
	  }
	}
	push(@{$orderedsents{$sentcount}},$in);
      }
      $sentcount++;
    }
  }

  return (\%orderedsents);
}

sub writeOrderedSet {
  (my $self, my $head, my $sents, my $tail, my $handle, my $outfile)=@_;
  my $in;
  my $maxvalue=0;

  open ($handle, ">$outfile") || die ("Could not open output treebank file file ($outfile)!");

## printing head
  foreach(@{$head}) {
    print $handle $_;
  }

  foreach (keys %{$sents}) {
    if ($_ > $maxvalue) {
      $maxvalue = $_;
    }
  }

## printing body in counting order but still leaving room for the possibility of missing IDs, keeping the original IDs in place
  for (my $i=0; $i<=$maxvalue; $i++) {
    if (defined $$sents{$i}) {
      foreach (@{$$sents{$i}}) {
	print $handle $_;
      }
    }
  }

## printing tail

  foreach(@{$tail}) {
    print $handle $_;
  }

  close ($handle);
}

sub get_n_sents {
  (my $self, my $sents, my $start, my $nr_of)=@_;
  my %newsents=();
  my $sentid;
  my $count=1;
  
  my $size=keys(%{$sents});
  for (my $i=0; $i<=$size; $i++ ) {
    if (defined $$sents{$i}) {
      $sentid=$i;
      if (($sentid >= $start) && ($count <= $nr_of)) {
	foreach(@{$$sents{$sentid}}) {
	  push(@{$newsents{$i}},$_); ## newsents of $i would return them in the same order (the first n ($nr_of)) starting at ID $start
	}
	$count++;
      }
      else {
	if ($count > $nr_of) {
	  return \%newsents;
	}
      }
    }
  }
  
  return \%newsents;
}


sub closeFile {
  (my $self, my $compressed, my $file)=@_;
  my $filehandle=$self->{-filehandle};

  if ($compressed == 1) {
    if ($file =~ /\.tmp/) { ## extra security check
      qx(rm $file); ## removes the temporary file that was created from decompressing the original file
    }
  }
  close($filehandle);
}

1;

=head1 DESCRIPTION

This module provides a series of functions for processing treebank in Tiger-XML format. Currently, the following functions are available:

=over

=item * new: The constructor

=item * getFile: Decompresses the file if necessary. Returns the decompressed file name or the original file name (if it wasn't compressed).

=item * getBasicStats: Returns a set of basic statistics in the form of references to hashes about the file.

=item * getAllStats: Returns a more comprehensive set of statistics on the treebank.

=item * cleanUp: If a temporary file was created from a compressed file, this is deleted.

=item * get_n_sents: Returns a specific set of sentences from the set, denoted by the variables $begin and $end. If $use_ids is 1, this is based on the ID numbers. If it is 0, a count of the sentences is used.

=back

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>g.j.kotze@rug.nlE<gt>

=cut

