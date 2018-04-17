#!/usr/bin/perl
#use strict;
package Treebank;
use Exporter;
#use feature 'say';
use List::Util qw[min max];
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
    $self->{'compressed'}=0;
    $self->{'leaves'}="";
    return $self;
}

sub getFile {
  my $self=shift;
  my $side=shift;
  my $stem;
  my $file=$self->{-file};

  if ($file =~ /(.*)\.gz$/) {
    $self->{'compressed'}=1;
    my $temp=$1;
    if ($temp =~ /(.*)\./) {
      $stem=$1;
    }
    else { $stem=$temp; }
    if ($side eq 's') {
      qx(gzip -cd $file > $stem.s.tmp);
      $self->{newfile}=$stem.".s.tmp";
    }
    elsif ($side eq 't') {
      qx(gzip -cd $file > $stem.t.tmp);
      $self->{newfile}=$stem.".t.tmp";
    }
  }
  if (defined $self->{newfile}) {
    return $self->{newfile};
  }
  else { return $file; }
}

sub getBasicStats {
  my $self=shift;
  my $file=shift;
  my $fh=$self->{-filehandle};
  my (%ids,%pos,%type,%cat)=((),(),(),());
  my $id;

  open ($fh, "<$file") || die ("Could not open treebank file ($file!)");
    my $in=<$fh>;
    while ((defined $in) && ($in=<$fh>)) {
      if ($in =~ /<t id="s?(.*?)"/) {
        $type{$1}="t";
        $ids{$1}=1;
        $id=$1;
        if ($in =~ /pos="(.*?)"/) {
          $pos{$id}=$1;
        }
      }
      if ($in =~ /<nt id="s?(.*?)"/) {
        $id=$1;
        $type{$id}="nt";
        $ids{$id}=1;
        if ($in =~ /cat="(.*?)"/) {
          $cat{$id}=$1;
        }
      }
    }
  close ($fh);
  return (\%ids,\%pos,\%type,\%cat);
}


