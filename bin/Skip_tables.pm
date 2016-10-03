package Skip_tables;
use strict;

use vars qw(@ISA @EXPORT_OK @skip_tables);

require Exporter;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(@skip_tables);

@skip_tables = ('gencode_codon_aa',
                'gencode_startcodon',
                'gencode');


1;

