#!/usr/bin/env perl

use strict;
use warnings;

use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;
use Bio::GMOD::DB::Tools::ETA;
use Getopt::Long;

=head1 NAME

gmod_materialized_view_tool.pl - a tool for creating and mangaing
materialized views for Chado.

=head1 SYNOPSYS

 % gmod_materialized_view_tool.pl [options]

=head1 COMMAND-LINE OPTIONS

 --create_view              Guides user through creating a MV
 --update_view viewname     Refreshes data in named MV
 --automatic                Refreshes data in all MV that are out of date
 --dematerialize viewname   Creates a true view, removing the MV
 --dbprofile profilename    DB profile options to use (default is 'default')
 --list                     Gives a list of MV
 --status                   Gives the status of all MV
 --view_name                Name of the view to be created
 --table_name               Schema qualified name of the table
 --refresh_time             Frequency at which the view should be updated
 --column_def               List of columns with types
 --sql_query                Select query to define table contents
 --index_fields             List of fields to build indexes on
 --special_index            SQL to create special indexes
 --yes                      Assume yes to any yes/no question
 --help                     Prints this documentation and quits

Note that the options can be shortened.  For example, '--de' is
an acceptable shortening of --dematerialize.  For options that have a
unique first letter, the short (single hyphened) version of the option
may be used, like '-a' for --automatic.

=head1 DESCRIPTION

WARNING: This script creates a rather large security hole that could 
result in data loss.  Users could easily enter SQL queries through this
interface that could damage your database.

This tool provides several useful functions for creating and maintaining
materialized views (MV) in a Chado schema.  A materialized view is simple
a (real) database table that has been created and contains data from
a collection of other tables.  It is like a view, only because it
materialized, it can be indexed and searches on it will go much faster
than on database views.  There are at least two down sides to MVs:

=over

=item 1 Data syncronisity

When normal tables are updated with values that are reflected in a MV,
there will be a delay (usually a very noticable one) between when 
the normal table is updated and when the MV is updated.  This tool
provides the means of updating the MVs; see --automatic below.

=item 2 Disk space

Since MVs are actual tables, they will take up actual disk space.  It
is possible, depending on how the MV is created, it may take up an
enormous amount of disk space.

=back

=head2 A Note about SQL for populating the table

When constructing the SELECT clause, the names of the columns selected
must match the names of the columns in the materalized view.  For example,
if the names of the columns are feature_id and name, but the columns
being selected are feature_id and uniquename, you must use the "AS" option
to rename the resulting column, like:

  SELECT feature_id, uniquename AS name ...

If you don't do this, the affected column in the resulting table will
be empty.

=head1 OPTIONS

=over

=item --create_view

Guides the user through a series of prompts to create a new materialized view.

=item  --update_view viewname

Updates the data in a materialized view by first deleting the data in 
the table and then running the query that defines the data to repopulate it. 

=item  --automatic

Automatically updates all of the MVs that are currently marked out of 
date according to the update frequency that was specified when the MV
was created.  This option is very useful in a cron job to update MVs
on a regular basis.

=item  --dematerialize viewname

Takes a MV and turns into a standard view.  This might be done if
the database administrator desides that the downsides of the MV scheme
is not working for a given view, if for example, the data in the underlying
tables is changing to frequently or the MV is taking up too much disk space.

=item  --dbprofile

The name of the DB profile to use for database connectivity.  These
profiles are kept in $GMOD_ROOT/conf (typically /usr/local/gmod/conf)
and contain information like the database name, user name and password.
The default value is 'default' which was created when the Chado
database was created.

=item  --list

Gives a list of current MVs.

=item  --status

Gives the status of all MVs, including whether they are considered
current or out of date.

=item  --help

Prints this documetation and quits.

=back

=head1 NONINTERACTIVE VIEW CREATION

The following options are provided to allow the creation of materialized
views in a non-interactive way.  If any of the below flags are omitted, you
will be prompted for the appropriate values.

=over

=item --view_name

This is the name that this tool will use later to refer to the MV as; 
typically it will be the same as the name of the MV in the database, 
but it doesn't have to be.

=item --table_name

The schema qualified name of the table, like "public.all_feature_names"

=item --refresh_time

