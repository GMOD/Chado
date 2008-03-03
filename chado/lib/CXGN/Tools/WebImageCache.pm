

=head1 NAME
           
           

=head1 SYNOPSYS

         
=head1 DESCRIPTION

 my $cache = CXGN::Tools::WebImageCache->new();
 $cache->set_key("abc");
 $cache->set_expiration_time(86400); # seconds, this would be a day.
$cache->set_map_name("map_name"); # what's in the <map name='map_name' tag.
 $cache->set_temp_dir("/documents/tempfiles/cview");
 $cache->set_basedir("/data/local/website/"); # would get this from VHost...
 if (! $cache->is_valid()) { 
    # generate the image and associated image map.
    # ...
    $img_data = ...
    $img_map_data = ...
    $cache->set_image_data($img_data);
    $cache->set_image_map_data($image_map_data);
 }
 print $cache->get_image_html();


=head1 AUTHOR(S)

 Lukas Mueller <lam87@cornell.edu>

=head1 VERSION
 
 0.1 (March 28, 2007)

=head1 FUNCTIONS

This class implements the following functions:

=cut

package CXGN::Tools::WebImageCache;

use Digest::MD5;

=head2 function new

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $args = shift;
    my $self = bless {}, $class;
    $self->set_expiration_time($args->{expiration_time}) 
	if exists($args->{expiration_time});

    $self->set_cache_name($args->{filename})
	if exists($args->{filename});
    
    $self->set_key($args->{key})
	if exists($args->{key});

    $self->set_temp_dir($args->{temp_dir}) 
	if exists($args->{temp_dir});

    $self->set_basedir($args->{basedir})
	if exists($args->{basedir});
    
    $self->set_force($args->{force})
	if exists($args->{force});

    $self->set_function($args->{function}) 
	if exists($args->{function});
    
    $self->set_image_type($args->{image_type}) 
	if exists($args->{image_type});

    

    return $self;   
}


=head2 accessors set_temp_dir, get_temp_dir

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_temp_dir { 
    my $self=shift;
    return $self->{temp_dir};

}

sub set_temp_dir { 
    my $self=shift;
    $self->{temp_dir}=shift;
}

=head2 accessors set_basedir, get_basedir

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_basedir { 
    my $self=shift;
    return $self->{basedir};
}

sub set_basedir { 
    my $self=shift;
    $self->{basedir}=shift;
}

=head2 function get_file_url

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_file_url {
    $self = shift;
    return File::Spec->catfile($self->get_temp_dir(), $self->get_cache_name());
}

=head2 function get_filepath

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_filepath {
    my $self = shift;
    return File::Spec->catfile($self->get_basedir(), $self->get_temp_dir(), $self->get_cache_name());
}


=head2 function get_image_path

  Description:	returns the fully qualified path to the image.

=cut

sub get_image_path {
    my $self = shift;
    return $self->get_filepath().".".$self->get_image_type();
}

=head2 function get_image_url

  Description:	returns the url of the cache image

=cut

sub get_image_url {
    my $self = shift;
    $self->get_file_url().".".$self->get_image_type();
}


=head2 function get_image_map_path

  Description:	returns the fully qualified path to the file

=cut

sub get_image_map_path {
    my $self = shift;
    return $self->get_filepath().".map";
}



=head2 accessors set_expiration_time, get_expiration_time

  Property:	the time in seconds after which the cache is considered
                obsolete
  Args/Rets:    the number of seconds that specify the expiration time
  Side Effects:	the cache will be considered invalid after this number
                of seconds have elapsed, and is_valid() will return 
                false, even if the cache file exists.
                If no expiration time is set, the cached file will never
                expire.
  Description:	

=cut

sub get_expiration_time { 
    my $self=shift;
    return $self->{expiration_time};
}

sub set_expiration_time { 
    my $self=shift;
	my $expiration_time = shift;
	unless($expiration_time =~ /^\d+$/){
		$expiration_time = 60 if $expiration_time =~ /minute/i;
		$expiration_time = 3600 if $expiration_time =~ /hour/i;
		$expiration_time = 3600*24 if $expiration_time =~ /day/i;
		$expiration_time = 3600*24*7 if $expiration_time =~ /week/i;
		$expiration_time = 3600*24*30 if $expiration_time =~ /month/i;
		$expiration_time = 3600*24*365 if $expiration_time =~ /year/i;
	}
    $self->{expiration_time} = $expiration_time;
}

=head2 accessors set_key, get_key

  Property:	the unique key that identifies the web image, 
                such as a concatenation of parameters that are
                used to generate the image in a webpage.
                This property needs to be set, otherwise the 
                program dies.
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_key { 
    my $self=shift;
    if (!exists($self->{key})) { die "use set_key to set a key. cannot proceed.\n"; }
    return $self->{key};
}

sub set_key { 
    my $self=shift;
    $self->{key}=shift;
}

=head2 accessors set_cache_name, get_cache_name

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_cache_name { 
    my $self=shift;
    return $self->{cache_name};
}

sub set_cache_name { 
    my $self=shift;
    $self->{cache_name}=shift;
}

