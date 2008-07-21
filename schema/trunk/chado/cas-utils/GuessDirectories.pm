package GuessDirectories;

# this package never gets installed - it's just used by Build.PL

sub gmod_root {
        for (
             '/usr/local/gmod',
             '/var/lib/gmod',
        )
        {
            return $_ if -d $_;
        }
    return;
}

sub conf {
        for (
            #standard gmod install
            '/usr/local/gmod/conf',

            #biopackages gmod install
            '/var/lib/gmod/conf',
            )
        {
            return $_ if -d $_;
        }
    return;
}

sub cgibin {
        for (
            '/usr/local/apache/cgi-bin',            # standard apache install
            '/usr/local/apache2/cgi-bin',           # standard apache2 install
            '/var/www/cgi-bin',                     # RedHat & Slackware linux
            '/Library/Webserver/CGI-Executables',   # MacOSX
            '/usr/lib/cgi-bin',                     # Ubuntu
            )
        {
            return $_ if -d $_;
        }
    return;
}

sub web_document_root {
    for (
        '/usr/local/apache/htdocs',        # standard apache install
        '/usr/local/apache2/htdocs',       # standard apache2 install
        '/var/www/html',                   # RedHat linux
        '/var/www/htdocs',                 # Slackware linux
        '/Library/Webserver/Documents',    # MacOSX
        '/var/www',                        # Ubuntu
        )
    {
        return $_ if -d $_;
    }
    return;
}


1;

=pod

=head1 SEE ALSO

L<perl>, L<Class::Base>.

=head1 AUTHOR

Taken from GBrowse.

Modified by Ben Faga E<lt>faga@cshl.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2007 Cold Spring Harbor Laboratory

This module is free software; you can redistribute it and/or modify it under
the terms of the GPL (either version 1, or at your option, any later version)
or the Artistic License 2.0.  Refer to LICENSE for the full license text and to
DISCLAIMER for additional warranty disclaimers.

=cut

