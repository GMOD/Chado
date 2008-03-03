package CXGN::Tools::Wget;

use strict;
use warnings;
use Carp qw/ cluck confess croak/;
use English;

use File::Temp qw/tempfile/;
use File::Copy;
use Digest::MD5 qw/ md5_hex /;
use URI;

use CXGN::Tools::List qw/ all str_in /;
use CXGN::Tools::File qw/ is_filehandle /;

=head1 NAME

CXGN::Tools::Wget - contains functions for getting files via http
or ftp in ways that aren't directly supported by L<LWP>.

=head1 SYNOPSIS

  use CXGN::Tools::Wget qw/wget_filter/;

  #get a gzipped file from a remote site, gunzipping it as it comes in
  #and putting in somewhere else
  wget_filter( http://example.com/myfile.gz => '/tmp/somelocalfile.txt',
               { gunzip => 1 },
             );

  #get the same file, but transform each line as it comes in with the given
  #subroutine, because they really mean bonobos, not monkeys
  wget_filter( http://example.com/myfile.gz => '/tmp/somelocalfile.txt',
               sub {
                 my $line = shift;
                 $line =~ s/\s+monkey/ bonobo/;
                 return $line;
               },
               { gunzip => 1 },
             );

  # get a cxgn-resource file defined in public.resource_file
  wget_filter( cxgn-resource://all_repeats => 'myrepeats.seq');
  OR
  my $temp_repeats_file = wget_filter( 'cxgn-resource://all_repeats' );

=head1 ABOUT CXGN-RESOURCE URLS

Sometimes we have a need for making datasets out of several other
datasets.  For example, say you wanted a combined set of sequences
composed of NCBI's NR dataset, SGN's ESTs, and some random thing from
MIPS.  You could define a resource file like:

  insert into public.resource_file (name,expression)
  values ('robs_composite_set','cat( gunzip(ftp://ftp.ncbi.nlm.nih.gov/nr.gz), ftp://ftp.sgn.cornell.edu/ests/Tomato_current.seq.gz, http://mips.gsf.de/some_random_set.fasta )');

Then, when you go

  my $file = wget_filter('cxgn-resource://robs_composite_set');

You will get the concatenation of the unzipped NR set, the SGN est
set, and the MIPs set.  What actually happens behind the scenes is,
wget downloads each of the files, gunzips the nr file, then
concatenates the three into another file and caches it, then copies
the cached copy into another tempfile, whose name it returns to you.

But you didn't have to know that.  All you have to know is, define a
resource in the resource_file table, and wget_filter will build it for
you when you ask for it by wgetting a URL with the cxgn-resource
protocol.

=head1 FUNCTIONS

All functions are @EXPORT_OK.

=cut

BEGIN { our @EXPORT_OK = qw/   wget_filter / }
our @EXPORT_OK;
use base 'Exporter';



=head2 wget_filter

  Usage: wget_filter( http://example.com/myfile.txt => 'somelocalfile.txt');
  Desc : get a remote file, optionally gunzipping it,
         and/or running some subroutines on each line as it
         comes in.
  Ret  : filename where the output was written, which
         is either the destination file you provided,
         or a tempfile if you did not provide a destination
         file
  Args : (url of file,
          optional destination filename or filehandle,
          optional list of filters to run on each line,
          optional hashref of behavior options, as:
            { gunzip => 1,
              cache => 1, # enable/disable persistent caching.  default enabled
            },
         )
  Side Effects: dies on error
  Example:
     #get the same file, but transform each line as it comes in with the given
     #subroutine, because they really mean bonobos, not monkeys
     wget_filter( http://example.com/myfile.gz => '/tmp/somelocalfile.txt',
                  sub {
                    my $line = shift;
                    $line =~ s/\s+monkey/ bonobo/;
                    return $line;
                  },
                  { gunzip => 1 },
                );
     # get a composite resource file defined in the public.resource_file
     # table
     wget_filter( cxgn-resource://test => '/tmp/mytestfile.html' );

=cut

sub wget_filter {
  my ($url,@args) = @_;

  my $destfile = do {
    if( !$args[0] || ref $args[0]) {
      my (undef,$f) = tempfile( CoLEANUP => 0);
      #      cluck "made tempfile $f\n";
      $f
    } else {
      shift @args
    }
  };

  #get our options hash if present
  my %options = (ref($args[-1]) eq 'HASH') ? %{pop @args} : ();

  $options{cache} = 1 unless exists $options{cache};

  #and the rest of the arguments must be our filters
  my @filters = @args;
  !@filters || all map ref $_ eq 'CODE', @filters
    or confess "all filters must be subroutine refs or anonymous subs (".join(',',@filters).")";

  #warn "got filters ".join(',',@filters) if @filters;

  # only do caching if we don't have any filters (we can't represent
  # these in a persistent way in a hash key, because the CODE(...)
  # will be different at every program run
  my $cache_key = $url.' WITH OPTIONS '.join('=>',%options);
  unless(@filters || !$options{cache}) {
    my $cache_filename = cache_filename( $cache_key );
    if( -r $cache_filename ) {
      copy $cache_filename => $destfile;
#      warn "copying $cache_filename from cache\n";
      return $destfile;
    }
  }

  #properly form the gunzip command
  $options{gunzip} = $options{gunzip} ? ' gunzip -c |' : '';

  my $parsed_url = URI->new($url)
    or croak "could not parse uri '$url'";

  ### file urls
  if( $parsed_url->scheme eq 'file' ) {
    return $parsed_url->path; #< the rest of the URI is just a full path
  }
  ### http and ftp urls
  elsif( str_in( $parsed_url->scheme, qw/ http ftp / ) ) {

  #try to use ncftpget for fetching from ftp with no wildcards, since
  #wget suffers from some kind of bug with large ftp transfers.
  #use wget for everything else, since it's a little more flexible
    my $fetchcommand = $url =~ /^ftp:/ && $url !~ /[\*\?]/
      ? "ncftpget -cV"
	: "wget -q -O -";

    #check that all of the given filters are code refs
    @filters = grep {$_} @filters; #just ignore false things in the filters
    foreach (@filters) {
      ref eq 'CODE' or croak "Invalid filter argument '$_', must be a code ref";
    }

    #open the output filehandle if our argument isn't already a filehandle
    my $out_fh;
    my $open_out = ! is_filehandle($destfile);
    if ($open_out) {
      open $out_fh,">$destfile"
	or die "Could not write to destination file $destfile: $!";
    } else {
      $out_fh = $destfile;
    }

    #run wget to download the file
    open my $urlpipe,"cd /tmp; $fetchcommand '$url' |$options{gunzip}"
      or die "Could not use wget to fetch $url: $!";
    while (my $line = <$urlpipe>) {
      #if we were given filters, run them on it
      foreach my $filter (@filters) {
	$line = $filter->($line);
      }
      print $out_fh $line;
    }
    close $urlpipe;

    #close the output filehandle if it was us who opened it
    close $out_fh if $open_out;
    (stat($destfile))[7] > 0 || die "Could not download $url using command '$fetchcommand'\n";
    #  print "done.\n";
  }
  ### cxgn-resource urls
  elsif( $parsed_url->scheme eq 'cxgn-resource' ) {

    #look for a resource with that name
    my $resource_name = $parsed_url->authority;

    my ($resource_file,$multiple_resources) = CXGN::Tools::Wget::ResourceFile->search( name => $resource_name );
    $resource_file or croak "no cxgn-resource found with name '$resource_name'";
    $multiple_resources and croak "multiple cxgn-resource entries found with name '$resource_name'";

    $resource_file->fetch($destfile);
  }
  else {
    croak "unable to handle URIs with scheme '".$parsed_url->scheme."'";
  }


  #if we're doing caching, copy the destination file into the cache
  unless(@filters || !$options{cache}) {
    my $cache_filename = cache_filename( $cache_key );
    copy $destfile => $cache_filename
      or confess "$! writing downloaded file to CXGN::Tools::Wget persistent cache (copy $destfile -> $cache_filename)";
  }

  return $destfile;
}


#given a url, return the full path to where it should be stored on the
#filesystem
sub cache_filename {
  my ($keystring) = @_;
  my $name = md5_hex($keystring);
  #md5sum the key to make a filename that we don't have to worry about
  #escaping filenames
  return File::Spec->catfile(cache_root_dir(), $name);
}

sub cache_root_dir {
  my $username = getpwuid $EUID;
  my $dir_name = File::Spec->catdir( File::Spec->tmpdir, "cxgn-tools-wget-cache-$username" );
  system 'mkdir', -p => $dir_name;
  -w $dir_name or die "could not make and/or write to cache dir $dir_name\n";
  return $dir_name;
}

=head2 clear_cache

  Usage: CXGN::Tools::Wget::clear_cache
  Desc : delete all the locally cached files managed by this module
  Args :
  Ret  :
  Side Effects:
  Example:

=cut

sub clear_cache {
  my ($class) = @_;
  my @delete_us = glob cache_root_dir().'/*';
  unlink @delete_us == scalar @delete_us
    or croak "could not delete all files in the cache root directory (".cache_root_dir().") : $OS_ERROR";
}

=head2 vacuum_cache

  Usage: CXGN::Tools::Wget::vacuum_cache(1200)
  Desc : delete all cached files that are older than N seconds old
  Args : number of seconds old a file must be to be deleted
  Ret  : nothing meaningful
  Side Effects: dies on error

=cut

sub vacuum_cache {
  my ($max_age) = @_;
  my @delete_us = grep { (stat $_)[9] < time-$max_age }
                  glob cache_root_dir().'/*';

  unlink @delete_us == scalar @delete_us
    or croak "could not vacuum files in the cache root directory (".cache_root_dir().") : $OS_ERROR";
}


package CXGN::Tools::Wget::ResourceFile;
use Carp qw/ cluck confess croak / ;
use File::Temp qw/ tempfile /;
use CXGN::Tools::Run;
use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('resource_file');
__PACKAGE__->columns(All => qw/ resource_file_id name expression /);

# the SQL table definition is here just for reference
my $creation_statement = <<EOSQL;

create table resource_file (
   resource_file_id serial primary key,
   name varchar(40) not null unique,
   expression text not null
);

comment on table resource_file is
'each row defines a composite dataset, downloadable at the url cxgn-resource://name, that is composed of other downloadable datasets, according to the expression column.  See CXGN::Tools::Wget for the accompanying code'
;

EOSQL

=head2 fetch

  Usage: $resourcefile->fetch('resource_name');
  Desc : assemble this composite resource file from its components
  Args : filename in which to store the complete
         assembled file
  Ret  : full path to the complete assembled file

=cut

sub fetch {
  my ($self,$destfile) = @_;

  my $parse_tree = $self->_parsed_expression; #< dies on parse error

  #now go depth-first down the tree and evaluate it
  # note that if no dest file is provided, _evaluate()
  # will make a temp file
  return _evaluate( $parse_tree, $destfile);
}

#recursively evaluate one of these little parse trees,
#converting the URLs and function calls into filenames
sub _evaluate {
  my ($tree,$destfile) = @_;

  #if we haven't been given a destination file, make a temporary one
  $destfile ||= do {
    my (undef,$f) = tempfile( CLEANUP => 0);
    #cluck "made tempfile $f\n";
    $f
  };

  if( $tree->isa('call') ) {
    # evaluate each argument, then call the function on it
    # these evaluations are each going to make a temp file
    my ($func,@args) = @$tree;
    @args = map _evaluate($_), @args;

    #now apply the function to each of these files and make a composite file
    no strict 'refs';
    "op_$func"->($destfile,@args);

    #delete each of the argument temp files
    unlink @args;
  }
  else {
    #fetch the URL pointed to
    ref $tree and die "assertion failed, parse tree should only have one element here";
    CXGN::Tools::Wget::wget_filter($tree,$destfile, {cache => 0});
  }
  return $destfile;
}

our @symbols;
# parse the expression and return a tree representation of it
sub _parsed_expression {
  my ($self) = @_;
  my $exp = $self->expression;

#  $exp = 'foo';
  #ignore all whitespace
  $exp =~ s/\s//g;

  #split the expression into symbols
  @symbols = ($exp =~ /[^\(\),]+|./g);

  my $parse_tree =  _parse_expression();

  return $parse_tree;
}


#recursively parse the expression
# _parse_expression and _parse_func make a simple recursive-descent parser
sub _parse_expression {
  #beginning of a tuple
  if( $symbols[0] =~ /^\S{2,}$/ ) {
    if( $symbols[1] && $symbols[1] eq '(' ) {
      return _parse_func();
    } else {
      return shift @symbols;
    }
  }
  else {
    die "unexpected symbol '$symbols[0]'";
  }
}
sub _parse_func {
  my $funcname = shift @symbols;
  my $leftparen = shift @symbols;
  $leftparen eq '('
    or die "unexpected symbol '$leftparen'";

  my @args = _parse_expression;

  while( $symbols[0] ne ')' ) {
    if( $symbols[0] eq ',' ) {
      shift @symbols;
      push @args, _parse_expression;
    }
    else {
      die "unexpected symbol '$symbols[0]'";
    }
  }
  shift @symbols; #< shift off the )

  #check that this is a valid function name
  __PACKAGE__->can("op_$funcname") or die "unknown resource file op '$funcname'";

  return bless [ $funcname, @args ], 'call';
}

#### FILE OPERATION FUNCTIONS, ADD YOUR OWN BELOW HERE ########
#
# 1. each function takes a destination file name, then a list of
#    filenames as arguments.  It does its operation on the argument files,
#    and writes to the destination file
#
# 2. functions are NOT allowed to modify any files except their
#    destination file
#
# 3. functions should die on error

sub op_gunzip {
  my ($destfile,@files) = @_;

#  warn "gunzip ".join(',',@files)."> $destfile\n";
  my $gunzip = CXGN::Tools::Run->run('gunzip', -c => @files,
				     { out_file => $destfile }
				    );
}

sub op_cat {
  my ($destfile,@files) = @_;
#  warn "cat ".join(',',@files)." > $destfile\n";
  my $cat = CXGN::Tools::Run->run('cat', @files,
				  { out_file => $destfile }
				 );
}

=head1 AUTHOR

Robert Buels

=cut

###
1;#do not remove
###

