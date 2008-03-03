package runtime;

#person in charge of this package
my $package_maintainer='Dan Ilut <dci1@cornell.edu>';


#runtime printer
#########################
sub runtime_print{
    my ($start_time, $action)=@_;
    my $runtime=time-$start_time;
    print "\n$action runtime: ".int($runtime/3600)."H:".int(($runtime%3600)/60)."M:".int($runtime%60)."S\n\n";
}

return 1;
