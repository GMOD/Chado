#!perl -w

use Config;
use File::Basename qw(&basename &dirname);
use FindBin '$Bin';
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
$file = "gmod_$file.pl";

my %OPTIONS;
if (open F,"$Bin/../../build.conf") {
  while (<F>) {
    next if /^\#/;
    chomp;
    $OPTIONS{$1} = $2 if /^(\w+)\s*=\s*(.+)/;
  }
  close F;
}


open OUT,">$file" or die "Can't create $file: $!";
print OUT "$Config{startperl}\n";

if ($OPTIONS{LIB}) {
  print OUT "use lib '$OPTIONS{LIB}';\n";
}
if ($OPTIONS{PREFIX}) {
  print OUT "use lib '$OPTIONS{PREFIX}/lib'i\n";
}

print OUT <<'!NO!SUBS!';
use strict;
use Bio::Tools::GFF;
use Bio::SeqIO;
use Chado::AutoDBI;
use Chado::LoadDBI;
use Data::Dumper;
use Getopt::Long;
use Term::ProgressBar;
use File::Temp qw(tempfile);

use constant DEBUG => 0;

$| = 1;

=head1 NAME

gmod_load_gff3.pl - Load gff3 files into a chado database.

=head1 SYNOPSIS

  % gmod_load_gff3.pl --organism Human --srcdb 'DB:refseq' --gfffile refseq.gff

=head1 COMMAND-LINE OPTIONS

The following command line options are available.  Note that they
can be abbreviated to one letter.

  --cache      (optional, defaults to 1000)         The number of features
                                                    to cache before
                                                    committing to the database
  --force      (optional, defaults to false)        Force the file to load,
                                                    even if it has already
                                                    been loaded before
  --gfffile    (required)                           The name of the GFF3 file
  --organism   (optional, defaults to 'Human')      Common name of the organism
  --srcdb      (optional, defaults to 'DB:refseq')  The name of the source
                                                    database
  --uniquename (optional)                           The tag to use to provide
                                                    feature.uniquename
  --ontology   (optional)                           Ontology to use instead
                                                    of the default.  Note that
                                                    this should be detected
                                                    automatically, but isn't
                                                    yet.

=head1 DESCRIPTION

