
package SOI::Adapter;

=head1 NAME

SOI::Adapter

=head1 SYNOPSIS


=head1 USAGE

my $ad = SOI::Adapter->new('Pg:chadodb@host');

OR

my $ad = SOI::Adapter->new;
$ad->dbh($dbh);

OR

my $ad = SOI::Adapter->get_adapter('Pg:chado@host' || $dbh);


=head1 FEEDBACK

Email sshu@fruitfly.org

=cut

use DBI;
use Exporter;
use SOI::Feature;

use strict;
use Carp;
use base qw(Exporter);

=head1 FUNCTIONS

=cut

sub new {
    my $proto = shift; my $class = ref($proto) || $proto;;
    my $self = {};
    bless $self, $class;

    my $dbh = $self->get_handle(@_);
    $self->dbh($dbh);
    return $self;
}
sub dbh {
    my $self = shift;
    if (@_) {
        $self->{dbh} = shift;
    }
    return $self->{dbh};
}

=head2 get_adapter

  Usage   - my $ad = SOI::Adapter->get_adapter("Pg:chadodbname\@host");
  Usage   - my $ad = SOI::Adapter->get_adapter($dbh);
  Returns - SOI::Adapter object
  Args    - db, dbh

  Descr   - another way to get this adapter obj with either db or dbh

=cut

sub get_adapter {
    my $class = shift;
    my $dbn = shift;

    my $dbh = $dbn;
    $dbh = $class->get_handle($dbn) unless (ref($dbh));
    $class->dbh($dbh);
    return $class;
}

sub get_feature {
    return shift @{shift->get_features(@_)};
}
*get_f = \&get_feature;

=head2 get_features

  Usage   - my $features = $ad->get_features({range=>{src=>'3L',fmin=>10000,fmax=>20000}})
  Returns - SOI::Feature object list
  Args    - constraint in the form of hash ref, optional options in the form of hash ref

  valid constraint key: range, src/src_seq, value is a single value or hash ref (range)

  valid options key: type, values is a single SO type or an array ref of SO types
                     default to [qw(gene transposable_element remark)]

                     source_origin_feature_type, default to chromosome_arm. This is critical option
                     when getting golden_path_region features in the range since your feature types
                     is a feature that does not have src seq (most top level feature in a genome).
                     This is true for getting any feature that is second level to most top feature
                     in the genome (see soi tree, read readme for this)

                     noauxillaries, not to get feature properties, dbxrefs, or ontology terms
                     default 0

  Description - get is_analysis false features and their children as a Feature tree

=cut

sub get_features {
    my $self = shift;
    my $constr = shift;
    my $opts = shift || {};
    my $typelist = $opts->{type} || $opts->{types} || $opts->{feature_types} || [qw(gene transposable_element remark)];

    my $f_src_origin_type = $opts->{source_origin_feature_type} || 'chromosome_arm';

    unless (ref($typelist) eq 'ARRAY') {
        $typelist = [$typelist];
    }
    my $tlist = join(",",map{sql_q($_)}@$typelist);
    my $where = $self->_get_where($constr);
    my $first_add_w = $where;

    my $fl_cols = join(", ",map{"fl.$_"}($self->_loc_attr));
    my $special_cols = qq(src.uniquename as src_seq, $fl_cols);
    my $sp_from =
      qq(
         INNER join
         featureloc fl ON (f.feature_id = fl.feature_id)
         INNER join
         feature src ON (src.feature_id = fl.srcfeature_id)
        );
    #no src for chromosome_arm
    if (grep {$_ eq $f_src_origin_type}@$typelist) {
        $special_cols = qq(null as src_seq, null as srcfeature_id, null as fmin, null as fmax, null as strand);
        $special_cols .= ",".join
          (",",
           map{"null as $_"}
           grep{$_ ne 'srcfeature_id' && $_ ne 'fmin' && $_ ne 'fmax' && $_ ne 'strand'}
           ($self->_loc_attr));
        $first_add_w = $self->_get_where($constr, {src_col=>'f.uniquename',chromosome_arm=>1});
        $sp_from = "";
    }
    $first_add_w = " AND $first_add_w" if ($first_add_w);
    my $sec_where = $where;
    if ($sec_where) {
        $sec_where = " WHERE $sec_where AND f.is_analysis = 'f'";
    } else {
        $sec_where = " WHERE f.is_analysis = 'f'";
    }
    my $soi_children_sql = $self->_soi_children_select($typelist);
    my $sql =
      qq(
         select * FROM
         ((select
           f.*,
           $special_cols,
           q.name as type,
           1 as depth,
           NULL as relationship_type,
           NULL as parent_id,
           0 as orderrank
           FROM
           feature f
           INNER join
           cvterm q ON (f.type_id = q.cvterm_id)
           INNER join
           cv ON (q.cv_id = cv.cv_id)
           $sp_from
           WHERE q.name in ($tlist) and cv.name = 'so' and f.is_analysis = 'f' $first_add_w
          )
          UNION
          (select
           f.*,
           src.uniquename as src_seq,
           $fl_cols,
           q.name as type,
           q.depth,
           frt.name as relationship_type,
           fr.object_id as parent_id,
           fr.rank as orderrank
           FROM
           feature f
           INNER join
           featureloc fl ON (f.feature_id = fl.feature_id)
           INNER join
           feature src ON (src.feature_id = fl.srcfeature_id)
           INNER join
           feature_relationship fr ON (f.feature_id = fr.subject_id)
           INNER join
           cvterm frt ON (fr.type_id = frt.cvterm_id)
           INNER join 
           ($soi_children_sql) as q ON (f.type_id = q.cvterm_id)
           $sec_where
          )) as uf);

    $sql = sprintf("$sql %s", "order by depth, parent_id, orderrank, rank");

    my $lfl;
    my %node_h = $self->_select_objhash($sql);

    return unless (scalar(keys %node_h));

    #auxillaries can be optional
    %node_h = $self->_get_auxillaries($constr, $typelist, \%node_h) unless ($opts->{noauxillaries});

    #collect top level
    foreach my $id (keys %node_h) {
        my $nodes = $node_h{$id};
        foreach my $node (@{$nodes || []}) {
            unless ($node->hash->{parent_id}) {
                push @$lfl, $node;
            }
        }
    }
    undef %node_h;

    return unless (scalar(@{$lfl || []}));

    $self->_get_organism($lfl);

    return $lfl;
}
*get_locatedfeature_list = \&get_features;
*get_locatedfeatures = \&get_features;
*get_lf_list = \&get_features;
*lget_lf = \&get_features;


