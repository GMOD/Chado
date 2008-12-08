package Bio::GMOD::DB::Adapter::Wormbase;

use base 'Bio::GMOD::DB::Adapter';

sub new {
    my $class = shift;
    my %arg   = @_;

    my $self  = $class->SUPER::new(%arg);
    return $self;
}


sub handle_unreserved_tags {
    my $self = shift;
    my ($feature,$uniquename,@unreserved_tags) = @_;

    foreach my $tag (@unreserved_tags) {
      next if $tag eq 'source';
      next if $tag eq 'phase';
      next if $tag eq 'seq_id';
      next if $tag eq 'type';
      next if $tag eq 'score';
      next if $tag eq 'dbxref';

      unless ($self->{const}{fp_cv_id} || $self->{const}{tried_fp_cv}){
      
        $self->fp_cv("autocreated") unless($self->fp_cv());
      
        my $sth = $self->dbh->prepare("SELECT cv_id FROM cv WHERE name='". $self->fp_cv()  ."'");
          # dgg: dropped  'autocreated' due to SO/auto conflicts for things like 'gene', 'chromosome'
          #      where SO and autocreated cvs are used primarily for type names in Bio/DB/Das/Chado
        $sth->execute;
        ($self->{const}{fp_cv_id}) = $sth->fetchrow_array;
        if(!$self->{const}{fp_cv_id} && $self->{'addpropertycv'}) {
          # create cv entry
          $self->{const}{fp_cv_id}= $self->nextoid('cv');
          $self->print_cv( $self->{const}{fp_cv_id}, $self->fp_cv());
          $self->nextoid('cv','++'); 
        }
        
        $self->{const}{tried_fp_cv} = 1;
      }

#       if (!$self->{const}{tried_fp_cv} and !$self->{const}{fp_cv_id}) {
#         my $sth = $self->dbh->prepare("SELECT cv_id FROM cv WHERE name='". $self->fp_cv  ."'");
#         $sth->execute;
#         ($self->{const}{fp_cv_id}) = $sth->fetchrow_array;
#         $self->{const}{tried_fp_cv} = 1;
#       }

      ## problems here with auto-added properties that clash with SO/other cvterms; cache-type?
      my $property_cvterm_id = $self->cache('property',$tag);
      # $property_cvterm_id = $self->cache('type',$tag) unless($property_cvterm_id); ## dgg; drop this?
      unless ( $property_cvterm_id ) {
        #check fp cv first; ## dgg drop this due to conflicts with SO type:  autocreated
        ## my ($tag_cvterm); # ==  $property_cvterm_id
        if ($self->{const}{fp_cv_id}) {
          $self->{queries}{search_cvterm_id}->execute( 
                                $tag, 
                                $self->{const}{fp_cv_id}) ;
         ($property_cvterm_id) = $self->{queries}{search_cvterm_id}->fetchrow_array;
         }

        if ($property_cvterm_id) { #good, the term is already there
          $self->cache('property',$tag,$property_cvterm_id); 
        } else { #bad! the term is not there for now we die with a helpful message

## dgg patch
          if($self->{'addpropertycv'} && $self->{const}{fp_cv_id}) {
            $property_cvterm_id= $self->nextoid('cvterm'); # $nextcvterm++;
            my $dbxid= $self->nextoid('dbxref'); #$nextdbxref++;
            my $cvid = $self->{const}{fp_cv_id};
            my $dbxacc= "autocreated:$tag";

            ## bad to use  gff_source_db id; use 'null' db
            unless ($self->{const}{null_db}) {
              my $sth = $self->dbh->prepare("SELECT db_id FROM db WHERE name='null'");
              $sth->execute;
              ($self->{const}{null_db}) = $sth->fetchrow_array;
            }
        
            $self->print_dbx($dbxid,$self->{const}{null_db},$dbxacc,1,'\N');
            $self->nextoid('dbxref','++'); 
            $self->cache('dbxref',$dbxacc,$dbxid);
            $self->print_cvterm($property_cvterm_id, $cvid, $tag, $dbxid);
            $self->nextoid('cvterm','++'); 
            $self->cache('property',$tag,$property_cvterm_id);  
          
          } else {
          dbxref_error_message($tag) && die;
          }
        }
      }
      #moving on, add this to the featureprop table
      my @values = map {$_->value} $feature->annotation->get_Annotations($tag);
      my $rank=0;
      foreach my $value (@values) {
        if ( $self->constraint( name => 'featureprop_c1',
                              terms=> [ $self->cache('feature',$uniquename),
                                        $self->cache('property',$tag), 
                                        $rank ] ) ) {
        $self->print_fprop($self->nextoid('featureprop'),$self->cache('feature',$uniquename),$property_cvterm_id,$value,$rank);
        $rank++;
        $self->nextoid('featureprop','++'); # $nextfeatureprop++;
        }
      }
    }
}


