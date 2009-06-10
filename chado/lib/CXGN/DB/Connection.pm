package CXGN::DB::Connection;
use strict;
use vars qw/$AUTOLOAD/;
use English;

use UNIVERSAL qw/isa/;
use Carp qw/cluck croak carp/;
use DBI;

use CXGN::Debug;
use CXGN::VHost;
use CXGN::Tools::Class qw/parricide/;

BEGIN {
  our @EXPORT = qw/connect_db/;
}
use base qw/CXGN::Class::Exporter Class::Data::Inheritable Class::Accessor/;
our @EXPORT;


BEGIN {
  #list of method names that, when called on this object,
  #will be forwarded to the enclosed database handle
  our @dbh_methods = qw/
			do

			selectall_arrayref
			selectall_hashref

			selectcol_arrayref
			selectcol_hashref

			selectrow_array
			selectrow_arrayref
			selectrow_hashref

			prepare
			prepare_cached

			begin_work
			commit
			rollback

			quote
			quote_identifier

			err
			errstr
			state
			ping

			trace
			trace_msg

			get_info

			table_info
			column_info
			primary_key_info
			primary_key
			foreign_key_info
			tables
			type_info_all
			type_info

			FETCH

			pg_savepoint
			pg_rollback_to
			pg_release
			pg_putline
			pg_getline
			pg_endcopy

		      /;
  foreach my $forward_method (@dbh_methods) {
      no strict 'refs';
      *{$forward_method} = sub { shift->_dbh->$forward_method(@_) };
  }
}

			

our @dbh_methods;

__PACKAGE__->mk_accessors( '_dbname',
			   '_dbschema',
			   '_dbuser',
			   '_dbpass',
			   '_dbhost',
			   '_dbport',
			   '_dbbranch',
			   '_dbargs',
			   '_conf',
			   '_dsn',
			   '_dbh',
			   #note that dbtype is an actual function defined below
		         );


=head1 NAME

CXGN::DB::Connection - connect to CXGN databases

=head1 SYNOPSIS

  # simple usage
  my $dbh = CXGN::DB::Connection->new();
  $dbh->do("SELECT 'BLAH'");

  # OR

  # as part of an object
  use base qw/CXGN::DB::Connection/;
  $self->do("SELECT 'BLAH'");

=head1 DESCRIPTION

This module can be used in two ways: it is a database handle ($dbh)
that can be used directly; alternatively, objects such as database APIs can
inherit from this by adding 'CXGN::DB::Connection' to their @ISA, and thus
become database handles themselves (see also L<Ima::DBI>, which allows
you to share a single database handle between all instances of a class).

To connect to the database, this object needs to figure out values
for a number of parameters (listed below in the documentation for new() ).
Any one of these parameters can be set in 4 different places:
1.) As arguments to the new() method when the object is created.
2.) As environment variables (e.g. $ENV{DBUSER})
3.) As parameters in the CXGN::Configuration system (e.g. $conf->get_conf('dbuser') )
4.) From the hardcoded default inside this module

Arguments to the new() method override environment variables, which override
CXGN::Configuration parameters, which override the hardcoded defaults.  Get it?
The hardcoded defaults are listed below in the documentation for new().

Example of setting environment variables for a database connection (using a bash
shell):

   user@box:~$ export $DBUSER=somebodyelse
   user@box:~$ export $DBPASS=lemmein
   user@box:~$ ./my_script_that_uses_db_connection.pl

Will specify a user and password for the script to use.

=head1 TRACING

If the CXGN_DB_CONNECTION_TRACE_CONNECTIONS environment variable is
set, will append backtraces of all database connections to the file
/tmp/cxgn_db_connections.log

Also, CXGN::DB::Connection supports the standard DBI tracing
facilities.  See L<DBI> perldoc.

=head1 METHODS

