package CXGN::Tools::File;
use strict;
use POSIX;
use Carp;

use UNIVERSAL qw/isa/;

use CXGN::Tools::Text;
use HTML::TreeBuilder;

=head1 NAME

CXGN::Tools::File - assorted lowish-level utilities for
working with, um, files and stuff.

=head1 FUNCTIONS

All functions below are EXPORT_OK.

=cut

BEGIN {
  our @EXPORT_OK = qw/
		      file_contents
		      read_commented_file
		      get_sections
		      create_zips_only
		      create_displays_only
		      create_thumbnails_displays_zips_for_psd_to_png
		      create_thumbnails_displays_zips
		      traverse_dir
		      count_file_lines
		      executable_is_in_path
		      size_changing
		      is_filehandle
		     /;
}
our @EXPORT_OK;
use base qw/Exporter/;

=head2 file_contents

  Desc: get the entire contents of a file as a string
  Args: filename
  Ret : string containing the entire contents of the file
  Side Effects: reads the file from the filesystem, dies if
                not openable

  Be careful with this function.  If the file is big, this will take a
  LOT of memory.

=cut

sub file_contents {
    my ($filename) = @_;
    local $/ = undef;
    open(my $FILE,"$filename") or croak ("Could not open file $filename: $!");
    return my $file_contents = <$FILE>;
}

=head2 read_commented_file

  Usage: my $contents = read_commented_file('myfile.txt');
  Desc : like file_contents, except removes any
         lines with # as the first characterf
  Args : filename
  Ret  : string containing file contents
  Side Effects: dies if file not found or not readable

=cut

sub read_commented_file {
    my ($filename) = @_;
    open(my $FILE,"$filename") or croak ("Could not open file $filename: $!");
    my $file_contents = "";
    while (<$FILE>) {
      next if /^\#/;
      $file_contents .= $_;
    }
    return $file_contents;
}