=head2 handle_CDS

=over

=item Usage

  $obj->handle_CDS($feature_obj)

=item Function

This function stores CDS and UTR features in a temporary database
table for processing after the entire GFF3 file has be seen.
If the feature's parents do not correspond to the central dogma
(that is, gene -> transcript -> cds), then the method will return
false and the CDS or UTR feature will be inserted as is into
the database.

=item Returns

False if the feature doesn't belong to a central dogma gene, 
otherwise nothing.

=item Arguments

A Bio::FeatureIO CDS or UTR object

=back

=cut

sub handle_CDS {
    my $self = shift;
    my $feat = shift;
    my $dbh  = $self->dbh;

#    warn Dumper($feat);

    my $feat_id     = ($feat->annotation->get_Annotations('ID'))[0]->value
               if ($feat && defined(($feat->annotation->get_Annotations('ID'))[0]));
    my @feat_parents= map {$_->value} 
               $feat->annotation->get_Annotations('Parent')
               if ($feat && defined(($feat->annotation->get_Annotations('Parent'))[0]));

    #assume that an exon can have at most one grandparent (gene, operon)
    my $parent_id = $self->cache('feature',$feat_parents[0]) if $feat_parents[0];

    unless ($parent_id) {
        warn "\n\nThere is a ".$feat->type->name." feature with no parent (ID:$feat_id)  I think that is wrong!\n\n";
    }

    my $feat_grandparent = $self->cache('parent',$parent_id);

    return 0 unless $feat_grandparent;

    unless ($self->cds_db_exists()) {
        $self->create_cds_db;
    }

    my $fmin = $feat->start;              #check that this is interbase
    my $fmax = $feat->end;
    # my $object = safeFreeze $feat;  ## original; dgg;  was bad for argos perl lib; had real old FreezeThaw
    ## dgg this works, and doesnt need a new 3rd party perl module: 
    my $dumper = Data::Dumper->new ([[$feat]]);
    $dumper->Indent(0)->Terse(1)->Purity(1);
    my $object = $dumper->Dump;
    
    my $feat_type   = $feat->type->name; 
    ##$feat_type= $feat_type->value if(ref $feat_type);
    my $seq_id = $feat->seq_id;  ## this is a ref->value !!

    my $insert = qq/
        INSERT INTO tmp_cds_handler (gff_id,seq_id,type,fmin,fmax,object) 
        VALUES (?,?,?,?,?,?)
    /;
    my $sth = $dbh->prepare($insert);
    $sth->execute($feat_id,$seq_id,$feat_type,$fmin,$fmax,$object);

    #get the value of the row just inserted
    $sth = $dbh->prepare("SELECT currval('tmp_cds_handler_cds_row_id_seq')");
    $sth->execute;
    my ($cds_row_id) = $sth->fetchrow_array;

    $sth = $dbh->prepare("INSERT INTO tmp_cds_handler_relationship (cds_row_id,parent_id,grandparent_id) VALUES (?,?,?)");
    for my $parent (@feat_parents) {
        $sth->execute($cds_row_id,$parent,$feat_grandparent);        
    }

    return 1;
}


=head2 process_CDS

=over

=item Usage

  my $feature_iterator = $obj->process_CDS()

=item Function

Retrieves CDS and UTR objects from a temporary database table and
does necessary conversion to exon and polypeptide features and
returns a feature iterator to let the bulk loader process them

=item Returns

A Bio::GMOD::Adaptor::FeatureIterator object

=item Arguments

None.

=back

=cut

