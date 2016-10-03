#########################
use strict;
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
use lib 'lib';
BEGIN { use_ok('Bio::Chado::LoadDBI') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

