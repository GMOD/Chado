#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;
                                                                                
$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
$file .= $^O eq 'VMS' ? '.com' : '.pl';
                                                                                
open OUT,">$file" or die "Can't create $file: $!";
                                                                                
print "Extracting $file (with variable substitutions)\n";
                                                                                
print OUT "$Config{startperl}\n";

print OUT <<'!NO!SUBS!';
use strict;
use Cwd;
use FindBin '$Bin';
                                                                                
foreach (@ARGV) {
  $_ =~ s/^\'(.*)\'$/$1/;
}
                                                                                
my %options = map {split /=/} @ARGV;
my $gmod_root = $options{GMOD_ROOT};
my $log_dir   = "$gmod_root/logs";

if (! (-e $log_dir)) {
    mkdir($log_dir, 0777) or die "unable to make $log_dir directory";
}

my $conf_text = qq(
log4perl.logger.SQL.Translator.Producer.Turnkey                  = DEBUG, Producer_Turnkey
log4perl.appender.Producer_Turnkey                               = Log::Log4perl::Appender::File
log4perl.appender.Producer_Turnkey.filename                      = $log_dir/debug_log
log4perl.appender.Producer_Turnkey.layout                        = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Producer_Turnkey.layout.ConversionPattern      =%c - [%d{HH:mm}] %M() in file .../%F{2} (line %L) says: %m%n
                                                                                                                                        
log4perl.logger.Turnkey.Request                                 = DEBUG, Turnkey_Request
log4perl.appender.Turnkey_Request                               = Log::Log4perl::Appender::File
log4perl.appender.Turnkey_Request.filename                      = $log_dir/debug_log
log4perl.appender.Turnkey_Request.layout                        = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Turnkey_Request.layout.ConversionPattern      =%c - [%d{HH:mm}] %M() in file .../%F{2} (line %L) says: %m%n
                                                                                                                                        
log4perl.logger.Turnkey.Util.WebXML                             = DEBUG, Turnkey_Util_WebXML
log4perl.appender.Turnkey_Util_WebXML                           = Log::Log4perl::Appender::File
log4perl.appender.Turnkey_Util_WebXML.filename                  = $log_dir/debug_log
log4perl.appender.Turnkey_Util_WebXML.layout                    = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Turnkey_Util_WebXML.layout.ConversionPattern  =%c - [%d{HH:mm}] %M() in file .../%F{2} (line %L) says: %m%n
                                                                                                                                        
log4perl.logger.Turnkey.Render                                  = DEBUG, Turnkey_Render
log4perl.appender.Turnkey_Render                                = Log::Log4perl::Appender::File
log4perl.appender.Turnkey_Render.filename                       = $log_dir/debug_log
log4perl.appender.Turnkey_Render.layout                         = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Turnkey_Render.layout.ConversionPattern       =%c - [%d{HH:mm}] %M() in file .../%F{2} (line %L) says: %m%n
);

if (-e '/etc/log4perl.conf') {
    warn "You appear to already have a log4perl.conf file in /etc\n";
    warn "Append the following to your conf file:\n";
    warn "#--------------------------------------------------------------#\n";
    warn "$conf_text\n";
    warn "#--------------------------------------------------------------#\n\n";
} else {
    warn "Installing log4perl.conf in /etc...\n";
    open CONF, ">/etc/log4perl.conf" or die "unable to open /etc/log4perl.conf: $!\n";
    print CONF $conf_text;
    close CONF;
}

exit(0);

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

