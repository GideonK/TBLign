package STA;
use Exporter;
@ISA = ('Exporter');
#use feature 'say';

sub new {
	my $class=shift;
	my %attr=@_;
	my $self={};

	bless $self,$class;
	foreach (keys %attr) {
		$self->{$_}=$attr{$_};
	}
	$self->{compressed}=0;
	return $self;
}

sub getFile {
  my $self=shift;
  my $stem;
  my $file=$self->{-file};

  if ($file =~ /(.*)\.gz$/) {
    $self->{compressed}=1;
    my $temp=$1;
    if ($temp =~ /(.*)\./) {
      $stem=$1;
    }
    else { $stem=$temp; }
    qx(gzip -cd $file > $stem.a.tmp);
    $self->{newfile}=$stem.".a.tmp";
  }
  if (defined $self->{newfile}) {
  	return $self->{newfile};
  }
  else { return $file; }
}

sub getStats {
	my $self=shift;
	my $file=shift;
## test
#my $testvar=shift;
#foreach (keys %{$testvar}) {
#  say $$testvar{$_};
#}
	my $fh=$self->{-filehandle};
	my (%linktype,%prob,%link,%author,%slink,%tlink)=((),(),(),(),(),());
	my ($sid,$tid,$author,$prob,$type,$curlink,$idprefix)=("","","","","","","");
#	print "STA file: $file\n";
	open ($fh, "<$file") || die ("Could not open alignment file ($file)!");
	my $in=<$fh>;
	while ((defined $in) && ($in=<$fh>)) {
		if ($in =~ /<align .*>/) {
			if ($in =~ /author="(.*?)"/) {
				$author=$1;
				if ($in =~ /type="(.*?)"/) {
					$type=$1;
					if ($in =~ /prob="(.*?)"/) {
						$prob=$1;
					}
					else {
						if ($type eq "good") {
							$prob=0.8;
						}
						elsif ($type eq "fuzzy") {
							$prob=0.4;
						}
						else { warn ("No (regular) type (\"good\" or \"fuzzy\") or probability specified on this line: $in")}
					}
				}
				else { warn("No probability specified on line: $in"); }
			}
			else { warn("No author specified on line: $in"); }
			$in=<$fh>;
			if (defined $in) {
				if ($in =~ /node_id="(s?)(.*?)"/) {
					$idprefix=$1;
					$sid=$2;
				}
				else { warn("No node ID found on this line: $in"); }
				$in=<$fh>;
				if (defined $in) {
					if ($in =~ /node_id="s?(.*?)"/) {
						$tid=$1;
					}
					else { warn("No node ID found on this line: $in"); }
				}
				else { die("Target node ID expected on this line but it is not defined!"); }
			}
			else { die("Source node ID expected on this line but it is not defined!"); }
		}
		if (($sid ne "") && ($tid ne "")) {
			$curlink=$sid."__".$tid;
			$link{$curlink}=1;
			if ($type ne "") {
				$linktype{$curlink}=$type;
			}
			if ($prob ne "") {
				$prob{$curlink}=$prob;
			}
			if ($author ne "") {
				$author{$curlink}=$author;
			}
			push(@{$slink{$sid}},$tid);
			push(@{$tlink{$tid}},$sid);
		}
		$sid="";
		$tid="";
		$type="";
		$prob="";
		$author="";
	}
	close ($fh);
	# say "STA size of linktype ".keys(%linktype);
	# say "STA size of prob ".keys(%prob);
	# say "STA size of link ".keys(%link);
	# say "STA size of author ".keys(%author);
	# say "STA size of slink: ".keys(%slink);
	# say "STA size of tlink: ".keys(%tlink);
	return (\%linktype,\%prob,\%link,\%author,\%slink,\%tlink,$idprefix);
}

