package Chado::Builder;
use strict;
use base 'Module::Build';
use Data::Dumper;
use Template;
use XML::Simple;
use LWP::Simple qw(mirror is_success status_message);
use Log::Log4perl;
Log::Log4perl::init('load/etc/log.conf');
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
  #this is the Module::Build instance
  my $m = shift;

  #make sure you log your actions for debugging later!
  $m->log->info("entering ACTION_foo");

  print "I'm fooing to death!\n";

  $m->log->info("leaving ACTION_foo");
}

=head2 ACTION_prepdb

 Title   : ACTION_prepdb
 Usage   :
 Function: Current hack to setup any rows in the DB before the load. Should be
           replaced in the future by encapsulating in the load scripts. Right
           now executes any SQL statements in the load/etc/initialize.sql file.
 Example :
 Returns : 
 Args    :

=cut
sub ACTION_prepdb {
  # the build object $m
  my $m = shift;
  # the XML config object
  my $conf = $m->conf;

  $m->log->info("entering ACTION_prepdb");

  $m->log->debug("system call: ". "psql ".$conf->{tt2}->{'load/tt2/LoadDBI.tt2'}->{token}->{db_name}." < ".
				 $conf->{tt2}->{'load/tt2/LoadDBI.tt2'}->{token}->{chado_path}."/load/etc/initialize.sql"
				);

  system("psql ".$conf->{tt2}->{'load/tt2/LoadDBI.tt2'}->{token}->{db_name}." < ".$conf->{tt2}->{'load/tt2/LoadDBI.tt2'}->{token}->{chado_path}."/load/etc/initialize.sql");

  $m->log->info("leaving ACTION_prepdb");
}

sub ACTION_ncbi {
  # the build object $m
  my $m = shift;
  # the XML config object
  my $conf = $m->conf;

  $m->log->info("entering ACTION_ncbi");

  # print out the available refseq datasets
  my %ncbis = printAndReadOptions($m,$conf,"ncbi");

  # now that I know what you want mirror files and load
  # fetchAndLoadFiles is called for each possible type
  # but only actively loaded for those the user selects
  fetchAndLoadFiles($m, $conf, "refseq", "./load/bin/load_gff3.pl --organism Human --srcdb refseq --gfffile", %ncbis);
  fetchAndLoadFiles($m, $conf, "locuslink", "./load/bin/load_locuslink.pl", %ncbis);

  $m->log->info("leaving ACTION_ncbi");
}

sub ACTION_mageml {
  my $m = shift;
  my $conf = $m->conf;

  $m->log->info("entering ACTION_mageml");

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
		$m->log->debug("mkdir -p $fullpath");
        system( 'mkdir','-p',$fullpath ) or print "!possible problem, couldn't mkdir -p $fullpath: $!\n";
      }

      print "  +",$file->{remote},"\n";
      $load = 1 if $m->_mirror($file->{remote},$file->{local});
	  $load = 1 if !$m->_loaded($conf->{'path'}{'data'}.'/'.$file->{'local'});

	  next unless $load;

      print "    loading...";

	  $m->log->debug("system call: ".'./load/bin/load_affymetrix.pl'. ' '/
					 $conf->{'path'}{'data'}.'/'.$file->{'local'}
					);

      my $result = system('./load/bin/load_affymetrix.pl',
				  $conf->{'path'}{'data'}.'/'.$file->{'local'});
      if ($result != 0) { print "failed: $!\n"; die; }
	  else {
		$m->_loaded( $conf->{'path'}{'data'}.'/'.$file->{'local'} , 1 );
		print "done!\n";
	  }
	}
  }

  $m->log->info("leaving ACTION_mageml");
}