=head2 get_analysis

  Usage   - my $features = $ad->get_analysis()
  Returns - SOI::Feature object list
  Args    - optional constraint in the form of hash ref, optional options in the form of hash ref

  valid constraint key: analysis, program, sourcename/database, value is either single val or arrayref

  Description - get feature holders (that will hold result feature from the computational analysis)

=cut

sub get_analysis {
    my $self = shift;
    my $constr = shift;

    my ($progs, $dbs) = $self->_get_progs_dbs($constr);
    my $prog_str = join(",", map{sql_q($_)}@{$progs || []});
    my $wheres;
    push @$wheres, "an.program IN ($prog_str)" if ($prog_str);
    my $db_str = join(",", map{sql_q($_)}@{$dbs || []});
    push @$wheres, "an.sourcename IN ($db_str)" if ($db_str);

    my $where = join(" AND ", @{$wheres || []});
    $where = " WHERE $where" if $where;
    my $sql =
      qq(select
         an.*,
         t.name as type,
         ap.value
         FROM
         analysis an
         LEFT join
         analysisprop ap ON (an.analysis_id = ap.analysis_id)
         LEFT join
         cvterm t ON (t.cvterm_id = ap.type_id)
         $where);
    my %node_h;
    my $hl = $self->_select_hashlist($sql);
    foreach my $h (@{$hl || []}) {
        my $node = $node_h{$h->{analysis_id}};
        my ($t,$v) = ($h->{type},$h->{value});
        delete $h->{type}; delete $h->{value};
        unless ($node) {
            $node = SOI::Feature->new($h);
            $node->hash->{type} = 'companalysis';
            $node_h{$h->{analysis_id}} = $node;
        }
        $node->add_property({type=>$t,value=>$v});
    }
    return [values %node_h];
}

sub _get_progs_dbs {
    my $self = shift;
    my $constr = shift;

    my (@progs, @dbs);
    if ($constr->{analysis}) {
        my $an = $constr->{analysis};
        $an = [$an] unless (ref($an) eq 'ARRAY');
        map {
            if ($_->isa("SOI::Feature")) {
                push @progs, $an->hash->{program};
                push @progs, $an->hash->{sourcename};
            } else {
                my ($prog, $db) = (split/\:/, $_);
                push @progs, $prog;
                push @dbs, $db;
            }
        }@{$an}
    }
    elsif ($constr->{program}) {
        my $prog = $constr->{program};
        $prog = [$prog] unless (ref($prog) eq 'ARRAY');
        map{push @progs, $_}@{$prog};
    }
    my $db = $constr->{sourcename} || $constr->{database} || $constr->{dbname};
    if ($db) {
        $db = [$db] unless (ref($db) eq 'ARRAY');
        map{push @dbs, $_}@{$db};
    }
    return (\@progs, \@dbs);
}


=head2 get_results

  Usage   - my $features = $ad->get_results({range=>{src=>'3L',fmin=>10000,fmax=>20000}})
  Returns - SOI::Feature object list
  Args    - constraint in the form of hash ref, optional options in the form of hash ref

  valid constraint key: range, src/src_seq, value is a single value or hash ref (range)
                        analysis, program, sourcename/database, value is either single val or arrayref

  valid options key: type, values is a single SO type or an array ref of SO types
                     default to [qw(match mRNA transposable_element)]

                     noresidues, not to get subject seq residues, default 0

  Description - get is_analysis true features and their children as a Feature tree

=cut

