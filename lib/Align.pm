#!/usr/bin/perl
package Align;
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
  (my $self, my $file, my $sfile, my $tfile)=@_;
  my $handle=$self->{-filehandle};
  my $already=0;
  my $in;
  my @head=(); my @body=(); my @tail=();

  open ($handle, "<$file");

## get head
  $in=<$handle>;
  while ((defined $in) && ($in !~ /<alignments>/)) {
    if ($in =~ /(.*<treebank.*filename=")(.*?)(".*)/) {
      if ($already == 0) {
	$in=$1.$sfile.$3."\n";
	$already++;
      }
      elsif ($already == 1) {
	$in=$1.$tfile.$3."\n";
      }
    }
    push(@head,$in);
    $in=<$handle>;
  }
  if (defined $in) {
    push(@head,$in);
  }
  $in=<$handle>;

## get body
  while ((defined $in) && (($in =~ /<alignments>/) || ($in =~ /<\/align>/) || ($in =~ /<align\s+/) || ($in =~ /<node\s+/))) {
    push(@body,$in);
    $in=<$handle>;
  }

## get tail
  while (defined $in) {
    push(@tail,$in);
    $in=<$handle>;
  }

  close ($handle);

  return (\@head,\@body,\@tail);
}

sub writeAlignOrder {
  (my $self, my $sents, my $toskip, my $handle, my $outfile, my $head, my $tail)=@_;
  my $count=1;
  my $sent; my $size; my $towrite; my $in;

  open ($handle, ">$outfile") || die ("Could not open output alignment file ($outfile)!");

## writing head

  foreach(@{$head}) {
    print $handle $_;
  }

## writing body, without the sentences to be skipped and in counting order
  $size=keys(%{$sents});
  for ($sent=1; $sent<=$size; $sent++) { ## assuming that original sentences are in counting order and starting at 1
    if (defined $$sents{$sent}) {
      unless (defined $$toskip{$sent}) { ## we write the following unless it occurs in the list of sentences to skip
	if ($count == $sent) {
	  foreach (@{$$sents{$sent}}) {
	    print $handle $_;
	  }
	}
	else {
	  foreach (@{$$sents{$sent}}) {
	    $in=$_;
	    if ($in =~ /(.*node_id=".?)([0-9]+)(_.*)/) {
	      $towrite=$1.$count.$3."\n";
	    }
	    else {
	      $towrite=$in;
	    }
	    print $handle $towrite;
	  }
	}
	$count++; ## we only count when a sentence is written;
      }
    } ## unless (defined $toskip{$sent}) {
  }
  
## writing tail

  foreach(@{$tail}) {
    print $handle $_;
  }

## test
#    $size=keys(%asents_count);
#    for ($sent=1; $sent<=$size; $sent++) {
#      foreach (@{$asents_count{$sent}}) {
#        print $_;
#      }
#    }

  close ($handle);
}

sub getSents {
  (my $self, my $file, my $body)=@_;

  my %sents=();
  my $in; my $cursent; my $sid, my $tid; my $id;
  my @link=();
  my $already=0;

   foreach(@{$body}) {
    $in=$_;
    push(@link,$in);
    if ($in =~ /<\/align>/) {
      if (defined $cursent) {
	foreach(@link) {
	  push(@{$sents{$cursent}},$_);
	}
      }
      @link=();
      $already=0;
    }
    if ($in =~ /node_id=".?([0-9]+)_/) {
      $id=$1;
      if ($already == 0) { ## first occurrence, i.e. source tree node reference
	$already++;
	$sid=$id;
      }
      elsif ($already == 1) {
	$tid=$id;
	if ($sid != $tid) {
	  warn ("Source tree ID ($sid) not the same as target tree ID ($tid)!");
	}
	$cursent=$sid;
      }
    }
   }

  return \%sents;
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

sub getCountingOrder {
  (my $self, my $alignments)=@_;
  my $in; my $curid; my $sent; my $sentid; my $size;
  my $sentcount=1; my $maxvalue=0;
  my %orderedsents=();
  
  $size=keys(%{$alignments});

  foreach $sentid (keys %{$alignments}) {
    if ($sentid > $maxvalue) {
      $maxvalue=$sentid;
    }
  }

  for (my $sentid=0; $sentid<=$maxvalue; $sentid++) {
    if (defined $$alignments{$sentid}) {
#print "sentid: $sentid and sentcount: $sentcount\n";
      foreach(@{$$alignments{$sentid}}) {
	$in=$_;
	if ($in =~ /node_id=".?([0-9]+)_/) {
	  $curid=$1;
	  if ($curid != $sentcount) {
	    $in =~ s/(^.*node_id=".?)[0-9]+(_.*$)/$1$sentcount$2/;
	  }
	}
	push(@{$orderedsents{$sentcount}},$in);
      }
      $sentcount++;
    }
  }

#    foreach(keys %orderedsents) {
#      print "$_\n";
#    }

  return (\%orderedsents);
}

sub writeOrderedSet {
  (my $self, my $head, my $sents, my $tail, my $handle, my $outfile)=@_;
  my $in;
  my $maxvalue=0;

  open ($handle, ">$outfile") || die ("Could not open output alignment file ($outfile)!");

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

=item * getHeadBodyTail: Identifies and returns the head, body and tail of the file in the form of hash references. The head is changed to reflect the paths and names of the output treebank files.

=item * getBasicStats: Returns a set of basic statistics in the form of references to hashes about the file.

=item * getAllStats: Returns a more comprehensive set of statistics on the treebank.

=item * cleanUp: If a temporary file was created from a compressed file, this is deleted.

=item * get_n_sents: Returns a specific set of sentences from the set, denoted by the variables $begin and $end. If $use_ids is 1, this is based on the ID numbers. If it is 0, a count of the sentences is used.

=back

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>g.j.kotze@rug.nlE<gt>

=cut