sub process_CDS {
    my $self = shift;

#    $self->dbh->commit && die;
    return unless $self->cds_db_exists;

    my $dbh  = $self->dbh;

    #get one of the features from the database(!)

#    print Dumper($self);
#    die;

    my $min_feat_query = "SELECT min(fmax) FROM tmp_cds_handler";
    my $sth = $dbh->prepare($min_feat_query);
    $sth->execute;
    my ($min_feat) = $sth->fetchrow_array;

    my $cds_utr_query = qq/
SELECT distinct cds.gff_id,cds.object,cds.type,cds.fmin,cds.fmax, rel.grandparent_id
FROM tmp_cds_handler cds, tmp_cds_handler_relationship rel
WHERE rel.cds_row_id = cds.cds_row_id
  AND rel.grandparent_id IN
        (SELECT grandparent_id FROM tmp_cds_handler_relationship
          WHERE cds_row_id IN
           (SELECT cds_row_id FROM tmp_cds_handler WHERE fmax = ?))
ORDER BY cds.fmin,cds.gff_id
                /;
    $sth = $dbh->prepare($cds_utr_query);
    $sth->execute($min_feat);

    my %polypeptide;
    my @feature_list;
    my $grandparent;
#do stuff, create a list of features
    while (my $feat_row = $sth->fetchrow_hashref) {
        $grandparent  = $$feat_row{ grandparent_id };

## dgg: Data::Dumper works and is easier on user (Data::Dumper part of sys perl lib) ##          
        ##my ($feat_obj)= thaw $$feat_row{ object }; # original
        my $objs = eval $$feat_row{ object }; if($@) { warn @$; }
        my $feat_obj = $$objs[0];

        my $type      = $$feat_row{ type };
        my $fmin      = $$feat_row{ fmin };
        my $fmax      = $$feat_row{ fmax };
        my @parents   = map {$_->value}
                              $feat_obj->annotation->get_Annotations('Parent');

        for my $parent_id (@parents) {
          if ($type =~ /CDS/) {
            #check for a polypeptide with for this parent
            if ($polypeptide{ $parent_id }) {
            #add to it if it exists

                if ( $polypeptide{ $parent_id }->start > $fmin ) {
                    $polypeptide{ $parent_id }->start($fmin);
                }
                if ( $polypeptide{ $parent_id }->end   < $fmax ) {
                    $polypeptide{ $parent_id }->end($fmax);
                }
            }
            else {
            #create it if it doesn't
                my $polyp = Bio::SeqFeature::Annotated->new();
                $polyp->start(  $fmin  );
                $polyp->end(    $fmax  );
                $polyp->strand( $feat_obj->strand );
                $polyp->name(   $parent_id.' polypeptide');

                my $srcval= Bio::Annotation::SimpleValue->new(
                     ref($feat_obj->source) 
                         ? $feat_obj->source->value : $feat_obj->source);
                         
                $polyp->source( $srcval );

                my $polyp_ac = Bio::Annotation::Collection->new();
                $polyp_ac->add_Annotation( 'source', $srcval);

                $polyp_ac->add_Annotation(
                    'Note',Bio::Annotation::SimpleValue->new(
                     'polypeptide feature inferred from GFF3 CDS feature'));
                $polyp_ac->add_Annotation(
                    'Derives_from',Bio::Annotation::SimpleValue->new(
                      $parent_id));
                $polyp_ac->add_Annotation(
                    'type',Bio::Annotation::OntologyTerm->new(
                      -term => Bio::Ontology::Term->new(-name=>'polypeptide')));
                $polyp_ac->add_Annotation(
                    'seq_id',Bio::Annotation::SimpleValue->new(
                      $feat_obj->seq_id));
                $polyp_ac->add_Annotation(
                    'phase',Bio::Annotation::SimpleValue->new('.'));
                $polyp->annotation($polyp_ac);

                $polypeptide{ $parent_id } = $polyp;
            }
          }
        }

        #create an exon feature (or add to an existing one)
        my $merged_exon = 0;
        for my $exon ( @feature_list ) {
            next unless ($exon->type->name eq 'exon');
            if ($exon->start == $fmax - 1 ) {
        #this feature imideately precedes an existing exon, glue them together

                $exon->start($fmin);

                $exon = $self->_merge_annotations($exon, $feat_obj);
                $merged_exon = 1;
            }

            if ($exon->end == $fmin -1 ) {
        #this feature come right after an existing exon, glue them together
                $exon->end($fmax);

                $exon = $self->_merge_annotations($exon, $feat_obj);
                $merged_exon = 1;
            }
        }

#        if ($merged_exon) {
#            print Dumper($_) for @feature_list;
#        }

        unless ($merged_exon) {
        #convert the existing feature to an exon
            my $ac = $feat_obj->annotation();

            $ac->remove_Annotations('type');
            $ac->add_Annotation('type',Bio::Annotation::OntologyTerm->new(
                             -term => Bio::Ontology::Term->new(-name=>'exon')));
            $ac->add_Annotation('Note',Bio::Annotation::SimpleValue->new(
                             'Exon inferred from GFF3 ' .
                             $feat_obj->type->name .
                             ' feature line'));

            $feat_obj->annotation($ac);

            push @feature_list, $feat_obj;
        }
    }
    #add the polypeptides to the list
    if ($self->noexon) {
        #only return the polpeptides if noexon is set
        @feature_list = values %polypeptide;
    }
    else {
        push @feature_list, values %polypeptide;
    }

#delete the features from the temp tables:

    my $delete_query = qq/DELETE FROM tmp_cds_handler WHERE cds_row_id IN
  (SELECT cds_row_id FROM tmp_cds_handler_relationship WHERE grandparent_id =?)
   /;
    $sth = $dbh->prepare($delete_query);
    $sth->execute($grandparent);
    $dbh->commit;

#return an iterator
    if (@feature_list > 0) {
        return Bio::GMOD::DB::Adapter::FeatureIterator->new(\@feature_list);
    }
    else {
        return 0;
    }
}