#function to get sections of text from a file. sections are separated by single empty lines. used by index.pl.
sub get_sections
{
    my($filename,$number_of_sections_to_get)=@_;
    #unless(CXGN::Tools::Text::is_number($number_of_sections_to_get) and $number_of_sections_to_get>0){return;}
    my $content='';
    my $FILE;
    open($FILE,"$filename") or croak "Could not open file $filename: $!";
    
    # the first line contains the number of sections to show
    # and is of the format: COUNT <integer>
    $number_of_sections_to_get = <$FILE>;
    $number_of_sections_to_get =~ s/.*COUNT\s+(\d+).*/$1/i;
    #print STDERR "NUMBER OF SECTIONS: $number_of_sections_to_get\n";
    while($number_of_sections_to_get>0)
    {
        if(my $line=<$FILE>)
        {
	    # ignore comment lines
	    if ($line =~ /^\#/) { next; }
            if($line=~/^\s+$/)#if line is all whitespace, then it's a section divider, so we've completed another section
            {
                $number_of_sections_to_get--;
            }
            else#otherwise, we want this line
            {
                $content.=$line;
    	    }
        }
        else
        {
            $number_of_sections_to_get=0;
        }
    }
    close $FILE;
    return $content;
}

sub get_div_sections {
	my ($file, $num_sections, $skip_num) = @_;
	$skip_num = 0 unless ($skip_num > 0);
	$num_sections = 1 unless ($num_sections > 1);
	my $root = HTML::TreeBuilder->new_from_file($file);
	my ($body) = grep { $_->tag eq "body"} $root->content_list;
	my (@div_children) = grep{$_->tag eq "div"} $body->content_list;
	my ($lb, $rb) = ($skip_num, $num_sections + $skip_num - 1);
	my @sections = @div_children[$lb..$rb];
	my $content = "";
	$content .= $_->as_HTML() foreach(@sections);
	return ($content, scalar @sections, scalar @div_children);
}


=head2 create_zips_only

  Desc:
  Args:
  Ret :
  Side Effects:
  Example:

=cut

sub create_zips_only($$$) {
  my ($image_name, $source_dir, $dest_dir) = @_;

  #parse file path to find path and name
  my $tmp = $image_name;
  $tmp =~ /($source_dir)(.*)(\/)(.*)(\.)(png|jpg|tiff|tif|gif|psd)$/i;
  my $path = $2;
  my $just_name = $4;
  my $no_ext = "$1"."$2"."$3"."$4";
  my $no_path = "$4"."$5"."$6";
  my $ext = $6;

  #create mirror directory structure for thumbnails and original image zipped
  if ($path) {
    system ("mkdirhier "."$dest_dir"."/zips"."$path");
  }
  else {
    system ("mkdirhier "."$dest_dir"."/zips");
    $path = "";
  }

  #zip and move original image
  #zip new_name original
  #print "zip "."$just_name"." $image_name -D\n";
  #print "mv $just_name"."\."."zip"." $dest_dir"."/zips"."$path\n\n";
  #system ("gzip "." $image_name"."$just_name\.zip");
  #system ("mv $just_name"."\."."zip"." $dest_dir"."/zips"."$path");

  #copy and gzip original image
  system ("cp $image_name" . " $dest_dir" . "/zips"."$path");
  system ("gzip " . "$dest_dir" . "/zips"."$path"."/$just_name"."\.$ext");
  #system ("mv $dest_dir" . "/zips"."$path"."/$just_name"."\.$ext"."\.gz"." $dest_dir" . "/zips"."$path"."/$just_name"."\.$ext"."\.zip");

}

=head2 create_displays_only

  Desc:
  Args:
  Ret :
  Side Effects:
  Example:

=cut

sub create_displays_only($$$) {
  my ($image_name, $source_dir, $dest_dir) = @_;

  #parse file path to find path and name
  my $tmp = $image_name;
  $tmp =~ /($source_dir)(.*)(\/.*)(\.)(png|jpg|tiff|tif|gif|psd)$/i;
  my $path = $2;
  my $just_name = $3;
  my $ext = $5;
  #print "path - $path\n";
  #print "filename - $just_name\n";

  #create mirror directory structure for thumbnails and original image zipped
  if ($path) {
    system ("mkdirhier "."$dest_dir"."/displays"."$path");
  }
  else {
    system ("mkdirhier "."$dest_dir"."/displays");
    $path = "";
  }

  #create display image in png format
  system ("convert -geometry 440 -format png $image_name "."$dest_dir" . "/displays"."$path"."$just_name"."_display.png");
#  system ("cp $image_name" . " $dest_dir" . "/displays"."$path"."$just_name"."_display"."\.$ext");
#  if (($ext eq "tiff") || ($ext eq "tif")) {
#    system (convert $);
#    $ext = "png";
#  }
#  system ("mogrify -geometry 440 -format png $dest_dir"."/displays"."$path"."$just_name"."_display"."\.$ext");

}

=head2 create_thumbnails_displays_zips_for_psd_to_png

  Desc:
  Args:
  Ret :
  Side Effects:
  Example:

  Legacy Documentation:

  ----------------------------------------------------------------
  INPUT:
    directory path of the image to be processed
    destination of thumbnail, display and zipped source files
  OUTPUT:
    thumbnails (standard-size and display sizes) and original
        in png format with a mirroring original directory structure
        testing: /auto/home/jenny/Phenotypic/Generated_Images
   thumbnails will have the original name plus "_thumbnail"
   display images will have the original name plus "_display"
   zipped images will have the original name plus ".gz" in the extension

=cut

sub create_thumbnails_displays_zips_for_psd_to_png ($$$) {
    print "entering create_thumbnails_displays_zips_for_psd_to_png... \n";

    my ($image_name, $source_dir, $dest_dir) = @_;
    #print "$image_name, \n$source_dir, \n$dest_dir \n\n";

    #parse file path to find path and name
    my $tmp = $image_name;
    $tmp =~ /($source_dir)(.*)(\/.*)(\.)(png|jpg|tiff|tif|gif|psd)$/i;
    my $path = $2;
    my $just_name = $3;

    my $ext = $5;
    if ($ext eq "png") {
      print "\n$image_name\n";

      #print "path - $path\n";
      #print "filename - $just_name\n";

      #create thumbnail
#      system ("convert -geometry 63x63! $image_name "."$dest_dir" . "/thumbnails" . "$path" . "$just_name"."_thumbnail.jpg");
      #system ("convert -size 63x63 $image_name -resize 216x274 +profile \"*\" " . "$dest_dir" . "/thumbnails" . "$path" . "/$just_name"."_thumbnail.jpg");

      #copy and gzip original image
#      system ("cp $image_name" . " $dest_dir" . "/zips"."$path");
#      system ("gzip " . "$dest_dir" . "/zips"."$path"."$just_name"."\.$ext");

      #create display image in png format
      system ("convert -geometry 440 $image_name "."$dest_dir" . "/displays"."$path"."$just_name"."_display.png");
      #system ("mogrify -format png -resize 720x720! $image_name");
      #system ("mv $source_dir"."$path"."$just_name"."\.png " . "$dest_dir" . "/displays"."$path"."/$just_name"."_display.png");

      print "leaving create_thumbnails... \n\n";
    }
  }
						
=head2 create_thumbnails_displays_zips

  Usage:
  Desc :
  Ret  :
  Args :
  Side Effects:
  Example:

  Legacy documentation:

  ----------------------------------------------------------------
  INPUT:
    directory path of the image to be processed
    destination of thumbnail, display and zipped source files
  OUTPUT:
    thumbnails (standard-size and display sizes) and original
        in png format with a mirroring original directory structure
        testing: /auto/home/jenny/Phenotypic/Generated_Images
   thumbnails will have the original name plus "_thumbnail"
   display images will have the original name plus "_display"
   zipped images will have the original name plus ".gz" in the extension

=cut

sub create_thumbnails_displays_zips ($$$) {
    #print "entering create_thumbnails... \n";

    my ($image_name, $source_dir, $dest_dir) = @_;
    #print "$image_name, \n$source_dir, \n$dest_dir \n\n";

    #parse file path to find path and name
    my $tmp = $image_name;
    $tmp =~ /($source_dir)(.*)(\/.*)(\.)(png|jpg|tiff|tif|gif|psd)$/i;
    my $path = $2;
    my $just_name = $3;
    my $ext = $5;
    #print "path - $path\n";
    #print "filename - $just_name\n";

    #create mirror directory structure for thumbnails and original image zipped
    if ($path) {
	system ("mkdirhier "."$dest_dir"."/thumbnails"."$path");
	system ("mkdirhier "."$dest_dir"."/displays"."$path");
	system ("mkdirhier "."$dest_dir"."/zips"."$path");
    }
    else {
	system ("mkdirhier "."$dest_dir"."/thumbnails");
	system ("mkdirhier "."$dest_dir"."/displays");
	system ("mkdirhier "."$dest_dir"."/zips");
	$path = "";
    }

    #create thumbnail
    system ("convert -geometry 63x63! $image_name "."$dest_dir" . "/thumbnails" . "$path" . "$just_name"."_thumbnail.jpg");
    #system ("convert -size 63x63 $image_name -resize 216x274 +profile \"*\" " . "$dest_dir" . "/thumbnails" . "$path" . "/$just_name"."_thumbnail.jpg");

    #copy and gzip original image
    system ("cp $image_name" . " $dest_dir" . "/zips"."$path");
    system ("gzip " . "$dest_dir" . "/zips"."$path"."$just_name"."\.$ext");

    #create display image in png format
    system ("convert -geometry 440 $image_name "."$dest_dir" . "/displays"."$path"."$just_name"."_display.png");
    #system ("mogrify -format png -resize 720x720! $image_name");
    #system ("mv $source_dir"."$path"."$just_name"."\.png " . "$dest_dir" . "/displays"."$path"."/$just_name"."_display.png");

    #print "leaving create_thumbnails... \n\n";
}



=head2 traverse_dir

  THIS FUNCTION IS DEPRECATED.  USE L<File::Find> for this.  Do
  'perldoc File::Find'

  Usage:
  Desc :
  Ret  :
  Args :
  Side Effects:
  Example:

  ----------------------------------------------------------------
  Dan's function to recursively traverse a directory,
   appends all file names (with full paths) to a list

=cut

sub traverse_dir ($) {
    #my ($dirarg)= "/home/jenny/bin/";
    #print "entering traverse_dir...\n<br />";

    my ($dirarg)= @_;
    opendir (THISDIR, $dirarg) or croak "Couldn't open directory $dirarg\n";

    #skip any files starting with .
    my @dir_list= grep !/^\./, readdir THISDIR;
    #print "\ndirectory list: @dir_list\n<br />";

    my ($filename, @filelist);

    foreach $filename (@dir_list){
	#print "filename: $filename\n<br />";
	$filename=$dirarg.$filename;
	if(-d $filename){
	    $filename.='/';
	    push @filelist,  &traverse_dir($filename);
	}
	else{
	    #print "adding $filename\n<br />";
	    push @filelist, $filename;
	}
    }

    #print "leaving traverse_dir...\n<br />";
    return @filelist;
}


=head2 count_file_lines

  Desc: count the number of lines in a file, in pure perl
  Args: the file name
  Ret : the number of lines in the file
  Side Effects:  dies if the file can't be opened
  Example:

    my $lines = count_file_lines('my_lame_file.txt');
    print "There are $lines lines in that file, yo.\n";

=cut

sub count_file_lines {
  my $filename = shift;

  my $pagesize = POSIX::sysconf(&POSIX::_SC_PAGESIZE);
  my $lines = 0;
  open(my $bleh, $filename) or croak "Can't open `$filename': $!";
  while (sysread $bleh, my $buffer, $pagesize) {
    $lines += ($buffer =~ tr/\n//);
  }
  close $bleh;
  return $lines;
}

# =head2 looks_like_fasta

#   Usage: if( looks_like_fasta($myfilename) ) { print 'it is in fasta format' }
#   Desc :
#   Ret  :
#   Args :
#   Side Effects:
#   Example:

# =cut

# sub looks_like_fasta {

# }

=head2 executable_is_in_path

  Usage: print 'we have cross_match' if executable_is_in_path('cross_match');
  Desc : figure out if an executable with the given name is in our execution path
  Ret  : 1 if there is an executable by that name, 0 otherwise
  Args : name of an executable
  Side Effects: runs 'which'
  Example:

=cut

sub executable_is_in_path($) {
  my $executable = shift;
  `which $executable` or return 0;
  return 1;
}


=head2 size_changing

  Usage: print "changing!" if size_changing('myfile.txt');
  Desc : given a filename, look at the file over a X-second window
         of time and see if its size is changing
  Ret  : 1 if it is changing, undef if not
  Args : filename,
        (optional) time in seconds to sleep between looks
        default 5 seconds.
  Side Effects: stats a file, sleeps, stats it again

=cut

sub size_changing {
  my $filename = shift;
  my $sleeptime = shift || 5;
  -f $filename or croak "$filename is not a file!\n";

  my $begin_time = time;
  my @begin_stat = stat $filename
    or croak "Could not stat $filename: $!\n";

  sleep $sleeptime;

  return $begin_stat[7] != (stat $filename)[7];
}

=head2 is_filehandle

  Usage: print "it's a filehandle" if is_filehandle($my_thing);
  Desc : check whether the given thing is usable as a filehandle.
         I put this in a module cause a filehandle might be either
         a GLOB or isa IO::Handle or isa Apache::Upload
  Ret  : true if it is a filehandle, false otherwise
  Args : a single thing
  Side Effects: none

=cut

sub is_filehandle {
  my ($thing) = @_;
  return isa($thing,'IO::Handle') || isa($thing,'Apache::Upload') || ref($thing) eq 'GLOB';
}


###
1;#do not remove
###