sub getAllStats {
  my $self=shift;
  my $file=shift;
  my $fh=$self->{-filehandle};
  my (%ids, %pos, %type, %cat, %word, %parent, %children, %childrenposition, %leaves, %edge, %terms, %nonterms, @sentids, %height, %heights, %maxheight, %nodesonheight, %has_nonterminal_unary_daughter, %has_nonterminal_unary_daughter_except_punct)=((),(),(),(),(),(),(),(),(),(),(),(),(),(),(),(),(),());
  my ($cursent,$id,$childrencount,$childposition,$idref,$node,$childnode,$isdefined,$height,$key,$parent,$ntcount,$tcount,$notpunct);
  my (@sentheights,@terminaldaughters,@leaves)=((),(),());

  open ($fh, "<$file") || die ("Could not open treebank file ($file!)");

  my $in=<$fh>;

  while ((defined $in) && ($in !~ /<body>/)) {
    $in=<$fh>;
  }
  while ((defined $in) && ($in=<$fh>)) {
    if ($in =~ /<\/s>/) {
      if (defined $cursent) {
	push(@sentids,$cursent);
	foreach (@{$nonterms{$cursent}}) {
	  $node=$_;
	  $tcount=0;
	  $ntcount=0;
	  $childrencount=0;
	  @terminaldaughters=();
	  foreach (keys %{$children{$node}}) {
	    $childposition=$_;
	    if (defined $children{$node}{$childposition}) {
	      $childnode=$children{$node}{$childposition};
	      if ($type{$childnode} eq "nt") {
		$ntcount++;
	      }
	      elsif ($type{$childnode} eq "t") {
		$tcount++;
		push(@terminaldaughters,$childnode);
	      }
	      $childrencount++;
	    }
	  }

	  if (($childrencount == 1) && ($ntcount == 1)) { ## checking if there is exactly one daughter node which is a nonterminal: indicates a unary relation
	    $childnode=$children{$node}{0};
	    unless (defined $childnode) {
	      warn "Expected defined node not defined (parent: $id, file handle: $fh)!";
	    }
	    else {
	      $has_nonterminal_unary_daughter{$node}=1;
	    }
	  }
	  else {
	      $has_nonterminal_unary_daughter{$node}=0;
	  }
	  
	  if (($childrencount > 1) && ($ntcount == 1)) { ## in the case of only one nonterminal daughter and at least one other terminal daughter, checks if all the terminals are punctuation. This distinction is often the only difference between top nodes and SENT nodes (at least for Dutch/Alpino).
	    $notpunct=0;
	    foreach(@terminaldaughters) {
	      unless (defined $word{$_}) {
		warn ("No token defined for node $_ (parent: $id, file handle: $fh)!");
	      }
	      else {
		if (($word{$_} ne ",") && ($word{$_} ne ".") && ($word{$_} ne ":") && ($word{$_} ne "_") && ($word{$_} ne "-") && ($word{$_} ne "(") && ($word{$_} ne ")") && ($word{$_} ne "[") && ($word{$_} ne "]") && ($word{$_} ne "{") && ($word{$_} ne "}") && ($word{$_} ne "\"") && ($word{$_} ne "'") && ($word{$_} ne "~") && ($word{$_} ne "`") && ($word{$_} ne "+") && ($word{$_} ne "=") && ($word{$_} ne ";") && ($word{$_} ne "?") && ($word{$_} ne "/") && ($word{$_} ne "\\") && ($word{$_} ne "!") && ($word{$_} ne "<") && ($word{$_} ne "<") && ($word{$_} ne "\@") && ($word{$_} ne "#") && ($word{$_} ne "\$") && ($word{$_} ne "%") && ($word{$_} ne "^") && ($word{$_} ne "&") && ($word{$_} ne "*") && ($word{$_} ne "|")) {
		  $notpunct=1;
		}
	      }
	    }
	    if ($notpunct == 0) { ## all terminal nodes are punctuation marks
	      $has_nonterminal_unary_daughter_except_punct{$node}=1;
	    }
	    else {
	      $has_nonterminal_unary_daughter_except_punct{$node}=0;
	    }
	  } ## if (($childrencount > 1) && ($ntcount == 1)) {
	  else {
	      $has_nonterminal_unary_daughter_except_punct{$node}=0;
	  }

	} ## foreach (@{$nonterms{$cursent}}) {
      } ## if (defined $cursent)
 
    } ## if ($in =~ /<\/s>/) {

    if ($in =~ /<s id="s?([0-9]+)"/) {
      $cursent=$1;
    }
    if ($in =~ /<t id="s?(.*?)"/) {
      $id=$1;
      $ids{$id}=1;
      $type{$id}="t";
      push (@{$terms{$cursent}},$id);
      if ($in =~ /<t id.*word="(.*?)"/) {
	$word{$id}=$1;
      }
      if ($in =~ /<t id.*pos="(.*?)"/) {
	$pos{$id}=$1;
      }
    }
    if ($in =~ /<nt id="s?(.*?)"/) {
      $id=$1;
      $ids{$id}=1;
      $type{$id}="nt";
      if ($in =~ /<nt id.*cat="(.*?)"/) {
	$cat{$id}=$1;
      }
      $childrencount=0;
      $tcount=0;
      $ntcount=0;
      @terminaldaughters=();
      push (@{$nonterms{$cursent}},$id);
      while ($in !~ /<\/nt>/) {
	if ($in =~ /idref="s?(.*?)"/) {
	  $idref=$1;
	  $parent{$idref}=$id;
	  $children{$id}{$childrencount}=$idref;
	  $childrenposition{$idref}=$childrencount;
	  $childrencount++;
	  if ($in =~ /label="(.*?)"/) {
	    $edge{$idref}=$1;
	  }
	}
	$in=<$fh>;
      }
    } ## if ($in =~ /<nt id="s?(.*?)"/) {
  } ## while ((defined $in) && ($in=<$fh>)) {

  ## getting heights
  $isdefined=1;
  $height=0;
  
## first traversing through terminals and their parents recursively, assigning counts to the nonterminal nodes.
  foreach (keys(%terms)) {
    $key=$_;
    foreach(@{$terms{$key}}) {
      $isdefined=1;
      $height=0;
      $node=$_;
      if (defined $parent{$node}) {
	$node=$parent{$node};
	$height++;
	push(@{$heights{$node}},$height);
	while ($isdefined == 1) {
	  $node=$parent{$node};
	  if (defined $node) {
	    $height++;
	    push(@{$heights{$node}},$height);
	  }
	  else {
	    $isdefined=0;
	  }
	}
      }
    }
  }

  ## Traversing through nonterminals and for each one, selecting the maximum assigned height count to be the actual height. Also extracting the leaves for each node.
  foreach (keys(%nonterms)) {
    $key=$_;
    @sentheights=();
    foreach(@{$nonterms{$key}}) {
      $node=$_;
      $height{$node}=max(@{$heights{$node}});
      if (defined $height{$node}) {
	push(@{$nodesonheight{$key}{$height{$node}}},$node); ## adding to the list of nodes on this particular height for $key (the sentence ID)
	push(@sentheights,$height{$node});
      }
      $self->{'leaves'}="";
      $self->getLeaves($node,\%children,\%type);
      chop($self->{'leaves'});
      @leaves=split(/ /,$self->{'leaves'});
      foreach(@leaves) {
	push(@{$leaves{$node}},$_);
      }
    }
    $maxheight{$key}=max(@sentheights);
  }

  close ($fh);
  return (\%ids,\%word,\%pos,\%type,\%cat,\%terms,\%nonterms,\@sentids,\%parent,\%children,\%childrenposition,\%leaves,\%edge,\%height,\%maxheight,\%nodesonheight,\%has_nonterminal_unary_daughter,\%has_nonterminal_unary_daughter_except_punct);
}


