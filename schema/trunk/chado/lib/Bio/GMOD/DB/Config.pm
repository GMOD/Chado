package Bio::GMOD::DB::Config;
use strict;

=head1 NAME

Bio::GMOD::Config::DB -- a GMOD utility package for reading db config files

=head1 SYNOPSIS

    $ export GMOD_ROOT=/usr/local/gmod
    
    my $conf    = Bio::GMOD::Config->new();
    my $tmpdir  = $conf->tmp();
    my $confdir = $conf->conf();

    #assume there is a file 'chado.conf' with database connetion info
    my $dbconf  = Bio::GMOD::DB::Config->new($conf, 'chado');
    my $dbusername = $dbconf->user();
    my $dbhostname = $dbconf->port();
    # ...etc...

=head1 DESCRIPTION

Bio::GMOD::DB::Config is a module to allow programmatic access to the
database configuration files in GMOD_ROOT/conf.   

=head1 METHODS

=cut

use DBI;
use File::Spec::Functions qw/ catdir catfile /;
use vars '@ISA';
@ISA = qw/ Bio::GMOD::Config /;


=head2 new

 Title   : new
 Usage   : my $config = Bio::GMOD::DB::Config->new($conf, 'dbname');
 Function: create new Bio::GMOD::DB::Config object
 Returns : new Bio::GMOD::DB::Config
 Args    : Bio::GMOD::Config object, db config name
 Status  : Public

Returns a Bio::GMOD::DB::Config object.  If no db config name argument is
specified, the configuration file called 'default.conf' will be used.

=cut


sub new {
    my $self    = shift;
    my $conf    = shift;
    my $dbname  = shift;

    $dbname ||= 'default';

    my $confdir = $conf->confdir; #get from Bio::GMOD::Config
    my $conffile= catfile($confdir, "$dbname.conf");

    my %dbconf;
    open CONF, $conffile or die "Couldn't open $conffile: $!";
    while (<CONF>) {
        next if /^\#/;
        if (/(\w+)\s*=\s*(\S.*)/) {
            $dbconf{$1}=$2; 
        }
    }
    close CONF;

    return bless {conf   => \%dbconf}, $self;
}

=head2 user
                                                                                
 Title   : user
 Usage   : $username = $dbconf->user();
 Function: return the value the database username
 Returns : see above
 Args    : none
 Status  : Public
                                                                                
=cut

sub user {
    shift->get_tag_value('DBUSER');
}

=head2 password
                                                                                
 Title   : password
 Usage   : $password = $dbconf->password();
 Function: return the value the database password
 Returns : see above
 Args    : none
 Status  : Public
                                                                                
=cut

sub password {
    shift->get_tag_value('DBPASS');
}
                                                                                
=head2 host
                                                                                
 Title   : host
 Usage   : $host = $dbconf->host();
 Function: return the value the database host name
 Returns : see above
 Args    : none
 Status  : Public
                                                                                
=cut

sub host {
    shift->get_tag_value('DBHOST');
}
                                                                                
=head2 port
                                                                                
 Title   : port
 Usage   : $port = $dbconf->port();
 Function: return the value the database port
 Returns : see above
 Args    : none
 Status  : Public
                                                                                
=cut

sub port {
	shift->get_tag_value('DBPORT');
}
                                                                                
=head2 driver
                                                                                
 Title   : driver
 Usage   : $driver = $dbconf->driver();
 Function: return the value the database driver
 Returns : see above
 Args    : none
 Status  : Public
                                                                                
=cut
                                                                                
sub driver {
    shift->get_tag_value('DBDRIVER');
}

=head2 name
                                                                                
 Title   : name 
 Usage   : $dbname = $dbconf->name();
 Function: return the value the database name
 Returns : see above
 Args    : none
 Status  : Public

=cut

sub name {
    shift->get_tag_value('DBNAME');
}

=head2 sqlfile
                                                                                
 Title   : sqlfile
 Usage   : $sqlfile = $dbconf->sqlfile();
 Function: returns the path of the sqlfile (ie, ddl file) the defines the schema
 Returns : see above
 Args    : none
 Status  : Public
                                                                                
=cut

sub sqlfile {
    shift->get_tag_value('SQLFILE');
}


=head2 dbh
                                                                                
 Title   : dbh
 Usage   : $dbh = $dbconf->dbh();
 Function: return a database handle
 Returns : see above
 Args    : none
 Status  : Public
                                                                                
=cut

sub dbh {
    my $self = shift;

    my $dsn = "dbi:Pg:dbname=".$self->name();
    $dsn .= ";host=".$self->host() if $self->host();
    $dsn .= ";port=".$self->port() if $self->port();

    my $dbh = DBI->connect( $dsn, $self->user(), $self->password() )
        or die "couldn't create db connection:$!";
        #this should throw--maybe I should inherit from Bio::Root

    return $dbh;
}


1;

=head1 AUTHOR
                                                                                
Scott Cain E<lt>cain@cshl.orgE<gt>.
                                                                                
Copyright (c) 2004 Cold Spring Harbor Laboratory
                                                                                
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
                                                                                
=cut