=head2 _merge_annotations

=over

=item Usage

  $obj->_merge_annotations()

=item Function

Take two adjecent feature objects and merge their annotations

=item Returns

The merged feature object (which will be an exon feature)

=item Arguments

Two feature objects, with the existing exon first

=back

=cut

sub _merge_annotations {
    my ($self, $exon, $obj2) = @_;

    my $exon_ac = $exon->annotation;
    my $obj2_ac = $obj2->annotation;

    for my $key ( $obj2_ac->get_all_annotation_keys() ) {
        my @values = $obj2_ac->get_Annotations($key);
        if ($key eq 'type') {
            $exon_ac->add_Annotation('Note',Bio::Annotation::SimpleValue->new(
                'exon feature the result of two merged features in GFF3, one '.
                'of which was a '.$obj2->type->name.' feature')); 
        }
        elsif ( $key eq 'source'
             or $key eq 'Parent'
             or $key eq 'seq_id'
             or $key eq 'phase'
             or $key eq 'score' ) {
            next;
        }
        else {
            for my $value ( @values ) {
                $exon_ac->add_Annotation($key,$value); 
            }
        }
    }
    $exon->annotation($exon_ac);

    return $exon;
}


=pod

    my $iterator;
  #so its time to process the most recent set of features and return an iterator
    if (($feat_id && $self->{cdscache}{id} && $feat_id ne $self->{cdscache}{id})
         or
       ($feat_parent && $self->{cdscache}{parent} && $feat_parent ne $self->{cdscache}{parent})
         or
       (!$self->{cdscache}{id} && !$self->{cdscache}{parent}) ) {

        #this is a new cds feature so package up the old one to give back
        if ($self->noexon) {
            $iterator = Bio::GMOD::DB::Adapter::FeatureIterator->new(
                $self->{cdscache}{polypeptide_obj} 
            );
        }
        elsif ($self->{cdscache}{polypeptide_obj}) {
            push @{ $self->{cdscache}{feature_array} }, 
                $self->{cdscache}{polypeptide_obj};

            $iterator = Bio::GMOD::DB::Adapter::FeatureIterator->new(
                \@{ $self->{cdscache}{feature_array} }
            );
        }

        #now empty the caches and set parent/id
        $self->{cdscache}{feature_array}   = ();
        $self->{cdscache}{polypeptide_obj} = '';
        $self->{cdscache}{id}              = $feat_id;
        $self->{cdscache}{parent}          = $feat_parent;
    }

    #get the current AnnotationCollection and change
    # that is, convert CDS features to exon features
    if ($feat && !$self->noexon) {

        #check for existing created exons that but up against this feature
        my $start = $feat->start;
        my $stop  = $feat->end;

        my $appended_feature_flag = 0;
        for my $cached_feat ( @{ $self->{cdscache}{feature_array} } ) {
            if ($stop + 1 == $cached_feat->start) {
                my $cached_ac = $cached_feat->annotation();
                my $ac        = $feat->annotation();

                $ac->remove_Annotations('type');
                $ac->add_Annotation('Note',Bio::Annotation::SimpleValue->new(
                             'Exon added to from an adjacent feature in GFF3'));
                
                my @annot_list = $ac->get_Annotations;
                for my $annot (@annot_list) {
                    $cached_ac->add_Annotation($annot);
                } 

                $cached_feat->start($start);
                $appended_feature_flag = 1;
            }
            elsif ( $start == $cached_feat->end + 1 ) {
                my $cached_ac = $cached_feat->annotation();
                my $ac        = $feat->annotation();

                $ac->remove_Annotations('type');
                $ac->add_Annotation('Note',Bio::Annotation::SimpleValue->new(
                             'Exon added to from an adjacent feature in GFF3'));
                my @annot_list = $ac->get_Annotations;
                for my $annot (@annot_list) {
                    $cached_ac->add_Annotation($annot);
                }

                $cached_feat->end($stop);
                $appended_feature_flag = 1;
            } 
        }

        unless ( $appended_feature_flag ) {
            my $ac = $feat->annotation();

            $ac->remove_Annotations('type'); 
            $ac->add_Annotation('type',Bio::Annotation::OntologyTerm->new(
                             -term => Bio::Ontology::Term->new(-name=>'exon')));
            $ac->add_Annotation('Note',Bio::Annotation::SimpleValue->new(
                             'Exon inferred from GFF3 ' .
                             $feat->type->name .
                             ' feature line'));

            $feat->annotation($ac); 
        }
    }

    if ($feat && !$self->{cdscache}{polypeptide_obj}) {
    #polypeptide doesn't exist yet, so create it
        my $polyp = Bio::SeqFeature::Annotated->new();
        $polyp->start(    $feat->start  );
        $polyp->end(      $feat->end    );
        $polyp->strand(   $feat->strand );
        $polyp->name(     $feat_parent.' polypeptide');

        my $polyp_ac = Bio::Annotation::Collection->new();
        $polyp_ac->add_Annotation('Note',Bio::Annotation::SimpleValue->new(
                      'polypeptide feature inferred from GFF3 CDS feature'));
        $polyp_ac->add_Annotation('Derives_from',Bio::Annotation::SimpleValue->new(
                      $feat_parent));
        $polyp_ac->add_Annotation('type',Bio::Annotation::OntologyTerm->new(
                      -term => Bio::Ontology::Term->new(-name=>'polypeptide')));
        $polyp_ac->add_Annotation('seq_id',Bio::Annotation::SimpleValue->new(
                      $feat->seq_id));
        $polyp->annotation($polyp_ac);

        $self->{cdscache}{polypeptide_obj} = $polyp;
    }
    #check for bounds change on the existing polypeptide
    elsif ( $feat 
              && $self->{cdscache}{polypeptide_obj}->start > $feat->start
              && $feat->type->name =~ /CDS/ ) {
        $self->{cdscache}{polypeptide_obj}->start($feat->start);
    }
    elsif ( $feat 
              && $self->{cdscache}{polypeptide_obj}->end < $feat->end
              && $feat->type->name =~ /CDS/ ) {
        $self->{cdscache}{polypeptide_obj}->end($feat->end);
    }

    push @{ $self->{cdscache}{feature_array} }, $feat if $feat;

    return $iterator;
}
=cut