sub getLeaves {
  my ($self,$node,$children,$type)=@_;
  (my $childnode, my $size);

  if (defined $$children{$node}) {
    $size=keys(%{$$children{$node}});
    for (my $i=0; $i<$size; $i++) {
      $childnode=$$children{$node}{$i};
      if (defined $childnode) {
	if ($$type{$childnode} eq "t") {
	  $self->{'leaves'}=$self->{'leaves'}.$childnode." ";
	}
	else {
	  $self->getLeaves($childnode,\%{$children},\%{$type});
	}
      }
    }
  }
  return "";
}

sub get_n_sents {
  (my $self, my $begin, my $end, my $use_ids)=@_;
  (my @nsents, my @sent)=((),());
  my $count=0;
  my $sentid=0;

  my $fh=$self->{-filehandle};
  my $file=$self->{-file};
  open ($fh, "<$file") || die ("Could not open treebank file ($file) (file handle: $fh)");

  my $in=<$fh>;
  while ((defined $in) && ($in !~ /<body>/)) {
    push (@nsents, $in);
    $in=<$fh>;
  }
  push (@nsents, $in);
  while ((defined $in) && ($in=<$fh>)) {
    @sent=();
    if ($in =~ /<s id="s?([0-9]+)"/) {
     $sentid=$1;
      while ((defined $in) && ($in !~ /<\/s>/)) {
	push(@sent,$in);
	$in=<$fh>;
      }
      push (@sent,$in);
      $count++;
      if ($use_ids == 1) {
#say "sentid: $sentid begin: $begin end: $end";
	$sentid=$sentid+0;
	if (($sentid >= $begin) && ($sentid <= $end)) {
	  foreach(@sent) {
#say $_;
	    push(@nsents,$_);
	  }
	}
      }
      elsif ($use_ids == 0) {
	if (($count >= $begin) && ($count <= $end)) {
	  foreach(@sent) {
	    push(@nsents,$_);
	  }
	}
      }
    }
    else {
      push(@nsents,$in);
    }
  }
  
  close ($fh);
  return \@nsents;
}

sub cleanUp {
  my $self=shift;

  if (defined $self->{newfile}) {
    qx(rm $self->{newfile});
  }
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

