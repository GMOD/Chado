#!/usr/bin/perl -w
use strict;
use XML::DOM;

=head1 NAME

  PrettyPrintDom.pm -  writes an XML::DOM::Document object to pretty XML 

=head1 SYNOPSIS

 function pretty_print will take an XML::DOM::Document object and a 
 valid file handle reference (either glob or FileHandle object) and 
 print the DOM as nicely indented and multiline XML output

 NOTE: will now handle comments as well

 usage: pretty_print(XML::DOM::Document, filehandle)

=head1 AUTHOR

Dave? Pinglei? - harvdev@morgan.harvard.edu

=head1 SEE ALSO

XML::DOM

=cut

#functions for writing XML::DOM::Document object to pretty XML 
#
# usage: prety_print($doc,$fh)
#        $doc is XML::DOM::Document object
#        $fh  is open File::Handle object
# or: traverse($doc, $filehandle)
#     has to declare $docindex=-1; $lindex=0; first.
#
our %DecodeDefaultEntity =
(
 '"' => "&quot;",
 ">" => "&gt;",
 "<" => "&lt;",
 "'" => "&apos;",
 "&" => "&amp;"
);

our $docindex;
our $lindex;

sub pretty_print
{
  my $node = shift;
  my $fh = shift;
  $docindex=-1;
  $lindex=0;
  &traverse($node,$fh);
}
sub traverse {
  my($node,$filehandle)= @_;
  if ($node->getNodeType == ELEMENT_NODE) {
    $docindex++;
    if($lindex==0)
      { print $filehandle "\n";}
    my $attrs=$node->getAttributes();
    my @lists= $attrs->getValues;
    print  $filehandle ' 'x$docindex,"<",$node->getNodeName;
    foreach my $attr (@lists)
      {
	print $filehandle ' ', $attr->getName,'=\'', $attr->getValue,'\'';
      }
    print $filehandle ">";

    foreach my $child ($node->getChildNodes()) {
      traverse($child,$filehandle);
    }
    if($lindex==0)
      {
	print $filehandle "\n",' 'x$docindex;
      }
    print $filehandle "</", $node->getNodeName, ">";
    $lindex=0;
    $docindex--;
  } elsif ($node->getNodeType() == TEXT_NODE) {
    print $filehandle &encodeText($node->getData, '<&>"');
    $lindex=1;
  } elsif ($node->getNodeType() == COMMENT_NODE) {
    print $filehandle "\n<!-- ",$node->getData," -->";

  } else {
    foreach my $child ($node->getChildNodes()){
#      print $node->getNodeType(),"\n";
      traverse($child,$filehandle);
  }
  }
}
sub encodeText
{
    my ($str, $default) = @_;
    return undef unless defined $str;

    if ($] >= 5.006) {
      $str =~ s/([$default])|(]]>)/
        defined ($1) ? $DecodeDefaultEntity{$1} : "]]&gt;" /egs;
    }
    else {
      $str =~ s/([\xC0-\xDF].|[\xE0-\xEF]..|[\xF0-\xFF]...)|([$default])|(]]>)/
        defined($1) ? XmlUtf8Decode ($1) :
        defined ($2) ? $DecodeDefaultEntity{$2} : "]]&gt;" /egs;
    }

#?? could there be references that should not be expanded?
# e.g. should not replace &#nn; &#xAF; and &abc;
#    $str =~ s/&(?!($ReName|#[0-9]+|#x[0-9a-fA-F]+);)/&amp;/go;

    $str;
}

sub XmlUtf8Decode
{
    my ($str, $hex) = @_;
    my $len = length ($str);
    my $n;

    if ($len == 2)
    {
        my @n = unpack "C2", $str;
        $n = (($n[0] & 0x3f) << 6) + ($n[1] & 0x3f);
    }
    elsif ($len == 3)
    {
        my @n = unpack "C3", $str;
        $n = (($n[0] & 0x1f) << 12) + (($n[1] & 0x3f) << 6) + 
                ($n[2] & 0x3f);
    }
    elsif ($len == 4)
    {
        my @n = unpack "C4", $str;
        $n = (($n[0] & 0x0f) << 18) + (($n[1] & 0x3f) << 12) + 
                (($n[2] & 0x3f) << 6) + ($n[3] & 0x3f);
    }
   elsif ($len == 1)   # just to be complete...
    {
        $n = ord ($str);
    }
    else
    {
        print "bad value [$str] for XmlUtf8Decode";
    }
    $hex ? sprintf ("&#x%x;", $n) : "&#$n;";
}

1;
