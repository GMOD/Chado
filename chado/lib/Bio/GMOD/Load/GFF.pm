package Bio::GMOD::Load::GFF;
use strict;
use Bio::SeqIO;
use lib '../../../lib';
use Chado::AutoDBI;
use Chado::LoadDBI;
use Data::Dumper;
use File::Temp qw(tempfile);

=head1 NAME

Bio::GMOD::Load::GFF - loads GFF3 data to a chado database

=head1 SYNOPSIS

  my $loader = Bio::GMOD::Load::GFF->new(
                gfffile  => '/usr/local/gmod/src/gff/yeast.gff',
                organism => 'yeast',
                src_db   => 'DB:SGD'
              );

=head1 AUTHORS
                                                                                          
Scott Cain E<lt>cain@cshl.orgE<gt>
                                                                                          
Copyright (c) 2004
                                                                                          
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 APPENDIX
                                                                                
The rest of the documentation details each of the object
methods. 

=cut


use vars qw( @ISA );

@ISA = qw( Bio::GMOD::Load );

use constant DEBUG => 0;

sub new {
    my $proto = shift;
    my $self = bless {}, ref($proto) || $proto;

    my %arg = @_;

    $self->gfffile($arg{'gfffile'});
    $self->organism($arg{'organism'});
    $self->src_db($arg{'src_db'});
    $self->cache_size($arg{'cache_size'});
    $self->force_load($arg{'force'});

    my ( undef, $TMPFASTA ) = tempfile( $arg{'pid'}, ".fa",  SUFFIX => '.fa' );
    my ( undef, $TMPGFF )   = tempfile( $arg{'pid'}, ".gff", SUFFIX => '.gff' );
   
    $self->tmpfasta($TMPFASTA);
    $self->tmpgff($TMPGFF); 

    $self->transaction(); #initialize transaction queue


    $self->initialize(); #handles all kinds of stuff
    return $self;
}

=head2 force_load

=over

=item Usage

  $obj->force_load()        #get existing value
  $obj->force_load($newval) #set new value

=item Function

=item Returns

value of force_load (a scalar)

=item Arguments

new value of force_load (to set)

=back

=cut

sub force_load {
    my $self = shift;
    return $self->{'force_load'} = shift if defined(@_);
    return $self->{'force_load'};
}


=head2 cache_size

=over

=item Usage

  $obj->cache_size()        #get existing value
  $obj->cache_size($newval) #set new value

=item Function

=item Returns

value of cache_size (a scalar)

=item Arguments

new value of cache_size (to set)

=back

=cut

sub cache_size {
    my $self = shift;
    return $self->{'cache_size'} = shift if defined(@_);
    return $self->{'cache_size'};
}

=head2 commit_cache

=over

=item Usage

  $obj->commit_cache()

=item Function

=item Returns

=item Arguments

=back

=cut

sub commit_cache {
    my $self = shift;
    $self->transaction();
    return;
}


=head2 gfffile

=over

=item Usage

  $obj->gfffile()        #get existing value
  $obj->gfffile($newval) #set new value

=item Function

=item Returns

value of gfffile (a scalar)

=item Arguments

new value of gfffile (to set)

=back

=cut

sub gfffile {
    my $self = shift;
    return $self->{'gfffile'} = shift if defined(@_);
    return $self->{'gfffile'};
}

=head2 organism

=over

=item Usage

  $obj->organism()        #get existing value
  $obj->organism($newval) #set new value

=item Function

=item Returns

value of organism (a scalar)

=item Arguments

new value of organism (to set)

=back

=cut

sub organism {
    my $self = shift;
    return $self->{'organism'} = shift if defined(@_);
    return $self->{'organism'};
}

=head2 src_db

=over

=item Usage

  $obj->src_db()        #get existing value
  $obj->src_db($newval) #set new value

=item Function

=item Returns

value of src_db (a scalar)

=item Arguments

new value of src_db (to set)

=back

=cut

sub src_db {
    my $self = shift;
    return $self->{'src_db'} = shift if defined(@_);
    return $self->{'src_db'};
}

=head2 transaction

