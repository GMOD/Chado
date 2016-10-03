#!/usr/bin/env perl 

use strict;
use warnings;
use Data::Stag;
use FileHandle;
use Getopt::Long;
use Tk;
use SQL::Translator;
use Data::Dumper;

my ($HELP, $OUTFILE, $INFILE, $ONLY_SQL);

my $rows_of_stuff=28;

GetOptions(
  'help'      => \$HELP,
  'outfile=s' => \$OUTFILE,
  'infile=s'  => \$INFILE,
  'only_sql'  => \$ONLY_SQL,
);

if ($HELP) {
    system ("pod2text", $0);
    exit(0);
}

my $SCHEMA_FILE  = $OUTFILE || "chado_schema.sql";
my $metafile     = $INFILE  || "chado-module-metadata.xml";

my $schema_md = Data::Stag->parse($metafile);

my $module_dir = $schema_md->get('modules/source/@/path');
my @modules = $schema_md->get('modules/module');
my @components = $schema_md->get('modules/module/component');
my %module_h = map {$_->sget('@/id') => $_} (@modules, @components);
my @module_ids = map {$_->sget('@/id')} @modules;

# Tk - root frame
my $mw = MainWindow->new;
$mw->title("Chado Admin Tool");
my $mframe = $mw->Frame;

my $row = 0;
my $column1 = 1;
my %button_h = ();
foreach my $id (@module_ids) {
    my $mod = $module_h{$id};
    attach_module_checkbutton($id);

    # components associated with this module
    my @components = $mod->get('component');
    foreach my $component (@components) {
        my $c_id = $component->sget('@/id');
        attach_module_checkbutton($c_id, 1);
    }

}

my $translate_to;

$mframe->Checkbutton(-text=>"SQL only",
                     -variable => \$ONLY_SQL)->grid;
$mframe->Button(-text=>"Select All",
                -command=>\&select_all)->grid(-column=>1,-row=>$rows_of_stuff+2);
$mframe->Button(-text=>"Deselect All",
                -command=>\&deselect_all)->grid(-column=>2,-row=>$rows_of_stuff+2);

$mframe->Button(-text=>"Create Pg Schema",
                -command=>\&create_schema)->grid(-column=>3,-row=>$rows_of_stuff+2);

my @optionlist = ('Oracle','MySQL','Diagram','GraphViz','HTML');
$mframe->Label( -text=>"Translate to:")->grid(-column=>4,-row=>$rows_of_stuff+2);
$mframe->Optionmenu (-options => \@optionlist,
                -variable => \$translate_to)->grid(-column=>5,-row=>$rows_of_stuff+2);
$mframe->Button(-text=>"Translate Schema",
                -command=>\&translate_schema)->grid(-column=>6,-row=>$rows_of_stuff+2);



$mframe->pack(-side=>'bottom');
MainLoop;

exit 0;
#

sub attach_module_checkbutton {
    my $id = shift;
    my $indent = shift || 0;
    $row++;

    my $col;
    if ($row == $rows_of_stuff+1) {
        $col+=4;
        $row=1;
        $column1=0;
    } elsif ($column1) {
        $col=0;
    } else {
        $col=4;
    }


    my $mod = $module_h{$id};
    my $desc = $mod->sget('description');
    my $status = $mod->sget('status');
    my $is_required = $mod->sget('@/required') ? 1 : 0;

    # button frame: contains button and help ? button
    my $bframe = $mframe->Frame;
    {
        $bframe->Label(-text=>".." x $indent)->pack(-anchor=>'w',-side=>'left')
          if $indent;
        
        my $text = $id;
        my $cb = $bframe->Checkbutton(-text=>$text,
                                      -command=>sub {
                                          module_checkbox_action($id);
                                      });
        $cb->{'Value'} = $is_required;
        $cb->pack(-anchor=>'w',-side=>'left',-fill=>'x',-padx=>0);
        $button_h{$id} = $cb;
    }

    $bframe->grid(-column=>$col++,-row=>$row,-sticky=>'w');

    $mframe->Label(-text=>substr($desc,0,40))->grid(-column=>$col++,-row=>$row,-sticky=>'w');

    my $help_but =
      $mframe->Button(-text=>'?',
                      -foreground=>'red',
                      -command=>sub {
                          my $help_dialog = $mframe->messageBox(-message=>$mod->xml);
                          return;
                      });
    $help_but->grid(-column=>$col++,-row=>$row);

    if ($status) {
        $mframe->Label(-text=>$status->sget('@/code'),
                       -foreground=>'blue')->grid(-column=>$col,-row=>$row);
    }
    $col++;
}

