package Bio::GMOD::Config;
use strict;

=head1 NAME

Bio::GMOD::Config -- a GMOD utility package for reading config files

=head1 SYNOPSIS

    $ export GMOD_ROOT=/usr/local/gmod
    
    my $conf    = Bio::GMOD::Config->new();
    my $tmpdir  = $conf->tmpdir();
    my $confdir = $conf->confdir();

    my @dbnames = $conf->available_dbs();

=head1 DESCRIPTION

Bio::GMOD::Config is a module to allow programmatic access to the configuration
files in GMOD_ROOT/conf.  Typically, these files will be gmod.conf 
(containing site-wide parameters), and one each configuration file for
each database, named dbname.conf, containing database connection parameters,
which are accessed through Bio::GMOD::Config::DB objects.

=head1 METHODS

=cut

use File::Spec::Functions qw/ catdir catfile /;

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

    my @db;
    opendir CONFDIR, $confdir
       or die "couldn't open $confdir directory for reading:$!\n";
    my $dbname;
    while (my $dbfile = readdir(CONFDIR) ) {
        if ($dbfile =~ /^(\w+)\.conf/) {
            push @db, $1;
        } else {
            next;
        }
    }
    closedir CONFDIR;

    my %conf;
    my $conffile = catfile($confdir, 'gmod.conf');
    open CONF, $conffile or die "Unable to open $conffile: $!\n";
    while (<CONF>) {
        next if /^\#/;
        if (/(\w+)\s*=\s*(\S.*)$/) {
            $conf{$1}=$2;
        }
    }
    close CONF;

    return bless {db       => \@db,
                  conf     => \%conf,
                  confdir  => $confdir,
                  gmod_root=> $root}, $self;
}

=head2 available_dbs

 Title   : available_dbs
 Usage   : my @dbs = $config->available_dbs();
 Function: returns a list of database config files
 Returns : see above
 Args    : none
 Status  : public

This method returns reference to a list of database configuration
files available in GMOD_ROOT/conf.

=cut


sub available_dbs {
    shift->{'db'};
}

=head2 all_tags
                                                                                
 Title   : all_tags
 Usage   : @tags = $config->all_tags();
 Function: returns a list of parameters (ie, hash keys) for a given database
 Returns : see above
 Args    : none
 Status  : public
                                                                                
Returns a list of database connection parameters (ie, hash keys) for
a given database configuration file.
                                                                                
=cut

sub all_tags {
    my $self = shift;
                                                                                
    my $params = $self->{'conf'};
    my @params;
    foreach (keys %$params) {
        push @params, $_;
    }
    return @params;
}

=head2 has_tag

 Title   : has_tag
 Usage   : $bool = $conf->has_tag('TMP');
 Function: Returns true if the tag is contained in the config file
 Returns : see above
 Args    : name of tag
 Status  : public

=cut

sub has_tag{
    my $self = shift;
    my $tag  = shift;

    my $conf = $self->{'conf'};
    if (defined $$conf{$tag}) {
        return 1;
    } else {
        return 0;
    }
}

=head2 get_tag_value

 Title   : get_tag_value 
 Usage   : $value = $conf->get_tag_value($tag);
 Function: return the value of a config parameter
 Returns : see above
 Args    : name of a tag
 Status  : Public
                                                                                
=cut

sub get_tag_value {
    my $self = shift;
    my $tag  = shift;

    my $conf = $self->{'conf'};
    if (defined $$conf{$tag}) {
        return $$conf{$tag};
    } else {
        return;
    }
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
    shift->{'confdir'};
}

=head2 tmp

 Title   : tmp
 Usage   : $tmpdir = $config->tmpdir();
 Function: returns the path to the GMOD tmp directory
 Returns : see above
 Args    : none
 Status  : public

Returns the path to the GMOD tmp directory.

=cut


sub tmpdir {
    shift->get_tag_value('TMP');
}

=head2 gmod_root 
                                                                                
 Title   : gmod_root
 Usage   : $gmod_root = $config->gmod_root();
 Function: returns the path to the GMOD root directory
 Returns : see above
 Args    : none
 Status  : public
                                                                                
Returns the path to the GMOD root directory.

=cut

sub gmod_root {
    shift->{'gmod_root'};
}

1;

=head1 AUTHOR
                                                                                
Scott Cain E<lt>cain@cshl.orgE<gt>.
                                                                                
Copyright (c) 2004 Cold Spring Harbor Laboratory
                                                                                
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
                                                                                
=cut

