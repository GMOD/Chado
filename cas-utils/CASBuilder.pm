package CASBuilder;

use strict;
use base 'Module::Build';
use File::Spec::Functions qw( catfile catdir );
use File::Path;
use File::Copy;

sub ACTION_build {
    my $self = shift;
    $self->SUPER::ACTION_build;

    my $PL_file = 'lib/Bio/GMOD/CAS/Util.pm.PL';
    $self->run_perl_script($PL_file);

    return;
}


sub ACTION_test {
    my $self = shift;

    warn "No pre-installation tests defined.\n";

    return;
}


sub ACTION_install {
    my $self = shift;

    #install config directory
    my $conf_dir = $self->notes('CONF');
    unless (-d $conf_dir) {
        eval { mkpath( $conf_dir, 0, 0755 ) };
        warn "Can't create conf dir $conf_dir: $@\n" if $@;
    }

    my $from_conf = 'cas_install.conf';
    my $to_conf   = catfile( $conf_dir, 'cas.conf' );
    my $copy_conf = 1;
    if ( -e $to_conf ) {
        $copy_conf
            = $self->y_n( "'$to_conf' exists.  Overwrite?", 'n' );
    }

    $self->copy_if_modified(
        from    => $from_conf,
        to      => $to_conf,
        flatten => 0,
    ) if $copy_conf;

    #install CGIs
    for my $cgi ('apollo_request_region.pl',  'upload_game.pl') {
        my $from_cgi = catfile('cgi-bin', $cgi);
        my $to_cgi   = catfile($self->notes('CGIBIN'), $cgi);

        my $copy_cgi = 1;
        if (-e $to_cgi) {
            $copy_cgi = $self->y_n( "'$to_cgi' exists.  Overwrite?", 'n' );
        }

        $self->copy_if_modified(
            from    => $from_cgi,
            to      => $to_cgi,
            flatten => 0,
        ) if $copy_cgi;
        chmod 0755, $to_cgi or die "Cannot make '$to_cgi' executable: $!\n";
    }

    #make temp dir for writing chado->xml files to in webroot
    my $htdocs = $self->notes('HTDOCS');
    unless (-d $htdocs) {
        eval { mkpath( $htdocs, 0, 0755 ) };
        warn "Can't create htdocs dir $htdocs: $@\n" if $@;
    }   
    chmod 0777, $htdocs;
 
    #make temp dir for writing user->server xml files in /usr/local/gmod
    my $upload_dir = $self->notes('UPLOAD_DIR');
    unless (-d $upload_dir ) {
        eval { mkpath( $upload_dir, 0, 0755 ) };
        warn "Can't create XML upload dir $upload_dir: $@\n" if $@; 
    }
    chmod 0777, $upload_dir;

    #create a apollo.headless
    my $apollo = $self->notes('APOLLO_PATH');
    my $headless = "$apollo.headless";
    if (-e $apollo ) {
        copy($apollo, $headless);
        system("perl -pi -e 's/BUG} -Dlog/BUG} -Djava.awt.headless=true -Dlog/' $headless");
        chmod 0777, $headless;
    }
    else {
        warn "Could not find $apollo; is it installed?";
    }

    $self->SUPER::ACTION_install;
}

1;
