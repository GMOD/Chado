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

foreach (@ARGV) {
  $_ =~ s/^\'(.*)\'$/$1/;
}

my %options = map {split /=/} @ARGV;
my $gmod_root = $options{GMOD_ROOT};
my $confdir   = "$gmod_root/conf";
my $tmpdir    = "$gmod_root/tmp";

my $origdir = cwd;
my $homedir = "$Bin/..";
                                                                                
chdir $homedir or die "couldn't cd to $homedir: $!\n";

# create GMOD_ROOT and conf dir if they dont already exist
if (! (-e $gmod_root)) {
    mkdir($gmod_root, 0777) or die "unable to make $gmod_root directory";
}

if (! (-e $confdir)) {
    mkdir($confdir, 0777) or die "unable to make $confdir directory";
}

if (! (-e $tmpdir)) {
    mkdir($tmpdir, 0777) or die "unable to make $tmpdir directory";
}

my $localconf = 'build.conf';
my %confitems;
open LOCALCONF, $localconf or die "unable to open $localconf: $!";
while (<LOCALCONF>) {
    chomp;
    my ($key, $value) = split /=/;
    if ($key =~ /^DB/) {
        $confitems{$key} = $value;
    }
}
close LOCALCONF;              

my $gmodconf    = "$confdir/gmod.conf";
my $defaultconf = "$confdir/default.conf";
my $dbconf      = "$confdir/$confitems{DBNAME}.conf";

open GMODCONF, ">$gmodconf" or die "unable to open $gmodconf: $!";
print GMODCONF "CONF=$gmod_root/conf\n";
print GMODCONF "TMP=$gmod_root/tmp\n";
close GMODCONF;

open DEFAULT, ">$defaultconf" or die "unable to open $defaultconf: $!";
open DBCONF,  ">$dbconf" or die "unable to open $dbconf: $!";
foreach my $key (keys %confitems) {
    print DEFAULT "$key=$confitems{$key}\n";
    print DBCONF  "$key=$confitems{$key}\n";
}
print DEFAULT "SQLFILE=$gmod_root/src/chado/modules/complete.sql";
print DBCONF  "SQLFILE=$gmod_root/src/chado/modules/complete.sql";
close DEFAULT;
close DBCONF;

chdir $origdir;

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

