#!perl -w

use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
$file = "gmod_$file.pl";

open OUT,">$file" or die "Can't create $file: $!";
print OUT "$Config{startperl}\n";

print OUT <<'!NO!SUBS!';
use strict;
use Bio::Tools::GFF;
use Bio::SeqIO;
use Chado::AutoDBI;
use Chado::LoadDBI;
use Getopt::Long;
use Term::ProgressBar;
use File::Temp qw(tempfile);

$| = 1;

=head1 NAME

load_gff3.pl - Load gff3 files into a chado database.

=head1 SYNOPSIS

  % load_gff3.pl --organism Human --srcdb 'DB:refseq' --gfffile refseq.gff

=head1 DESCRIPTION

See the notes; there is plenty there.

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

=back

=head1 COMMAND-LINE OPTIONS

The following command line options are required.  Note that they
can be abbreviated to one letter.

  --organism <org name>      Common name of the organism
                                (default: 'Human')
  --srcdb    <dbname>        The name of the source database
                                (default: 'DB:refseq')
  --gfffile  <filename>      The name of the GFF3 file
  --cache    <# of features> The number of features to cache before
                                committing to the database
                                (default: 1000)
  --force                    Force the file to load, even if it has already been
                                loaded before

=head1 AUTHORS

Allen Day E<lt>allenday@ucla.eduE<gt>, Scott Cain E<lt>cain@cshl.orgE<gt>

Copyright (c) 2003

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  

=cut

#my $TMPFASTA = 'tmp.fasta';
#my $TMPGFF   = 'tmp.gff';
my(undef,$TMPFASTA) = tempfile("XXXXXX",".fa", SUFFIX => '.fa');
my(undef,$TMPGFF) = tempfile("XXXXXX",".gff", SUFFIX => '.gff');
#warn $TMPFASTA;
#warn $TMPGFF;

my ($ORGANISM, $SRC_DB, $GFFFILE, $CACHE_SIZE, $FORCE_LOAD);
my($progress,$next_update,$linecount) = (undef,undef,undef); #progressbar;
my($chado_db,$chado_organism,$nullpub,$nullcontact) = (undef,undef,undef,undef);
my $feature_count = 0; #for cache/flush
my $cv;
my %feature = ();
my %featureloc_rank = ();
my %dbxref = ();
my %cvterm = ();

initialize();

my $mtime = (stat($GFFFILE))[9];
my ($pub) = Chado::Pub->search(title => $GFFFILE." ".$mtime);
if ($pub and !$FORCE_LOAD) {
  print "\nIt appears that you have already loaded this exact file\n";
  print "Do you want to continue [no]? ";
  chomp (my $response = <STDIN>);
  unless ($response =~ /^[Yy]/) {
    print "OK--bye.\n";
    exit 0;
  }
} else {
  $pub = Chado::Pub->find_or_create({
                                     title      => $GFFFILE." ".$mtime,
                                     miniref    => $GFFFILE." ".$mtime,
                                     uniquename => $GFFFILE." ".$mtime,
                                     type_id    => $cvterm{gff_file}->id
                                    });
}
die "unable to find or create a pub entry in the pub table"
  unless $pub;


#iterate over each feature in the gff, caching objects up to
#CACHE_SIZE, then flushing.  this is a way to break our large
#load transaction into multiple cache/flush mini-transactions
my @transaction;

my $gffio = Bio::Tools::GFF->new(-file => $TMPGFF, -gff_version => 3);
#my $gffio = Bio::Tools::GFF->new(-file => $GFFFILE, -gff_version => 3);

$feature_count += load_segments($gffio);