The gmod_load_gff3.pl script takes genomic annotations in the GFF3 format
and loads them into several tables in chado.  (see
L<http://song.sourceforge.net/gff3.shtml> for a description of the format).  
There are two types of data tags in GFF3: those that are part of the
specification, and those that aren't.  There is a short list of those that
are part of the spec (ie, reserved)  They include ID, Parent, Name, Alias,
Target, and Gap.  Tags that are part of the spec are first letter capitalized
and all other tags are all lower case.  All tags that are part of the spec
are handled as special cases during the insert, as well as some non-spec
tags.  These include 'description', tags beginning with 'db:' or 'DB:',
and tags beginning with 'cvterm:'.  All other tags are inserted into the
same table (featureprop).  If that is not the desired behavior for a given
tag, you may look at modifying the load_custom_tags subroutine.  If you
have a modification that you feel might be particularly useful, please 
email your suggestion to the authors.

(Note that this behavior might better be module-ized, so that we could 
provide an empty 'custom tag processing' module, that if installed, would
provide addtional processing of custom tags.  Add it to the todo list.)

=head2 NOTES

=over

=item The ORGANISM table

This script assumes that the organism table is populated with information
about your organism.  If you are unsure if that is the case, you can
execute this command from the psql command-line:

  select * from organism;

If you do not see your organism listed, execute this command to insert it:

  insert into organism (abbreviation, genus, species, common_name)
                values ('H.sapiens', 'Homo','sapiens','Human');

substituting in the appropriate values for your organism.

=item The DB table

This script assumes that the db table is populated with a row describing
the database that is the source of these annotations.  If you are unsure,
execute this command:

  select * from db;

If you do not see your database listed, execute this command:

  insert into db (name, contact_id) values ('DB:refseq',1);

Substituting for the name of your database.  A more complete insert
command may be appropriate in your case, but this should work in a pinch.

=item GFF3

The GFF in the datafile must be version 3 due to its tighter control of
the specification and use of controlled vocabulary.  Accordingly, the names
of feature types must be exactly those in the Sequence Ontology, not the
synonyms and not the accession numbers (SO accession numbers may be
supported in future versions of this script).  Also, in order for the load
to be successful, the reference sequences (eg, chromosomes or contigs)
must be defined in the GFF file before any features on them are listed.
This can be done either by the reference-sequence meta data specification,
which would be lines that look like this:

  ##sequence-region chr1 1 246127941

or with a standard GFF line:

  chr1	NCBI	chromosome	1	246127941	.	.	.	ID=chr1

Do not use both.  Note that if the '##sequence-region' notation is used,
this script will not be able to determine the type of sequence and therefore
will assign it the 'region' type which is very general. If that is not what
you want, use the standard GFF line to specify the reference
sequence.

=item Uniquename

By providing the command line flag --uniquename, the user indicates what
GFF tag to uses as the feature.uniquename when inserting into the feature
table.  Note that this name must be unique among all features in the feature
table; if it is not, the load of that feature will probably fail.

=back

=head1 AUTHORS

Allen Day E<lt>allenday@ucla.eduE<gt>, Scott Cain E<lt>cain@cshl.orgE<gt>

Copyright (c) 2003-2004

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ( undef, $TMPFASTA ) = tempfile( "XXXXXX", ".fa",  SUFFIX => '.fa' );
my ( undef, $TMPGFF )   = tempfile( "XXXXXX", ".gff", SUFFIX => '.gff' );

warn $TMPFASTA if DEBUG;
warn $TMPGFF if DEBUG;

my ( $ORGANISM,$SRC_DB,$GFFFILE,$UNIQUENAME,$CACHE_SIZE,$FORCE_LOAD,$ONTOLOGY );
my ( $progress, $next_update, $linecount ) =
  ( undef, undef, undef );    #progressbar;
my ( $chado_db, $chado_organism, $nullpub, $nullcontact ) =
  ( undef, undef, undef, undef );
my $feature_count = 0;        #for cache/flush
my $cv;
my $null_db_id;
my %srcfeature        = ();
my %feature           = ();
my %featureloc_locgroup   = ();
my %dbxref            = ();
my %cvterm            = ();
my $so;
my $gff_source_db;
my %gff_source;

initialize();

my $mtime = ( stat($GFFFILE) )[9];
my ($pub) = Chado::Pub->search( title => $GFFFILE . " " . $mtime );
if ( $pub and !$FORCE_LOAD ) {
    print "\nIt appears that you have already loaded this exact file\n";
    print "Do you want to continue [no]? ";
    chomp( my $response = <STDIN> );
    unless ( $response =~ /^[Yy]/ ) {
        print "OK--bye.\n";
        exit 0;
    }
}
else {
    $pub = Chado::Pub->find_or_create(
        {
            title      => $GFFFILE . " " . $mtime,
            miniref    => $GFFFILE . " " . $mtime,
            uniquename => $GFFFILE . " " . $mtime,
            type_id    => $cvterm{gff_file}->id
        }
    );
}
die "unable to find or create a pub entry in the pub table"
  unless $pub;

#iterate over each feature in the gff, caching objects up to
#CACHE_SIZE, then flushing.  this is a way to break our large
#load transaction into multiple cache/flush mini-transactions
my @transaction;

my $gffio = Bio::Tools::GFF->new( -file => $TMPGFF, -gff_version => 3 );

#my $gffio = Bio::Tools::GFF->new(-file => $GFFFILE, -gff_version => 3);

$feature_count += load_segments($gffio);

while ( my $gff_feature = $gffio->next_feature() ) {

    my ($id) =
        $gff_feature->has_tag('ID')
      ? $gff_feature->get_tag_values('ID')
      : '';

    my ($parent) = 
        $gff_feature->has_tag('Parent')
      ? $gff_feature->get_tag_values('Parent')
      : '';

    # look up the feature
    # problem here: two places that the reference sequence/srcfeature
    # might be found: either in the GFF file (in which case, look
    # for it in a hash here) or in the database already.  If it is
    # in the database already, it might be very difficult to look up
    # via seq_id.  I'll solve the first problem and think about the
    # second  sjc 3/23/04
    if ( ($id ne $gff_feature->seq_id) && ($gff_feature->seq_id ne '.') ) {
        ( $srcfeature{$gff_feature->seq_id} ) =
            Chado::Feature->search( name => $gff_feature->seq_id )
                unless $srcfeature{$gff_feature->seq_id};

        unless ( $srcfeature{$gff_feature->seq_id} ) {
            warn "\n" . "*" x 72 . "\n";
            warn "Unable to find a source feature id for the reference sequence in this line:\n";
            warn $gff_feature->gff_string . "\n\n";
            warn "That is, "
              . $gff_feature->seq_id
              . " should either have a entry in the \n";
            warn
              "feature table or earlier in this GFF file and it doesn't.\n\n";
            warn "*" x 72 . "\n";
            exit 1;
        }
    }

    #is this general, or what should really be done here?
    if ( $id && !$dbxref{$id} ) {
        my ($chado_dbxref) = Chado::Dbxref->find_or_create(
            {
                db_id     => $chado_db->id,
                accession => $id,
            }
        );
        $dbxref{$id} = $chado_dbxref;
    }

    cache_cvterm( $gff_feature->primary_tag, $so->id );
    my ($chado_type) = $cvterm{ $gff_feature->primary_tag };

    die $gff_feature->primary_tag
      . " could not be found in your cvterm table.\n"
      . "Either the Sequence Ontology was incorrectly loaded,\n"
      . "or this file doesn't contain GFF3"
      unless $chado_type;

    my $chado_feature =
      load_feature_locations( $gff_feature, $chado_type, $id );
    $feature_count++;

    $feature{$id} = $chado_feature if $gff_feature->has_tag('ID');

    my @tags = $gff_feature->all_tags;
    foreach my $tag (@tags) {
        if ( $tag eq 'ID' ) {
            #this currently doesn't do anything.  ID is used elsewhere though
        }
        elsif ( $tag eq 'Parent' ) {
            load_Parent_tag( $gff_feature, $chado_feature );
        }
        elsif ( $tag eq 'Alias' ) {
            load_Alias_tag( $gff_feature, $chado_feature );
        }
        elsif ( $tag eq 'Name' ) {
            load_Name_tag( $gff_feature, $chado_feature );
        }
        elsif ( $tag eq 'Target' ) {
            load_Target_tag( $gff_feature, $chado_feature );
        }
        elsif ( $tag eq 'Note' ) {
            load_Note_tag( $gff_feature, $chado_feature );
        }
        elsif ( $tag eq 'Ontology_term' || $tag =~ /^cvterm/) {
            load_Ontology_term( $gff_feature, $chado_feature, $tag );
        }
        elsif ( $tag =~ /^[A-Z]/ ) {
            die "$0 doesn't handle '$tag' tags yet.  are you sure it's allowed by the GFF3 spec?";
        }
        elsif ( $tag eq $UNIQUENAME ) {
           # do nothing--we already used this information to create the feature
        }
        elsif ( $tag =~ /^[a-z]/ ) {
            load_custom_tags( $gff_feature, $chado_feature, $tag );
        }
    }

    if ( $feature_count % $CACHE_SIZE == 0 ) {
        $_->dbi_commit foreach @transaction;
        @transaction = ();
    }

    $next_update = $progress->update($feature_count)
      if ( $feature_count > $next_update );
    $progress->update($feature_count) if ( $feature_count >= $next_update );
    $progress->update($linecount)     if ( $next_update >= $linecount );
}

$_->dbi_commit foreach @transaction;
$gffio->close();

print "\n$feature_count features added\n";

my $seqs_loaded = load_sequences();
print "\n$seqs_loaded sequences added\n";
print "Done\n";
exit 0;

=pod

=head1 load_custom_tags

Handles inserting non-reserved tags into chado.  Determines if the tag
falls into a short list of tags for custom handling and deals with them
appropriately.  If the tag is not on the list, the information is placed 
in the featureprop table.

=cut

sub load_custom_tags {
    my $gff_feature   = shift;
    my $chado_feature = shift;
    my $tag           = shift;

    my @d = $gff_feature->get_tag_values($tag);

    if (0) {
    }
    elsif ( $tag eq 'description' ) {
        foreach my $d (@d) {
            next if $d eq '';
            my ($featureprop) = Chado::Featureprop->find_or_create(
                {
                    feature_id => $chado_feature->id,
                    type_id    => $cvterm{description}->id,
                    value      => $d,
                }
            );

            push @transaction, ($featureprop);
        }
    }
    elsif ( $tag =~ /^db:/ ) {
        $tag =~ s/^db:/DB:/;

        my $add_db = 0;
        my ($db) = Chado::Db->search( name => $tag );
        if ( !$db ) {
            $add_db = 1;
            $db = Chado::Db->find_or_create(
                {
                    name       => $tag,
                    contact_id => $nullcontact,
                }
            );
        }
        die "couldn't create db $db" unless $db;
        push @transaction, $db if $add_db;

        foreach my $d (@d) {
            next if $d eq '';
            my ($dbxref) = Chado::Dbxref->find_or_create(
                {
                    db_id     => $db->id,
                    accession => $d
                }
            );
            my ($feature_dbxref) = Chado::Feature_Dbxref->find_or_create(
                {
                    feature_id => $chado_feature->id,
                    dbxref_id  => $dbxref->id,
                }
            );
            push @transaction, ( $dbxref, $feature_dbxref );
        }

    }
    elsif ( $tag eq 'dbxref') {
        foreach my $d (@d) { 
            next if $d eq '';
            if ($d =~ /(.+):(.+)/) {
                $tag = "DB:$1";
                $d   = $2;
            } else {
                die "unable to determine database for dbxref: $d\n";
            }

            my $add_db = 0;
            my ($db) = Chado::Db->search( name => $tag );
            if ( !$db ) {
                $add_db = 1;
                $db = Chado::Db->find_or_create(
                    {
                        name       => $tag,
                        contact_id => $nullcontact,
                    }
                );
            }
            die "couldn't create db $db" unless $db;
            push @transaction, $db if $add_db;
                                                                                
            my ($dbxref) = Chado::Dbxref->find_or_create(
                {
                    db_id     => $db->id,
                    accession => $d
                }
            );
            my ($feature_dbxref) = Chado::Feature_Dbxref->find_or_create(
                {
                    feature_id => $chado_feature->id,
                    dbxref_id  => $dbxref->id,
                }
            );
            push @transaction, ( $dbxref, $feature_dbxref );
        } 
    }
    else {
        unless ( defined $cvterm{$tag} ) {
            cache_cvterm($tag);
            $progress->message("Data with the $tag tag are being placed in the featureprop table");
        }

        my $rank = 0;
        foreach my $d (@d) {
            next if $d eq '';
            my ($featureprop) = Chado::Featureprop->find_or_create(
                {
                    feature_id => $chado_feature->id,
                    type_id    => $cvterm{$tag}->id,
                    value      => $d,
                    rank       => $rank,
                }
            );
            $rank++;
            push @transaction, $featureprop;
        }
    }
}

=pod

=head1 load_Ontology_term

Loads ontology terms to feature_cvterm.

=cut

sub load_Ontology_term {
    my $gff_feature   = shift;
    my $chado_feature = shift;
    my $tag           = shift;
                                                                                
    my @d = $gff_feature->get_tag_values($tag);

    foreach my $d (@d) {
        next if $d eq '';
        my ($dbxref) = Chado::Dbxref->search( accession => $d );
        $progress->message("couldn't find cvterm in dbxref: $d") and next
          unless $dbxref;
        my ($cvterm) = Chado::Cvterm->search( dbxref_id => $dbxref->id );
                                                                                
        next unless $cvterm;
                              
        my ($feature_cvterm) = Chado::Feature_Cvterm->find_or_create(
            {
                feature_id => $chado_feature->id,
                cvterm_id  => $cvterm->id,
                pub_id     => $nullpub->id,
                dbxref_id  => $dbxref->id,
            }
        );
        push @transaction, $feature_cvterm;
    }
}

=pod

=head1 load_Note_tag

Loads Note tag values to the featureprop table.

=cut

sub load_Note_tag {
    my $gff_feature   = shift;
    my $chado_feature = shift;

    cache_cvterm('Note') unless ( defined $cvterm{'Note'} );

    my @d = $gff_feature->get_tag_values('Note');
    my $rank = 0;
    foreach my $d (@d) {
        next if $d eq '';
        my ($featureprop) = Chado::Featureprop->find_or_create(
            {
                feature_id => $chado_feature->id,
                type_id    => $cvterm{'Note'}->id,
                value      => $d,
                rank       => $rank,
            }
        );
        push @transaction, $featureprop;
        $rank++;
    }
}

=pod

=head1 load_Target_tag

Loads Target values.  These are used for alignment information.

=cut

sub load_Target_tag {
    my $gff_feature   = shift;
    my $chado_feature = shift;

    if ( $gff_feature->has_tag('Target') ) {
        my @targets = $gff_feature->get_tag_values('Target');
        foreach my $target (@targets) {
            my ( $tstart, $tend );
            if ( $target =~ /^(\S+?)\+(\d+)\+(\d+)$/ ) {
                ( $target, $tstart, $tend ) = ( $1, $2, $3 );
            }
            else {
                die "your Target attribute seems to be improperly formated";
            }

            my ($chado_synonym1) = Chado::Synonym->find_or_create(
                {
                    name         => $target,
                    synonym_sgml => $target,
                    type_id      => $cvterm{synonym}->id
                }
            );

            my ($chado_synonym2) = Chado::Feature_Synonym->find_or_create(
                {
                    synonym_id => $chado_synonym1->id,
                    feature_id => $chado_feature->id,
                    pub_id     => $pub->id,
                }
            );

            my ($chado_featureloc) = Chado::Featureloc->find_or_create(
                {
                    feature_id    => $chado_feature->id,
                    srcfeature_id => $chado_feature->id,
                    fmin          => $tstart,
                    fmax          => $tend,
                    rank          => 1 #potential bug here -allenday
                }
            );

            my ($chado_featureprop) = Chado::Featureprop->find_or_create(
                {
                    feature_id => $chado_feature->id,
                    type_id    => $cvterm{score}->id,
                    value      => $gff_feature->score
                }
            );

            push @transaction, $chado_synonym1;
            push @transaction, $chado_synonym2;
            push @transaction, $chado_featureloc;
            push @transaction, $chado_featureprop;
        }
    }
}

=pod

=head1 load_Parent_tag

Loads Parent tag values.  These are used to denote a parent feature
of the given feature.

=cut

sub load_Parent_tag {
    my $gff_feature   = shift;
    my $chado_feature = shift;

    if ( $gff_feature->has_tag('Parent') ) {
        my @parents = $gff_feature->get_tag_values('Parent');
        foreach my $parent (@parents) {
            next if $parent eq '';

            my $reltype =
                ( $gff_feature->primary_tag eq 'protein' ||
                  $gff_feature->primary_tag eq 'polypeptide' )
              ? $cvterm{develops_from}
              : $cvterm{part_of};

           #unhandled exception: what if $feature{$parent} hasn't been seen yet?
            ( $feature{$parent} ) = Chado::Feature->search( name => $parent )
              unless $feature{$parent};

            my $chado_feature_relationship =
              Chado::Feature_Relationship->find_or_create(
                {
                    subject_id => $chado_feature->id,
                    object_id  => $feature{$parent}->id,
                    type_id    => $reltype,
                }
              );
            push @transaction, $chado_feature_relationship;
        }
    }
}

=pod

=head1 load_Alias_tag

Loads Alias tag values.  These are used for synonyms.

=cut

sub load_Alias_tag {
    my $gff_feature   = shift;
    my $chado_feature = shift;

    if ( $gff_feature->has_tag('Alias') ) {
        my @aliases;
        if ( $gff_feature->has_tag('Alias') ) {
            push @aliases, $gff_feature->get_tag_values('Alias');
        }
        foreach my $alias (@aliases) {
            next if $alias eq '';
            #create the synonym
            my ($chado_synonym1) = Chado::Synonym->find_or_create(
                {
                    name         => $alias,
                    synonym_sgml => $alias,
                    type_id      => $cvterm{synonym}->id
                }
            );

            #and link it to the feature via feature_synonym
            my ($chado_synonym2) = Chado::Feature_Synonym->find_or_create(
                {
                    synonym_id => $chado_synonym1->id,
                    feature_id => $chado_feature->id,
                    pub_id     => $pub->id,
                }
            );
            push @transaction, $chado_synonym1;
            push @transaction, $chado_synonym2;
        }
    }
}

=pod

=head1 load_Name_tag

Loads Name tag values.

=cut

sub load_Name_tag {
    my $gff_feature   = shift;
    my $chado_feature = shift;

    my @names;
    if ( $gff_feature->has_tag('Name') ) {
        @names = $gff_feature->get_tag_values('Name');
    } elsif ($gff_feature->has_tag('ID') ) {
        @names = $gff_feature->get_tag_values('ID');
    } else {
        return;
    }

    foreach my $name (@names) {
        next if $name eq '';
        my ($chado_synonym1) = Chado::Synonym->find_or_create(
            {
                name         => $name,
                synonym_sgml => $name,
                type_id      => $cvterm{synonym}->id
            }
        );

        my ($chado_synonym2) = Chado::Feature_Synonym->find_or_create(
            {
                synonym_id => $chado_synonym1->id,
                feature_id => $chado_feature->id,
                pub_id     => $pub->id,
            }
        );
        push @transaction, $chado_synonym1;
        push @transaction, $chado_synonym2;
    }
}

sub initialize {

    GetOptions(
        'organism:s' => \$ORGANISM,
        'srcdb:s'    => \$SRC_DB,
        'gfffile:s'  => \$GFFFILE,
        'uniquename:s'=>\$UNIQUENAME,
        'cache:s'    => \$CACHE_SIZE,
        'force'      => \$FORCE_LOAD,
        'ontology:s' => \$ONTOLOGY,
      )
      or ( system( 'pod2text', $0 ), exit -1 );

    $ORGANISM   ||= 'Human';
    $SRC_DB     ||= 'DB:refseq';
    $CACHE_SIZE ||= 1000;
    $ONTOLOGY   ||= 'Sequence Ontology Feature Annotation';

    die "\nYou must specify a GFF file\n" unless $GFFFILE;

    #deal with GFF3 files that contain sequence
    # this is ugly, ugly, ugly, but in addtion to dealing with
    # sequence, it also fixes Allen's method of tracking progress
    die "$GFFFILE does not exist" unless ( -e $GFFFILE );

    my $linenumber = `grep -n "^>" $GFFFILE`;
    if ( $linenumber =~ /^(\d+)/ ) {
        $linenumber = $1;
        system("tail +$linenumber $GFFFILE > $TMPFASTA");
        $linenumber -= 1;
        system("head -$linenumber $GFFFILE > $TMPGFF");

        #we don't want to do this, as the filename is used in a pub record
        #$GFFFILE = $TMPGFF;
    }
    else {
        $TMPGFF = $GFFFILE;
    }

    #count the file lines.  we need this to track load progress
    open( WC, "grep -c -v '^#' $TMPGFF |" );

    #  open(WC,"grep -c -v '^#' $GFFFILE |");
    $linecount = <WC>;
    chomp $linecount;
    close(WC);
    ($linecount) = $linecount =~ /^\s*?(\d+)/;

    $progress = Term::ProgressBar->new(
        {
            name  => "Approx $linecount features",
            count => $linecount,
            ETA   => 'linear',
        }
    );
    $progress->max_update_rate(1);
    $next_update = 0;

    Chado::LoadDBI->init();
    ($cv) = Chado::Cv->search(
        {
            name       => 'autocreated',
        }
    );
    die "Unable to find a 'autocreated' cv in the cv table; please add one" unless $cv;
    ($so) = Chado::Cv->search( { name => $ONTOLOGY } );
    die "Unable to find $ONTOLOGY in cv table; that is a pretty big problem" unless $so;

    # find needed cvterm and other pieces of information
    my @needed_cvterms =
      qw(description synonym note develops_from part_of gff_file score protein);
    foreach my $n (@needed_cvterms) {
        cache_cvterm($n);
    }
    cache_cvterm('region',$so->id); #make sure to get the SO region term

    ($chado_organism) = Chado::Organism->search( common_name => lc($ORGANISM))
        unless $chado_organism;
    ($chado_organism) = Chado::Organism->search( abbreviation => ucfirst($ORGANISM))
        unless($chado_organism);
    ($chado_organism) = Chado::Organism->search( genus => $ORGANISM  )
        unless($chado_organism);

    ($chado_db)       = Chado::Db->search( name              => $SRC_DB );
    ($nullpub)        = Chado::Pub->search( miniref          => 'null' );
    ($nullcontact)    = Chado::Contact->search( name         => 'null' );

    unless ($chado_organism) {
      warn "\n\nCouldn't find or create organism $ORGANISM.\n";
      warn "The current contents of the organism table is:\n\n";

      my @all_columns = Chado::Organism->columns;
      printf "%15s %8s %11s %11s %12s %15s\n\n", sort @all_columns;

      my $organism_iterator = Chado::Organism->retrieve_all();
      while(my $organism = $organism_iterator->next){ 
        my @cols = map { $organism->$_ } sort $organism->columns;
        printf "%15s %8s %11s %11s %12s %15s\n", @cols;
      }
      print "\nPlease see \`perldoc gmod_load_gff3.pl\` for more information\n";
      exit 1;
    }

    unless ($chado_db) {
      warn "\n\nCouldn't find or create database $SRC_DB.\n";
      warn "The current contents of the database table is:\n\n";

      my @all_columns = Chado::Db->columns;
      printf "%10s %6s %13s %25s %5s %10s\n\n", sort @all_columns;

      my $db_iterator = Chado::Db->retrieve_all();
      while(my $db = $db_iterator->next){
        my @cols = map { $db->$_ } sort $db->columns;
        printf "%10s %6s %13s %25s %5s %10s\n", @cols;
      }
      print "\nPlease see \`perldoc gmod_load_gff3.pl\` for more information\n";
      exit 1;
    }
}

sub load_segments {
    my $gffio = shift;
    my $i     = 0;

    # creates the features for each gff segment
    while ( my $gff_segment = $gffio->next_segment() ) {
        my ($segment) =
          Chado::Feature->search( { name => $gff_segment->display_id , organism_id => $chado_organism } );
        if ( !$segment ) {

# about uniquenames here: since these are coming from ##sequence_region
# meta stuff in the header, there will be no uniquename attribute, so the
# only thing to do is to generate one.

            my $f = Chado::Feature->create(
                {
                    organism_id => $chado_organism,
                    name        => $gff_segment->display_id,
                    uniquename  => $gff_segment->display_id . '_region',
                    type_id     => $cvterm{'region'},
                    seqlen      => $gff_segment->end
                }
            );

            $i++;
            $f->dbi_commit;
            $srcfeature{ $f->name } = $f;
        }
        else {
            $srcfeature{ $segment->name } = $segment;
        }
    }
    return $i;
}

sub load_sequences {
    my $seqs_loaded = 0;

    if ( -e $TMPFASTA ) {
        Chado::Feature->set_sql( update_residues =>
          qq{UPDATE feature SET residues = residues || ? WHERE feature_id = ?}
        );
        my $sth = Chado::Feature->sql_update_residues;

        print STDERR "loading sequence data...\n";

        #count the file lines.  we need this to track load progress
        open( WC, "grep -c '^>' $TMPFASTA |" );
        $linecount = <WC>;
        chomp $linecount;
        close(WC);
        ($linecount) = $linecount =~ /^\s*?(\d+)/;

        $progress = Term::ProgressBar->new(
            {
                name  => "Approx $linecount sequences",
                count => $linecount,
                ETA   => 'linear',
            }
        );
        $progress->max_update_rate(1);
        $next_update = 0;

        my $in = Bio::SeqIO->new( -file => $TMPFASTA, '-format' => 'Fasta' );
        while ( my $seq = $in->next_seq() ) {
            my $name          = $seq->id;
            my @chado_feature = Chado::Feature->search( { 'name' => $name , organism_id => $chado_organism} );

            unless (@chado_feature) { #check synonym and dbxref
                my ($dbh) = Chado::DBI->db_handles();
                my $sth = $dbh->prepare(
                        "SELECT feature_id 
                         FROM feature_dbxref fd join dbxref d using (dbxref_id)
                         WHERE d.accession = ?"
                          );
                $sth->execute($name) or die $sth->errstr;

                my $rows = $sth->rows;
 
                if ($rows < 1) {
                    $sth = $dbh->prepare(
                      "SELECT feature_id
                       FROM feature_synonym fs join synonym s using (synonym_id)
                       WHERE s.name = ?"
                           );
                    $sth->execute($name) or die $sth->errstr;
                } 

                while (my $hashref =  $sth->fetchrow_hashref) {
                    my @temp_feat = Chado::Feature->search( {'feature_id' => $$hashref{'feature_id'} } );
                    push @chado_feature, @temp_feat;
                }
            }

            #no, let's just load the sequence into all of them
            #die "couldn't uniquely identify the sequence identified by $name"
            #  unless (scalar @chado_feature == 1);
            $progress->message("no feature for sequence $name")
              unless scalar(@chado_feature);
            $progress->message("multiple features for sequence $name\n")
              if scalar(@chado_feature) > 1;

            my $dna       = $seq->seq;
            undef $seq;                     #get this thing out of here ASAP, it's using memory
            foreach my $f (@chado_feature) {

                $f->residues('');
                $f->update;
                $f->dbi_commit;

                $progress->message("copying Bio::Seq sequence to simple scalar variable") if DEBUG;
                $progress->message("copied.  Bio::Seq object purged to conserve memory") if DEBUG;

                my $shredsize = 100_000_000;    #don't increase this...
                my $offset    = 0;
                my $dnalen    = length($dna);

                while ( $offset < $dnalen ) {
                    $progress->message("loading shred.  offset: $offset bp") if DEBUG;
                    my $shred = substr( $dna, $offset, $shredsize );
                    $progress->message("${offset}bp loaded") if $offset > 0 and DEBUG;
                    $sth->execute( $shred, $f->id );
                    $progress->message("loaded shred") if DEBUG;

                    $offset += $shredsize;
                }

                $progress->message("${dnalen}bp loaded") if DEBUG;
                $f->update;

                $progress->message("pre dbi_commit") if DEBUG;
                $f->dbi_commit;
                $progress->message("post dbi_commit") if DEBUG;

            }
            $seqs_loaded++;

            $next_update = $progress->update($seqs_loaded)
              if ( $seqs_loaded > $next_update );
            $progress->update($seqs_loaded) if ( $seqs_loaded >= $next_update );
            $progress->update($linecount)   if ( $next_update >= $linecount );

        }

        unlink $TMPFASTA unless $TMPFASTA eq $GFFFILE;
        unlink $TMPGFF   unless $TMPGFF   eq $GFFFILE;
    }

    return $seqs_loaded;
}

sub load_feature_locations {
    my $gff_feature = shift;
    my $chado_type  = shift;
    my $id          = shift;

    ## GFF features are base-oriented, so we must add 1 to the diff
    ## between the end base and the start base, to get the number of
    ## intervening bases between the start and end intervals
    my $seqlen = ( $gff_feature->end - $gff_feature->start ) + 1;

    ## we must convert between base-oriented coordinates (GFF3) and
    ## interbase coordinates (chado)
    ##
    ## interbase counts *between* bases (starting from 0)
    ## GFF3 (and blast, bioperl, etc) count the actual bases (origin 1)
    ##
    ##
    ## 0 1 2 3 4 5 6 7 8 : INTERBASE
    ##  A T G C G T A T
    ##  1 2 3 4 5 6 7 8  : BIOPERL/GFF
    ##
    ## from the above we can see that we need to add/subtract 1 from fmin
    ## we don't touch fmax
    my $fmin = $gff_feature->start - 1;    # GFF -> InterBase
    my $fmax = $gff_feature->end;

    my $frame = $gff_feature->frame eq '.' ? 0 : $gff_feature->frame;


    # logic for creating feature.uniquename and feature.name (040414 allenday):
    #
    # if you decide to change the logic, please email the gmod-schema list before committing.
    # many people depend on the convention outlined here.
    #
    # UNIQUENAME
    #
    # 1. if --uniquename tag given, use data from that tag, or die if non-existant
    # 2. else, if ID tag available, use its value
    # 3. else, use a combination of GFF objects primary tag, seq_id, and, if available,
    #    positional information.
    # 4. die, not enough information to generate a uniquename
    #
    # NAME
    #
    # 1. use Name tag if available
    # 2. else, use ID tag if available
    # 3. else, feature has no name
    #
    my $uniquename = '';
    my $name       = '';

    if( defined($UNIQUENAME) and $gff_feature->has_tag($UNIQUENAME) ) {
        ($uniquename) = $gff_feature->get_tag_values($UNIQUENAME);

    } elsif( defined($UNIQUENAME) ) {
        die("The --uniquename tag was specified as '$UNIQUENAME, but a feature was found without this tag");

    } elsif( $gff_feature->has_tag('ID') ) {
      ($uniquename) = $gff_feature->get_tag_values('ID');

    } elsif( $gff_feature->primary_tag and $gff_feature->seq_id ) {

        my $position    = $fmax eq '.' ? '' : ":$fmin..$fmax";
        my($parentname) = $gff_feature->has_tag('Parent') ? $gff_feature->get_tag_values('Parent') : '';

        $uniquename = sprintf("_%s_%s_%s%s",
                              $parentname, $gff_feature->primary_tag, $gff_feature->seq_id, $position
                             );
    } else {
        die("not enough information available to make a uniquename for $gff_feature");
    }

    my %feature_attributes = (
        organism_id => $chado_organism->id,
        type_id => $chado_type->id,
        uniquename => $uniquename,
    );

    my $used_ID_for_Name = 0;
    if ( $gff_feature->has_tag('Name') ) {
        ($name) = $gff_feature->get_tag_values('Name');
        $feature_attributes{name} = $name;
    } elsif ( $gff_feature->has_tag('ID') ) {
        ($name) = $gff_feature->get_tag_values('ID');
        $feature_attributes{name} = $name;
        $used_ID_for_Name = 1;
    }

    my $chado_feature;
    if ( $gff_feature->has_tag('Name') ) {
        ($name) = $gff_feature->get_tag_values('Name');
    }
    elsif ( $gff_feature->has_tag('ID') ){
        ($name) = $gff_feature->get_tag_values('ID');
    }

    ($chado_feature) = Chado::Feature->find_or_create(\%feature_attributes);

    if(!defined($chado_feature->seqlen)){
        $chado_feature->seqlen($seqlen);
        $chado_feature->update;
        $chado_feature->dbi_commit;
    }

    push @transaction, $chado_feature;

    if ($used_ID_for_Name)   {
        load_Name_tag ($gff_feature, $chado_feature);
    }

    my $source = $gff_feature->source_tag();
    if ( $source && $source ne '.') { #make source a feature prop

        unless ($gff_source_db) {#create a new db for keeping GFF sources
            $gff_source_db = Chado::Db->find_or_create( {
                name        => 'GFF_source',
                contact_id  => $nullcontact,
                description => 'A collection of sources (ie, column 2) from GFF files',
            } );

            push @transaction, $gff_source_db;
        }

        unless ($gff_source{$source}) { #now make a dbxref for the source
            $gff_source{$source} = Chado::Dbxref->find_or_create( {
                db_id     => $gff_source_db->id,
                accession => $source,
            } );
            push @transaction, $gff_source{$source};
        }

        #now tie feature and source together in feature_dbxref
        my $feature_dbxref = Chado::Feature_Dbxref->find_or_create( {
            feature_id => $chado_feature->id,
            dbxref_id  => $gff_source{$source}->id
        }); 
        push @transaction, $feature_dbxref;
    }

    $chado_feature->dbxref_id( $dbxref{$id} )
        if $gff_feature->has_tag('ID');         # is this the right thing to do here?
    $chado_feature->update;                     # flush updates to this feature object

    if ( $id eq $gff_feature->seq_id
        or $gff_feature->seq_id eq '.' ) {
      #ie, this is a srcfeature (ie, fref) so only create the feature
        $srcfeature{$gff_feature->seq_id} = $chado_feature;
        return ($chado_feature);
    }

    # find pre-existing feature locations that were loaded prior
    # to this GFF3 file.
    if(!$featureloc_locgroup{ $chado_feature->id }){
      my $max_locgroup = undef;
      foreach my $previous_featureloc (Chado::Featureloc->search(
        feature_id => $chado_feature->id,
      )){
        if($fmin == $previous_featureloc->fmin and
           $fmax == $previous_featureloc->fmax and
           $previous_featureloc->srcfeature_id == $srcfeature{$gff_feature->seq_id}->id
          ){
          return $chado_feature;
        }

        $max_locgroup = $max_locgroup > $previous_featureloc->locgroup ? $max_locgroup : $previous_featureloc->locgroup;
      }

      if(defined($max_locgroup)){
        $featureloc_locgroup{ $chado_feature->id } = $max_locgroup;
      }
    }

    # add feature location
    $featureloc_locgroup{ $chado_feature->id }++;

    my $locgroup =  $featureloc_locgroup{ $chado_feature->id };
    my($parent) = $gff_feature->has_tag('Parent') ? $gff_feature->get_tag_values('Parent') : ();

    if($parent && $featureloc_locgroup{ $feature{$parent} }){
        $locgroup = $featureloc_locgroup{ $feature{$parent} };
    }

    $locgroup ||= 0;

    if (DEBUG) {
        $progress->message("adding featureloc for gff string:");
        $progress->message("\t".$gff_feature->gff_string);
#	print STDERR $chado_feature->id , "\t" , $locgroup , "\n";

        if($parent){
            $progress->message("srcfeature_id: " . Dumper($feature{$parent}));
        }
    }

    my $chado_featureloc = Chado::Featureloc->find_or_create(
        {
            feature_id    => $chado_feature->id,
            fmin          => $fmin,
            fmax          => $fmax,
            strand        => $gff_feature->strand,
            phase         => $frame,
            locgroup      => $locgroup,
            srcfeature_id => $srcfeature{$gff_feature->seq_id}->id,
        }
    );

    push @transaction, $chado_featureloc;

    return ($chado_feature);
}

sub cache_cvterm {
    my $name = shift;
    my $soid = shift;

    #we need an ontology source check here.  GO has an obsolete term for 'protein', but we want the
    #one from SO.

    ( $cvterm{$name} ) = Chado::Cvterm->search( {
                                                  name => $name,
                                                  cv_id=> $soid } ) 
                      || Chado::Cvterm->search( {
                                                  name => ucfirst($name),
                                                  cv_id=> $soid } );

    if (!$cvterm{$name} and !$soid) {
        ( $cvterm{$name} )=Chado::Cvterm->search( { name => $name } )
                         ||Chado::Cvterm->search( { name => ucfirst($name) } );
    }

    $cvterm{$name} = $cvterm{$name}->next()
      if defined( $cvterm{$name} )
      and $cvterm{$name}->isa('Class::DBI::Iterator');

    if ( !$cvterm{$name} && !$soid  ) {

        unless ($null_db_id) {
            my ($null_db)  = Chado::Db->search(
                {
                    name   => 'null'
                }
            );
            $null_db_id = $null_db->id;
        }

        my ($dbxref)       = Chado::Dbxref->find_or_create(
            {
                db_id      => $null_db_id,
                accession  => $cv->name.":".$name,
            }
        );

        ( $cvterm{$name} ) = Chado::Cvterm->find_or_create(
            {
                name       => $name,
                cv_id      => $cv->id,
                definition => 'autocreated by gmod_load_gff3.pl',
                dbxref_id  => $dbxref->id,
            }
        );
    }
    die "unable to create a '$name' entry in the cvterm table"
      if (!$cvterm{$name} && !$soid );
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
chdir $origdir;

