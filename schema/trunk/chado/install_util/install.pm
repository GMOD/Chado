use strict;
use Carp 'croak';
use File::Basename qw( basename fileparse );
use IO::Dir;
use lib "../lib";
use Bio::GMOD::Config;

sub copy_tree {
  my ($src,$dest) = @_;
  if (-f $src) {
    copy_no_substitutions($src,$dest) or die "copy_with_substitutions($src,$dest): $!";
    return 1;
  }
  croak "$src doesn't exist" unless -e $src;
  croak "Usage: copy_tree(\$src,\$dest).  Can't copy a directory into a file or vice versa" 
    unless -d $src && -d $dest;
  croak "Can't read from $src" unless -r $src;
  croak "Can't write to $dest" unless -w $dest;

  my $tgt = basename($src);

  # create the dest if it doesn't exist
  mkdir ("$dest/$tgt",0777) or die "mkdir($dest/$tgt): $!" unless -d "$dest/$tgt";
  my $d = IO::Dir->new($src) or die "opendir($src): $!";
  while (my $item = $d->read) {
    # bunches of things to skip
    next if $item eq 'CVS';
    next if $item =~ /^\./;
    next if $item =~ /~$/;
    next if $item =~ /^\#/;
    if (-f "$src/$item") {
      copy_no_substitutions("$src/$item","$dest/$tgt") or die "copy_with_substitutions('$src/$item','$dest/$tgt'): $!";
    } elsif (-d "$src/$item") {
      copy_tree("$src/$item","$dest/$tgt");
    }
  }
  1;
}

sub copy_no_substitutions {
  my ($localfile,$install_file) = @_;
  open (IN,$localfile) or warn "Couldn't open $localfile: $!";
  my $basename = basename($localfile);
  my $dest = -d $install_file ? "$install_file/$basename" : $install_file;
  open (OUT,">$dest") or die "Couldn't open $install_file for writing: $!";
  if (-T IN) {
    while (<IN>) {
      print OUT;
    }
  }
  else {
    binmode OUT;
    my $buffer;
    print OUT $buffer while read(IN,$buffer,5000);
  }
  close OUT;
  close IN;
}

1;

