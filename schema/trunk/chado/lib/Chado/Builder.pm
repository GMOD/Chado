package Chado::Builder;
use strict;
use base 'Module::Build';
use Data::Dumper;
use Template;
use XML::Simple;

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
  warn $m;
  warn Dumper($m->conf);
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

sub conf {
  my $self = shift;
  my $arg = shift;
#  $self->{conf} = XMLin($arg, forcearray => ['token'], keyattr => [ 'tt2', 'input', 'token', 'name', 'value'], ContentKey => '-value') if defined($arg);
  $self->{conf} = XMLin($arg, forcearray => ['token','path'], keyattr => [qw(tt2 input token name
  )], ContentKey => '-value') if defined($arg);
warn Dumper($self->{conf});
  return $self->{conf};
}

1;
