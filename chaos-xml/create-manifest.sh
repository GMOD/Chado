cvs status | perl -ne 'print "$1\n" if m@Repository revision.*/cvsroot/gmod/schema/chado/chaos\-xml/(.*),v@' > MANIFEST
