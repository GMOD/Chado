package Bio::GMOD::Config;
use strict;

=head1 NAME

Bio::GMOD::Config -- a GMOD utility package for reading config files

=head1 SYNOPSIS

    $ export GMOD_ROOT=/usr/local/gmod
    
    my $conf    = Bio::GMOD::Config->new();
    my $tmpdir  = $conf->tmp();
    my $confdir = $conf->conf();

    #assume there is a file 'chado.conf' with database connetion info
    my $dbusername = $conf->db->{'chado'}{'DBNAME'};
    my $dbhostname = $conf->db->{'chado'}{'DBHOST'};
    # ...etc...

    my @dbnames = $conf->available_dbs();
    my @dbparams = $conf->available_params($dbnames[0]);

=head1 DESCRIPTION

Bio::GMOD::Config is a module to allow programmatic access to the configuration
files in GMOD_ROOT/conf.  Typically, these files will be gmod.conf 
(containing site-wide parameters), and one each configuration file for
each database, named dbname.conf, containing database connection parameters.

=head1 METHODS

=cut

use File::Spec::Functions qw/ catdir /;

=head2 new

 Title   : new
 Usage   : my $config = Bio::GMOD::Config->new('/path/to/gmod');
 Function: create new Bio::GMOD::Config object
 Returns : new Bio::GMOD::Config
 Args    : optional path to gmod installation
 Status  : Public

Takes one optional argument that is the path to the root of the GMOD 
installation.  If that argument is not provided, Bio::GMOD::Config will
fall back to the enviroment variable GMOD_ROOT, which should be defined
for any GMOD installation.

=cut


sub new {
    my $self = shift;
    my $arg  = shift;

    my $root;
    if ($arg) {
        $root = $arg; #can override the environment variable
    } else {
        $root = $ENV{'GMOD_ROOT'};  #required
    }

    die "Please set the GMOD_ROOT environment variable\n"
       ."It is required from proper functioning of gmod" unless ($root);

    my $confdir = catdir($root, 'conf'); #not clear to me what should be in
                                      #gmod.conf since db stuff should go in
                                      #db.conf (per programmers guide)

    my %db;
    opendir CONFDIR, $confdir
       or die "couldn't open $confdir directory for reading:$!\n";
    my $dbname;
    while (my $dbfile = readdir(CONFDIR) ) {
        my $tmpconf =  catdir($confdir, $dbfile); 
        next unless (-f $tmpconf);
        if ($dbfile =~ /^(\w+)\.conf/) {
            $dbname = $1;
        } else {
            next;
        }
        $db{$dbname}{'conf'} = $tmpconf; 
    }
    closedir CONFDIR;

    foreach my $conffile (keys %db) {
        open CONF, $db{$conffile}{'conf'}
           or die "Couldn't open $db{$conffile}{'conf'} for reading: $!";
        while (<CONF>) {
            next if /^\#/;
            if (/(\w+)\s*=\s*(\S+)/) {
                $db{$conffile}{$1} = $2;
            }
        }
        close CONF;
    }

    return bless {db       => \%db,
                  confdir  => $confdir}, $self;
}

=head2 available_dbs

 Title   : available_dbs
 Usage   : my @dbs = $config->available_dbs();
 Function: returns a list of database config files
 Returns : see above
 Args    : none
 Status  : public

This method returns a list of database configuration files available in
GMOD_ROOT/conf.

=cut


sub available_dbs {
    my $self = shift;
    my @dbs;
    my $dbs = $self->{'db'};
    foreach (keys %$dbs ) {
        next if $_ eq 'gmod';
        push @dbs, $_;    
    }
    return @dbs;
}

=head2 available_params

 Title   : available_params
 Usage   : @params = $config->available_params('chado');
 Function: returns a list of parameters (ie, hash keys) for a given database
 Returns : see above
 Args    : The name of a database
 Status  : public

Returns a list of database connection parameters (ie, hash keys) for 
a given database configuration file.

=cut


sub available_params {
    my $self = shift;
    my $db   = shift;

    my $params = $self->{'db'}{$db};
    my @params;
    foreach (keys %$params) {
        push @params, $_;
    }
    return @params;
}

=head2 confdir

 Title   : confdir
 Usage   : $confdir = $config->confdir();
 Function: returns the path to the configuration directory
 Returns : see above
 Args    : none
 Status  : public


=cut


sub confdir {
    shift->{'conf'};
}

=head2 tmp

 Title   : tmp
 Usage   : $tmpdir = $config->tmp();
 Function: returns the path to the GMOD tmp directory
 Returns : see above
 Args    : none
 Status  : public

Returns the path to the GMOD tmp directory.

=cut


sub tmp {
    my $self = shift;
    $self->{'db'}->{'gmod'}->{'TMP'};
}

1;

=head1 AUTHOR
                                                                                
Scott Cain E<lt>cain@cshl.orgE<gt>.
                                                                                
Copyright (c) 2004 Cold Spring Harbor Laboratory
                                                                                
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
                                                                                
=cut