sub ACTION_ontologies {
  my $m = shift;
  my $conf = $m->conf;

  $m->log->info("entering ACTION_ontologies");

  print "Available ontologies:\n";

  my %ont = ();
  foreach my $ontology (keys %{ $conf->{ontology} }) {
    $ont{$conf->{ontology}->{$ontology}->{order}} = $ontology;
  }
  foreach my $key (sort keys %ont) { print "[$key] ", $ont{$key}, "\n"; }
  print "\n";

  my $chosen = $m->prompt("Which ontologies would you like to load (Comma delimited)? [0]");
  $m->notes('ontologies' => $chosen);
  my %ontologies = map {$_ => $conf->{ontology}{$ont{$_}}} split ',',$chosen;

  foreach my $ontology (sort keys %ontologies){
    print "fetching files for ", $ont{$ontology}, "\n";

    my $load = 0;
    foreach my $file (grep {$_->{type} eq 'definitions'} @{ $ontologies{$ontology}{file} }){
      my $fullpath = $conf->{path}{data}.'/'.$file->{local};
      $fullpath =~ s!^(.+)/[^/]*!$1!;

      if(! -d $fullpath){
		$m->log->debug("mkdir -p $fullpath");
        system( 'mkdir','-p',$fullpath ) or print "!possible problem, couldn't mkdir -p $fullpath: $!\n";
      }

      print "  +",$file->{remote},"\n";
      $load = 1 if $m->_mirror($file->{remote},$file->{local});
    }

    my($deffile) = grep {$_ if $_->{type} eq 'definitions'} @{ $ontologies{$ontology}{file} };
    foreach my $ontfile (grep {$_->{type} eq 'ontology'} @{ $ontologies{$ontology}{file} }){
      print "  +",$ontfile->{remote},"\n";

      $load = 1 if $m->_mirror($ontfile->{remote},$ontfile->{local});
#	  $load = 1 if !$m->_loaded($conf->{'path'}{'data'}.'/'.$ontfile->{'local'});

	  next unless $load;

      print "    loading...";

	  $m->log->debug("system call: ".'./load/bin/load_ontology.pl'.    ' '.
					 $conf->{'path'}{'data'}.'/'.$ontfile->{'local'}.  ' '.
					 $conf->{'path'}{'data'}.'/'.$deffile->{'local'}
					);

	  my $result = system('./load/bin/load_ontology.pl',
						  $conf->{'path'}{'data'}.'/'.$ontfile->{'local'},
						  $conf->{'path'}{'data'}.'/'.$deffile->{'local'});

      if ($result != 0) {
		print "failed: $!\n";
		$m->log->fatal("failed: $!");
		die;
	  } else {
		$m->_loaded( $conf->{'path'}{'data'}.'/'.$ontfile->{'local'} , 1 );
		$m->_loaded( $conf->{'path'}{'data'}.'/'.$deffile->{'local'} , 1 );
		print "done!\n";
		$m->log->debug("done!");
	  }
    }
  }

  $m->log->info("leaving ACTION_ontologies");
}

sub ACTION_tokenize {
  my $m = shift;
  my $conf = $m->conf;

  $m->log->info('entering ACTION_tokenize');

  my $template = Template->new({
    INTERPOLATE  => 0,
    RELATIVE     => 1,
  }) || ($m->log->fatal("Template error: $Template::ERROR") and die);

  foreach my $tt2file ( keys %{ $m->conf->{tt2} } ){
    my $tokenized;
    $template->process($tt2file, $conf->{tt2}->{$tt2file}->{token}, \$tokenized) || ($m->log->fatal("Template error: ".$template->error()) and die);

    open(OUT,'>'.$conf->{tt2}->{$tt2file}->{output});
    print OUT $tokenized;
    close(OUT);
  }

  $m->log->info('leaving ACTION_tokenize');
}

=head1 NON-ACTIONS

=cut

=head2 fetchAndLoadFiles

 Title   : fetchAndLoadFiles
 Usage   : fetchAndLoadFiles(<build_obj>, <xml_conf_obj>, <file_type>...)
 Function: Calls internal methods to mirror files specified for this file_type in the xml_conf_obj
 Example :
 Returns : 
 Args    :


=cut

sub fetchAndLoadFiles {
  my ($m,$conf,$type,$command,%itm) = @_;

  $m->log->info('entering fetchAndLoadFiles');

  foreach my $key (keys %itm){
	print "fetching files for $key\n";

	my $load = 0;
    foreach my $file (@{ $itm{$key}{file} }) {
	  # check to see if this command can handle this type
      if($file->{type} eq $type) {
		my $fullpath = $conf->{path}{data}.'/'.$file->{local};
		$fullpath =~ s!^(.+)/[^/]*!$1!;

		if(! -d $fullpath){
		  $m->log->debug("mkdir -p $fullpath");
		  system( 'mkdir','-p',$fullpath ) or print "!possible problem, couldn't mkdir -p $fullpath: $!\n";
		}

		print "  +",$file->{remote},"\n";
		$load = 1 if $m->_mirror($file->{remote},$file->{local});
		$load = 1 if !$m->_loaded($conf->{'path'}{'data'}.'/'.$file->{'local'});

		next unless $load;

		print "    loading...";

		$m->log->debug("system call: ". $command .' '.
					   $conf->{'path'}{'data'}.'/'.$file->{'local'}
					  );

		my $result = system($command,
							$conf->{'path'}{'data'}.'/'.$file->{'local'});

		if($result != 0) {
		  print "failed: $!\n";
		  $m->log->fatal("failed: $!");
		  die;
		} else{
		  $m->_loaded( $conf->{'path'}{'data'}.'/'.$file->{'local'} , 1 );
		  print "done!\n";
		  $m->log->debug("done!");
		}
	  }
	}
  }

  $m->log->info('leaving fetchAndLoadFiles');
}


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

sub log {
  my $m = shift;
  if(!$m->{log}){
	my $pack = ref($m);
	$pack =~ s/::/./g;
	$m->{log} = Log::Log4perl->get_logger($pack);
	$m->{log}->info("starting log for $pack");
  }
  return $m->{log};
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