sub module_checkbox_action {
    my $id = shift;
    my $mod = $module_h{$id};
    my $button = $button_h{$id};
    if ($button->{'Value'}) {
        # -- SELECT --
        my @dependencies = $mod->get('dependency/@/to');
        foreach my $dep_id (@dependencies) {
            my $b2 = $button_h{$dep_id};
            if (!$b2->{'Value'}) {
                $b2->select;
                # recursively set dependencies
                module_checkbox_action($dep_id);
            }
        }
    }
    else {
        # -- DESELECT --
        my @dependents = 
          map {
              $_->sget('@/id')
          } $schema_md->qmatch('module',
                               ('dependency/@/to'=>$id));
        foreach my $dep_id (@dependents) {
            my $b2 = $button_h{$dep_id};
            if ($b2->{'Value'}) {
                $b2->deselect;
                # recursively deselect dependents
                module_checkbox_action($dep_id);
            }
        }

        # deselect subcomponents
        my @components = $mod->get('component/@/id');
        foreach my $c_id (@components) {
            my $b2 = $button_h{$c_id};
            if ($b2->{'Value'}) {
                $b2->deselect;
                # recursively set dependencies
                module_checkbox_action($c_id);
            }
        }
    }
    return;
}

sub create_schema {
    my @sql_lines = ();
    foreach my $id (@module_ids) {
        my $mod = $module_h{$id};
        if ($button_h{$id}->{'Value'}) {
            push(@sql_lines, read_source($mod));
        }

        # components associated with this module
        my @components = $mod->get('component');
        foreach my $component (@components) {
            my $c_id = $component->sget('@/id');
            if ($button_h{$c_id}->{'Value'}) {
                push(@sql_lines, read_source($component));
                if (my @subs = $component->get('component')) {
                    foreach my $subcomp (@subs) {
                        push(@sql_lines, read_source($subcomp));
                    }
                }

            }

        }
    }
    my $fh = FileHandle->new(">$SCHEMA_FILE");
    if ($fh) {
        print $fh join('',@sql_lines);
        $fh->close;
        #print `cat $SCHEMA_FILE`;
        $mw->messageBox(-message=>"Pg schema created in file $SCHEMA_FILE");
    } else {
        $mw->messageBox(-message=>"cannot write to $SCHEMA_FILE");
    }
}

sub translate_schema {
    $ONLY_SQL = 1;
    create_schema();

    $mw->messageBox(-message=>"Please wait for the translation (it can take several minutes)");

    my $TRANS_FILE = $SCHEMA_FILE."_$translate_to";
    my $translator = SQL::Translator->new(
        show_warnings       => 1,
    );
   
    my $output = $translator->translate(
        from                => 'PostgreSQL',
        to                  => $translate_to,
        filename            => $SCHEMA_FILE,
    ) or warn $translator->error; 

    my $fh = FileHandle->new(">$TRANS_FILE");
    if ($fh) {
        print $fh $output;
        $fh->close;
        $mw->messageBox(-message=>"$translate_to schema created in file $TRANS_FILE");
    } else {
        $mw->messageBox(-message=>"cannot write to $TRANS_FILE");
    }
}

sub read_source {
    my $mod = shift;
    my $id = $mod->sget('@/id');
    my @sources = $mod->get_source;
    my @lines = ();
    foreach my $source (@sources) {
        my $type = $source->sget('@/type');
        my $path = $source->sget('@/path');
        if ($ONLY_SQL && ($type ne 'sql' || $path =~ /view/ || $path =~ /bridge/ ) ) {
            print STDERR "Skipping source $type $path for $id\n";
            next;
        }
        elsif ($type ne 'sql' && $type ne 'plpgsql') {
            print STDERR "Skipping source $type $path for $id\n";
            next;
        }
        my $f = "$module_dir/$path";
        my $fh=FileHandle->new($f);        
        if ($fh) {
            push(@lines, <$fh>);
            $fh->close;
        }
        else {
            $mw->messageBox(-message=>"cannot find $f");
        }
    }
    return @lines;
}

sub select_all {
    foreach (keys %button_h) {
       $button_h{$_}->{'Value'} = 1;
    }
    return;
}

sub deselect_all {
    foreach (keys %button_h) {
       $button_h{$_}->{'Value'} = 0;
    }
    return;
}


sub usage {
    system( 'pod2usage', $0 );
    exit(0);
}


=pod

=head1 NAME

chado-build-schema.pl - PerlTk application to build and translate a chado schema

=head1 SYNOPSIS

  % chado-build-schema.pl [options]

=head1 COMMAND-LINE OPTIONS

    --help              This usage statement
    --infile            The name of the metadata xml file
                          (default: chado-module-metadata.xml)
    --outfile           The name of the output ddl file
                          (default: chado_schema.sql)
    --only_sql          Only use pure sql (ie, no views or functions)


=head1 DESCRIPTION

This is a perlTk application to help uses interactively build
a chado data definition langauge (ddl/sql) file.  By default, it
builds a PostgreSQL compatible file, but by making use of SQL::Translator,
it can translate the ddl to Oracle or MySQL ddl, or create schema diagrams
or html documentation.  Use of this application is not required if 
the standard default chado schema will be used.

=head1 AUTHORS

Chris Mungall, Scott Cain E<lt>cain@cshl.eduE<gt>

Copyright (c) 2005

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