Frequency at which the view should be updated.  This can either be a number
of seconds, or one of 'daily', 'weekly', or 'monthly'.

=item --column_def

List of columns with types, like
"feature_id integer,name varchar(255),organism_id integer".

=item --sql_query

Select query to define table contents; see the note above about how
the SQL must be written for this query.

=item --index_fields

List of fields to build indexes on.

=item --special_index

SQL to create special indexes.  This allows you to create functional
and full text search indexes.

=item --yes

Assume yes to any yes/no question

=back

=head1 AUTHORS

Chris Carpita <ccarpita at gmail dot com>, with some minor additions and
GMOD specific alterations from Scott Cain E<lt>cain@cshl.eduE<gt>.

Copyright (c) 2007

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


our $TABLE  = "materialized_view";
our $SCHEMA = "public";

my ( $DBPROFILE, $STATUS, $LIST, $NAME, $DEMATERIALIZE, $CREATE_VIEW,
    $UPDATE_VIEW, $AUTOMATIC, $HELP,
    $VIEWNAME, $TABLENAME, $REFRESH_TIME, $COLUMNDEF, $SQLQUERY, $INDEXFIELDS,
    $SPECIALINDEX, $YES,);

GetOptions(
    'dbprofile=s'     => \$DBPROFILE,
    'status'          => \$STATUS,
    'list'            => \$LIST,
    'create_view'     => \$CREATE_VIEW,
    'update_view=s'   => \$UPDATE_VIEW,
    'automatic'       => \$AUTOMATIC,
    'dematerialize=s' => \$DEMATERIALIZE,
    'view_name=s'     => \$VIEWNAME,
    'table_name=s'    => \$TABLENAME,
    'refresh_time=s'  => \$REFRESH_TIME,
    'column_def=s'    => \$COLUMNDEF,
    'sql_query=s'     => \$SQLQUERY,
    'index_fields=s'  => \$INDEXFIELDS,
    'special_index=s' => \$SPECIALINDEX,
    'yes'             => \$YES, 
    'help'            => \$HELP,
) or ( system( 'pod2text', $0 ), exit -1 );

( system( 'pod2text', $0 ), exit -1 ) if $HELP;

$DBPROFILE ||= 'default';

my $gmod_conf = Bio::GMOD::Config->new();
my $db_conf = Bio::GMOD::DB::Config->new( $gmod_conf, $DBPROFILE );

$SCHEMA = $db_conf->schema || $SCHEMA;
my $dbh = $db_conf->dbh;
$dbh->{AutoCommit} = 0;

my $db_message =
  "Viewing '" . $db_conf->name . "' database on host " . $db_conf->host;
print "=" x length($db_message) . "\n";
print $db_message . "\n";
print "=" x length($db_message) . "\n\n";

