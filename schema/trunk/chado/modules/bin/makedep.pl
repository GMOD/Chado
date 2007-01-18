#!/usr/local/bin/perl
#
# Hilmar Lapp, hlapp at gmx.net, 2007.
#
# You may use, modify, and distribute this script under the same terms
# as Perl itself. Consult the Perl Artistic License.

use strict;
use Getopt::Long;

#################################################################
# global variables
#################################################################

my @modules = ();
my $mod_names = "";

#################################################################
# main
#################################################################

my $ok = GetOptions("modules=s",\$mod_names);

@modules = split(/[, ]+/,$mod_names);
die "no module(s) provided - use --modules to specify\n" unless @modules;

my $module_name_map = {};
my @schema_mods = ();
foreach my $mod_name (@modules) {
    print STDERR "module $mod_name\n";
    my $module = get_dep_tree($mod_name,$module_name_map);
    $module_name_map->{$mod_name} = $module;
}

@modules = values(%$module_name_map);
foreach my $module (@modules) {
    print_schema($module);
}

#################################################################
# functions
#################################################################

sub get_dep_tree {
    my $mod_name = shift;
    my $module_name_map = shift || {};
    my @deps = ();
    my @new_mods = ();
    my $modf;
    my $mod_file = get_module_sqlfile($mod_name);
    print STDERR "checking module $mod_name for dependencies ...\n";
    open($modf, "<$mod_file") or
        die "cannot open $mod_file for reading: $!\n";
    while (<$modf>) {
        if (/^--\s*:import\s+\S+\s+from\s+(\S+)/i) {
            my $dep = $1;
            chomp($dep);
            push(@deps, $dep);
        }
    }
    close($modf);
    my @dep_mods = ();
    foreach my $dep (@deps) {
        my $dep_mod = $module_name_map->{$dep};
        if (!$dep_mod) {
            $dep_mod = get_dep_tree($dep, $module_name_map);
            $module_name_map->{$dep} = $dep_mod;
        }
        push(@dep_mods, $dep_mod);
    }
    return {'-name'=>$mod_name, '-deps'=>\@dep_mods};
}

sub print_schema {
    my $module = shift;
    return 1 if $module->{-is_printed};
    # need to print dependencies first that have not been printed yet
    foreach my $dep (@{$module->{-deps}}) {
        print_schema($dep) unless $dep->{-is_printed};
    }
    my $mod_name = $module->{-name};
    print STDERR "printing schema for module $mod_name ...\n";
    print "-- ######################################################\n";
    print "-- module $mod_name\n";
    print "-- ######################################################\n";
    my $modf;
    my $mod_file = get_module_sqlfile($mod_name);
    open $modf, "<$mod_file" or
        die "unable to open $mod_file for reading: $!\n";
    while (<$modf>) {
        next if /^--/;
        print $_;
    }
    close($modf);
    $module->{-is_printed} = 1;
    return 1;
}

sub get_module_sqlfile {
    my $mod_name = shift;
    return $mod_name if (-e $mod_name) && (! -d $mod_name);
    return $mod_name."/".$mod_name.".sql";
}