while(my $gff_feature = $gffio->next_feature()) {

  my($id) = $gff_feature->has_tag('ID')? $gff_feature->get_tag_values('ID')
                                       : $gff_feature->get_tag_values('Parent');

  # look up the feature
  if ($gff_feature->has_tag('ID') && !($id eq $gff_feature->seq_id) && !($gff_feature->seq_id eq '.')){
    ($feature{$id}) = Chado::Feature->search(name => $gff_feature->seq_id);

    unless ($feature{$id}) {
      warn "\n" . "*" x 72 ."\n";
      warn "Unable to find a source feature id for the reference sequence in this line:\n";
      warn $gff_feature->gff_string . "\n\n";
      warn "That is, ".$gff_feature->seq_id." should either have a entry in the \n";
      warn "feature table or earlier in this GFF file and it doesn't.\n\n";
      warn "*" x 72 ."\n";
      exit 1;
    }

    #is this general, or what should really be done here?
    if(!$dbxref{$id}){
      my($chado_dbxref) = Chado::Dbxref->find_or_create({
                                                         db_id => $chado_db->id,
                                                         accession => $id,
                                                        });
      $dbxref{$id} = $chado_dbxref;
    }
  }

  cache_cvterm($gff_feature->primary_tag);
  my($chado_type) = $cvterm{$gff_feature->primary_tag};

  die $gff_feature->primary_tag . " could not be found in your cvterm table.\n".
    "Either the Sequence Ontology was incorrectly loaded,\n".
    "or this file doesn't contain GFF3" unless $chado_type;

  my $chado_feature = load_feature_locations($gff_feature,$chado_type,$id);
  $feature_count++;

  $feature{$id} = $chado_feature if $gff_feature->has_tag('ID');

  my @tags = $gff_feature->all_tags;
  foreach my $tag (@tags) {
    if($tag eq 'ID'){
      load_ID_tag($gff_feature,$chado_feature,$id);
    } elsif($tag eq 'Parent'){
      load_Parent_tag($gff_feature,$chado_feature);
    } elsif($tag eq 'Alias'){
      load_Alias_tag($gff_feature,$chado_feature);
    } elsif($tag eq 'Name'){
      load_Name_tag($gff_feature,$chado_feature);
    } elsif($tag eq 'Target'){
      load_Target_tag($gff_feature,$chado_feature);
    } elsif($tag eq 'Note'){
      load_Note_tag($gff_feature,$chado_feature);
    } elsif($tag =~ /^[A-Z]/){
      die "$0 doesn't handle '$tag' tags yet.  are you sure it's allowed by the spec?";
    } elsif($tag =~ /^[a-z]/){
      load_custom_tags($gff_feature,$chado_feature,$tag);
    }
  }

  if ($feature_count % $CACHE_SIZE == 0) {
    $_->dbi_commit foreach @transaction;
    @transaction = ();
  }

  $next_update = $progress->update($feature_count) if($feature_count > $next_update);
  $progress->update($feature_count) if($feature_count >= $next_update);
  $progress->update($linecount) if($next_update >= $linecount);
}

$_->dbi_commit foreach @transaction;
$gffio->close();

print "\n$feature_count features added\n";

my $seqs_loaded = load_sequences();
print "\n$seqs_loaded sequences added\n";
print "Done\n";




