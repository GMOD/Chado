#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;
                                                                                
$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
$file .= $^O eq 'VMS' ? '.com' : '.pl';
                                                                                
open OUT,">$file" or die "Can't create $file: $!";
                                                                                
print "Extracting $file (with variable substitutions)\n";
                                                                                
print OUT "$Config{startperl}\n";

print OUT <<'!NO!SUBS!';
use strict;
use Cwd;
use FindBin '$Bin';
use lib './lib';
use Bio::GMOD::Config;
use lib './install_util';
use install;

my $origdir = cwd;
my $homedir = "$Bin/..";

my $conf = Bio::GMOD::Config->new();
my $gmod_root = $conf->gmod_root();

$gmod_root ||= '/usr/local/gmod';
my $src_dir  = "$gmod_root/src/chado";
                                                                                
chdir $homedir or die "couldn't cd to $homedir: $!\n";

if (! (-e "$gmod_root/src") ) {
    mkdir ("$gmod_root/src", 0777) or die "unable to mkdir $gmod_root/src: $!\n";
}

if (! (-e $src_dir) ) {
    mkdir ($src_dir, 0777) or die "unable to mkdir $src_dir: $!\n";
}

copy_tree('modules',$src_dir);

chdir $origdir;                                                                                
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