=over

=item Usage

  $obj->transaction()        #commits current transactions and
                             #clears transaction queue
  $obj->transaction($newval) #adds object to transaction queue

=item Function

Handles the transaction queue.  When called with no arguments, it
commits any Class::DBI transactions that are currently in the queue
and empties the queue.  When called with a Class::DBI object, it adds
the object to the commit queue. 

=item Returns

Nothing

=item Arguments

See function above

=back

=cut

sub transaction {
    my $self = shift;
    my $arg  = shift;

    if ($arg) { # add it to the queue
        push @{$self->{'transaction'}}, $arg;

    } else {  # do the commit and flush the queue
        $_->dbi_commit foreach @{$self->{'transaction'}}; 
        @{$self->{'transaction'}} = ();
    }

    return $self->{'transaction'} = shift if defined(@_);
    return $self->{'transaction'};
}


=head2 tmpfasta

=over

=item Usage

  $obj->tmpfasta()        #get existing value
  $obj->tmpfasta($newval) #set new value

=item Function

=item Returns

value of tmpfasta (a scalar)

=item Arguments

new value of tmpfasta (to set)

=back

=cut

sub tmpfasta {
    my $self = shift;
    return $self->{'tmpfasta'} = shift if defined(@_);
    return $self->{'tmpfasta'};
}

=head2 tmpgff

=over

=item Usage

  $obj->tmpgff()        #get existing value
  $obj->tmpgff($newval) #set new value

=item Function

=item Returns

value of tmpgff (a scalar)

=item Arguments

new value of tmpgff (to set)

=back

=cut

sub tmpgff {
    my $self = shift;
    return $self->{'tmpgff'} = shift if defined(@_);
    return $self->{'tmpgff'};
}


=head1 load_custom_tags

Handles inserting non-reserved tags into chado.  Determines if the tag
falls into a short list of tags for custom handling and deals with them
appropriately.  If the tag is not on the list, the information is placed 
in the featureprop table.

=cut

sub load_custom_tags {
    my $self          = shift;
    my $gff_feature   = shift;
    my $chado_feature = shift;
    my $tag           = shift;

    my @d = $gff_feature->get_tag_values($tag);

    if (0) {
    }
    elsif ( $tag eq 'description' ) {
        foreach my $d (@d) {

            my ($featureprop) = Chado::Featureprop->find_or_create(
                {
                    feature_id => $chado_feature->id,
                    type_id    => $self->cache_cvterm('description')->id,
                    value      => $d,
                }
            );

            $self->transaction($featureprop);
        }
    }
    elsif ( $tag =~ /^db:/ ) {
        $tag =~ s/^db:/DB:/;

        my ($db) = Chado::Db->search( name => $tag );
        if ( !$db ) {
            $db = Chado::Db->find_or_create(
                {
                    name       => $tag,
                    contact_id => $self->nullcontact()->id,
                }
            );
        }
        die "couldn't create db $db" unless $db;
        $self->transaction($db);

        foreach my $d (@d) {
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
            $self->transaction( $dbxref );
            $self->transaction( $feature_dbxref );
        }

    }
    else {
        foreach my $d (@d) {
            my ($featureprop) = Chado::Featureprop->find_or_create(
                {
                    feature_id => $chado_feature->id,
                    type_id    => $self->cache_cvterm($tag)->id,
                    value      => $d,
                }
            );

            $self->transaction($featureprop);
        }
    }
}

=pod

=head1 load_Ontology_term

Loads ontology terms to feature_cvterm.

=cut

sub load_Ontology_term {
    my $self          = shift;
    my $gff_feature   = shift;
    my $chado_feature = shift;
    my $tag           = shift;
                                                                                
    my @d = $gff_feature->get_tag_values($tag);

    foreach my $d (@d) {
        my ($dbxref) = Chado::Dbxref->search( accession => $d );
        warn "couldn't find cvterm in dbxref: $d" and next
          unless $dbxref;
        my ($cvterm) = Chado::Cvterm->search( dbxref_id => $dbxref->id );
                                                                                
        next unless $cvterm;
                                                                                
        my ($feature_cvterm) = Chado::Feature_Cvterm->find_or_create(
            {
                feature_id => $chado_feature->id,
                cvterm_id  => $cvterm->id,
                pub_id     => $self->nullpub()->id,
            }
        );
        $self->transaction($feature_cvterm);
    }
}

