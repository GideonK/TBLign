#!/usr/bin/perl
package Text;
use Exporter;

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

sub findHashDuplicates {
  (my $self, my $words, my $side)=@_;
  my %sentids=(); my %duplicates=(); my %dupes=(); my @uniquelist=(); my @curlist=(); my @sortedlist=();
  my $sentid; my $sent; my $duplicate;
  my $has_duplicates=0; my $count=0;

  foreach (keys %{$words}) {
    $sentid=$_;
    $sent=$$words{$sentid};
     if (defined $sentids{$sent}) { ## duplicate is found
      $has_duplicates=1;
      if (defined $duplicates{$sent}) {
	$duplicates{$sent}=$duplicates{$sent}." ".$sentids{$sent}." ".$sentid;
      }
      else {
	$duplicates{$sent}=$sentids{$sent}." ".$sentid;
      }
     } ## if (defined $sentids{$sent}) {
     else {
       $sentids{$sent}=$sentid;
     }
  }

  if ($has_duplicates==0) {
    if (defined $$side) {
      if ($$side eq 's') {
	print "No duplicates found on source side.\n";
      }
      elsif ($$side eq 't') {
	print "No duplicates found on target side.\n";
      }
    }
    else {
      print "No duplicates found.\n";
    }
  }
  else {
    if (defined $$side) {
      if ($$side eq 's') {
	print "Duplicates found in these source side sentences:\n";
      }
      elsif ($$side eq 't') {
	print "Duplicates found in these target side sentences:\n";
      }
    }
    else {
      print "Duplicates found in these sentences:\n";
    }
    foreach (keys %duplicates) {
      $sent=$_;
      $values=$duplicates{$sent};
      @curlist=split(/ /, $values);
      @uniquelist=();
      foreach(@curlist) {
	unless(defined $dupes{$_}) {
	  push(@uniquelist,$_);
	  $dupes{$_}=1;
	}
      }
      @sortedlist=sort {$a <=> $b} @uniquelist;
      foreach(@sortedlist) {
	print "$_ ";
      }
      if (@sortedlist) {
	print "\n";
      }
    }
  }
}

1;