sub load_custom_tags {
   my $gff_feature = shift;
   my $chado_feature = shift;
   my $tag = shift;

   my @d = $gff_feature->get_tag_values($tag);

   if(0){
   } elsif($tag eq 'description'){
     foreach my $d (@d){
       my($featureprop) = Chado::Featureprop->find_or_create({
                                                              feature_id => $chado_feature->id,
                                                              type_id    => $cvterm{description}->id,
                                                              value      => $d,
                                                             });
#        if(length($d) < 256){
#          my($synonym) = Chado::Synonym->find_or_create({
#                                                         name         => $d,
#                                                         synonym_sgml => $d,
#                                                         type_id      => $cvterm{description}->id
#                                                        });

#          my($feature_synonym) = Chado::Feature_Synonym->find_or_create ({
#                                                                          synonym_id => $synonym->id,
#                                                                          feature_id => $chado_feature->id,
#                                                                          pub_id     => $pub->id
#                                                                         });
#          push @transaction, ($synonym,$feature_synonym);
#        }
       push @transaction, ($featureprop);
     }
   } elsif($tag =~ /^db:/){
     $tag =~ s/^db:/DB:/;

     my($db) = Chado::Db->search(name => $tag);
     if(!$db){
       $db = Chado::Db->find_or_create({name       => $tag,
                                        contact_id => $nullcontact,
                                       });
     }
     die "couldn't create db $db" unless $db;
     push @transaction, $db;

     foreach my $d (@d){
       my($dbxref) = Chado::Dbxref->find_or_create({db_id => $db->id,
                                                   accession => $d
                                                  });
       my($feature_dbxref) = Chado::Feature_Dbxref->find_or_create({
                                                                    feature_id => $chado_feature->id,
                                                                    dbxref_id => $dbxref->id,
                                                                  });
       push @transaction, ($dbxref, $feature_dbxref);
     }

   } elsif($tag =~ /^cvterm:(.+)/){
     foreach my $d (@d){
       my($dbxref) = Chado::Dbxref->search(accession => $d);
       $progress->message("couldn't find cvterm: $d") and next unless $dbxref;
       my($cvterm) = Chado::Cvterm->search(dbxref_id => $dbxref->id);

       next unless $cvterm;

       my($feature_cvterm) = Chado::Feature_Cvterm->find_or_create({
                                                                    feature_id => $chado_feature->id,
                                                                    cvterm_id => $cvterm->id,
                                                                    pub_id => $nullpub->id,
                                                                   });
       push @transaction, $feature_cvterm;
     }
   } elsif($tag eq 'completeness'){
     #fix fix fix
   } else {
        unless (defined $cvterm{$tag}) {
            cache_cvterm($tag);
            warn "Data with the $tag tag are being placed in the featureprop table\n";
        }

        foreach my $d (@d) {
            my ($featureprop) = Chado::Featureprop->find_or_create(
                {
                    feature_id => $chado_feature->id,
                    type_id    => $cvterm{$tag}->id,
                    value      => $d,
                }
            );

            push @transaction, $featureprop;
        }
   }
}

sub load_ID_tag {
  my $gff_feature = shift;
  my $chado_feature = shift;
  my $id = shift;

  #i don't think this cost of clogging up
  #the synonym table is worth making searches
  #easier.
  #
  #if you want a synonym, use an Alias tag.
  #searches need to look in two places
  #(feature and synonym) for primary and
  #secondary IDs
  #if($gff_feature->has_tag('ID')){
  #  my($chado_synonym1) = Chado::Synonym->find_or_create({
  #                                                        name         => $id,
  #                                                        synonym_sgml => $id,
  #                                                        type_id      => $cvterm{synonym}->id
  #                                                       });
  #
  #  my($chado_synonym2) = Chado::Feature_Synonym->find_or_create ({
  #                                                                 synonym_id => $chado_synonym1->id,
  #                                                                 feature_id => $chado_feature->id,
  #                                                                 pub_id     => $pub->id
  #                                                                });
  #
  #  push @transaction, $chado_synonym1;
  #  push @transaction, $chado_synonym2;
  #}
}

sub load_Note_tag {
    my $gff_feature   = shift;
    my $chado_feature = shift;
                                                                                
    cache_cvterm('Note') unless (defined $cvterm{'Note'});
                                                                                
    my @d = $gff_feature->get_tag_values('Note');
                                                                                
    foreach my $d (@d) {
        my ($featureprop) = Chado::Featureprop->find_or_create(
            {
                feature_id => $chado_feature->id,
                type_id    => $cvterm{'Note'}->id,
                value      => $d,
            }
        );
    }
}

sub load_Target_tag {
  my $gff_feature = shift;
  my $chado_feature = shift;

  if($gff_feature->has_tag('Target')) {
    my @targets = $gff_feature->get_tag_values('Target');
    foreach my $target (@targets) {
      my ($tstart,$tend);
      if ($target =~ /^(\S+?)\+(\d+)\+(\d+)$/) {
        ($target,$tstart,$tend) = ($1,$2,$3); 
      } else {
        die "your Target attribute seems to be improperly formated";
      }

      my($chado_synonym1) = Chado::Synonym->find_or_create({
                                                            name         => $target,
                                                            synonym_sgml => $target,
                                                            type_id      => $cvterm{synonym}->id
                                                           });

      my($chado_synonym2) = Chado::Feature_Synonym->find_or_create ({
                                                                     synonym_id => $chado_synonym1->id,
                                                                     feature_id => $chado_feature->id,
                                                                     pub_id     => $pub->id,
                                                                    });

      my($chado_featureloc) = Chado::Featureloc->find_or_create({
                                                                 feature_id    => $chado_feature->id,
                                                                 srcfeature_id => $chado_feature->id,
                                                                 fmin          => $tstart,
                                                                 fmax          => $tend,
                                                                 rank          => 1 
                                                                });

      my($chado_featureprop) = Chado::Featureprop->find_or_create({
                                                                   feature_id => $chado_feature->id,
                                                                   type_id    => $cvterm{score}->id,
                                                                   value      => $gff_feature->score
                                                                  });

      push @transaction, $chado_synonym1;
      push @transaction, $chado_synonym2;
      push @transaction, $chado_featureloc;
      push @transaction, $chado_featureprop;
    }
  }
}