=pod

=head1 load_Note_tag

Loads Note tag values to the featureprop table.

=cut

sub load_Note_tag {
    my $self          = shift;
    my $gff_feature   = shift;
    my $chado_feature = shift;

    my @d = $gff_feature->get_tag_values('Note');

    foreach my $d (@d) {
        my ($featureprop) = Chado::Featureprop->find_or_create(
            {
                feature_id => $chado_feature->id,
                type_id    => $self->cache_cvterm('Note')->id,
                value      => $d,
            }
        );
    }
}

=pod

=head1 load_Target_tag

Loads Target values.  These are used for alignment information.

=cut

sub load_Target_tag {
    my $self          = shift;
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
                    type_id      => $self->cache_cvterm('synonym')->id
                }
            );

            my ($chado_synonym2) = Chado::Feature_Synonym->find_or_create(
                {
                    synonym_id => $chado_synonym1->id,
                    feature_id => $chado_feature->id,
                    pub_id     => $self->pub()->id,
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
                    type_id    => $self->cache_cvterm('score')->id,
                    value      => $gff_feature->score
                }
            );

            $self->transaction( $chado_synonym1 );
            $self->transaction( $chado_synonym2 );
            $self->transaction( $chado_featureloc );
            $self->transaction( $chado_featureprop );
        }
    }
}

=pod

=head1 load_Parent_tag

Loads Parent tag values.  These are used to denote a parent feature
of the given feature.

=cut

sub load_Parent_tag {
    my $self          = shift;
    my $gff_feature   = shift;
    my $chado_feature = shift;

    if ( $gff_feature->has_tag('Parent') ) {
        my @parents = $gff_feature->get_tag_values('Parent');
        foreach my $parent (@parents) {

            my $reltype =
                ( $gff_feature->primary_tag eq 'protein' ||
                  $gff_feature->primary_tag eq 'polypeptide' )
              ? $self->cache_cvterm('develops_from')
              : $self->cache_cvterm('part_of');

           #unhandled exception: what if $feature{$parent} hasn't been seen yet?
            $self->feature($parent, Chado::Feature->search( name => $parent ))
              unless $self->feature($parent);

            my $chado_feature_relationship =
              Chado::Feature_Relationship->find_or_create(
                {
                    subject_id => $chado_feature->id,
                    object_id  => $self->feature($parent)->id,
                    type_id    => $reltype,
                }
              );
            $self->transaction( $chado_feature_relationship );
        }
    }
}

=pod

=head1 load_Alias_tag

Loads Alias tag values.  These are used for synonyms.

=cut

sub load_Alias_tag {
    my $self          = shift;
    my $gff_feature   = shift;
    my $chado_feature = shift;

    if ( $gff_feature->has_tag('Alias') ) {
        my @aliases;
        if ( $gff_feature->has_tag('Alias') ) {
            push @aliases, $gff_feature->get_tag_values('Alias');
        }
        foreach my $alias (@aliases) {

            #create the synonym
            my ($chado_synonym1) = Chado::Synonym->find_or_create(
                {
                    name         => $alias,
                    synonym_sgml => $alias,
                    type_id      => $self->cache_cvterm('synonym')->id
                }
            );

            #and link it to the feature via feature_synonym
            my ($chado_synonym2) = Chado::Feature_Synonym->find_or_create(
                {
                    synonym_id => $chado_synonym1->id,
                    feature_id => $chado_feature->id,
                    pub_id     => $self->pub()->id,
                }
            );
            $self->transaction( $chado_synonym1 );
            $self->transaction( $chado_synonym2 );
        }
    }
}

=pod

=head1 load_Name_tag

Loads Name tag values.

=cut