sub get_results {
    my $self = shift;
    my $constr = shift;
    my $opts = shift || {};

    my $tlist = $opts->{type} || $opts->{types} || $opts->{feature_types} || [qw(match mRNA transposable_element)];
    my $tliststr = join(",", map{"'".$_."'"}@$tlist);
    my ($progs, $dbs) = $self->_get_progs_dbs($constr);
    my $where;
    #ok where clause is more complicated for analysi results.
    #can search query src seq and subj src seq, nor subject seq range yet!!!
    my $where = "f.is_analysis = 't'";
    my $prog_str = join(",", map{sql_q($_)}@{$progs || []});
    $where .= " AND an.program IN ($prog_str)" if ($prog_str);
    my $db_str = join(",", map{sql_q($_)}@{$dbs || []});
    $where .= " AND an.sourcename IN ($db_str)" if ($db_str);

    if ($constr->{range}) {
        my $range = $constr->{range};
        $where .= sprintf(" AND %s", "src.uniquename = ".sql_q($range->{src} || $range->{src_seq}));
        $where .= sprintf(" AND %s", "fl.fmin <= ".$range->{fmax});
        $where .= sprintf(" AND %s", "fl.fmax >= ".$range->{fmin});
        $where .= " AND fl.rank = 0";
    }
    elsif ($constr->{src} || $constr->{src_seq}) {
        my $src = $constr->{src} || $constr->{src_seq};
        $where .= sprintf(" AND src.uniquename = %s", sql_q($src)." AND fl.rank = 0");
    }
    elsif ($constr->{subj} || $constr->{subj_seq}) {
        my $src = $constr->{subj} || $constr->{subj_seq};
        $where .= sprintf(" AND src.uniquename = %s", sql_q($src)." AND fl.rank = 1");
    }

    #soi children only
    my $soi_sql = $self->_soi_children_select($tlist);
    my $sub_select = 
      qq(select DISTINCT feature_id, name, depth, object_id, rank FROM
         ((select
           f.feature_id,
           q.name,
           1 as depth,
           null as object_id,
           null as rank
           FROM
           analysis an
           INNER join
           analysisfeature a2f ON (an.analysis_id = a2f.analysis_id)
           INNER join
           feature f ON (f.feature_id = a2f.feature_id)
           INNER join
           featureloc fl ON (f.feature_id = fl.feature_id)
           INNER join
           feature src ON (src.feature_id = fl.srcfeature_id)
           INNER join
           cvterm q ON (f.type_id = q.cvterm_id)
           INNER join
           cv ON (cv.cv_id = q.cv_id)
           WHERE cv.name = 'so' AND q.name IN ($tliststr) and $where
          )
          UNION
          (select
           f.feature_id,
           q.name,
           q.depth,
           fr.object_id,
           fr.rank as rank
           FROM
           analysis an
           INNER join
           analysisfeature a2f ON (an.analysis_id = a2f.analysis_id)
           INNER join
           feature f ON (f.feature_id = a2f.feature_id)
           INNER join
           feature_relationship fr ON (f.feature_id = fr.subject_id)
           INNER join
           featureloc fl ON (f.feature_id = fl.feature_id)
           INNER join
           feature src ON (src.feature_id = fl.srcfeature_id)
           INNER join
           ($soi_sql) as q ON (f.type_id = q.cvterm_id)
           WHERE $where
          )) as uf);
    my $sql =
      qq(select
         f.*,
         af.*,
         fl.*,
         src.uniquename as src_seq,
         q.name as type,
         q.depth,
         q.object_id as parent_id,
         q.rank as orderrank
         FROM
         feature f
         INNER join
         analysisfeature AS af ON  (af.feature_id = f.feature_id)
         INNER join
         featureloc fl ON (fl.feature_id = f.feature_id)
         INNER join
         feature AS src ON (src.feature_id = fl.srcfeature_id)
         INNER join
         ($sub_select) as q ON (f.feature_id = q.feature_id)
         order by depth, object_id, q.rank, fl.rank
        );

    my %node_h = $self->_select_objhash($sql);

    my $lfl;
#    #collect top level
#    foreach my $id (keys %node_h) {
#        my $node = $node_h{$id};
#        unless ($node->hash->{parent_id}) {
#            push @$lfl, $node;
#        }
#    }

    my (%parent_h, %sec_loc_h);
    #resultset (match) does not have entry in featureloc, do special thing here
    foreach my $id (keys %node_h) {
        my $nodes = $node_h{$id};
        foreach my $node (@{$nodes || []}) {
            if (!$node->hash->{parent_id}) {
                $parent_h{$node->id} = $node;
            }elsif ($node->depth == 2) {
                #only second level may have subject span!!!
                map{push @{$sec_loc_h{$_->{srcfeature_id}}}, $_}@{$node->secondary_locations || []};
                my $parent = $parent_h{$node->parent_id};
                unless ($parent) {
                    my $pattr_h = {};
                    my $t = $node->type eq 'exon' ? 'mRNA' : 'match'; #hack
                    $pattr_h = {feature_id => $node->parent_id,
                                uniquename => $node->parent_id,
                                analysis_id=> $node->hash->{analysis_id},
                                depth      => 1,
                                type       => $t}; #only type top level SO type for analysis result?
                    $parent = SOI::Feature->new($pattr_h);
                    $parent_h{$parent->id} = $parent;
                }
                $parent->add_node($node);
            }
        }
    }
    undef %node_h;
    #get organism (genus, species) as one query
    my $sub_select2 =
      qq(select DISTINCT
         f.feature_id
         FROM
         analysis an
         INNER join
         analysisfeature a2f ON (an.analysis_id = a2f.analysis_id)
         INNER join
         feature f ON (f.feature_id = a2f.feature_id)
         INNER join
         feature_relationship fr ON (f.feature_id = fr.subject_id)
         INNER join
         featureloc fl ON (f.feature_id = fl.feature_id)
         INNER join
         feature src ON (src.feature_id = fl.srcfeature_id)
         INNER join
         ($soi_sql) as q ON (f.type_id = q.cvterm_id)
         WHERE $where AND fl.rank = 0
        );
    my $sql2 =
      qq(select DISTINCT
         src.*,
         org.genus,
         org.species,
         t.name as type,
         fp.value as description
         FROM
         feature f
         INNER join
         featureloc fl ON (fl.feature_id = f.feature_id)
         INNER join
         feature AS src ON (src.feature_id = fl.srcfeature_id)
         INNER join
         organism org ON (src.organism_id = org.organism_id)
         INNER join
         cvterm t ON (src.type_id = t.cvterm_id)
         INNER join
         featureprop fp ON (src.feature_id = fp.feature_id)
         INNER join
         cvterm fpt ON (fp.type_id = fpt.cvterm_id)
         INNER join
         ($sub_select2) as q ON (f.feature_id = q.feature_id)
         WHERE fl.rank > 0 AND fpt.name = 'description'
        );
    my $hl = $self->_select_hashlist($sql2) unless ($opts->{noresidues});
    foreach my $h (@{$hl || []}) {
        my $sec_locs = $sec_loc_h{$h->{feature_id}};
        map{$_->{seq} = $h}@{$sec_locs || []};
    }
    undef %sec_loc_h;

    return [values %parent_h];
}

