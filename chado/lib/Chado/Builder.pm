package Chado::Builder;
use strict;
use base 'Module::Build';
use Data::Dumper;
use Template;
use XML::Simple;
use LWP::Simple qw(mirror is_success status_message);
no warnings;

=head1 ACTIONS

=item foo()

this is an example target

=item ncbi()

fixfixfix

=item mageml()

fixfixfix

=item ontologies()

loads ontologies by running load_ontology.pl on all files in
$(DATA)/ontology

=item tokenize()

processes templates specified in configuration file, filling in
platform-specific variable values

=item _last

=cut

# create an ACTION_whatever method to implement a particular build target
sub ACTION_foo {
  print "I'm fooing to death!\n";
}

sub ACTION_ncbi
{
  # the build object $m
  my $m = shift;
  # the XML config object
  my $conf = $m->conf;

  # print out the available refseq datasets
  my %ncbis = printAndReadOptions($m,$conf,"ncbi");
  #print Dumper(%ncbis);

}

sub ACTION_mageml {
  my $m = shift;
  my $conf = $m->conf;

  print "Available MAGE-ML annotation files:\n";

  my $i = 1;
  my %ml = ();
  foreach my $mageml (sort keys %{ $conf->{mageml} }){
	$ml{$i} = $mageml;
	print "[$i] $mageml\n";
	$i++;
  }
  print "\n";

  my $chosen = $m->prompt("Which ontologies would you like to load (Comma delimited)? [0]");
  $m->notes('affymetrix' => $chosen);

  my %mageml = map {$ml{$_} => $conf->{mageml}{$ml{$_}}} split ',',$chosen;

  foreach my $mageml (keys %mageml){
	print "fetching files for $mageml\n";

	my $load = 0;
    foreach my $file (@{ $mageml{$mageml}{file} }){

	  my $fullpath = $conf->{path}{data}.'/'.$file->{local};
	  $fullpath =~ s!^(.+)/[^/]*!$1!;

      if(! -d $fullpath){
        system( 'mkdir','-p',$fullpath ) or print "!possible problem, couldn't mkdir -p $fullpath: $!\n";
      }

      print "  +",$file->{remote},"\n";
      $load = 1 if $m->_mirror($file->{remote},$file->{local});
	  $load = 1 if !$m->_loaded($conf->{'path'}{'data'}.'/'.$file->{'local'});

	  next unless $load;

      print "    loading...";

      if(! system('./load/bin/load_affymetrix.pl',
				  $conf->{'path'}{'data'}.'/'.$file->{'local'},
				 ) && (print "failed: $!\n" and die)
		){

		$m->_loaded( $conf->{'path'}{'data'}.'/'.$file->{'local'} , 1 );
		print "done!\n";
	  }
	}
  }
}
sub ACTION_ontologies {
  my $m = shift;
  my $conf = $m->conf;

  print "Available ontologies:\n";

  my $i = 1;
  my %ont = ();
  foreach my $ontology (sort keys %{ $conf->{ontology} }) {
    $ont{$i} = $ontology;
    print "[$i] $ontology\n";
    $i++;
  }
  print "\n";

  my $chosen = $m->prompt("Which ontologies would you like to load (Comma delimited)? [0]");
  $m->notes('ontologies' => $chosen);
  
  my %ontologies = map {$ont{$_} => $conf->{ontology}{$ont{$_}}} split ',',$chosen;

  foreach my $ontology (keys %ontologies){
    print "fetching files for $ontology\n";

    my $load = 0;
    foreach my $file (grep {$_->{type} eq 'definitions'} @{ $ontologies{$ontology}{file} }){
      my $fullpath = $conf->{path}{data}.'/'.$file->{local};
      $fullpath =~ s!^(.+)/[^/]*!$1!;

      if(! -d $fullpath){
        system( 'mkdir','-p',$fullpath ) or print "!possible problem, couldn't mkdir -p $fullpath: $!\n";
      }

      print "  +",$file->{remote},"\n";
      $load = 1 if $m->_mirror($file->{remote},$file->{local});
    }

    my($deffile) = grep {$_ if $_->{type} eq '  print "Available ontologies:\n";

  my $i = 1;
  my %ont = ();
  foreach my $ontology (sort keys %{ $conf->{ontology} }) {
    $ont{$i} = $ontology;
    print "[$i] $ontology\n";
    $i++;
  }
  print "\n";definitions'} @{ $ontologies{$ontology}{file} };
    foreach my $ontfile (grep {$_->{type} eq 'ontology'} @{ $ontologies{$ontology}{file} }){
      print "  +",$ontfile->{remote},"\n";

      $load = 1 if $m->_mirror($ontfile->{remote},$ontfile->{local});
	  $load = 1 if !$m->_loaded($conf->{'path'}{'data'}.'/'.$ontfile->{'local'});

	  next unless $load;

      print "    loading...";

      if(! system('./load/bin/load_ontology.pl',
				  $conf->{'path'}{'data'}.'/'.$ontfile->{'local'},
				  $conf->{'path'}{'data'}.'/'.$deffile->{'local'},
				 ) && (print "failed: $!\n" and die)
		){
		_loaded( $conf->{'path'}{'data'}.'/'.$ontfile->{'local'} , 1 );
		print "done!\n";
	  }
    }
  }
}

sub ACTION_tokenize {
  my $m = shift;
  my $conf = $m->conf;

  my $template = Template->new({
    INTERPOLATE  => 0,
    RELATIVE     => 1,
  }) || die "Template error: $Template::ERROR\n";

  foreach my $tt2file ( keys %{ $m->conf->{tt2} } ){
    my $tokenized;
    $template->process($tt2file, $conf->{tt2}->{$tt2file}->{token}, \$tokenized) || die "Template error: ".$template->error()."\n";

    open(O,'>'.$conf->{tt2}->{$tt2file}->{output});
    print O $tokenized;
    close(O);
  }
}

=head1 NON-ACTIONS

=cut

=head2 printAndReadOptions

 Title   : printAndReadOptions
 Usage   : prints out and reads options from the XML file
 Function:
 Example :
 Returns :
 Args    : m=build obj, conf=conf obj, option=which option to pull from the conf XML file


=cut
sub printAndReadOptions
{
   my ($m,$conf,$option) = @_;
   print "Available $option Items:\n";

   my $i = 1;
   my %itm = ();
   foreach my $item (sort keys %{ $conf->{$option} })
   {
     $itm{$i} = $item;
     print "[$i] $item\n";
     $i++;
   }
   print "\n";

   my $chosen = $m->prompt("Which items would you like to load (Comma delimited)? [0]");
   $m->notes("$option"."s" => $chosen);

   my %options = map {$itm{$_} => $conf->{$option}{$itm{$_}}} split ',',$chosen;
   return(%options);
}

sub property {
  my $m = shift;
  my $key  = shift;
  my $val  = $m->{properties}{$key};
  $val     =~ s/^$key=//;
  return $val;
}

sub conf {
  my $self = shift;
  return $self->{conf} if defined $self->{conf};

  my $file = $self->property('load_conf');
  $self->{conf} = XMLin($file, forcearray => ['token','path','file'], keyattr => [qw(tt2 input token name file)], ContentKey => '-value');
#warn Dumper($self->{conf});
  return $self->{conf};
}

sub _loaded {
  my $m = shift;
  my $conf = $m->conf;
  my ($file,$touch) = @_;
  $file .= '_'. $conf->{'tt2'}{'load/tt2/Makefile.tt2'}{'token'}{'touch_ext'};

  if($touch){
	open(T,'>'.$file);
    print T "\n";
	close(T);
	return 1;
  } else {
	return 1 if -f $file;
	return 0;
  }
}

sub _mirror {
  my $m = shift;
  my $conf = $m->conf;
  my ($remote,$local) = @_;
  $local = $conf->{'path'}{'data'} .'/'. $local;

  if( $m->_loaded($local) ){
	print "  already loaded, remove touchfile to reload.  skipping\n";
	return 0;
  }

  #mirror the file
  my $rc = mirror($remote, $local);

  if ($rc == 304) {
    print "    ". $local ." is up to date\n";
    return 0;
  } elsif (!is_success($rc)) {
    print "    $rc ", status_message($rc), "   (",$remote,")\n";
    return 0;
  } else {
    #file is new, load it
    print "    updated\n";
    return 1;
  }
}

1;
