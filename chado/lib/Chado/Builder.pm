package Chado::Builder;
use strict;
use base 'Module::Build';
use Data::Dumper;
use Template;
use XML::Simple;
use LWP::Simple qw(mirror is_success status_message);

=head1 ACTIONS

=item foo()

this is an example target

=item ontologies()

loads ontologies by running load_ontology.pl on all files in
$(DATA)/ontology

=item tokenize()

processes templates specified in configuration file, filling in
platform-specific variable values

=item _last

=cut

sub ACTION_foo {
  print "I'm fooing to death!\n";
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
    foreach my $file (@{ $ontologies{$ontology}{file} }){
      print "  +",$file->{remote},"\n";

      my $fullpath = $conf->{path}{data}.'/'.$file->{local};
      $fullpath =~ s!^(.+)/[^/]*!$1!;

      if(! -d $fullpath){
        system( 'mkdir','-p',$fullpath ) or print "!possible problem, couldn't mkdir -p $fullpath: $!\n";
      }

      #mirror the file
      my $rc = mirror($file->{remote}, $conf->{path}{data} .'/'. $file->{local});

      if ($rc == 304) {
        print "    ". $file->{local} ." is up to date\n";
      } elsif (!is_success($rc)) {
        print "    $rc ", status_message($rc), "   (",$file->{remote},")\n";
        next;
      } else {
		#file is new, load it
        print "    updated\n";
		$load = 1;
      }
    }
	next unless $load;

	my($deffile) = grep {$_ if $_->{type} eq 'definitions'} @{ $ontologies{$ontology}{file} };
	foreach my $ontfile (grep {$_->{type} eq 'ontology'} @{ $ontologies{$ontology}{file} }){
      print "    loading...";
	  system('./bin/load_ontology.pl',
			 $conf->{'tt2'}{'load/tt2/AutoDB.tt2'}{'token'}{'db_username'},
			 $conf->{'tt2'}{'load/tt2/AutoDB.tt2'}{'token'}{'db_name'},
			 $conf->{'path'}{'data'}.'/'.$ontfile->{'local'},
			 $conf->{'path'}{'data'}.'/'.$deffile->{'local'},
			) && (print "failed: $!\n" and die);
	  print "done!\n";

#warn Dumper($conf);
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

sub property {
  my $self = shift;
  my $key  = shift;
  my $val  = $self->{properties}{$key};
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

1;