=head2 accessors set_image_data, get_image_data

  Property:	image data, as a string
  Args/Ret:     the image data, as a string.
  Side Effects:	writes the string to the cache image file.
  Description:	

=cut

sub get_image_data { 
    my $self=shift;
    open (my $FILE, "<".($self->get_image_path())) || die "Can't open ".$self->get_image_path()." for reading";
    my @contents = <$FILE>;
    close($FILE);
    return join "\n", @contents;
}

sub set_image_data { 
    my $self=shift;
    my @contents = @_;
    print STDERR "Generating image cache file ".$self->get_image_path()."\n";
    open (my $FILE, ">".($self->get_image_path())) || die "Can't open ".$self->get_image_path()." for writing";
    print $FILE join "\n", @contents;
    close($FILE);
}

=head2 accessors set_image_map_data, get_image_map_data

  Property:	the image map data as a string
  Side Effects:	writes/retrieves the image map data to/from
                the cache file.
  Description:	

=cut

sub get_image_map_data { 
    my $self=shift;
    print STDERR "Generating image map cache file ".$self->get_image_map_path()."\n";
    open (my $FILE, "<".($self->get_image_map_path())) || die "Can't open ".$self->get_image_map_path();
    my @contents = <$FILE>;
    close($FILE);
    return join "\n", @contents;

}

sub set_image_map_data { 
    my $self=shift;
    my @contents = @_;
    open (my $FILE, ">".($self->get_image_map_path())) || die "Can't open ".$self->get_image_map_path();
    print $FILE join "\n", @contents;
    close($FILE);

}




=head2 function is_valid

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub is_valid {
    my $self = shift;

    # generate the filename from the key
    $self->_hash();

    if ($self->get_force() eq "1") { 
	print STDERR "Force reloading cache...\n";
	return 0;
    }

    # is there a cache file?
    if (-e $self->get_image_path()) { 
	
	# has the expiration time already expired?
	if ($self->get_expiration_time()) { 

	    my $mtime = (stat($self->get_image_path()))[9];
	    my $age = time()-$mtime;
	    if ($age > $self->get_expiration_time()) { 
		print STDERR "ARGH! Cache has expired!!!!!\n";
		return 0;
	    }
	}

	# the cache file is ok.
	print STDERR "Cache exists...\n";
	return 1;
    }
    else {
	# there is no cache.
	print STDERR "Cache DOES NOT exist!\n";
	return 0;
    }
}

=head2 function get_image_tag

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_image_tag {
    $self= shift;
    my $image_url = $self->get_image_url();
    my $usemap = $self->get_map_name();
    return qq{ <img src="$image_url" border="0" usemap="#$usemap" />\n };
}

=head2 accessors set_map_name, get_map_name

  Property:	the name of the image map, to link to the image with usemap.
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_map_name { 
my $self=shift;
return $self->{map_name};
}

sub set_map_name { 
my $self=shift;
$self->{map_name}=shift;
}



# =head2 function get_image_map_url

#   Property:	
#   Setter Args:	
#   Getter Args:	
#   Getter Ret:	
#   Side Effects:	
#   Description:	

# =cut

# sub get_image_map_url { 
#     my $self=shift;
#     return $self->get_file_url().".map";
# }

=head2 accessors set_force, get_force

  Property:	force - whether to force the generation of
                a new image
  Setter Args:  true to force generation of new file
                false to use cache if present
  Getter Args:	none
  Side Effects:	true value will cause old file to be deleted
  Description:	

=cut

sub get_force { 
    my $self=shift;
    return $self->{force};
}

sub set_force { 
    my $self=shift;
    $self->{force}=shift;
}

=head2 function get_image_html

  Synopsis:	$image->get_image_html()
  Arguments:	none
  Returns:	a string representing the image in html,
                including the image tag and the image map.
  Side effects:	
  Description:	

=cut

sub get_image_html {
    my $self = shift;
	my $map_data = undef;
	eval{$map_data = $self->get_image_map_data()};
	$map_data = "" if $@;
    return $self->get_image_tag() ."<br />". $map_data;
}

=head2 accessors set_function, get_function

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_function { 
    my $self=shift;
    return $self->{function};
}

sub set_function { 
    my $self=shift;
    $self->{function}=shift;
}

=head2 accessors set_image_type, get_image_type

  Property:	the type of image to be handled.
  Args/Ret:     the image type, such as png, jpg, etc.
  Side Effects:	used to construct the cache image name
  Description:	default returned is "png"

=cut

sub get_image_type { 
    my $self=shift;
    if (!exists($self->{image_type}) || !defined($self->{image_type})) { 
	$self->{image_type}="png";
    }
    return $self->{image_type};
}

sub set_image_type { 
    my $self=shift;
    $self->{image_type}=shift;
}

=head2 function _hash

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub _hash {
    my $self = shift;
    my $filename = Digest::MD5->new()->add($self->get_key())->hexdigest();
    print STDERR "Generated filename $filename\n";
    $self->set_cache_name($filename);
}




return 1;