sub load_Parent_tag {
  my $gff_feature = shift;
  my $chado_feature = shift;

  if($gff_feature->has_tag('Parent')){
    my @parents = $gff_feature->get_tag_values('Parent');
    foreach my $parent (@parents) {

      my $reltype = $gff_feature->primary_tag eq 'protein' ? $cvterm{develops_from} : $cvterm{part_of};

      #unhandled exception: what if $feature{$parent} hasn't been seen yet?
      my $chado_feature_relationship = Chado::Feature_Relationship->find_or_create({
                                                                                    subject_id => $chado_feature->id,
                                                                                    object_id => $feature{$parent}->id,
                                                                                    type_id => $reltype,
                                                                                   });
      push @transaction, $chado_feature_relationship;
    }
  }
}

sub load_Alias_tag {
  my $gff_feature = shift;
  my $chado_feature = shift;

  if($gff_feature->has_tag('Alias')) {
    my @aliases;
    if($gff_feature->has_tag('Alias')) { push @aliases, $gff_feature->get_tag_values('Alias'); }
    foreach my $alias (@aliases) {
      #create the synonym
      my($chado_synonym1) = Chado::Synonym->find_or_create({
                                                            name         => $alias,
                                                            synonym_sgml => $alias,
                                                            type_id      => $cvterm{synonym}->id
                                                           });

      #and link it to the feature via feature_synonym
      my($chado_synonym2) = Chado::Feature_Synonym->find_or_create ({
                                                                     synonym_id => $chado_synonym1->id,
                                                                     feature_id => $chado_feature->id,
                                                                     pub_id     => $pub->id,
                                                                    });
      push @transaction, $chado_synonym1;
      push @transaction, $chado_synonym2;
    }
  }
}

sub load_Name_tag {
  my $gff_feature = shift;
  my $chado_feature = shift;

  if($gff_feature->has_tag('Name')) {
    my @names = $gff_feature->get_tag_values('Name');
    foreach my $name (@names) {
      my($chado_synonym1) = Chado::Synonym->find_or_create({
                                                            name         => $name,
                                                            synonym_sgml => $name,
                                                            type_id      => $cvterm{synonym}->id
                                                           });

      my($chado_synonym2) = Chado::Feature_Synonym->find_or_create ({
                                                                     synonym_id => $chado_synonym1->id,
                                                                     feature_id => $chado_feature->id,
                                                                     pub_id     => $pub->id,
                                                                    });
      push @transaction, $chado_synonym1;
      push @transaction, $chado_synonym2;
    }
  }
}


