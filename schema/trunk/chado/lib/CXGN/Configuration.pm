
=head1 NAME

CXGN::Configuration

=head1 DESCRIPTION

Reads in a configuration file in a certain syntax and stores this configuration for access by scripts. Takes item names and lists of values for that item. Puts values as arrayrefs into a hash with the item names as a keys. 

    #syntax example

    #comment
    <name1> <value1>

    #comment
    <name2> <value2>  #another comment

    #this example will put multiple values into name3
    <name3> <value3.0> <value3.1> <value3.2>

=head1 OBJECT METHODS

=head2 new

Creates a new configuration object.

    #example
    use CXGN::Configuration;
    my $config=CXGN::Configuration->new($config_file_location);

=head2 get_conf

Gives you back the FIRST value for the variable you ask for, using the information that was retrieved from the configuration file. If there are many values for this variable, and you want them, you must use get_conf_arrayref().

    #example which gets the locally located location of your web checkout
    my $basepath=$config->get_conf('basepath');

=head2 get_conf_arrayref

Gives you back an arrayref of the values for the variable you ask for, even if there is one value or no values.

=head2 get_conf_hashref_single_values

Gives you back a hash with all your items, and the first values in their lists.

=head2 parse_line

For internal use. Gets a variable name from the configuration file and assigns a value or values to it.

=head1 AUTHOR

john binns - John Binns <zombieite@gmail.com>

=cut

package CXGN::Configuration;
use strict;
sub new
{
    my $class=shift;
    my $self=bless({},$class);
    $self->{conf_files}=\@_;
    my $FILE;
    my $files_found=0;
    for my $file_location(@{$self->{conf_files}})#these will be done in order, so later ones will override earlier ones
    {
        if(-f($file_location))
        {
            $files_found++;
            if(open($FILE,$file_location))
            {
#	      warn "parsing config $file_location\n";
                while(my $line=<$FILE>)
                {
                    chomp($line);
                    my($name,$values)=$self->parse_line($line);
                    if($name)
                    {
                        $self->{config}->{$name}=$values;#set this element, and override any previously existing configuration setting for this element
                    }
                }
            }
            else{warn"CXGN::Configuration: Cannot open file '$file_location: $!'.\n";return;}
        }
        #else{warn"CXGN::Configuration: File '$file_location' does not exist.\n";}
    }
    unless($files_found){warn"CXGN::Configuration: None of the requested configuration files were found.\n";return;}
    return $self;
}
sub parse_line
{
    my $self=shift;
    my($line)=@_;
    $line =~ s/#.+//; #remove any comments from consideration
    return unless $line =~ /\S/; #ignore empty lines
    my($name,@values)=split(/[\t ]+/,$line);
    unless(defined($values[0])){$values[0]='';}#let's make "no value" be stored as an empty string instead
    return($name,\@values);
}
sub get_conf#returns a single scalar value even if this item contains more than one value. use get_conf_arrayref to get all values for this item.
{
    my $self=shift;
    my($requested_conf)=@_;
    if($requested_conf and defined($self->{config}->{$requested_conf}))
    {
        return $self->{config}->{$requested_conf}->[0];
    }
    else
    {
        return;
    }
}
sub get_conf_arrayref#returns an arrayref, even if a single value is stored
{
    my $self=shift;
    my($requested_conf)=@_;
    return $self->{config}->{$requested_conf};         
}
sub get_conf_hashref_single_values#returns a hashref with single values for all items, even if multiple values are available
{
    my $self=shift;
    my %hash;
    for my $key(keys(%{$self->{config}}))
    {
        $hash{$key}=$self->{config}->{$key}->[0];
    }
    return \%hash;
}
1;