our $table_exist_q = $dbh->prepare( "
	SELECT * FROM pg_catalog.pg_tables 
	WHERE schemaname=?
	AND tablename=?
	" );
$table_exist_q->execute( $SCHEMA, $TABLE );
my $mv_table_exists = $table_exist_q->fetchrow_hashref;

if ( $STATUS or $LIST ) {
    create_mv_table() unless $mv_table_exists;
    my $arg = $STATUS ? 'status' : 'list';
    view_info($arg);
}

##Begin Pre-fetch
our @NAMES = ();
my $sth = $dbh->prepare("SELECT name FROM $SCHEMA.$TABLE");
$sth->execute();
while ( my ($n) = $sth->fetchrow_array() ) { push( @NAMES, $n ) }

our @VIEWS = ();
$sth = $dbh->prepare("SELECT viewname FROM pg_views WHERE schemaname= ?");
$sth->execute($SCHEMA);
while ( my ($n) = $sth->fetchrow_array() ) { push( @VIEWS, $n ) }
###End Pre-fetch

if ($CREATE_VIEW) {
    prompt_create_mv();
}
elsif ($UPDATE_VIEW) {
    update_mv($UPDATE_VIEW);
}
elsif ($AUTOMATIC) {
    print "Automatic update mode...\n";
    my $sth = $dbh->prepare( "
		SELECT name FROM $SCHEMA.$TABLE 
		WHERE 
		EXTRACT(epoch FROM (NOW() - last_update)) >= refresh_time
		" );
    $sth->execute();
    while ( my ($name) = $sth->fetchrow_array() ) {
        update_mv($name);
    }
}
elsif ($DEMATERIALIZE) {
    dematerialize_view($DEMATERIALIZE);
}
else {
    system( 'pod2text', $0 ), exit -1;
}

sub create_mv_table {
    print "Table $SCHEMA.$TABLE does not exist, creating...\n";
    $dbh->do( "
		CREATE TABLE $SCHEMA.$TABLE
			( 	${TABLE}_id SERIAL,
				last_update TIMESTAMP,
				refresh_time INT,
				name VARCHAR(64) UNIQUE,
				mv_schema VARCHAR(64),
				mv_table VARCHAR(128),
				mv_specs TEXT,
				indexed TEXT,
				query TEXT,
                                special_index TEXT
				)" )
      or die "Can't create table\n";
    $dbh->do("GRANT SELECT ON $SCHEMA.$TABLE TO public");
    $dbh->commit();
}

sub view_info {
    my $longarg   = shift;
    my $query     = "";
    my @list_cols = qw/ name mv_schema mv_table refresh_time last_update /;
    $query = "SELECT " . join( ", ", @list_cols ) . " FROM $SCHEMA.$TABLE"
      if $longarg eq "list";
    $query =
"SELECT name, EXTRACT(epoch FROM NOW() - last_update) AS time_passed, refresh_time FROM $SCHEMA.$TABLE"
      if $longarg eq "status";
    my $sth = $dbh->prepare($query);
    print "Status of materialized views:\n" if $longarg eq "status";
    print "List of materialized views:\n"   if $longarg eq "list";
    $sth->execute() or exit 0;
    my $i     = 0;
    my $table = [];

    while ( my $row = $sth->fetchrow_hashref() ) {
        unless ($i) {
            $table->[0] = \@list_cols if $longarg eq "list";
            $table->[0] = [ "MV Name", "Status", "Time to Update" ]
              if $longarg eq "status";
        }
        my @vals = ();
        push( @vals, $row->{$_} ) foreach @list_cols;
        $table->[ $i + 1 ] = \@vals if $longarg eq "list";
        if ( $longarg eq "status" ) {
            my $status    = "Current";
            my $remaining = $row->{refresh_time} - $row->{time_passed};
            $status = "Outdated" if $remaining < 0;
            my $format_time = format_secs( abs($remaining) );
            $format_time .= " PAST DUE" if $status eq "Outdated";
            $table->[ $i + 1 ] = [ $row->{name}, $status, $format_time ];
        }
        $i++;
    }
    print_table( $table, 3 );

    print "\n";
    exit 0;
}

sub print_table {
    my $table        = shift;
    my $cell_spacing = shift;
    $cell_spacing ||= 2;

    my $valid    = 1;
    my $num_cols = undef;
    if ( ref($table) eq "ARRAY" ) {
        foreach my $row (@$table) {
            $valid = 0 unless ref($row) eq "ARRAY";
            $num_cols = scalar @$row unless defined $num_cols;
            unless ( ( scalar @$row ) == $num_cols ) {
                print "This row has "
                  . scalar(@$row)
                  . " entries, when the number of columns should be $num_cols:\n";
                print join( "\t", @$row );
                $valid = 0;
            }
            foreach my $col_entry (@$row) {
                $valid = 0 if ref($col_entry);
            }
        }
    }
    else { $valid = 0 }
    die
"Argument to print_table() must be a rectangular two-dimensional hashref, with values being scalars\n"
      unless $valid;

    my $col_widths = [];
    my $format     = "";
    for ( my $i = 0 ; $i < $num_cols ; $i++ ) {
        my @colvals = ();
        for ( my $j = 0 ; $j < @$table ; $j++ ) {
            push( @colvals, $table->[$j]->[$i] );
        }
        my $max_length = 0;
        foreach (@colvals) {
            $max_length = length($_) if length($_) > $max_length;
        }
        $col_widths->[$i] = $max_length + $cell_spacing;
        if ( $i == ( $num_cols - 1 ) ) {
            $format .= '%s' . "\n";
        }
        else {
            $format .= "%-" . ( $max_length + $cell_spacing ) . "s";
        }
    }

    foreach my $row (@$table) {
        printf( $format, @$row );
    }
}

sub prompt_create_mv {
    my $confirm = 0;

    #Create a new materialized view.
    print "\n\n";
    print "=================================\n";
    print "Creating a new materialized view!\n";
    print "=================================\n\n";

    my ($remove_view, $location, $name);
    while ( !$confirm ) {

        $name = validate(
            {
                resp   => $VIEWNAME,
                prompt =>
                  "Give your materialized view a name (word characters only): ",
                test => sub {
                    my $t      = shift;
                    my %exists = ();
                    foreach my $n (@NAMES) { $exists{$n} = 1 }
                    if ( $exists{$t} ) {
                        print "MV '$_' already exists!  Current names taken: "
                          . join( ", ", @NAMES ) . "\n";
                        die "$VIEWNAME already exists and must be explicitly removed with '--dematerialize $VIEWNAME'" if ($VIEWNAME);
                    }
                    unless ( $t =~ /^\w+$/ ) {
                        print "Invalid format, use word characters only($t)\n";
                    }
                    ( !$exists{$t} && $t =~ /^\w+$/ );
                  }
            }
        );

        $location = validate(
            {
                resp   => $TABLENAME,
                prompt =>
                  "Where will this MV be located? (schemaname.tablename): ",
                regexp => '^\w+\.\w+$'
            }
        );

        my ( $mv_schema, $mv_table ) = $location =~ /(\w+)\.(\w+)/;

        for my $view (@VIEWS) {
            if ( "$SCHEMA.$view" eq $location ) {
                $remove_view = validate(
                    {
                        resp   => $YES ? 'y' : '',
                        prompt =>
                          "A view with this name already exists; do you want"
                          ." to replace it\nwith a materialized view? [y|n] ",
                        regexp => '^y|n$'
                    }
                );
            }
        }
        if ( $remove_view and $remove_view ne 'y' ) {
            print "This (non-materialized) view already exists, and you won't"
                  ."let me remove it.\nBye!\n";
            exit(0);
        }


        my $refresh_time = validate(
            {
                resp   => $REFRESH_TIME,
                prompt =>
                     "How often, in seconds, should the MV be refreshed?\n"
                    ."You can also type 'daily', 'weekly', 'monthly' (30 days), or 'yearly' (365 days): ",
                regexp => '^(?i:(\d+)|(daily)|(weekly)|(monthly)|(yearly))$'
            }
        );
        unless ( $refresh_time =~ /^\d+$/ ) {
            if ( $refresh_time =~ /daily/i ) {
                $refresh_time = 60 * 60 * 24;
            }
            elsif ( $refresh_time =~ /weekly/i ) {
                $refresh_time = 60 * 60 * 24 * 7;
            }
            elsif ( $refresh_time =~ /monthly/i ) {
                $refresh_time = 60 * 60 * 24 * 30;
            }
            elsif ( $refresh_time =~ /yearly/i ) {
                $refresh_time = 60 * 60 * 24 * 365;
            }
            print "Using refresh_time of $refresh_time seconds\n";
        }

        my $mv_specs = validate(
            {
                resp   => $COLUMNDEF,
                prompt =>
"Enter specifications for the materialized view, OR provide a file in which\n"
."the specs are written ('? for help): ",
                test => sub {
                    my $t = $_[0];
                    if ( -f $t ) {
                        print
"'$t' is a valid file, reading into specifications variable...\n";
                        print "File '$t' contents: ";
                        $t = slurp_file($t);
                        print $t . "\n";
                    }
                    if ( $t =~ /^(\w+(\s+[\w)('"]+)+\s*,?\s*)+\s*$/ ) {
                        $_[0] = $t;
                        return 1;
                    }
                    elsif ( $t =~ /^\s*[\?]\s*$/ ) {
                        print
"This is supposed to be the stuff in-between parenthesis in a CREATE TABLE query.\nYou should use the same column names that would result from the MV query\nFor Example: \"member VARCHAR(32), member_desc TEXT, has_parent TINYINT DEFAULT 0";
                    }
                    else {
                        print "'$t' is not a valid format OR existing file\n";
                    }
                    return 0;
                  }
            }
        );

        my $query = validate(
            {
                resp   => $SQLQUERY,
                prompt =>
                        "Enter the SQL query for the materialized view,\n"
                       ."or a file containing only the query: ",
                test => sub {
                    my $t = @_[0];
                    if ( -f $t ) {
                        print
                   "'$t' is a valid file, reading into query variable...\n";
                        print "File '$t' contents: ";
                        $t = slurp_file($t);
                        print "$t\n";
                    }
                    if ( $t =~ /^\s*SELECT.*FROM[^?]+$/i ) {
                        $_[0] = $t;
                        return 1;
                    }
                    else {
                        print
"'$t' is not a valid file, or it is not valid SQL.  You can't use placeholders, by the way.\n";
                    }
                    return 0;
                  }

            }
        );

        my $indexes = validate(
            {
                resp   => $INDEXFIELDS,
                prompt =>
"Enter a comma separated list of fields to index (or return for none):",
                test => sub {
                    my $t = @_[0];
                    if ( $t =~ /^[A-Za-z,_]*$/ ) {
                        $_[0] = $t;
                        return 1;
                    }
                    print
"'$t' is not valid; please make sure that you use only the name of the fields separated by commas.\n";
                    return 0;
                  }
            }
        );

        my $special_indexes = validate(
            {
                resp   => $SPECIALINDEX,
                prompt =>
                   "Enter the SQL queries for special indexes,\n"
                   ."or a file containing only the query (or return for none): ",
                test => sub {
                    my $t = @_[0];
                    if ( $t eq "") {
                        $_[0] = '';
                        return 1;
                    }
                    if ( -f $t ) {
                        print
                   "'$t' is a valid file, reading into query variable...\n";
                        print "File '$t' contents: ";
                        $t = slurp_file($t);
                        print "$t\n";
                    }
                    if ( $t =~ /^\s*CREATE.*INDEX[^?]+$/i ) {
                        $_[0] = $t;
                        return 1;
                    }
                    else {
                        print
"'$t' is not a valid file, or it is not valid SQL.  You can't use placeholders, by the way.\n";
                    }
                    return 0;
                  }
            } 
        );

        my $insert_q =
          $dbh->prepare(
"INSERT INTO $SCHEMA.$TABLE (last_update, refresh_time, name, mv_schema, mv_table, mv_specs, query, indexed, special_index ) VALUES (NOW(), ?, ?, ?, ?, ?, ?, ?, ?)"
          );

        print "\n\nConfirm that the following is correct:\n";
        print "Name: $name\nLocation: $mv_schema.$mv_table\n";
        print "Refresh Time (sec): $refresh_time\n";
        print
"MV creation query: CREATE TABLE $mv_schema.$mv_table ( $mv_specs )\n";
        print "Query: $query\n";
        print "Indexes on: $indexes\n";
        print "Special index query: $special_indexes\n";
        my $resp = validate(
            {
                resp   => $YES ? 'y' : '',
                prompt => "Enter 'y' to confirm, 'n' to re-enter data: ",
                regexp => '^y|n$'
            }
        );
        $confirm = 1 if $resp eq 'y';

        if ($confirm) {
            $insert_q->execute( $refresh_time, $name, $mv_schema, $mv_table,
                $mv_specs, $query, $indexes, $special_indexes )
              or die "MV insert error: " . $dbh->errstr . "\n";
            $NAME = $name;
        }
    }
    $dbh->commit();

    if ($remove_view) {
        print "Removing the view $location\n";
        $dbh->do("DROP VIEW $location") 
            or die "View drop error: ".$dbh->errstr."\n";
    }

    #drop view if present
    #populate materialized view (using 'force')
    update_mv($name);

    $dbh->commit();
    print "MV Entered into the registry and created.\n";
}

sub slurp_file {
    my $filename = shift;
    open( FH, $filename ) or return;
    my $buffer = "";
    $buffer .= $_ while (<FH>);
    close FH;
    $buffer =~ s/[\n\r]/ /gs;
    return $buffer;
}

sub update_mv {
    my $name = shift;

    my $sth = $dbh->prepare("SELECT * FROM $SCHEMA.$TABLE WHERE name=?");
    $sth->execute($name);
    my $row = $sth->fetchrow_hashref();
    unless ($row) {
        print
"The MV with the name '$name' does not exist.  Here is a list of existing MV's: ";
        print join( ", ", @NAMES );
        print "\n";
        return;
    }
    my ( $mv_schema, $mv_table, $mv_specs ) =
      ( $row->{mv_schema}, $row->{mv_table}, $row->{mv_specs} );
    $table_exist_q->execute( $mv_schema, $mv_table );
    my $exists         = $table_exist_q->fetchrow_hashref;
    my $special_indexes = $row->{special_index};
    my $indexed_string = $row->{indexed};
    my @indexed        = split /\s*,\s*/, $indexed_string;
    unless ($exists) {
        print
"Creating materialized view '$name' for the first time at $mv_schema.$mv_table...\n";
        my $create_q = "CREATE TABLE $mv_schema.$mv_table ($mv_specs)";
        print $create_q . "\n";
        $dbh->do($create_q)
          or die "Couldn't create materialized view\n";
        $dbh->do("GRANT SELECT ON $mv_schema.$mv_table TO public");
        print "MV table created.\n";
        $dbh->do("SET SEARCH_PATH=$mv_schema");
        foreach (@indexed) {
            next unless /\w/;
            $dbh->do("CREATE INDEX ${mv_table}_$_ ON $mv_table($_)");
        }
        if ($special_indexes) {
            $dbh->do($special_indexes)
                or die "CREATE index query failed:\n"
                .$special_indexes. "\n".$dbh->errstr;
        }
        $dbh->commit();
    }

    my $query = $row->{query};

    my $count_query = $query;
    $count_query =~ s/SELECT.*\bFROM\b/SELECT COUNT(*) FROM/si;

    #	print "Using this query to count total entries: $count_query\n";
    $sth = $dbh->prepare($count_query);
    $sth->execute();
    my ($total) = $sth->fetchrow_array();
    my $eta = Bio::GMOD::DB::Tools::ETA->new();
    $eta->interval(0.3);
    $eta->target($total);

    print "Total # of entries in MV '$name': $total\n";

    $sth = $dbh->prepare($query);
    $sth->execute();

    my $i = 0;
    $eta->begin();
    print "Deleting current entries in MV '$name'...\n";
    $dbh->do("DELETE FROM $mv_schema.$mv_table");
    $dbh->do("SET SEARCH_PATH=$mv_schema");

    #find any indexes that belong to this table
    drop_indexes($mv_schema,$mv_table);

    print "Inserting new values into MV '$name'...\n";
    while ( my $entry = $sth->fetchrow_hashref() ) {
        my @valid_cols = extract_cols_from_specs($mv_specs);
        my @phs        = ();
        foreach (@valid_cols) { push( @phs, "?" ) }
        my $query =
          "INSERT INTO $mv_schema.$mv_table ( "
          . join( ", ", @valid_cols ) . " ) ";
        $query .= " VALUES ( " . join( ",", @phs ) . " )";
        my $insq   = $dbh->prepare($query);
        my @values = ();
        foreach (@valid_cols) {
            push( @values, $entry->{$_} );
        }
        $insq->execute(@values);
        $i++;
        $eta->update_and_print($i);
    }
    $dbh->do("SET SEARCH_PATH=$mv_schema");
    foreach (@indexed) {
        next unless /\w/;
        $dbh->do("CREATE INDEX ${mv_table}_$_ ON $mv_table($_)");
    }
    if ($special_indexes) {
        $dbh->do($special_indexes)
            or die "CREATE index query failed:\n"
            .$special_indexes. "\n".$dbh->errstr;
    }

    my $timeupq =
      $dbh->prepare("UPDATE $SCHEMA.$TABLE SET last_update=NOW() WHERE name=?");
    $timeupq->execute($name);

    print "\nUpdate of MV '$name' successful.\n";
    $dbh->commit();
}

sub dematerialize_view {
    my $view   = shift;
    my $really = validate(
        {
            resp   => $YES ? 'y' : '',
            prompt => 
"Really remove the materialized view? Enter 'y' to confirm, 'n' to exit: ",
            regexp => '^y|n$'
        }
    );
    if ( $really ne 'y' ) {
        print "OK, exiting instead.\n";
        exit(0);
    }

    #get table and schema name from view name
    my $get_the_pieces_query = $dbh->prepare("
            SELECT mv_schema,mv_table,mv_specs,query
            FROM materialized_view
            WHERE name = ?
        ");
    $get_the_pieces_query->execute($view)
        or die "problem with query ". $dbh->errstr;

    my ($schema,$table,$columns,$query) = $get_the_pieces_query->fetchrow_array;

    

    #determine if the table already exists, if not, exit
    my $exists_query = $dbh->prepare("SELECT count(*) FROM pg_tables
                                      WHERE schemaname=? AND
                                            tablename=?");
    $exists_query->execute($schema,$table); 
    my ($exists) = $exists_query->fetchrow_array;
    unless ($exists) {
        print "The table $schema.$table doesn't exist, so there is nothing to dematerialize.\n";
        exit(0);
    } 

    #drop indexes and table
    drop_indexes_and_table($schema,$table);

    #create index from mv_table, mv_specs, query
    #fix column spec
    my @cols = split /,/, $columns;
    my @columns;
    for my $col (@cols) {
        $col =~ /^\s*(\w+)\s+/;
        push @columns, $1; 
    }
    $columns = join(',', @columns);

    my $create_view_query = "CREATE VIEW $schema.$table ($columns) AS $query";
    $dbh->do($create_view_query) or die "problem creating view: ".$dbh->errstr;

    #this used to set the update time to 20 years rather than deleting the
    #entry.  Now it just deletes the entry
    my $update_query = $dbh->prepare(
         "DELETE FROM  materialized_view WHERE name = ?");
    $update_query->execute($view) 
         or die "problem delete deleted MV from materialized_view table: ".$dbh->errstr;
    $dbh->commit();
    return;
}

sub drop_indexes_and_table {
    my $schema = shift;
    my $table  = shift;

    drop_indexes($schema,$table);

    $dbh->do("DROP TABLE $schema.$table")
           or die "problem dropping table ".$dbh->errstr;

    return;
}

sub drop_indexes {
    my $schema = shift;
    my $table  = shift;

    my $index_query = $dbh->prepare(
        'SELECT indexname FROM pg_indexes WHERE tablename=? AND schemaname=?');
    $index_query->execute( $table, $schema );

    while ( my $hashref = $index_query->fetchrow_hashref ) {
        print "Dropping index $schema.$$hashref{indexname}\n";
        my $query = "DROP INDEX $schema.$$hashref{indexname}";
        $dbh->do($query);
    }
    return;
}

sub extract_cols_from_specs {
    my $specs = shift;
    $specs =~ s/\(\s*\d+\s*,\s*\d+\s*\)//g;
    my @items = split /,/, $specs;
    my @cols = ();
    foreach (@items) {
        my ($name) = /^\s*(\w+)/;
        push( @cols, $name );
    }
    return @cols;
}

sub validate {
    my $args      = shift;
    my $valid     = 0;
    my $resp      = $args->{resp} || "";
    my $error_msg = $args->{regexp_error};
    $error_msg ||= "Invalid format, try again";
    while ( !$valid ) {
        unless ($resp) {
            print "\n" . $args->{prompt};
            $resp = <STDIN>;
            chomp $resp;
        }
        if ( exists( $args->{test} ) ) {
            $valid = 1 if $args->{test}->($resp);
        }
        else {
            $valid = 1 if $resp =~ /$args->{regexp}/;
            print $error_msg unless $valid;
        }
    }
    return $resp;
}

sub format_secs {
    my $secs  = int(shift);
    my $mins  = 0;
    my $hours = 0;
    my $days  = 0;

    if ( $secs > 60 ) {
        $mins = int( $secs / 60 );
        $secs -= $mins * 60;
    }
    if ( $mins > 60 ) {
        $hours = int( $mins / 60 );
        $mins -= $hours * 60;
    }
    if ( $hours > 24 ) {
        $days = int( $hours / 24 );
        $hours -= $days * 24;
    }
    foreach ( $mins, $secs, $hours ) {
        $_ = "0" . $_ if ( $_ < 10 );
    }
    my $formatted = "";
    $formatted = "$days days, " if $days > 0;
    $formatted .= "$hours:$mins:$secs";
    return $formatted;
}