=head2 get_features_by_typed_value

  Usage   - my $features = $ad->get_features_by_type_value('gene', 'CG1234', {extend=>5000})
            my ($range, $features) = $ad->get_features_by_type_value('gene', 'CG1234', {extend=>500})
  Returns - a list of a range value in the form of has ref, e.g. {src=>NAME,fmin=>N1,fmax=>N2}
            and SOI::Feature object list in the range of this typed feature,
  Args    - SO type, this typed feature ID, optional extending this feature bounds for the range

  valid options key: all valid option keys in get_features or get_results

                     is_analysis, get is_analysis false features or is_analysis true featurs

  Description - help function for get_features[get_results]_by_$type

=cut

sub get_features_by_typed_value {
    my $self = shift;
    my $type = shift;
    my $value = shift;
    my $opts = shift || {};
    my $extend =  $opts->{extend} || 0;
    my $tlist = $opts->{type} || $opts->{feature_types} || $opts->{types};

    my $where = "(f.name = '$value' OR f.uniquename = '$value')";

    my $method = $opts->{is_analysis} ? 'results' : 'features';
    $method = "get_".$method;

    my $sql =
      qq(
         select
         src.uniquename as src,
         fl.fmin,
         fl.fmax
         FROM
         feature f
         INNER join
         featureloc fl ON (f.feature_id = fl.feature_id)
         INNER join
         feature src ON (src.feature_id = fl.srcfeature_id)
         INNER join
         cvterm type ON (type.cvterm_id = f.type_id)
         WHERE type.name = '$type' AND $where
        );
    my $range;
    if ($type eq 'range') {
        $range = $value; #range hashref
    }
    else {
        my $hl = $self->_select_hashlist($sql);
        return unless (@{$hl || []});
        my $h = $hl->[0];
        $range =
          {
           src=>$h->{src},fmin=>$h->{fmin},fmax=>$h->{fmax}
          };
    }
    if ($extend) {
        $range->{fmin} -= $extend;
        $range->{fmax} += $extend;
    }
    my $constr = {range=>$range};
    return ($range, $self->$method($constr, $tlist));
}

=head2 get_features_by_gene

  Description - delegate to get_features_by_typed_value

=cut

sub get_features_by_gene {
    my $self = shift;
    my $gene = shift;
    my $opts = shift || {};
    return ($self->get_features_by_typed_value('gene', $gene, $opts));
}

=head2 get_features_by_scaffold

  Description - delegate to get_features_by_typed_value

=cut

sub get_features_by_scaffold {
    my $self = shift;
    my $scf = shift;
    my $opts = shift;
    return ($self->get_features_by_typed_value('golden_path_region', $scf, $opts));
}
*get_features_by_accession = \&get_features_by_scaffold;

=head2 get_features_by_range

  Description - delegate to get_features_by_typed_value

=cut

sub get_features_by_range {
    my $self = shift;
    my $range = shift;
    my $opts = shift;
    if ($range =~ /(\w+)\:(\d+)(\-|\:)(\d+)/) {
        my $range = {src=>$1,fmin=>$2,fmax=>$4};
        return ($self->get_features_by_typed_value('range',$range,$opts));
    }
}

=head2 get_features_by_cytoband

  Description - similar to get_features_by_typed_value, but use computational analysis
                result to get the range.
                one more option key (analysis), default to locator:cytology

=cut

sub get_features_by_cytoband {
    my $self = shift;
    my $band = shift;
    my $opts = shift || {};
    my $analysis = $opts->{analysis} || 'locator:cytology';
    my ($prog, $sn) = (split/\:/, $analysis);

    $band = sprintf("'band-%s-cyto'",$band);#special naming for cytoband in harvard chado!!!

    my $sql = qq
      (select f.name, min(cfl.fmin) as fmin, max(cfl.fmax) as fmax, src.uniquename as src
       FROM feature f INNER join feature_relationship fr ON (f.feature_id = fr.object_id)
       INNER join feature c ON (c.feature_id = fr.subject_id) INNER join featureloc cfl
       ON (c.feature_id = cfl.feature_id) INNER join feature src ON (src.feature_id = cfl.srcfeature_id)
       INNER join analysisfeature af ON (f.feature_id = af.feature_id)
       INNER join analysis a ON (a.analysis_id = af.analysis_id)
       WHERE f.name = $band AND cfl.rank = 0 AND a.program = '$prog' AND a.sourcename = '$sn'
       group by f.name, src);

    my $hl = $self->_select_hashlist($sql);
    return unless (@{$hl || []});
    my $h = $hl->[0];
    my $range =
      {
       src=>$h->{src},fmin=>$h->{fmin},fmax=>$h->{fmax}
      };

    return ($range, $self->get_features({range=>$range}));
}
*get_features_by_band = \&get_features_by_cytoband;

=head2 get_results_by_gene

  Description - delegate to get_features_by_typed_value

=cut

sub get_results_by_gene {
    my $self = shift;
    my $gene = shift;
    my $opts = shift || {};
    $opts->{is_analysis} = 1;
    return ($self->get_features_by_typed_value('gene', $gene, $opts));
}