=head2 new

  Desc: Connects to the database and returns a new Connection object
  Args: optional parameters hash ref as
        ({  dbname => name of the database; defaults to 'cxgn'; unused for MySQL
            dbschema => name of schema you want to connect to; defaults to 'sgn'
            dbtype => type of database - 'Pg' or 'mysql'; defaults to 'Pg'
	    dbuser => username for the connection; defaults to 'web_usr'
	    dbpass => password for the connection; defaults to nothing
	    dbargs => DBI connection params, merged with the default, which are explained below,
	    dbhost => host to connect to, default 'db.sgn.cornell.edu',
	    dbbranch => the database "branch" to use, default 'devel' unless you are configured as a production website, in which case it would default to 'production'
	 })
        all parameters in the hash are optional as well
  Ret: new CXGN::DB::Connection object
  Side Effects: sets up the internal state of the CXGN::DB::Connection object
  Example:
     my $dbh = CXGN::DB::Connection->new();

  Defaults for dbargs:
     RaiseError:
        Explicitly set to 1.
     AutoCommit:
       If the environment variable $ENV{MOD_PERL} is set (which would be
       the case if you are running under mod_perl, AutoCommit defaults to 1, that is, ON.  If
       $ENV{MOD_PERL} is not set, which would probably be the case if you
       are running in some other environment (like in a shell), AutoCommit is
       defaults to 0, which is OFF.  For more on what AutoCommit is and why you
       need to be careful with it, see the documentation of L<DBI> and
       L<Class::DBI>.

     Note that DBI handle options (AutoCommit, RaiseError, etc) are also
     merged, with the same order of precedence as the DB::Connection options
     (dbname, dbpass, etc).

=cut

#the new() method is now defined by Class::MethodMaker above

=head2 new_no_connect

  Desc: Same as above, except does not connect to the database.
        Used by things that want to use the connection parameters for
        themselves.

=cut

sub new_no_connect {
  my ($class, $db, $p) = @_;
  my $self = bless {},$class;

  # This is a little gross, but it looks weird to have to call new
  # like this when all you want to customize is the dbuser:
  #
  # new("sgn", { 'dbuser' => 'bob' });
  #
  # According to Rob, this usage was meant to match some deprecated interface.
  # Anyhow, if $db is a ref, then use it as a hash potentially containing
  # all the connection parameters.  -- Marty, 2005 July 26.
  if (ref ($db)) { # The first argument was a hash ref.
    if (ref $p) { # Something's wrong if TWO hash refs were passed
      croak ("Programmer error: two hashes passed into CXGN::DB::Connection->new()");
    } else {
      $p = $db; # The first argument was a hash ref, so call it $p.
    }
  } else { # The first argument is the dbschema
    $p->{dbschema} = $db;
  }

  my $autocommit_default=0;
  if( defined $ENV{MOD_PERL} ) {
      $autocommit_default = 1; #if we are running in the website, run with autocommit on. otherwise, don't
  }

  my $conf = $self->_conf( CXGN::VHost->new );

  my $dbbranch_default = $conf->get_conf("production_server") ? "production" : "devel";
#  warn "branch: " . $dbbranch_default;

  #list of valid args to pass in the params hash, and defaults and auxiliary configuration sources for them.
  my @args = (# hash key,       environment var name,    VHost configuration name,    hardcoded default value
	      ['dbhost'  ,      'DBHOST'  ,              'dbhost'  ,                  'db.sgn.cornell.edu'                     ],
	      ['dbport'  ,      'DBPORT'  ,              'dbport'  ,                  ''                                             ],
	      ['dbname'  ,      'DBNAME'  ,              'dbname'  ,                  'cxgn'                                         ],
	      ['dbuser'  ,      'DBUSER'  ,              'dbuser'  ,                  'web_usr'                                      ],
	      ['dbpass'  ,      'DBPASS'  ,              'dbpass'  ,                  ''                                     ],
	      ['dbtype'  ,      'DBTYPE'  ,              'dbtype'  ,                  'Pg'                                           ],
	      ['dbschema',      'DBSCHEMA',              'dbschema',                  'sgn'                                          ],
	      ['dbbranch',      'DBBRANCH',              'dbbranch',                  $dbbranch_default                              ], #see above for default
	      ['dbargs'  ,      undef     ,              undef     ,                  {RaiseError=>1,AutoCommit=>$autocommit_default}], #see above for default
	     );

  my %valid_argnames = map {$_->[0],1} @args;

  #copy our args from the parameters hash into our object
  foreach my $pkey (keys %$p) {
    unless ($valid_argnames{$pkey}) {
      warn Carp::longmess("Invalid parameter '$pkey' passed to CXGN::DB::Connection argument hash");
    }

    my $upkey = "_$pkey";
    $self->$upkey( $p->{$pkey} );
  }

  #check for environment variables for things that weren't set from
  #the params hash, and if there is still no value, set it to the
  #conf object's value, and if there is still no value, set it to the 
  #default value
  foreach my $arg (@args) {
    my ($argname,$envname,$confname,$default) = @$arg;
    if( $argname eq 'dbargs' ) { #merge dbargs specially
      my %merged;
      #only get args from either what you passed in, or the hardcoded defaults
      foreach my $hash ( $default, $self->_dbargs ) {
	while( my($key,$val) = each %$hash ) {
	  $merged{$key} = $val;
	}
      }
      $self->_dbargs( \%merged );
    }
    else {
      $argname = "_$argname"; #these are private methods

      # If the $argname field isn't filled in,
      # then if the policy allows for an environment
      # variable, a conf object key, or a default,
      # try those in succession.
      $self->$argname( $ENV{$envname} )
	if defined $envname && ! defined $self->$argname;

      $self->$argname( $conf->get_conf($confname) )
	if defined $confname && ! defined $self->$argname;

      $self->$argname( $default )
	if defined $default && ! defined $self->$argname;
    }
  }

  ## Validation  and such.

  # Now set up our derived connection params based on what kind of
  # database we're connecting to
  if( $self->_dbtype eq 'Pg' ) {
    # The following line adds 1 optional argument to the dbargs hash, but
    # no DBD driver is expected to use this key: it's there only so that
    # Apache::DBI will distinguish DBI handles.  If some day in the future
    # DBD::Pg does support schemas, you might as well change this argument,
    # though leaving it here for Apache::DBI to use shouldn't hurt, either.
    # update: according to the DBI docs, if your parameter is prefixed by
    #         'private_', the DB driver will ignore it
    $self->_dbargs->{private_cxgn_schema} = $self->_dbschema;
    my $dsn = "dbi:Pg:".join(';',
			     $self->_dbname ? "dbname=".$self->_dbname : (),
			     $self->_dbhost ? "host=".$self->_dbhost : (),
			     $self->_dbport ? "port=".$self->_dbport : (),
			    );
    $self->_dsn($dsn);
  }
  # MySQL
  elsif( $self->_dbtype eq 'mysql' ) {
    if ($self->_dbschema) {
      $self->_dsn( "dbi:mysql:host=".$self->_dbhost.";database=".$self->_dbschema.';port='.$self->_dbport );
    } elsif ($self->_dbname) {
      $self->_dsn( "dbi:mysql:host=".$self->_dbhost.";database=".$self->_dbname.';port='.$self->_dbport );
    } else {
      croak "Unknown CXGN::DB::Connection database name or schema for dbtype '".$self->_dbtype."'";
    }
  }
  # Ensure that dbbranch validates.  qualify_schema will croak otherwise.
  $self->qualify_schema( $self->_dbschema );

  return $self;
}

=head2 new

  Desc: called by new to set up the new object's internal state
  Args: same as for new
  Ret : nothing

=cut

sub _compact_backtrace {
    return join '/', map {join(':',(caller($_))[0,2])} 1..3;
}


my $debug = CXGN::Debug->new;

sub new {
    my $class = shift;

    UNIVERSAL::isa($class,'CXGN::DB::Connection')
          or croak "First argument to init_connect or new() must be a CXGN::DB::Connection or a subclass thereof";
    my $self = $class->new_no_connect(@_);

    # Now connect to a DB.
    $self->_dbh( DBI->connect($self->get_connection_parameters) );
    $self->trace_msg('CXGN_TRACE | '._compact_backtrace().' | '.__PACKAGE__."::new | $self | ".$self->_dbh."\n",1);

    #generate the search path
    if ( $self->_dbtype eq 'Pg' ) {
        my @searchpath = qw/public/;
        unshift @searchpath, 'tsearch2' unless $self->_dbh->{pg_server_version} >= 80300;
        my $qualified_schema = $self->qualify_schema;
        if ( $qualified_schema ) {
            unshift @searchpath, $qualified_schema;
        }
        $self->do("SET SEARCH_PATH = ".join(',',@searchpath));
    }
    if ( $debug->get_debug || $ENV{CXGN_DB_CONNECTION_TRACE_CONNECTIONS}) {
        my $trace_str = join '',map {"$_\n"}
            (
             "# === DB::Connection parameters ===",
             "# dbhost:     " . $self->_dbhost,
             "# dbport:     " . $self->_dbport,
             "# dbname:     " . $self->_dbname,
             "# dbuser:     " . $self->_dbuser,
             "# dbtype:     " . $self->_dbtype,
             "# dbschema:   " . $self->_dbschema,
             "# dbbranch:   " . $self->_dbbranch,
             "# searchpath: " . $self->search_path,
             "# dbargs:",
             ( map {
                 "#  $_ => ".$self->_dbargs->{$_}
             } keys %{$self->_dbargs}
             ),
             "# === End of DB::Connection parameters ==="
            );

        $debug->debug($trace_str);

        if ( $ENV{CXGN_DB_CONNECTION_TRACE_CONNECTIONS} ) {
            #warn $trace_str;
            open my $l,'>>','/tmp/trace.log';
            local *STDERR_SAVE;
            open STDERR_SAVE, ">&STDERR" or die "$! saving STDERR";
            open STDERR, ">>", '/tmp/cxgn_db_connections.log' or die "run3(): $! redirecting STDERR";
            cluck $trace_str;
            open STDERR, '>&', \*STDERR_SAVE;
        }
  }
  return $self;
}

=head2 connect_db

  Alias for CXGN::DB::Connection->new(@_)

=cut

sub connect_db {
  if($_[1]) {
    if (ref($_[1])) {
      croak "Second argument to connect_db must be a string, if supplied.";
    }
    return __PACKAGE__->new({dbschema => $_[1]});
  }
  return __PACKAGE__->new();
}

# =head2 dbh

#   Args: none
#   Ret : a DBI database handle for this connection
#   Side Effects: none
#   Example:
#     my $dbconn = CXGN::DB::Connection->new
#     $dbconn->dbh->do('delete from seqread');

# =cut

sub dbh {
  carp __PACKAGE__.": the dbh() method is deprecated. Just call dbh methods on the CXGN::DB::Connection object instead.";
  return shift;
}

# =head2 get_dbh

# Alias for dbh method.

# =cut

# sub get_dbh {
#   carp __PACKAGE__.': the get_dbh() method is deprecated';
#   return shift;
# }

=head2 get_actual_dbh

 Usage: my $dbh = $self->get_actual_dbh()
 Desc: return the actual $dbh object
 Ret: $dbh, a database connectio object
 Args: none
 Side Effects: none
 Example:

=cut

sub get_actual_dbh {
  shift->_dbh;
}





=head2 get_connection_parameters

  Desc: get connection parameters you can use with your own DBI::connect call.
        Some things (like some CPAN's Class::DBI) seem to have a burning need
        to make DBI connections themselves.  You can satisfy them using the
        parameters you get from this.
  Args: none
  Ret : list of (dsn, db user, db password, DBI connection arguments)

=cut
#'
sub get_connection_parameters {
  my ($self) = @_;
  return ( $self->_dsn,
	   $self->_dbuser,
	   $self->_dbpass,
	   $self->_dbargs,
	 );
}

=head2 dbtype

  PRIVATE

  Desc: get the database type set on this connection
  Args: none
  Ret : the dbtype set on this connection thingy
        The dbtype will be a string containing either
        'Pg' or 'mysql'

=cut

sub dbtype { shift->_dbtype } #read-only
sub _dbtype {
  my $self = shift;
  my $newtype = shift;

  if( $newtype ) {
    $self->{dbtype} = $newtype;
  }

  my %valid_dbtypes = ( Pg => 1, mysql => 1 );

  !$self->{dbtype} || $valid_dbtypes{ $self->{dbtype} }
    or die "Invalid dbtype '$self->{dbtype}'";

  return $self->{dbtype};
}

=head2 dbname

  Usage: my $n = $dbc->dbname
  Desc :
  Ret  : the name of the database we're currently connected to
  Args : none
  Side Effects: none
  Example:

=cut

sub dbname { shift->_dbname } #keep this read-only

=head2 dbhost

  Usage: my $host = $dbc->dbhost
  Desc :
  Ret  : the hostname of the database server
  Args : none
  Side Effects: none
  Example:

=cut

sub dbhost { shift->_dbhost } #read-only

=head2 dbport

  Usage: my $port = $dbc->dbport
  Desc :
  Ret  : the port on the database server
  Args : none
  Side Effects: none
  Example:

=cut

sub dbport { shift->_dbport } #read-only

=head2 dbbranch

  Usage: my $branch = $dbc->dbbranch
  Desc :
  Ret  : the name of the database branch we're using,
         usually either 'devel' or 'production'
  Args : none
  Side Effects: none
  Example:

=cut

sub dbbranch { shift->_dbbranch } #keeping this read-only

=head2 dbh_param

  Desc: get or set the value of a DBI::db parameter
  Args: name of parameter to work with, (optional) new value to set it to
  Ret : new value of DBI::db parameter
  Side Effects: sets the new value of the parameter in the internal state of
                our enclosed dbh
  Example:

     my $dbconn = CXGN::DB::Connection->new;
     $dbconn->dbh_param( AutoCommit => 0 );
     $dbconn->dbh_param( PrintError => 0 );
     $dbconn->dbh_param( RaiseError => 1 );

=cut

sub dbh_param {
  my ($self,$paramname,$newvalue) = @_;

  if( defined($newvalue) ) { #set a new value if given
    $self->_dbh->{$paramname} = $newvalue;
  }

  return $self->_dbh->{$paramname};
}


#disconnect the database handle after we're done
#and call the DESTROY methods of any parent classes that have them
sub DESTROY {
  my $self = shift;
  #warn __PACKAGE__."(pid $PID): destroy called on dbc $self\n";

  return unless $self->_dbh;
  $self->trace_msg('CXGN_TRACE | '._compact_backtrace().' | '.__PACKAGE__."::DESTROY | $self | ".$self->_dbh."\n",1);

  #      unless( $self->dbh_param('InactiveDestroy') ){
  #         #warn "pid $PID disconnecting dbh ".$self->_dbh."\n";
  #        #print a warning in the DBI trace when it's enabled
  #        $self->disconnect(42);
  #        $self->_dbh->DESTROY;
  #    }
  #}
  # return parricide($self,our @ISA);
}

=head2 qualify_schema

  Desc: Get a fully-qualified schema name for the connection object or
        for a schema.
  Args: Nothing, or a schema basename.
  Ret : Fully-qualified schema.
  Side Effects: None.
  Examples:

     my $dbconn = CXGN::DB::Connection->new({dbschema=>"genomic", dbbranch=>"production"});
     my $qualified_schema_name=$dbconn->qualify_schema;  # Returns "genomic"
     my $qualified_sgn_schema_name=$dbconn->qualify_schema("sgn");  # Returns "sgn"

     my $dbconn = CXGN::DB::Connection->new({dbschema=>"genomic", dbbranch=>"devel"});
     my $qualified_schema_name=$dbconn->qualify_schema;  # Returns "genomic_dev"
     my $qualified_sgn_schema_name=$dbconn->qualify_schema("sgn");  # Returns "sgn_dev"

  Note: DO NOT hard-code the values this method returns in your code.
  We make no guarantees that development/production schemas will keep
  their names in future.

=cut

sub qualify_schema {
  my ($self, $schema_basename, $return_base_table) = @_;
  my $working_schema = $schema_basename || $self->_dbschema;
  my $branch = $return_base_table ? "base" : $self->_dbbranch;

  # Not all database schemas have production/development branches,
  # though most of them do as of Nov 2005.  This logic should perhaps
  # be reversed in future
  my @branched_schemas = qw/ physical annotation/;

  # These are the mappings from user-visible schema branch names
  # to routines that return qualified schema names in our database.
  my %branch_names = ( production => sub { $_[0] },
		       devel      => sub { $_[0] . "_dev" },
		       base       => sub { $_[0] . "" },
		     );


  # SCHEMA MIGRATION CONFIGURATION - for moving tables out of base schema  TEMPORARY
  # If the host conf base_schema_migrated evaluates true, then 'base' is no longer *_bt

  my $conf = CXGN::VHost->new();
  my ($migrated) = $conf->get_conf('base_schema_migrated');
  if ($migrated) {
  	$branch_names{base} = sub { $_[0] };
	$branch_names{devel} = sub { $_[0] };
  }
  # If the dbbranch validates, return the qualified schema.
  # We (ab)use this validation functionality in the constructor.

  # We don't want this routine to ever return if $self has a bad dbbranch,
  # because then our users may try inserting into random places.  It's
  # Better to just die.
  croak("Unknown schema branch $branch.")
    unless $branch_names{$branch};

  my $ret = "";
  if (grep {$working_schema eq $_ } @branched_schemas) {
    #if this schema is branched
    $ret = $branch_names{$branch}->($working_schema);
  } else {
    $ret = $working_schema;
  }

  return $ret;
}

=head2 base_schema

For migrating our tables out of the base schemas, factor 
out all "_bt" from code

=cut

sub base_schema {
	my ($self, $schema) = @_;
	return $self->qualify_schema($schema, 1);
}

=head2 search_path

  Desc: Get the databases current SEARCH_PATH parameter (or a snarky
        message, if the database is MySQL.
  Args: Nothing.
  Ret : A string.
  Side Effects: None.
  Examples:

   # This is your program
   my $sp = $dbh->search_path;
   print $sp . "\n";

   # This is its output
   annotation

=cut

sub search_path {
  my ($self) = @_;
  if ($self->_dbtype =~ 'mysql') {
    return ("You're using MySQL.  Nnyeeehhh.");
  } else {
    my ($sp) = $self->selectrow_array('SHOW SEARCH_PATH');
    return ($sp);
  }
}

=head2 add_search_path

 Add a schema to the search path, if it is not already there.
 One or many search paths may be added at once.
 Ex: $dbh->add_search_path(qw/ sgn sgn_people /); 

=cut

sub add_search_path {
	my $self = shift;
	my ($current_string) = $self->selectrow_array('SHOW SEARCH_PATH');
	my @current = split ",", $current_string;
	push(@current, @_);
	@current = grep { /\w/ } @current; #avoid null items in array
	s/\s//g foreach @current;  #trim trailing spaces
	my $search_paths = {};
	$search_paths->{$_} = 1 foreach (@current);
	my $new_string = join ",", keys %$search_paths;
	my $update_q = "SET SEARCH_PATH=$new_string";
	$self->do($update_q);
}

=head2 last_insert_id

  Desc: Return the last auto-incremented primary key inserted into
        a table in the current connection.  Postgres ONLY!
  Args: A table name, an optional schema name (eventually perhaps the table
        name can be optional).
  Ret : The last insert id, an integer.
  Side Effects: None.
  Warning: in case there is no sequence found to be the default value
           for the primary key column of the table argument, this method
           DIEs.  You should only ever be using this inside a transaction
           eval block, and therefore should be checking the return from
           that eval.
  Examples:

   $dbh->do("INSERT INTO mytable (mytable_id, foo, bar) VALUES (DEFAULT, 1, 'two')");
   my $id = $dbh->last_insert_id("mytable")
   print "$id\n";
   -| 12345  # just an example

=cut

sub last_insert_id {
  my ($self, $table, $schema) = @_;

  # warning before the die gets the message through to loading scripts.
  warn "you forgot the table name argument to last_insert_id\n" unless $table;
  die unless $table;

  $schema ||= $self->_dbschema;
  my $btschema = $self->qualify_schema($schema, 1);
  # This query needs work.  For one thing, we're banking on the split_part/replace
  # munging things correctly, which is dubious.  It'd be better to actually
  # figure out the name of the sequence associated with the default on a primary
  # key column, but I don't know how to do that.
  my ($seq) = $self->selectrow_array("SELECT split_part(replace(adsrc, 'nextval(''', ''), '''::', 1)
                                        FROM pg_class t,                     -- tables
                                             pg_attribute a,                 -- attributes (columns)
                                             pg_attrdef d,                   -- attribute defaults
                                             pg_namespace n,                 -- schemas (called namespaces inside Pg)
                                             pg_constraint o                 -- constraints
                                       WHERE t.relkind='r'                   -- select only tables
                                         AND n.oid=t.relnamespace            -- joining tables to schemas
                                         AND a.attrelid=t.oid                -- joining attributes to tables
                                         AND d.adnum=a.attnum                -- joining defaults to attributes
                                         AND d.adrelid=t.oid                 -- joining defaults to tables
                                         AND o.conrelid=t.oid                -- joining constraints with tables
                                         AND o.contype='p'                   -- selecting only pkey constraints
                                         AND array_upper(o.conkey, 1)=1      -- selecting only single-column constraints (serial numbering can only apply to one column)
                                         AND o.conkey[1]=a.attnum            -- joining constraint column numbers with attribute column numbers
                                         AND adsrc LIKE 'nextval%'           -- select only defaults that look like nextval of some sequence
                                         AND t.relname = '$table'            -- select only tables whose name is the table argument
                                         AND n.nspname = '$btschema'         -- select only schemas whose name is the schema argument");
  unless($seq){die"No sequence name found for table '$table' and schema '$schema' using qualified schema name '$btschema'.\n";}
  my ($id) = $self->selectrow_array("SELECT currval('$btschema.$seq')");
  unless($id){die"No id found for table '$table' and schema '$schema' using qualified schema name '$btschema' and sequence name '$seq'.\n";}
  return ($id);
}

###
1;#do not remove
###

=head1 DBI database handle methods

All methods that can be used on a DBI database handle can also be
used on a CXGN::DB::Connection object.  They will be transparently
forwarded to this object's enclosed database handle.

Except for:

=head2 disconnect

  Usage: $dbconn->disconnect(42);
         #if you don't pass 42 here, it will print a dire warning
  Desc : Disconnect this database connection.  To prevent people
         doing this by accident, you must give this an argument
         of 42, or it will print a _dire_ warning.  Really, very dire.
  Ret  : true if the disconnection was successful
  Args : (optional) the number 42
  Side Effects: disconnects from the database
  Example:


  Notes: This is here because a lot of code uses shared database
         handles, and erroneously disconnecting one can have great
         potential for causing far-away code to die a gruesome death.

=cut

#to alter which methods are forwarded, edit the array @dbh_methods
#at the top of this file

#disconnect is not directly forwarded, because we want to catch
#spurious disconnects, because they may be buried somewhere
sub disconnect {
  my $self = shift;
  my $you_know_what_you_doing = shift; #for great justice

  unless( defined($you_know_what_you_doing) && $you_know_what_you_doing == 42 ) {
    my $msg = "Are you sure you want to be disconnecting here?  If you are sharing this CXGN::DB::Connection with other modules, they may not be expecting you to disconnect, which could lead to a bug that would be hard to track down.  To confirm that you really want to do this, pass the number 42 as an argument to disconnect";
    if( $self->_conf->get_conf('production_server') ) {
      carp $msg;
    } else {
      croak $msg;
    }
    if( $self->_dbh ) {
      $self->trace_msg('Spurious disconnection emanating from '.join(':',caller)."\n",1);
    }
  }

  if( $self->_dbh ) {
      $self->trace_msg('CXGN_TRACE | '._compact_backtrace().' | '.__PACKAGE__."::disconnect | $self | ".$self->_dbh."\n",1);
      return $self->_dbh->disconnect;
  } else {
    return undef;
  }
}

=head1 CLASS METHODS

=head2 verbose

  DEPRECATED.  This method no longer does anything, this module just uses CXGN::Debug::debug.  

  OLD DOCUMENTATION
  # Usage: CXGN::DB::Connection->verbose(1);
  # Desc : get/set the verbosity level of CXGN::DB::Connection objects.
  #        defaults to 0 in web server, 1 otherwise.
  # Ret  : currently set verbosity level
  # Args : new verbosity level
  # Side Effects: sets the verbosity level for all CXGN::DB::Connection objects
  # Example:

=cut

sub verbose {
    carp "CXGN::DB::Connection::verbose no longer does anything, might as well remove this invocation";
}

sub is_valid_dbh
{
    my($dbh)=@_;
    if($dbh eq 'CXGN::DB::Connection')
    {
        warn "You sent in the string 'CXGN::DB::Connection'. Did you call this function with a '->' instead of a '::'?";
        return 0;
    }
    unless(ref($dbh))
    {
        warn "'$dbh' is not a reference";
        return 0;
    }
    if(ref($dbh) eq "ARRAY" or ref($dbh) eq "HASH")
    {
        warn "'$dbh' is not an object reference";
        return 0;
    }
    unless($dbh->isa('CXGN::DB::Connection'))
    {
        warn "'$dbh' is a reference but not a CXGN::DB::Connection";
        return 0;
    }
    return 1;
}

=head1 LICENSE

This module is part of the SGN/CXGN codebase and is distributed under
the same terms that it is. If you're confused about the license or did
not receive one, please email us at sgn-feedback@sgn.cornell.edu.

=head1 AUTHOR

Written by the SGN crew.  The first person to have her grubby mitts
on this was Beth.  Then Rob.  Then Marty.  Then Rob again.  And so on.

=head1 SEE ALSO

L<DBI>, L<Apache::DBI>, L<Ima::DBI>, L<Class::DBI>

=cut


1;