sub initialize {

  GetOptions('organism:s'       => \$ORGANISM,
             'srcdb:s'          => \$SRC_DB,
             'gfffile:s'        => \$GFFFILE,
             'cache:s'          => \$CACHE_SIZE,
             'force'            => \$FORCE_LOAD,
            ) or (system('pod2text',$0), exit -1); 

  $ORGANISM   ||='Human';
  $SRC_DB     ||= 'DB:refseq';
  $CACHE_SIZE ||= 1000;

  die "\nYou must specify a GFF file\n" unless $GFFFILE;

  #deal with GFF3 files that contain sequence
  # this is ugly, ugly, ugly, but in addtion to dealing with
  # sequence, it also fixes Allen's method of tracking progress
  die "$GFFFILE does not exist" unless (-e $GFFFILE);

  my $linenumber = `grep -n "^>" $GFFFILE`;
  if ($linenumber =~ /^(\d+)/) {
    $linenumber = $1;
    system("tail +$linenumber $GFFFILE > $TMPFASTA");
    $linenumber -= 1;
    system("head -$linenumber $GFFFILE > $TMPGFF");

    #we don't want to do this, as the filename is used in a pub record
    #$GFFFILE = $TMPGFF;
  } else {
    $TMPGFF = $GFFFILE;
  }

  #count the file lines.  we need this to track load progress
  open(WC,"grep -c -v '^#' $TMPGFF |");
#  open(WC,"grep -c -v '^#' $GFFFILE |");
  $linecount = <WC>; chomp $linecount;
  close(WC);
  ($linecount) = $linecount =~ /^\s*?(\d+)/;

  $progress = Term::ProgressBar->new({name => "Approx $linecount features", count => $linecount,
                                      ETA => 'linear', });
  $progress->max_update_rate(1);
  $next_update = 0;

  Chado::LoadDBI->init();
  ($cv) = Chado::Cv->find_or_create({
                                     name       => 'autocreated',
                                     definition => 'auto created by load_gff3.pl'
                                    });

  # find needed cvterm and other pieces of information
  my @needed_cvterms = qw(description synonym region note develops_from part_of gff_file score protein);
  foreach my $n (@needed_cvterms){
    cache_cvterm($n);
  }

  ($chado_organism) = Chado::Organism->search(common_name => $ORGANISM );
  ($chado_db)       = Chado::Db->search(name => $SRC_DB);
  ($nullpub)        = Chado::Pub->search(miniref => 'null');
  ($nullcontact)    = Chado::Contact->search(name => 'null');

  die "The organism '$ORGANISM' could not be found. Did you spell it correctly?"
    unless $chado_organism;

  die "The database '$SRC_DB' could not be found. Did you spell it correctly?"
    unless $chado_db;
}

sub load_segments {
  my $gffio = shift;
  my $i = 0;
  # creates the features for each gff segment
  while(my $gff_segment = $gffio->next_segment()) {
    my ($segment) = Chado::Feature->search({name => $gff_segment->display_id});
    if(!$segment){
      my $f = Chado::Feature->create({
                                      organism_id => $chado_organism,
                                      name        => $gff_segment->display_id,
                                      uniquename  => $gff_segment->display_id .'_region',
                                      type_id     => $cvterm{'region'},
                                      seqlen      => $gff_segment->end
                                     });

      $i++;
      $f->dbi_commit;
      $feature{$f->name} = $f;
    } else {
      $feature{$segment->name} = $segment;
    }
  }
  return $i;
}

sub load_sequences {
  my $seqs_loaded = 0;

  if (-e $TMPFASTA) {
    Chado::Feature->set_sql(update_residues => qq{UPDATE feature SET residues = residues || ? WHERE feature_id = ?});
    my $sth = Chado::Feature->sql_update_residues;

    print STDERR "loading sequence data...\n";

    #count the file lines.  we need this to track load progress
    open(WC,"grep -c '^>' $TMPFASTA |");
    $linecount = <WC>; chomp $linecount;
    close(WC);
    ($linecount) = $linecount =~ /^\s*?(\d+)/;

    $progress = Term::ProgressBar->new({name => "Approx $linecount sequences", count => $linecount,
                                        ETA => 'linear', });
    $progress->max_update_rate(1);
    $next_update = 0;

    my $in = Bio::SeqIO->new(-file => $TMPFASTA, '-format' => 'Fasta');
    while (my $seq = $in->next_seq() ) {
      my $name = $seq->id;
      my @chado_feature = Chado::Feature->search({'name' => $name});

      #no, let's just load the sequence into all of them
      #die "couldn't uniquely identify the sequence identified by $name"
      #  unless (scalar @chado_feature == 1);
      print STDERR "no feature for sequence $name\n" unless scalar(@chado_feature);
      print STDERR "multiple features for sequence $name\n" if scalar(@chado_feature) > 1;

      foreach my $f (@chado_feature){

        $f->residues('');
        $f->update;
        $f->dbi_commit;

        my $dna = $seq->seq;
        my $shredsize = 100_000_000; #don't increase this...
        my $offset = 0;
        my $dnalen = length($dna);

        while($offset < $dnalen){
          my $shred = substr($dna,$offset,$shredsize);
          $sth->execute($shred,$f->id);

          $offset += $shredsize;
        }

        $f->update;
        $f->dbi_commit;

      }
      $seqs_loaded++;

      $next_update = $progress->update($seqs_loaded) if($seqs_loaded > $next_update);
      $progress->update($seqs_loaded) if($seqs_loaded >= $next_update);
      $progress->update($linecount) if($next_update >= $linecount);

    }

    unlink $TMPFASTA unless $TMPFASTA eq $GFFFILE;
    unlink $TMPGFF   unless $TMPGFF   eq $GFFFILE;
  }

  return $seqs_loaded;
}

