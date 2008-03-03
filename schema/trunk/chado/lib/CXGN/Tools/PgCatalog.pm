package CXGN::Tools::PgCatalog;
use strict;
use warnings;
use Carp;

BEGIN {
  our @EXPORT_OK = qw/ table_info /;
}
our @EXPORT_OK;
use base qw/Exporter/;

=head1 NAME

CXGN::Tools::PgCatalog - tools for getting information out of the
Postgres pg_catalog schema.

=head1 DESCRIPTION

Tools for getting information from the Postgres pg_catalog schema,
which holds everything you ever wanted to know about the structure
of the database itself.

=head1 FUNCTIONS

All functions listed below are EXPORT_OK.

=head2 table_info

  Usage: my %info = table_info($dbc,'genomic','blast_hit');
  Desc :
  Ret  : hash-style list as:
         ( primary  => ['primary key col','primary key col',...],
           columns  => ['column name', 'column name', ...],
           sequence => 'genomic.my_crazy_seq',
         )
  Args : L<CXGN::DB::Connection> object, schema name, table name
  Side Effects:
  Example:

=cut

#adapted by Rob from set_up_table in Class::DBI::Pg
sub table_info {
  my ( $dbh, $schema, $table ) = @_;
  print "getting info for $schema.$table\n";

  #convert the schema into the base table schema name
  my $schema_bt = $dbh->qualify_schema($schema,1);

  # find primary key
  my $sth = $dbh->prepare_cached(<<SQL);
SELECT indkey
FROM pg_catalog.pg_index
WHERE indisprimary=true
  AND indrelid=( SELECT c.oid
                 FROM pg_catalog.pg_class as c
                 JOIN pg_catalog.pg_namespace as n ON (c.relnamespace=n.oid)
                 WHERE n.nspname = ?
                   AND c.relname = ?
               )
SQL
  $sth->execute($schema_bt,$table);
  my %prinum = map { $_ => 1 } split ' ', ($sth->fetchrow_array || (''));
  $sth->finish;

  # find all columns
  $sth = $dbh->prepare_cached(<<SQL);
SELECT a.attname,
       a.attnum
FROM pg_catalog.pg_class as c,
     pg_catalog.pg_attribute as a,
     pg_catalog.pg_namespace as n
WHERE n.nspname = ?
  AND a.attnum > 0
  AND a.attrelid = c.oid
  AND n.oid = c.relnamespace
  AND c.relname = ?
ORDER BY a.attnum
SQL
  $sth->execute($schema, $table);
  my $columns = $sth->fetchall_arrayref;
  $sth->finish;

  # find SERIAL type.
  # nextval('"table_id_seq"'::text)
  $sth = $dbh->prepare_cached(<<SQL);
SELECT adsrc
FROM pg_catalog.pg_attrdef
WHERE adrelid=( SELECT c.oid
                 FROM pg_catalog.pg_class as c
                 JOIN pg_catalog.pg_namespace as n ON (c.relnamespace=n.oid)
                 WHERE n.nspname = ?
                   AND c.relname = ?
              )
SQL
  $sth->execute($schema_bt, $table);
  my ($nextval_str) = $sth->fetchrow_array;
  $sth->finish;
  my ($sequence) =
    $nextval_str ? $nextval_str =~ m/^nextval\('"?([^"']+)"?'::text\)/ : '';
#  ($sequence) = (split /\./,$sequence)[-1]; #un-qualify the sequence name

  my ( @cols, @primary );
  foreach my $col (@$columns) {

    # skip dropped column.
    next if $col->[0] =~ /^\.+pg\.dropped\.\d+\.+$/;
    push @cols, $col->[0];
    next unless $prinum{ $col->[1] };
    push @primary, $col->[0];
  }
  warn("$schema.$table has no primary key") unless @primary;
  warn("$schema.$table has a composite primary key") if @primary > 1;

  return ( primary  => \@primary,
	   columns  => \@cols,
	   sequence => $sequence,
	 );
}

=head2 is_valid_column

    #Example
    unless(CXGN::DB::Tools::is_valid_column($dbh,$table_name,$column_name))
    {
        CXGN::Apache::Error::notify('found invalid parameter',"Someone sent in '$column_name' as a parameter. Wacky.");
        $sortby='';
    }

=cut

sub is_valid_column
{    
    my($dbh,$table_name,$column_name)=@_;
    my $test=$dbh->prepare
    ("
        select 
            count(*)
        from 
            pg_class 
            inner join pg_attribute on (pg_attribute.attrelid=pg_class.oid) 
        where 
            relname=? 
            and attname=? 
            and relkind='r'
    ");
    $test->execute($table_name,$column_name);
    my($found)=$test->fetchrow_array();
    return $found;    
}

=head1 AUTHOR

Robert Buels and John Binns <zombieite@gmail.com>

=cut

###
1;#do not remove
###