sub load_Name_tag {
    my $self          = shift;
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
        my ($chado_synonym1) = Chado::Synonym->find_or_create(
            {
                name         => $name,
                synonym_sgml => $name,
                type_id      => $self->cache_cvterm('synonym')->id
            }
        );

        my ($chado_synonym2) = Chado::Feature_Synonym->find_or_create(
            {
                synonym_id => $chado_synonym1->id,
                feature_id => $chado_feature->id,
                pub_id     => $self->pub()->id,
            }
        );
        $self->transaction( $chado_synonym1 );
        $self->transaction( $chado_synonym2 );
    }
}

sub initialize {
    my $self = shift;

    my $linenumber = `grep -n "^>" $self->gfffile()`;
    if ( $linenumber =~ /^(\d+)/ ) {
        $linenumber = $1;
        system("tail +$linenumber $self->gfffile() > ".$self->tmpfasta() );
        $linenumber -= 1;
        system("head -$linenumber $self->gfffile() > ".$self->tmpgff() );

        #we don't want to do this, as the filename is used in a pub record
        #$GFFFILE = $TMPGFF;
    }

    #count the file lines.  we need this to track load progress

    Chado::LoadDBI->init();

    # find needed cvterm and other pieces of information
    my @needed_cvterms =
      qw(description synonym region note develops_from part_of gff_file score protein);
    foreach my $n (@needed_cvterms) {
        $self->cache_cvterm($n);
    }

    unless ($self->chado_organism()) {
      warn "\n\nCouldn't find or create organism ".$self->organism().".\n";
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

    unless ($self->chado_db() ) {
      warn "\n\nCouldn't find or create database ".$self->src_DB().".\n";
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

=head2 chado_db

=over

=item Usage

  $obj->chado_db()

=item Function

=item Returns

The Class::DBI object for the row of the db table corresponding to
the current src_db; if it does not exist, it will create it.

=item Arguments

=back

=cut

sub chado_db {
    my $self = shift;
    return $self->{'chado_db'} if $self->{'chado_db'};

    ($self->{'chado_db'}) = Chado::Db->search( name => $self->src_db() );
    return $self->{'chado_db'};
}


=head2 nullpub

=over

=item Usage

  $obj->nullpub()

=item Function

=item Returns

The Class::DBI object for the 'null publication' row of the pub table;
if it doesn't exist, it will create it.

=item Arguments

=back

=cut

sub nullpub {
    my $self = shift;
    return $self->{'nullpub'} if $self->{'nullpub'};

    ($self->{'nullpub'}) = Chado::Pub->search( miniref => 'null' );
    return $self->{'nullpub'};
}


=head2 nullcontact

=over

=item Usage

  $obj->nullcontact()

=item Function

=item Returns

The Class::DBI object for the null contact in the --- table;
if it does not already exist, it will attempt to create it.

=item Arguments

=back

=cut

sub nullcontact {
    my $self = shift;
    return $self->{'nullcontact'} if $self->{'nullcontact'};
   
    ($self->{'nullcontact'}) = Chado::Contact->search( name => 'null' ); 
    return $self->{'nullcontact'};
}


=head2 chado_organism

=over

=item Usage

  $obj->chado_organism()

=item Function

=item Returns

Returns the Class::DBI object for the current organism table row;
if it does not exist, it will attempt to create it.

=item Arguments

None

=back

=cut

sub chado_organism {
    my $self = shift;
    return $self->{'chado_organism'} if $self->{'chado_organism'};


    ($self->{'chado_organism'}) = Chado::Organism->search( common_name => lc($self->organism() ));
    ($self->{'chado_organism'}) = Chado::Organism->search( abbreviation => ucfirst($self->organism()))
        unless($self->{'chado_organism'} );
    ($self->{'chado_organism'}) = Chado::Organism->search( genus => $self->organism()  )
        unless($self->{'chado_organism'} );
    return $self->{'chado_organism'};
}


sub load_segments {
    my $self  = shift;
    my $gffio = shift;
    my $i     = 0;

    # creates the features for each gff segment
    while ( my $gff_segment = $gffio->next_segment() ) {
        my ($segment) =
          Chado::Feature->search( { name => $gff_segment->display_id } );
        if ( !$segment ) {

# about uniquenames here: since these are coming from ##sequence_region
# meta stuff in the header, there will be no uniquename attribute, so the
# only thing to do is to generate one.

            my $f = Chado::Feature->create(
                {
                    organism_id => $self->chado_organism()->id,
                    name        => $gff_segment->display_id,
                    uniquename  => $gff_segment->display_id . '_region',
                    type_id     => $self->cache_cvterm('region'),
                    seqlen      => $gff_segment->end
                }
            );

            $i++;
            $f->dbi_commit;
            $self->srcfeature($f->name, $f);
        }
        else {
            $self->srcfeature($segment->name, $segment);
        }
    }
    return $i;
}

sub load_sequences {
    my $self = shift;
    my $seqs_loaded = 0;

    if ( -e $self->tmpfasta() ) {
        Chado::Feature->set_sql( update_residues =>
          qq{UPDATE feature SET residues = residues || ? WHERE feature_id = ?}
        );
        my $sth = Chado::Feature->sql_update_residues;

        print STDERR "loading sequence data...\n";

        my $in = Bio::SeqIO->new( -file => $self->tmpfasta() , '-format' => 'Fasta' );
        while ( my $seq = $in->next_seq() ) {
            my $name          = $seq->id;
            my @chado_feature = Chado::Feature->search( { 'name' => $name } );

            #no, let's just load the sequence into all of them
            #die "couldn't uniquely identify the sequence identified by $name"
            #  unless (scalar @chado_feature == 1);
            warn "no feature for sequence $name"
              unless scalar(@chado_feature);
            warn "multiple features for sequence $name\n"
              if scalar(@chado_feature) > 1;

            foreach my $f (@chado_feature) {

                $f->residues('');
                $f->update;
                $f->dbi_commit;

                warn "copying Bio::Seq sequence to simple scalar variable" if DEBUG;
                my $dna       = $seq->seq;
                undef $seq;                     #get this thing out of here ASAP, it's using memory
                warn "copied.  Bio::Seq object purged to conserve memory" if DEBUG;

                my $shredsize = 100_000_000;    #don't increase this...
                my $offset    = 0;
                my $dnalen    = length($dna);

                while ( $offset < $dnalen ) {
                    warn "loading shred.  offset: $offset bp" if DEBUG;
                    my $shred = substr( $dna, $offset, $shredsize );
                    warn "${offset}bp loaded" if $offset > 0 and DEBUG;
                    $sth->execute( $shred, $f->id );
                    warn "loaded shred" if DEBUG;

                    $offset += $shredsize;
                }

                warn "${dnalen}bp loaded" if DEBUG;
                $f->update;

                warn "pre dbi_commit" if DEBUG;
                $f->dbi_commit;
                warn "post dbi_commit" if DEBUG;

            }
            $seqs_loaded++;

        }

        unlink $self->tmpfasta() unless $self->tmpfasta() eq $self->gfffile();
        unlink $self->tmpgff()   unless $self->tmpgff()   eq $self->gfffile();
    }

    return $seqs_loaded;
}

sub load_feature_locations {
    my $self        = shift;
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
    # 1. else, if ID tag available, use its value
    # 2. else, use a combination of GFF objects primary tag, seq_id, and, if available,
    #    positional information.
    # 3. die, not enough information to generate a uniquename
    #
    # NAME
    #
    # 1. use Name tag if available
    # 2. else, use ID tag if available
    # 3. else, feature has no name
    #
    my $uniquename = '';
    my $name       = '';

    if( $gff_feature->has_tag('ID') ) {
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
        organism_id => $self->chado_organism()->id,
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

    $self->transaction( $chado_feature );

    if ($used_ID_for_Name)   {
        load_Name_tag ($gff_feature, $chado_feature);
    }

    my $source = $gff_feature->source_tag();
    if ( $source && $source ne '.') { #make source a feature prop

        unless ($self->gff_source_db() ) {#create a new db for keeping GFF sources
            $self->gff_source_db( Chado::Db->find_or_create( {
                name        => 'GFF_sources',
                contact_id  => $self->nullcontact()->id,
                description => 'A collection of sources (ie, column 2) from GFF files',
            } ) );

            $self->transaction( $self->gff_source_db() );
        }

        unless ($self->gff_source($source)) { #now make a dbxref for the source
            $self->gff_source($source, 
                              Chado::Dbxref->find_or_create( {
                                 db_id     => $self->gff_source_db()->id,
                                 accession => $source,
                              } ) );
            $self->transaction( $self->gff_source($source) );
        }

        #now tie feature and source together in feature_dbxref
        my $feature_dbxref = Chado::Feature_Dbxref->find_or_create( {
            feature_id => $chado_feature->id,
            dbxref_id  => $self->gff_source($source)->id
        }); 
        $self->transaction( $feature_dbxref );
    }

    if ( $id eq $gff_feature->seq_id
        or $gff_feature->seq_id eq '.' ) {
      #ie, this is a srcfeature (ie, fref) so only create the feature
        $self->srcfeature($gff_feature->seq_id, $chado_feature);
        return ($chado_feature);
    }

    $chado_feature->dbxref_id( $self->dbxref($id) )
        if $gff_feature->has_tag('ID');         # is this the right thing to do here?
    $chado_feature->update;                     # flush updates to this feature object


    # find pre-existing feature locations that were loaded prior
    # to this GFF3 file.
    if(!$self->featureloc_locgroup( $chado_feature->id ) ){
      my $max_locgroup = undef;
      foreach my $previous_featureloc (Chado::Featureloc->search(
        feature_id => $chado_feature->id,
      )){
        if($fmin == $previous_featureloc->fmin and
           $fmax == $previous_featureloc->fmax and
           $previous_featureloc->srcfeature_id == $self->srcfeature($gff_feature->seq_id)->id
          ){
          return $chado_feature;
        }

        $max_locgroup = $max_locgroup > $previous_featureloc->locgroup ? $max_locgroup : $previous_featureloc->locgroup;
      }

      if(defined($max_locgroup)){
        $self->featureloc_locgroup( $chado_feature->id , $max_locgroup);
      }
    }

    # add feature location
    $self->featureloc_locgroup($chado_feature->id , 
                               $self->featureloc_locgroup($chado_feature->id)+1 );

    my $locgroup =  $self->featureloc_locgroup( $chado_feature->id );
    my($parent) = $gff_feature->has_tag('Parent') ? $gff_feature->get_tag_values('Parent') : ();

    if($parent && $self->featureloc_locgroup( $self->feature($parent) )){
        $locgroup = $self->featureloc_locgroup( $self->feature($parent) );
    }

    $locgroup ||= 0;

    if (DEBUG) {
        warn "adding featureloc for gff string:";
        warn "\t".$gff_feature->gff_string;
#	print STDERR $chado_feature->id , "\t" , $locgroup , "\n";

        if($parent){
            warn "srcfeature_id: " . Dumper($self->feature($parent));
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
            srcfeature_id => $self->srcfeature($gff_feature->seq_id)->id,
        }
    );

    $self->transaction( $chado_featureloc );

    return ($chado_feature);
}


=head2 pub

=over

=item Usage

  $obj->pub()        #get existing value
  $obj->pub($newval) #set new value

=item Function

When called with a 'uniqified' gff file name, creates an entry
in the pub table; on subsequent calls with no argument, it returns
the Class::DBI object for that table entry.

=item Returns

value of pub (a scalar)

=item Arguments

new value of pub (to set)

=back

=cut

sub pub {
    my $self = shift;

    if (defined @_) {
        my $file_uname = shift;
        my ($pub) = Chado::Pub->search( title => $file_uname );
        if ($pub and !($self->force_load())) {
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
                    title      => $file_uname,
                    miniref    => $file_uname,
                    uniquename => $file_uname,
                    type_id    => $self->cache_cvterm('gff_file')->id
                }
            );
        }
        die "unable to find or create a pub entry in the pub table"
            unless $pub;

    }
    else {
        return $self->{'pub'};
    }

    return $self->{'pub'} = shift if defined(@_);
}