sub load_feature_locations {
  my $gff_feature = shift;
  my $chado_type = shift;
  my $id = shift;

  ## GFF features are base-oriented, so we must add 1 to the diff
  ## between the end base and the start base, to get the number of
  ## intervening bases between the start and end intervals
  my $seqlen = ($gff_feature->end - $gff_feature->start) + 1;

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
  my $fmin = $gff_feature->start -1;    # GFF -> InterBase
  my $fmax = $gff_feature->end;

  my $uniquename = undef;
  if($gff_feature->primary_tag && $gff_feature->seq_id && $fmax ne '.'){
    $uniquename = '_'. $gff_feature->primary_tag .'_'. $gff_feature->seq_id .":$fmin..$fmax";
  } elsif($gff_feature->primary_tag && $gff_feature->seq_id){
    $uniquename = '_'. $gff_feature->primary_tag .'_'. $gff_feature->seq_id;
  }

  my $chado_feature;
  if ($gff_feature->has_tag('ID')) {
    ($chado_feature) = Chado::Feature->find_or_create({
      organism_id  => $chado_organism,
      name         => $id,
      uniquename   => $id . $uniquename,
      type_id      => $chado_type->id,
      seqlen       => $seqlen
                                                      });
  } else {
    ($chado_feature) = Chado::Feature->find_or_create({
      organism_id  => $chado_organism,
      uniquename   => $uniquename,
      type_id      => $chado_type->id,
      seqlen       => $seqlen
                                                      });
  }

  push @transaction, $chado_feature;
  return($chado_feature) if $id eq $gff_feature->seq_id or $gff_feature->seq_id eq '.'; #ie, this is a srcfeature (ie, fref) so only create the feature

  $chado_feature->dbxref_id($dbxref{$id}) if $gff_feature->has_tag('ID'); # is this the right thing to do here?
  $chado_feature->update; # flush updates to this feature object

  my $frame = $gff_feature->frame eq '.' ? 0 : $gff_feature->frame;

  # add feature location
  my $chado_featureloc = Chado::Featureloc->find_or_create({
      feature_id    => $chado_feature->id,
      fmin          => $fmin,
      fmax          => $fmax,
      strand        => $gff_feature->strand,
      phase         => $frame,
      rank          => $featureloc_rank{$chado_feature->id} || 0,
      srcfeature_id => $feature{$id}->id,
                                      });

  push @transaction, $chado_featureloc;

  $featureloc_rank{$chado_feature->id}++;
  return($chado_feature);
}

sub cache_cvterm {
  my $name = shift;

  #we need an ontology source check here.  GO has an obsolete term for 'protein', but we want the
  #one from SO.

  ($cvterm{$name}) = Chado::Cvterm->search(name => $name) || Chado::Cvterm->search(name => ucfirst($name));
    $cvterm{$name} = $cvterm{$name}->next() if defined($cvterm{$name}) and $cvterm{$name}->isa('Class::DBI::Iterator');
    unless($cvterm{$name}){
      ($cvterm{$name}) = Chado::Cvterm->find_or_create({
                                                     name       => $name,
                                                     cv_id      => $cv->id,
                                                     definition => 'autocreated by gmod_load_gff3.pl',
                                                    });
    }
    die "unable to create a '$name' entry in the cvterm table" unless $cvterm{$name};
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
chdir $origdir;

