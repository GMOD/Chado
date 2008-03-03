
=head1 NAME

CXGN::Tools::Text

=head1 DESCRIPTION

Various tools for interpreting and displaying text strings.

=head1 FUNCTIONS

=head2 list_to_string

Takes a list, puts it into a string with commas and the word "and" before the last item.

=head2 is_all_letters

Takes a string, returns 1 if the string is all letters, 0 if not.

=head2 is_number

Takes a string, tests to see if it meets this pattern: optional + or -, 0 or more digits, followed by either: "." and one or more digits, or, just one or more digits. This should catch most normal ways that a user would enter a number. This function might be improved by returning the number that was contained in the string instead of just "1" (in case perl can't cast it on its own... i've never checked to see if perl can parse an initial "+" for instance)

=head2 trim

Takes a string and returns the string without leading or trailing whitespaces.

=head2 remove_all_whitespaces

Takes a string and returns it without any whitespaces in it at all anymore. If you sent in a spaced sentence, your spaces would be removed.

=head2 strip_unprintables

This function is still under development. It is meant to clean input of escape characters in preparation for display, database insertion, etc. However, different machines apparently are working with different character sets, so the higher characters cannot be cleaned reliably (when i tried to clean higher characters, this function produced different output on my machine than it did on the devel machine). For now, it just cleans out the lower characters.


=head2 abbr_latin

  Desc: abbreviate some latin words in your string and return
        the new abbreviated version
  Args: string
  Ret : string with abbreviations
  Side Effects: none
  Example:

   my $tomato = 'Lycopersicon esculentum';
   my $abbr = abbr_latin($tomato);
   print $abbr,"\n";
   #will print 'L. esculentum'

  Currently abbreviates Solanum, Lycopersicon, Capsicum, Nicotiana,
  and Coffea.

=cut

package CXGN::Tools::Text;
use strict;
use Carp;
BEGIN {
  our @EXPORT_OK = qw/
		      list_to_string
		      is_all_letters
		      is_number
		      is_garbage
		      trim
		      remove_all_whitespaces
		      strip_unprintables
		      abbr_latin
		      to_tsquery_string
		      from_tsquery_string
                      parse_pg_arraystr
		     /;
}
our @EXPORT_OK;
use base qw/Exporter/;


#returns the contents of the array in a string of the form "$_[0], $_[1],...., and $_[end]"
sub list_to_string {
    (@_ == 0) ? ''                                      :
    (@_ == 1) ? $_[0]                                   :
    (@_ == 2) ? join(" and ", @_)                       :
                join(", ", @_[0 .. ($#_-1)], "and $_[-1]");
}
#test a string to see if it is one continuous string of letters
sub is_all_letters
{
    my($string)=@_;
    if(defined($string)&&$string=~/^[A-Za-z]+$/i)#if there are one or more letters with no spaces in the string
    {
        return 1;
    }
    else{return 0;}
}
#test a string to see if it is a number
sub is_number
{
    my($string)=@_;
    if(defined($string)&&$string=~/^([+\-]?)\d*(\.\d+|\d+)$/)#optional + or -, 0 or more digits, followed by (. and one or more digits) or (just one or more digits) 
    {
        return 1;
    }
    else{return 0;}
}
#trim whitespace from string
sub trim
{
    my($string)=@_;
    $string =~ s/^\s+|\s+$//g if defined $string;
    return $string;
}

#remove_all all whitespace in string
sub remove_all_whitespaces
{
    my($string)=@_;
    if(defined($string))
    {
        $string=~s/\s+//g;
    }
    return $string;
}
sub abbr_latin
{
    my($string)=@_;
    if(defined($string))
    {
        $string=~s/Solanum/S\./g;
        $string=~s/Lycopersicon/L\./g;
        $string=~s/Capsicum/C\./g;
        $string=~s/Nicotiana/N\./g;
        $string=~s/Coffea/C\./g;
    }
    return $string;
}

=head2 to_tsquery_string

  Desc: format a plain-text string for feeding to Postgres to_tsquery
        function
  Args: list of strings to convert
  Ret : in scalar context: the first converted string,
        in list context:   list of converted strings
  Side Effects: none
  Example:

    my $teststring = 'gi|b4ogus123|blah is bogus & I hate it!';
    to_tsquery_string($teststring);
    #returns 'gi\\|b4ogus123\\|blah|is|bogus|\\&|I|hate|it\\!'

=cut

sub to_tsquery_string {
  ($_) = @_;

  $_ = trim($_);
  # Escape pipes
  s/\|/\\\|/g;
  # Escape ampersands and exclamation points
  s/([&!])/\\\\$1/g;
  # Escape parentheses and colons.
  s/([():])/\\$1/g;
  # And together all strings
  s/\s+/&/g;
  return $_;
}

=head2 from_tsquery_string

  Desc: attempt to recover the original string from the product
        of to_tsquery_string()
  Args: list of strings
  Ret : list of de-munged strings
  Side Effects: none
  Example:

=cut

sub from_tsquery_string {
  my @args = @_;

  foreach (@args) {
    next unless defined $_;
    s/(?<!\\)&/ /g; #& not preceded by backslashes is a space
    s/\\\\([^\\])/$1/g; #anything double-backslashed
    s/\\(.)/$1/g; #anything single-backslashed
  }
  return wantarray ? @args : $args[0];
}

=head2 parse_pg_arraystr

  Usage: my $arrayref = parse_pg_arraystr('{1234,543}');
  Desc : parse the string representation of a postgres array, returning
         an arrayref
  Args : string representation of postgres array
  Ret  : an arrayref
  Side Effects: none

=cut

sub parse_pg_arraystr {
  my ($str) = @_;

  return [] unless $str;

  my $origstr = $str;
  #remove leading and trailing braces
  $str =~ s/^{//
    or croak "malformed array string '$origstr'";
  $str =~ s/}$//
    or croak "malformed array string '$origstr'";

  return [
	  do {
	    if($str =~ /^"/) {
	      $str =~ s/^"|"$//g;
	      split /","/,$str;
	    } else {
	      split /,/,$str;
	    }
	  }
	 ];
}


=head1 AUTHOR

john binns - zombieite@gmail.com
Robert Buels - rmb32@cornell.edu

=cut

###
1;#do not remove
###