sub handle_parent {
    my $self = shift;
    my ($feature) = @_;

    for my $p_anot ( $feature->annotation->get_Annotations('Parent') ) {
        my $pname  = $p_anot->value;
        my $parent = $self->cache('feature',$pname);
        die "\nno parent $pname;\nyou probably need to rerun the loader with the --recreate_cache option\n\n" unless $parent;

        $self->cache('parent',$self->nextfeature,$parent);

        $self->print_frel($self->nextoid('feature_relationship'),$self->nextfeature,$parent,$part_of);

        $self->nextoid('feature_relationship','++'); # $nextfeaturerel++;
    }
}

sub handle_derives_from {
    my $self = shift;
    my ($feature) = @_;

    for my $p_anot ( $feature->annotation->get_Annotations('Derives_from') ) {
        my $pname  = $p_anot->value;
        my $parent = $self->cache('feature',$pname);
        die "no parent ".$pname unless $parent;

        $self->cache('parent',$self->nextfeature,$parent);

        $self->print_frel($self->nextoid('feature_relationship'),$self->nextfeature,$parent,$derives_from);
        $self->nextoid('feature_relationship','++'); #$nextfeaturerel++;
    }
}

sub handle_crud {
    my $self = shift;
    my $feature = shift;
    my $force_delete = shift;

    my ($op) = $feature->annotation->get_Annotations('CRUD');
    $op = $op->value if defined($op);
    if ($force_delete) {
        $op = 'delete-all';
    }

    my ($name) = $feature->annotation->get_Annotations('Name');

    if (!defined($name)) {
        #try to get the name from the ID
        ($name) = $feature->annotation->get_Annotations('ID');
        if (!defined($name)) {
        #if it doesn't have a name, don't do anything
        return 1;
        }
    }

    $name = $name->value if ref($name);
    my $type   = ref($feature->type) ? $feature->type->name : $feature->type;
    
    if ($op =~ /delete/) {
        #determine if a single feature corresponds to what is in the gff line
        #it is considered to be the same if the type, name (or synonym)
        #and organism are the same

        #this sql should be moved to the prepared sql hash after debugging is done
        my $sql = "SELECT feature_id FROM feature
                   WHERE name = ? and type_id = ? and organism_id = ?";
        my $delete_query_handle = $self->dbh->prepare($sql);
        $delete_query_handle->execute($name,
                                      $self->get_type($type),
                                      $self->organism_id);
        my $feature_id_arrayref = $delete_query_handle->fetchall_arrayref;

        my $feature_id;
        if (scalar @{$feature_id_arrayref} > 1 and $op ne 'delete-all') {
            $self->throw("I can't figure out which feature to delete that corresponds to a feature with a name of $name, a type of $type and organism of ".$self->organism.".  More than one feature match these criteria");
        }
        elsif (scalar @{$feature_id_arrayref} > 1) {
            warn "Deleting all features with name $name, type $type and organism ".$self->organism."\n";
            for my $id_row (@{$feature_id_arrayref}) {
                my $feature_id = $$id_row[0];
                $self->print_delete($$id_row[0]) if $feature_id;
            }
            return 1;
        }
        elsif (scalar @{$feature_id_arrayref} == 0) {
            warn "Couldn't fined a matching feature with name $name, type $type and organism ".$self->organism."\n";
            return 1;
#            warn("Searching for a feature with the name $name to delete yielded nothing; checking synonyms...");
#            $sql = "SELECT f.feature_id 
#                    FROM feature f, feature_synonym fs, synonym s
#                    WHERE s.name = ? and 
#                          s.synonym_id = fs.synonym_id and
#                          fs.feature_id = f.feature_id and
#                          f.type_id = ? and f.organism_id = ?"; 
#            my $delete_by_syn_query_handle = $self->dbh->prepare($sql);
#            $delete_by_syn_query_handle->execute($name,
#                                                 $self->get_type($type),
#                                                 $self->organism_id);
#            $feature_id_arrayref = $delete_by_syn_query_handle->fetchall_arrayref;
#            if (scalar @{$feature_id_arrayref} > 1) {
#                $self->throw("I couldn't figure out which feature to delete when searching by synonym $name; I found more than one matching feature");
#            } 
#            elsif (scalar @{$feature_id_arrayref} == 0) {
#                $self->throw("I couldn't find a matching feature using either feature.name or synonym.name of $name and a type of $type and organism of ".$self->organism.".  I can't go on... Bye.");
#            }
#            else { 
#                ($feature_id) = $$feature_id_arrayref[0];
#            }
        }
        else {
            $feature_id = $$feature_id_arrayref[0][0];
        }
        $self->print_delete($feature_id);
        return 1;
    }
    elsif ($op eq 'replace' or $op eq 'update') {
        $self->throw("The CRUD operation $op is not supported yet");
    }
    elsif ($op eq 'create') {
        return 0;  #nothing to do--create is the default
    }
    else {
        $self->throw("I don't know what to do for the CRUD operation $op");
    } 
}


1;