=head2 get_results_by_scaffold

  Description - delegate to get_features_by_typed_value

=cut

sub get_results_by_scaffold {
    my $self = shift;
    my $scf = shift;
    my $opts = shift;
    $opts->{is_analysis} = 1;
    return ($self->get_features_by_typed_value('golden_path_region', $scf, $opts));
}

=head2 get_results_by_range

  Description - delegate to get_features_by_typed_value

=cut

sub get_results_by_range {
    my $self = shift;
    my $range = shift;
    my $opts = shift;
    $opts->{is_analysis} = 1;
    if ($range =~ /(\w+)\:(\d+)\-(\d+)/) {
        my $range = {src=>$1,fmin=>$2,fmax=>$3};
        return ($self->get_features_by_typed_value('range',$range,$opts));
    }
}

=head2 get_features_by_template

  Usage   - my $features = $ad->get_features_by_template($templfile, $params_h, $option_h)
  Returns - SOI::Feature object list
  Args    - template file, parameters hash ref, optional options hash ref

  parameters - template can has parameter (syntax: f.uniquename = &&gene&&,
                                           params_h will have to have {gene=>GENENAME})
               or optional parameter (syntax: [AND type = &&type&&])

  options - valid key: noauxillaries for not getting properties, dbxref, ont terms
                       and no SQL for them in template

  Description - see typed_genes.soi under templates dir for general syntax of SOI::Adapter template

=cut

