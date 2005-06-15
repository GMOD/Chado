#!/usr/local/bin/perl -w

use strict;
use Getopt::Long;
use File::Glob ':glob';

my $interactive;
my $conffile;
my $build;
my $nodownload;
my $speciesl = [qw(mouse human anopheles)];
my $dbhost = "localhost";
my $dbuser = $ENV{USER};
my $quiet;
my $recreate;
my $help;
my $t = time;
my $logf = "./LOG.install-enseml-$t";

#  (
#   'ftp.ensembl.org/pub/current_mouse/data/mysql' => '*_{core,lite}_*',
#   'ftp.ensembl.org/pub/current_mosquito/data/mysql' => '*_{core,lite}_*',
#   'ftp.ensembl.org/pub/current_human/data/mysql' => '*_{core,lite}_*',
#   'ftp.ensembl.org/pub/current_mart/data/mysql' => 'ensembl_mart_*',
#  );

# OS X typically does not have wget; use curl instead
my $WGET = 
  "wget -r -np -nv";

if (system("which wget > /dev/null 2>1")) {
    print <<EOM;
wget not found

you need wget to run $0

if you are on OS X you can get wget via fink commander
EOM
                       
  exit 1;
}
  

my @sources = ();
my @ORGLIST =
  qw(
     cbriggsae
     celegans
     fugu
     human
     mosquito
     mouse
     rat
     worm
     chimp
     zebrafish

     mart
     multispecies
    );
my @orgs = ();
GetOptions("interactive|i"=>\$interactive,
	   "conffile|c=s"=>\$conffile,
	   "build|b"=>\$build,
	   "nodownload|nd"=>\$nodownload,
	   "dbhost|host=s"=>\$dbhost,
	   "dbuser|u=s"=>\$dbuser,
	   "quiet|q"=>\$quiet,
	   "recreate|r"=>\$recreate,
	   "help|h"=>\$help,
	   "log|l=s"=>\$logf,
#	   "dataset|d=s@"=>\@datasets,
	   "source|s=s@"=>\@sources,
	   "org=s@"=>\@orgs,
	  );
@ORGLIST = @orgs if scalar(@orgs);

my @datasets =
  (
   map {
       my $match = '*_{core,cdna,lite}_*';
       $match = 'ensembl_mart_*' if /^mart$/;
       $match = 'ensembl_compara_*' if /^multispecies$/;
       ("ftp.ensembl.org/pub/current_$_/data/mysql" => '*_{core,cdna,lite}_*')
   } @ORGLIST,
  );
   
if ($help) {
    print usage();
    exit;
}

my $U = '';
if ($dbuser) {
    $U = "-u $dbuser";
}
my @dbis = ();

open(LOG, ">$logf") || die("can't open $logf");

if ($conffile) {
    open(F, $conffile) || die;
    @datasets = ();
    while(<F>) {
	chomp;
	my ($loc, $pat) = split(' ', $_);
	push(@datasets, $loc=>$pat);
    }
    close(F);
}

my %sourceh = map {$_=>1} @sources;

my @d = @datasets;
while (my ($loc, $pat) = splice(@d, 0, 2)) {
    if (%sourceh) {
	$loc =~ /current_(\w+)/;
	if (!$sourceh{$1}) {
	    print "SKIPPING $loc\n";
	    next;
	}
    }
    $loc .= '/' unless substr($loc, -1) eq '/';
    unless ($nodownload) {
	sy("$WGET ftp://$loc");
    }
    if ($build) {
	my @files =
	  bsd_glob("$loc"."*/$pat.sql.gz");
	if (!@files) {
	    msg("nothing in $loc matches pattern:$pat\n");
	    next;
	}
	
	msg("Building databases from:\n" . join("\n", @files). "\n");
	foreach my $file (@files) {
	    build($file);
	}
    }
}
if (@dbis) {
    msg("Add these to bioresources.conf:\n");
    while (my ($logical, $physical) = splice(@dbis, 0, 2)) {
	my $schema = 'enscore';
	if ($physical =~ /lite/) {
	    $schema = 'enslite';
	}
	msg("# Autoloaded from ensembl\n");
	msg(sprintf("%19s rdb  %18s  schema=$schema\n", $logical, $physical));
    }
}
    
close(LOG);

sub build {
    my $file = shift;
    
    if ($file =~ /(.*)\/(\w+)\.sql\.gz/) {
	my $dir = $1;
	my $db=$2;
	if ($recreate) {
	    sy("mysql -h $dbhost $U -e 'drop database $db'", 1);
	}
	my $err =
	  sy("mysql -h $dbhost $U -e 'create database $db'");
	if ($err) {
	    msg("$db already exists - SKIPPING\n");
	    return;
	}
	else {
	    if (sy("gzip -dc $dir/$db.sql.gz | mysql -h $dbhost $U $db")) {
		msg("SKIPPING");
		return;
	    }
	    if (sy("gzip -d $dir/*table.gz")) {
		msg("ALREADY UNZIPPED?\n");
	    }
	    if (sy("mysqlimport -h $dbhost $U $db $dir/*table")) {
		msg("SKIPPING");
		return;
	    }
	    push(@dbis, ($db => "mysql:$db\@$dbhost"));
	}
    }
}

sub sy {
    my $call = shift;
    my $force = 1;
    if ($interactive) {
	return if !ask("Call: $call? [y/n] ");
    }
    else {
	msg("Running system call: $call\n");
    }
    my $err = system($call);
    return $err;
}


sub msg {
    my @m = @_;
    print LOG "@m";
    return if $quiet;
    print "@m";
}

sub ask {
    print "@_";
    my $yn = <STDIN>;
    $yn =~ /^y/i;
}

sub usage {
    return <<EOM
install-ensembl.pl

script for downloading and installing ensembl mysql dbs

by default it will use the following spec:


   'ftp.ensembl.org/pub/current_mouse/data/mysql' => '*_{core,lite}_*',
   'ftp.ensembl.org/pub/current_mosquito/data/mysql' => '*_{core,lite}_*',
   'ftp.ensembl.org/pub/current_human/data/mysql' => '*_{core,lite}_*',
   'ftp.ensembl.org/pub/current_mart/data/mysql' => 'ensembl_mart_*',

this can be overriden. the key specifies the ftp site, the value
specifies whi patterns to use when building a download

most tarballs are in directories named <species><db><version>

eg
mus_musculus_core_13_30

some do not conform to this - eg ensembl_mart_13_1 (this is a
compendium of all species)

we preserve these names when installing the db locally; this way we
can have different version concurrently. 

bioresources.conf can be used to provide shortened aliases

 arguments:

 -org ORGANISM

    just download this organism (must be ensembl name; eg mosquito, mouse)

    multiple args can be passed like this:
    -org human -org fly

 -b|build
    as well as downloading, perform the mysql build

 -q|quiet 
    operate silently

 -nodownload
    do not do the download step

 -i|interactive
    ask permission before doing anything

  -dbhost
    mysql server host (default space)

  -r|recreate   
    by default existing ensembl mysql database will not be dropped
    unless this is set.
    if this is not set, and an attempt is made to build an existing db,
    the attempt is skipped

  -c|conffile
    override conf - should be a whitespace delimited two column file
    e.g.
   ftp.ensembl.org/pub/current_mouse/data/mysql        *_{core,lite}_*

  -l|log
    override default logfile which is LOG.install-ensembl.TIMESTAMP
  

EOM
}