sub get_n_sents {
  (my $self, my $begin, my $end, my $use_ids)=@_;
  (my @nsents, my @link)=((),());
  my $count=0;
  (my $sid, my $tid)=("","");

  my $fh=$self->{-filehandle};
  my $file=$self->{-file};
  open ($fh, "<$file") || die ("Could not open alignment file ($file)!");
  my $in=<$fh>;
  while ((defined $in) && ($in !~ /<alignments>/)) {
    push(@nsents,$in);
    $in=<$fh>;
  }
  push(@nsents,$in);
  while ((defined $in) && ($in=<$fh>)) {
    @link=();
    if ($in =~ /<align.*author="/) {
      while ((defined $in) && ($in !~ /<\/align>/)) {
	push(@link,$in);
	$in=<$fh>;
      }
      push(@link,$in);
      $count++;
      if ($link[1] =~ /node_id="s?([0-9]+)_/) {
	$sid=$1;
	if ($link[2] =~ /node_id="s?([0-9]+)_/) {
	  $tid=$1;
	}
	else {
	  die ("Unexpected line (target side node ID expected)!\nLine: $link[2]");
	}      
      }
      else {
	die ("Unexpected line (source side node ID expected)!\nLine: $link[1]");
      }
      if ($use_ids == 1) {
	if (($sid >= $begin) && ($sid <= $end) && ($tid >= $begin) && ($tid <= $end)) { ## this will be saved for printing to output
	  foreach(@link) {
	    push(@nsents,$_);
	  }
	}
      }
      elsif ($use_ids == 0) {
	if (($count >= $begin) && ($count <= $end)) { ## ditto
	  foreach(@link) {
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

sub generateAlign {
	(my $self, my $link, my $linktype, my $author, my $prob, my $sfile, my $tfile, my $idprefix, my $stype, my $ttype)=@_;
	my @out=();
	(my $snode, my $tnode, my $sid, my $linkssize);
	my @sents=();
######### change code here to change filenames to their absolute paths

	if ((defined $self) && (defined $link) && (defined $author) && (defined $prob) && (defined $sfile) && (defined $tfile)) {
		push(@out,"<treealign>\n");
		push(@out,"<head>\n");
		push(@out,"</head>\n");
		push(@out,"  <treebanks>\n");
		push(@out,"    <treebank filename=\"$sfile\" id=\"1\"/>\n");
		push(@out,"    <treebank filename=\"$tfile\" id=\"2\"/>\n");
		push(@out,"  </treebanks>\n");
		push(@out,"  <aligments>\n");
		
		foreach(keys(%{$link})) {
			if ($_ =~ /(\S+)__(\S+)/) {
				$snode=$1;
				$tnode=$2;
				if ($snode =~ /([0-9]+)_/) {
					$sid=$1;
					if ($tnode =~ /([0-9]+)_/) {
						push(@{$sents[$sid]},$_);
#						print "link: $_, snode: $snode, tnode: $tnode, sid: $sid, tid: $tid\n";
					}
				}
			}
		}
		my $linkssize=@sents;
		for (my $i=0; $i<=$linkssize; $i++) {
			if (defined $sents[$i]) {
				foreach(@{$sents[$i]}) {
					if ((defined $$author{$_}) && (defined $$prob{$_}) && (defined $$linktype{$_})) {
						if ($_ =~ /(\S+)__(\S+)/) {
							$snode=$1;
							$tnode=$2;
							if ((defined $$stype{$snode}) && (defined $$ttype{$tnode})) {
								push(@out, "    <align author=\"$$author{$_}\" prob=\"$$prob{$_}\" type=\"$$linktype{$_}\">\n");
								push(@out, "      <node node_id=\"$idprefix$snode\" type=\"$$stype{$snode}\" treebank_id=\"1\"/>\n");
								push(@out, "      <node node_id=\"$idprefix$tnode\" type=\"$$ttype{$tnode}\" treebank_id=\"2\"/>\n");
								push(@out, "    </align>\n");					
							}
							else {
								warn ("Not all features found for nodes $stype and $ttype!");
							}

						}
						else {
							warn ("Unexpected node pair format: $_");
						}
					}
					else { warn ("Not all features found for link $_!"); }
				}
			}
		} ## for (my $i=0; $i<=$linkssize; $i++) {
		my $size=@out;
		if ($size > 0) {
			push(@out," </alignments>\n");
			push(@out,"</treealign>\n");
		}
	}
	return(\@out);
}

sub cleanUp {
  my $self=shift;

  if (defined $self->{newfile}) {
    qx(rm $self->{newfile});
  }
}

1;

__END__

=head1 DESCRIPTION

This module provides a series of functions for processing an XML file in STA (Stockholm TreeAligner) format. Currently, the following functions are available:

=over

=item * new: The constructor

=item * getFile: Decompresses the file if necessary. Returns the decompressed file name or the original file name (if it wasn't compressed).

=item * getStats: Returns a set of statistics in the form of references to hashes about the file.

=item * cleanUp: If a temporary file was created from a compressed file, this is deleted.

=item * get_n_sents: Returns a specific set of sentences from the set, denoted by the variables $begin and $end. If $use_ids is 1, this is based on the ID numbers. If it is 0, a count of the sentences is used.

=back

=head1 AUTHOR

Gideon KotzE<eacute>, E<lt>g.j.kotze@rug.nlE<gt>

=cut