sub get_features_by_template {
    my $self = shift;
    my $templatef = shift;
    my $args = shift || {};
    my $opts = shift || {};

    my %sql_h;
    my $type = "";
    my $sql;
    open(R, "< $templatef") or confess("can not open template file: $templatef");
    while (<R>) {
        chomp;
        next unless ($_);
        next if ($_ =~ /^--/ || $_ =~ /\#/);
        my $line = $_;
        if ($line =~ /^SQL\:/) {
            $type = 'SQL';
        }
        elsif ($line =~ /^(\w+)\-SQL\:/) {
            $type = $1;
        }
        elsif ($type) {
            $sql_h{$type} .= " $line";
        }
    }
    close(R);
    $sql = $sql_h{'SQL'} or confess("did not find valid sql statement");

    sub _translate {
        my $tsql = shift;
        my $args1 = shift;
        foreach my $k (keys %{$args1 || {}}) {
            my $vs = $args1->{$k};
            $vs = [$vs] unless (ref($vs) eq 'ARRAY');
            my $v = join(",",map{"'".$_."'"}@{$vs});
            $v =~ s/\*/\%/g;
            $tsql =~ s/\&\&$k\&\&/$v/g;
        }
        $tsql =~ s/\[[^\[\]]+\&\&\S+\&\&[^\[\]]*\]//g;
        $tsql =~ s/\[//g; $tsql =~ s/\]//g;
        return $tsql;
    }
    my %node_h = $self->_select_objhash(_translate($sql, $args));

    my $lfl;
    #collect top level
    foreach my $id (keys %node_h) {
        my $nodes = $node_h{$id};
        foreach my $node (@{$nodes || []}) {
            unless ($node->hash->{parent_id}) {
                push @$lfl, $node;
            }
        }
    }
    return unless (scalar(@{$lfl || []}));

    #auxillaries can be optional
    if (scalar(keys %sql_h) > 1) {
        my $ont_sql = $sql_h{'ONTOLOGLY'};
        $self->_get_ontologies(_translate($ont_sql, $args),\%node_h);
        my $prop_sql = $sql_h{'PROPERTY'};
        $self->_get_properties(_translate($prop_sql, $args), \%node_h);
        my $dbx_sql = $sql_h{'DBXREF'};
        $self->_get_dbxrefs(_translate($dbx_sql, $args), \%node_h);
    } else {
        $self->_get_auxillaries4features($lfl) unless ($opts->{noauxillaries});
    }
    undef %node_h;

    $self->_get_organism($lfl);
    return $lfl;
}

sub _get_where {
    my $self = shift;
    my $constr = shift;
    my $opts = shift || {};
    my $src_col = $opts->{src_col} || "src.uniquename";
    my $fl_tbl = $opts->{featureloc_tbl} || "fl";
    my $chr_arm = $opts->{chromosome_arm};

    my $where;
    my $range = $constr->{range};
    #constr will be RE-USED by caller, don't delete
    if ($range) {
        my ($src, $fmin, $fmax) = ($range->{src}, $range->{fmin}, $range->{fmax});
        confess("Invalid range args $src, $fmin, $fmax") if (!$src || ($fmax-$fmin) <=0);
        $where = "$src_col = '$src' and $fl_tbl.fmin <= $fmax and $fl_tbl.fmax >= $fmin";
        $where = "$src_col = '$src'" if ($chr_arm);
    }
    elsif ($constr->{src} || $constr->{src_seq}) {
        my $src = $constr->{src} || $constr->{src_seq};
        $where = "$src_col = '$src'";
    }
    elsif ($constr->{subj} || $constr->{subj_seq}) {
        my $src = $constr->{subj} || $constr->{subj_seq};
        $where = "$src_col = '$src'";
    }
    else {
        #confess("only support range and src seq name query");
        warn("get whole genome!!!");
    }
    return $where;
}
sub _loc_attr {
    return qw(srcfeature_id fmin fmax strand residue_info phase locgroup rank);
}
sub _soi_select {
    my $self = shift;
    my $tlist = shift || return;

    $tlist = [$tlist] unless (ref($tlist) eq 'ARRAY');
    my $tliststr = join(",",map{sql_q($_)}@$tlist);
    my $soi =
      qq
        ((select c.name, c.cvterm_id, 1 as depth
          FROM cvterm c, cv
          WHERE c.cv_id = cv.cv_id and c.name IN ($tliststr) and cv.name = 'so')
         UNION
         (select c.name, c.cvterm_id, max(pathdistance+1) as depth
          FROM cvterm c, cvtermpath path, cvterm p, cv
          WHERE c.cvterm_id = subject_id and p.cvterm_id = object_id
          and path.cv_id =cv.cv_id and cv.name = 'soi'
          and p.name in ($tliststr) group by c.name, c.cvterm_id
         ));
    return $soi;
}
sub _soi_children_select {
    my $self = shift;
    my $tlist = shift || return;

    $tlist = [$tlist] unless (ref($tlist) eq 'ARRAY');
    my $tliststr = join(",",map{sql_q($_)}@$tlist);
    my $soi =
      qq(select c.name, c.cvterm_id, max(pathdistance+1) as depth
         FROM cvterm c, cvtermpath path, cvterm p, cv
         WHERE c.cvterm_id = subject_id and p.cvterm_id = object_id
         and path.cv_id =cv.cv_id and cv.name = 'soi'
         and p.name in ($tliststr) group by c.name, c.cvterm_id
        );
    return $soi;
}
sub _get_organism {
    my $self = shift;
    my $lfl = shift || return;

    #get organism;
    my %id_h = ();
    map{$id_h{$_->hash->{organism_id}}++}@$lfl;

    my $hl = $self->_select_hashlist
      ("select * from organism where organism_id in (".join(",",keys %id_h).")") if (keys %id_h);
    my %org_h;
    map{$org_h{$_->{organism_id}} = $_}@{$hl || []};
    foreach my $l (@$lfl) {
        my $o_id = $l->hash->{organism_id};
        $l->hash->{genus} = $org_h{$o_id}->{genus};
        $l->hash->{species} = $org_h{$o_id}->{species};
    }
}
sub _get_auxillaries {
    my $self = shift;
    my $constr = shift;
    my $tlist = shift;
    my $href = shift;
    my %node_h = %{$href};

    my ($sql, $where);

    my $soi = $self->_soi_select($tlist);

    ###########---NOTE----##############################
    # maybe using is_analysis will make it more speedy??
    ####################################################

    #note: won't get chromosome's auxillary values

    #need to get is_current flag in feature_dbxref tabe!!
    #get dbxrefs
    $sql =
      qq(
         select
         f.feature_id,
         xref.accession,
         db.name as dbname
         FROM
         feature f
         INNER join
         featureloc fl ON (f.feature_id = fl.feature_id)
         INNER join
         feature src ON (src.feature_id = fl.srcfeature_id)
         INNER join
         feature_dbxref fxref ON (f.feature_id = fxref.feature_id)
         INNER join
         dbxref xref ON (fxref.dbxref_id = xref.dbxref_id)
         INNER join
         db ON (db.db_id = xref.db_id)
         INNER join
         (
          $soi
         ) as q ON (f.type_id = q.cvterm_id)
         );
    $where = $self->_get_where($constr);
    $sql = sprintf("$sql WHERE %s", $where);
    $self->_get_dbxrefs($sql, \%node_h);

    #get properties
    $sql =
      qq
        (
         select
         f.feature_id,
         t.name as type,
         fp.value,
         fp.rank
         FROM
         feature f
         INNER join
         featureloc fl ON (f.feature_id = fl.feature_id)
         INNER join
         feature src ON (src.feature_id = fl.srcfeature_id)
         INNER join
         featureprop fp ON (fp.feature_id = f.feature_id)
         INNER join
         cvterm t ON (t.cvterm_id = fp.type_id)
         INNER join
         (
          $soi
         ) as q ON (f.type_id = q.cvterm_id)
        );
    $sql = sprintf("$sql WHERE %s", $where);
    $self->_get_properties($sql, \%node_h);

    #get GO ontology
    $sql =
      qq(
         select
         f.feature_id,
         gf.name,
         gfx.accession,
         db.name as dbname,
         cv.name as cv
         FROM
         feature f
         INNER join
         featureloc fl ON (f.feature_id = fl.feature_id)
         INNER join
         feature src ON (src.feature_id = fl.srcfeature_id)
         INNER join
         feature_cvterm fcvt ON (f.feature_id = fcvt.feature_id)
         INNER join
         cvterm gf ON (gf.cvterm_id = fcvt.cvterm_id)
         INNER join
         dbxref gfx ON (gf.dbxref_id = gfx.dbxref_id)
         INNER join
         db ON (gfx.db_id = db.db_id)
         INNER join
         cv ON (gf.cv_id = cv.cv_id)
         INNER join
         (
          $soi
         ) as q ON (f.type_id = q.cvterm_id)
         WHERE db.name = 'GO'
         and $where
        );
#use cvterm.dbxref_id
#         cvterm_dbxref cvtx ON (gf.cvterm_id = cvtx.cvterm_id)
#         INNER join
    $self->_get_ontologies($sql, \%node_h);
    return %node_h;
}
sub _get_ontologies {
    my $self = shift;
    my $sql = shift || return;
    my $fhref = shift;
    my %node_h = %{$fhref};
    my $hl = $self->_select_hashlist($sql);
    foreach my $h (@{$hl || []}) {
        my $nodes = $node_h{$h->{feature_id}};
        foreach my $node (@{$nodes || []}) {
            $node->add_ontology($h);
        }
    }
}
sub _get_properties {
    my $self = shift;
    my $sql = shift || return;
    my $fhref = shift || {};

    my %node_h = %{$fhref};
    my $hl = $self->_select_hashlist($sql);
    foreach my $h (@{$hl || []}) {
        my $nodes = $node_h{$h->{feature_id}};
        foreach my $node (@{$nodes}) {
            $node->add_property($h);
        }
    }
}
sub _get_dbxrefs {
    my $self = shift;
    my $sql = shift || return;
    my $fhref = shift || {};

    my %node_h = %{$fhref};
    my $hl = $self->_select_hashlist($sql);
    foreach my $h (@{$hl || []}) {
        my $nodes = $node_h{$h->{feature_id}};
        foreach my $node (@{$nodes || []}) {
            $node->add_dbxref($h);
        }
    }
}
sub _get_auxillaries4features {
    my $self = shift;
    my $lfl = shift;
    my $opts = shift || {};

    my ($sql, $where);

    #get dbxref: assumption is dbxref on gene level feature
    my (%top_h, %node_h);
    map{$top_h{$_->id}++; push @{$node_h{$_->id}}, $_}@{$lfl || []};
    my $f_ids = join(",",(keys %top_h));
    $sql =
      qq(select
         f.feature_id,
         xref.accession,
         db.name as dbname
         FROM
         feature f
         INNER join
         feature_dbxref fxref ON (f.feature_id = fxref.feature_id)
         INNER join
         dbxref xref ON (fxref.dbxref_id = xref.dbxref_id)
         INNER join
         db ON (db.db_id = xref.db_id)
         WHERE f.feature_id IN ($f_ids)
        );
    $self->_get_dbxrefs($sql) if ($f_ids, \%node_h);

    #get properties: assumption: on gene and transcript level
    my %sec_h;
    map{map{$sec_h{$_->id}++; push @{$node_h{$_->id}}, $_}@{$_->nodes || []}}@{$lfl || []};
    my $fp_ids = join(",",(keys %top_h, keys %sec_h));
    $sql =
      qq(select
         f.feature_id,
         t.name as type,
         fp.value,
         fp.rank
         FROM
         feature f
         INNER join
         featureprop fp ON (fp.feature_id = f.feature_id)
         INNER join
         cvterm t ON (t.cvterm_id = fp.type_id)
         WHERE f.feature_id IN ($fp_ids)
        );
    $self->_get_properties($sql, \%node_h) if ($fp_ids);

    #get GO ontology: assumption: on gene level
    $sql =
      qq(
         select
         f.feature_id,
         gf.name,
         gfx.accession,
         db.name as dbname,
         cv.name as cv
         FROM
         feature f
         INNER join
         feature_cvterm fcvt ON (f.feature_id = fcvt.feature_id)
         INNER join
         cvterm gf ON (gf.cvterm_id = fcvt.cvterm_id)
         INNER join
         dbxref gfx ON (gf.dbxref_id = gfx.dbxref_id)
         INNER join
         db ON (gfx.db_id = db.db_id)
         INNER join
         cv ON (gf.cv_id = cv.cv_id)
         WHERE db.name = 'GO' and f.feature_id IN ($f_ids)
        );
#use cvterm.dbxref_id
#         cvterm_dbxref cvtx ON (gf.cvterm_id = cvtx.cvterm_id)
#         INNER join
    $self->_get_ontologies($sql, \%node_h) if ($f_ids);
    return $lfl;
}

=head2 get_handle

gets a DBI handle for a database. also sets up error tracing and
logging depending on env variables LOGFILE amd DBI_TRACE_LEVEL and
DBI_TRACE_FILE.

=cut

sub get_handle {
    my $self = shift;
    my $database_name = shift || confess("You must specify db name");

    my $loc = name2locator($database_name);
    if ($loc) {
        $database_name = $loc;
    }

    my $dbms = "Pg"; 

    if ($database_name =~ /:/) {
        ($dbms, $database_name) = split(/:/, $database_name);
        $ENV{DBMS} = $dbms;
    }

    my $dsn = "dbi:$dbms:$database_name";

    my $dbn = $database_name;
    my $host;
    if ($database_name =~ /\@/) {
        ($dbn,$host) = split(/\@/, $database_name);
        $dsn = "dbi:$dbms:database=$dbn:host=$host";
    }

    if ($dsn =~ /^dbi:pg/i) {
        $dsn =~ s/^dbi:pg/dbi:Pg/;
        $dsn =~ s/:database/:dbname/;
        $dsn =~ s/:host/;host/;
        if ($dsn !~ /:dbname/) {
            $dsn =~ s/^dbi:Pg:/dbi:Pg:dbname=/;
        }
    }

    if ($ENV{DBI_PROXY}) {
        $dsn = "DBI:Proxy:$ENV{DBI_PROXY};dsn=$dsn";
    }

    my $opt_user= ''; my $opt_password= '';
    my $dbh;
    eval {
        $dbh= DBI->connect($dsn,$opt_user,$opt_password)
    };
    if ($@ || !$dbh) {
        my $err=$@;
        confess(-text=>"Can't connect to $dsn",
				-reason=>$err);
    }
    if ($dbh->{proxy_client}) {
        $dbh->{proxy_client}->{maxmessage} = 20000000;
    }

    $dbh->{private_database_name} = $database_name;
    $dbh->{private_dbms} = $dbms;
    $dbh->{private_dbhost} = $host;
    eval {$dbh->{AutoCommit} = 0};
    $dbh->{private_dsn_str} = $dsn;
    # default behaviour should be to chop trailing blanks;
    # this behaviour is preferable as it makes the semantics free
    # of physical modelling issues
    # e.g. if we have some code that compares a user supplied string
    # with a database varchar, this code will break if the varchar
    # is changed to a char, unless we chop trailing blanks
    $dbh->{ChopBlanks} = 1;

    if ($ENV{DBI_TRACE_LEVEL}) {
        if ($ENV{DBI_TRACE_FILE}) {
            DBI->trace($ENV{DBI_TRACE_LEVEL}, $ENV{DBI_TRACE_FILE});
        }
        else {
            DBI->trace($ENV{DBI_TRACE_LEVEL});
        }
    }

    print STDERR "get_handle: $database_name\n";

    # set lock mode to wait
    if (!$ENV{DBMS} || $ENV{DBMS} ne "mysql" && lc($ENV{DBMS}) ne 'pg') {
        my $sth =
          $dbh->prepare("set lock mode to wait 120") ||
            confess $dbh->errstr;
        $sth->execute() ||
          confess $dbh->errstr;
    }

    return $dbh;
}

sub name2locator {
    my $name = shift;
    my $loc;
    if (-f "/data/bioconf/bioresources.conf") {
        open(F, "/data/bioconf/bioresources.conf") || warn("cant open conf");
        while(<F>) {
            chomp;
            next if /^\#/;
	    s/^\!//;
            my @f=split(' ', $_);
            if ($f[0] &&
                $f[0] eq $name &&
                $f[1] eq "rdb") {
                $loc = $f[2];
                last;
            }
        }
        close(F);
    }
    return $loc;
}

=head2 close_handle

closes a database connection

=cut

sub close_handle {

    my $dbh = shift->dbh;

    $dbh->disconnect();
    print STDERR "close_handle: $dbh->{private_database_name}\n" if ($ENV{SQL_TRACE});
}

*disconnect = \&close_handle;


sub commit {
    my $dbh = shift;
    if (!$ENV{DBMS} || $ENV{DBMS} ne "mysql") {
        $dbh->commit;
        print STDERR "commit\n";
    }
}

=head2 set_isolation_level

set the isolation level (must be ANSI standard)

 args: dbh, isolation level 
 exceptions: SQL errors

=cut

sub set_isolation_level {
    my $dbh = shift;
    my $isolation_level = shift;
    if (!$ENV{DBMS} || $ENV{DBMS} ne "mysql") {
        my $sth = 
          $dbh->prepare("set transaction isolation level $isolation_level") ||
            confess $dbh->errstr;

        # if we are not in transaction mode, this
        # will issue a 
        $sth->execute();
    }
}


=head2 set_handle_readonly

args: dbh

=cut

sub set_handle_readonly {
    my $dbh = shift;
    set_isolation_level($dbh, "read uncommitted");    # Use ANSI standard
}


=head2 set_handle_readwrite

args: dbh

=cut

sub set_handle_readwrite {
    my $dbh = shift;
    set_isolation_level($dbh, "read committed");     # Use ANSI standard
}

sub sql_q {
    my $string = shift;
    # escape real quotes by double-quoting
    $string =~ s/\'/\'\'/g;
    return "'".$string."'";
}
*sql_quote = \&sql_q;

sub _select_hashlist {
    my $self = shift;
    my $dbh = $self->dbh;
    my $sql = shift;

    printf STDERR "SQL: %s\n", $sql if ($ENV{SQL_TRACE});
    my $t = time;
    my $sth = $dbh->prepare($sql);
    my $hashr;
    my @hrows;
    $sth->execute() ||
      confess $dbh->errstr;
    while ($hashr = $sth->fetchrow_hashref) {
        if ($hashr) {
            push @hrows, $hashr;
        } else {
            if ($sth->err) {
                confess($sth->err);
            } else {
                $sth->finish;
            }
        }
    }
    printf STDERR "   SQLTime: %d\n", (time - $t) if ($ENV{SQL_TRACE});

    return \@hrows;
}
sub _select_objhash {
    my $self = shift;
    my $dbh = $self->dbh;
    my $sql = shift;
    my $opts = shift || {};

    printf STDERR "SQL: %s\n", $sql if ($ENV{SQL_TRACE});
    my $t = time;
    my $sth = $dbh->prepare($sql);
    my $h;

    $sth->execute() ||
      confess $dbh->errstr;

    my @sec_loc_attr = $self->_loc_attr;
    my %node_h;
    my %span_attr_h;
    while ($h = $sth->fetchrow_hashref) {
        if ($h) {
            confess("cycle") if ($h->{feature_id} eq $h->{parent_id});
            #same feature_id obj has separate instance when having diff parent_id
            #need parent_id in obj for xml dump without asking parent
            my $k = sprintf("%d",$h->{feature_id});
            my $nodes = $node_h{$k};
            my $node;
            foreach my $n (@{$nodes || []}) {
                if ($h->{parent_id} == $n->hash->{parent_id}) {
                    $node = $n;
                }
            }
            unless ($node) {
                $node = SOI::Feature->new($h);
                push @{$node_h{$k}}, $node;
            }
            #rank indicates secondary loc, another rank(renamed orderrank) for feature order
            if ($h->{rank}) {
                my %sec_loc_h;
                map {$sec_loc_h{$_} = $h->{$_}}('src_seq',@sec_loc_attr);
                $node->add_secondary_location({%sec_loc_h});
            }
            my $parent = $node_h{$h->{parent_id}};
            map{$_->add_node($node)}@{$parent || []};
        } else {
            if ($sth->err) {
                confess($sth->err);
            } else {
                $sth->finish;
            }
        }
    }

    printf STDERR "\nObjTime: %d\nnum node=%d\n", (time - $t), scalar(keys %node_h);

    return %node_h;
}


1;
