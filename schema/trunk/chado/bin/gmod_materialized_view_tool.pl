#!/usr/bin/perl

use strict;
use lib '/home/cain/cvs_stuff/schema/chado/lib';
use lib '/home/scott/cvs_stuff/schema/chado/lib';

use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;

#use CXGN::DB::InsertDBH;
#use CXGN::DB::Connection; #for read-only
#CXGN::DB::Connection->verbose(0);

use Bio::GMOD::DB::Tools::ETA;

#use Getopt::Std qw/getopts/;
use Getopt::Long;

#our $arg = {};
#getopts('cah:d:n:', $arg);

#my $longarg = $ARGV[0];

our $TABLE  = "materialized_view";
our $SCHEMA = "public";

my ( $DBPROFILE, $STATUS, $LIST, $NAME, $DEMATERIALIZE, $CREATE_VIEW,
    $UPDATE_VIEW, $AUTOMATIC );

GetOptions(
    'dbprofile=s'     => \$DBPROFILE,
    'status'          => \$STATUS,
    'list'            => \$LIST,
    'create_view'     => \$CREATE_VIEW,
    'update_view=s'   => \$UPDATE_VIEW,
    'automatic'       => \$AUTOMATIC,
    'name=s'          => \$NAME,
    'dematerialize=s' => \$DEMATERIALIZE,
) or ( system( 'pod2text', $0 ), exit -1 );

$DBPROFILE ||= 'default';

my $gmod_conf = Bio::GMOD::Config->new();
my $db_conf = Bio::GMOD::DB::Config->new( $gmod_conf, $DBPROFILE );

my $dbh = $db_conf->dbh;
$dbh->{AutoCommit} = 0;

#usage() unless($longarg =~ /^(status)|(list)$/ || $arg->{c} || $arg->{n} || $arg->{a});

#our $view_dbh = CXGN::DB::Connection->new({dbhost => $arg->{h}, dbname => $arg->{d}});

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
    usage();
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
				query TEXT
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
                prompt =>
                  "Give your materialized view a name (word characters only): ",
                test => sub {
                    my $t      = shift;
                    my %exists = ();
                    foreach my $n (@NAMES) { $exists{$n} = 1 }
                    if ( $exists{$t} ) {
                        print "MV '$_' already exists!  Current names taken: "
                          . join( ", ", @NAMES ) . "\n";
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
                        prompt =>
                          "A view with this name already exists; do you want to replace it with a materialized view? [y|n]",
                        regexp => '^y|n$'
                    }
                );
            }
        }
        if ( $remove_view and $remove_view ne 'y' ) {
            print
"This (non-materialized) view already exists, and you won't let me remove it.  Bye!\n";
            exit(0);
        }


        my $refresh_time = validate(
            {
                prompt =>
"How often, in seconds, should the MV be refreshed?\nYou can also type 'daily', 'weekly', 'monthly' (30 days), or 'yearly' (365 days): ",
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
                prompt =>
"Enter specifications for the MV, OR provide a file in which the specs are written ('? for help): ",
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
                prompt =>
"Enter the SQL query for the materialized view, or a file containing only the query: ",
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

        my $insert_q =
          $dbh->prepare(
"INSERT INTO $SCHEMA.$TABLE (last_update, refresh_time, name, mv_schema, mv_table, mv_specs, query, indexed ) VALUES (NOW(), ?, ?, ?, ?, ?, ?, ?)"
          );

        print "\n\nConfirm that the following is correct:\n";
        print "Name: $name\nLocation: $mv_schema.$mv_table\n";
        print "Refresh Time (sec): $refresh_time\n";
        print
"MV creation query: CREATE TABLE $mv_schema.$mv_table ( $mv_specs )\n";
        print "Query: $query\n";
        print "Indexes on: $indexes\n";
        my $resp = validate(
            {
                prompt => "Enter 'y' to confirm, 'n' to re-enter data: ",
                regexp => '^y|n$'
            }
        );
        $confirm = 1 if $resp eq 'y';

        if ($confirm) {
            $insert_q->execute( $refresh_time, $name, $mv_schema, $mv_table,
                $mv_specs, $query, $indexes )
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

    #        my $force = shift;
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
    my $index_query = $dbh->prepare(
        'SELECT indexname FROM pg_indexes WHERE tablename=? AND schemaname=?');
    $index_query->execute( $mv_table, $mv_schema );

    while ( my $hashref = $index_query->fetchrow_hashref ) {
        print "Dropping index $mv_schema.$$hashref{indexname}\n";
        my $query = "DROP INDEX $mv_schema.$$hashref{indexname}";
        $dbh->do($query);
    }

    #foreach(@indexed){
    #	next unless /\w/;
    #	my $query = "DROP INDEX ${mv_table}_$_";
    #	$dbh->do($query);
    #}
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
            prompt => "Enter 'y' to confirm, 'n' to re-enter data: ",
            regexp => '^y|n$'
        }
    );
    if ( $really ne 'y' ) {
        print "OK, exiting instead.\n";
        exit(0);
    }

    #determine if the table already exists, if not, exit
    #
    #drop indexes and table
    #
    #create index from mv_table, mv_specs, query

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
    my $resp      = "";
    my $error_msg = $args->{regexp_error};
    $error_msg ||= "Invalid format, try again";
    while ( !$valid ) {
        print "\n" . $args->{prompt};
        $resp = <STDIN>;
        chomp $resp;
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

sub usage {
    print "\nUSAGE:\n";
    print "$0 <options> [status|list]?\n";
    print "Update materialized view(s) or create one\n";
    print <<HERE;
View Info
	status - show which MV's are out-of-date and how current the others are
	list - more info about all MV's

Options with Arguments:
	-h  <hostname>
	-d  <database>
	-n  <MV name>  provided MV will be force-updated

Boolean Options:
	-c  MV creation mode (overwrites -n)
	-a  automatic update of all MV's that need to be refreshed

HERE

    exit 0;
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
