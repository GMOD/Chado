
=head1 NAME

CXGN::DB::SQLWrappers

=head1 AUTHOR

John Binns <zombieite@gmail.com>

=head1 DESCRIPTION

Functions which do basic selects and inserts in a clean way, so your code is easier to read, and SQL is segregated here.

=head2 new

    my $sql=CXGN::DB::SQLWrappers->new($dbh);

=head2 verbose

Sets verbosity level. Default is 1 meaning loud, setting this to 0 means quiet.

    $sql->verbose(0);

=head2 select

A simple way to get primary keys of data which matches some equality conditions. Send in undef for rows you want to match with nulls.

    my @ids=$sql->select('enzymes',{enzyme_name=>'EcoRI'});
    #Returns a list of all entries in the enzymes table matching the hash
    
=head2 insert

A simple way to insert data into a table.

    my $id=$sql->insert('enzymes',{enzyme_name=>'NewEnzyme'});
    #Returns the ID of a new entry into the enzymes table

=head2 insert_unless_exists

Does a 'select' as described above. If no results are found, does an 'insert' as described above and returns you the ID in a hash. If one result is found, returns you the ID in a hash. If more than one result is found, it dies with a good explanation.

    my $info=$sql->insert_unless_exists('enzymes',{enzyme_name=>'NewEnzyme'});
    if($info->{inserted})
    {
        print"Inserted with ID $info->{id}.\n";
    }
    if($info->{exists})
    {
        print"Similar row exists with ID $info->{id}.\n";
    }

=head2 primary_key_column_name

Used by this module, but can be used by anyone else that is interested as well. It queries the Postgres catalog database for a single-column primary key associated with a table and dies if it can't find one.

    my $pk_colname=$sql->primary_key_column_name('enzymes');

=cut

use strict;
use CXGN::DB::Connection;
use CXGN::Tools::Text;
use Data::Dumper;

package CXGN::DB::SQLWrappers;

sub new
{    
    my $class=shift;
    my ($dbh)=@_;
    my $self=bless({},$class);
    $self->{dbh}=$dbh;
    $self->{verbose}=1;
    return $self;
}

sub verbose
{
    my $self=shift;
    ($self->{verbose})=@_;
}

sub select
{
    my $self=shift;
    $self->_check_input(@_);
    my ($table,$select_hash)=@_;
    my $primary_key_column_name=$self->primary_key_column_name($table);
    my $select_statement=
    "
        select 
            $primary_key_column_name 
        from 
            $table 
        where 
            not 
            (
                (".join(',',keys(%{$select_hash})).") is distinct from (".join(',',map {'?'} keys(%{$select_hash})).")
            )
    ";#the "not is distinct from" stuff means "is equal to"--BUT it also works for null values (rather than having to replace "=null" with "is null")
    my $q=$self->{dbh}->prepare($select_statement);
    $q->execute(values(%{$select_hash}));
    my @ids;
    while(my($id)=$q->fetchrow_array())
    {
        push(@ids,$id);
    }
    return @ids;
}

sub insert
{
    my $self=shift;
    $self->_check_input(@_);
    my ($table,$insert_hash)=@_;
    my $insert_statement=
    "
        insert into sgn.$table 
        (".
            join(',',keys(%{$insert_hash}))
        .") 
        values 
        (".
            join(',',map {'?'} keys(%{$insert_hash}))
        .")
    ";
    my $q=$self->{dbh}->prepare($insert_statement);
    $q->execute(values(%{$insert_hash}));
    my $id=$self->{dbh}->last_insert_id($table);
    if($self->{verbose})
    {
        print"Executed\n$insert_statement;\nwith values\n(".CXGN::Tools::Text::list_to_string(values(%{$insert_hash})).")\ncreating new row with ID $id.\n\n";
    }
    return $id;
}

sub insert_unless_exists
{    
    my $self=shift;
    my ($table,$hash)=@_;
    my $return_info;
    $return_info->{table}=$table;
    my @ids=$self->select($table,$hash);
    if(@ids)
    {
        if(@ids>1)
        {
            die"insert_unless_exists found more than one existing entry like this (".CXGN::Tools::Text::list_to_string(@ids)."). This could mean one of 4 things:\n\n1. This table should have a uniqueness constraint, but doesn't\n2. This table has a uniqueness constraint, but null values are causing duplicate rows to appear anyway\n   (nulls do NOT match each other in a comparison of rows for the purposes of a uniqueness constraint)\n3: The row you are trying to insert does not specify enough columns of data to differentiate it from similar rows\n4: You meant to use 'insert' instead of 'insert_unless_exists'\n\nHere is what you tried to insert:\n".Data::Dumper::Dumper $hash;
        }
        $return_info->{exists}=1;
        ($return_info->{id})=@ids;
    }
    else
    {
        $return_info->{inserted}=1;
        $return_info->{id}=$self->insert($table,$hash);
    }
    return $return_info;
}

sub primary_key_column_name
{
    my $self=shift;
    my ($table)=@_;
    unless($table=~/^\w+$/){die"Invalid table name '$table'"};
    #this query is a modified version of the one in CXGN::DB::Connection::last_insert_id()
    my $q=$self->{dbh}->prepare
    ("
        SELECT 
            pg_attribute.attname
        FROM
            pg_class,          
            pg_attribute,            
            pg_attrdef,               
            pg_constraint  
        WHERE 
            pg_class.relkind='r'          
            AND pg_attribute.attrelid=pg_class.oid              
            AND pg_attrdef.adnum=pg_attribute.attnum              
            AND pg_attrdef.adrelid=pg_class.oid              
            AND pg_constraint.conrelid=pg_class.oid              
            AND pg_constraint.contype='p'                 
            AND array_upper(pg_constraint.conkey,1)=1    
            AND pg_constraint.conkey[1]=pg_attribute.attnum          
            AND pg_class.relname=?
    ");
    $q->execute($table);
    my($primary_key_column_name)=$q->fetchrow_array();
    unless($primary_key_column_name)
    {
        die"Primary key column name not found";
    }
    unless($primary_key_column_name=~/^\w+$/)
    {
        die"Invalid primary key name found";
    }
    return $primary_key_column_name;
}

sub _check_input
{
    my $self=shift;
    my ($table,$hash)=@_; 
    unless($table=~/^\w+$/)
    {
        die"Invalid table name '$table'"
    };
    unless(ref($hash) eq 'HASH')
    {
        die"Invalid hash '$hash'";
    }
    for my $key(keys(%{$hash}))
    {
        unless($key=~/^\w+$/)
        {
	    die"Invalid database column name '$key'";
	}
    }
}

1;
