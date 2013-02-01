#!/usr/bin/perl 
use strict;
use warnings;
use VM::EC2;
use HTTP::Request::Common;
use LWP::UserAgent;
use FindBin '$Bin';
use constant REGISTRATION_SERVER
           => 'http://modencode.oicr.on.ca/cgi-bin/gbrowse_registration';


my $instance = VM::EC2->instance_metadata();  # should be a metadata object

my $userdata  = $instance->userData;
my %userdata =  map {split /\s*\:\s*/, $_ } split "\n", $userdata;

#check to see if this instance all ready called
exit 0 if (-f "$Bin/gitc_lock");

#check if user specifically doesn't want to call home
exit 0 if ($userdata{'NoCallHome'});

my $ipaddress = $instance->publicIpv4;

my @callhome = ( user     => "GMOD in the Cloud:".$instance->imageId.'|'.$instance->instanceType,
                 email    => $userdata{email}    || '',
                 org      => $userdata{org}      || '',
                 organism => $userdata{organism} || '',
                 site     => $ipaddress
                );

print @callhome;

my $ua       = LWP::UserAgent->new;
my $response = $ua->request(
                 POST(REGISTRATION_SERVER,
                      \@callhome
               ));

#to prevent the same instance from calling home more than once
open (LOCK, ">$Bin/gitc_lock");
print LOCK "Sending the 'call home' email.  If you would like to suppress this in the\nfuture, add 'NoCallHome : 1' to the userdata when launching the instance.\n";

close LOCK;

exit 0;

