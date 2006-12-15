package Skip_tables;
use strict;

use vars qw(@ISA @EXPORT_OK @skip_tables);

require Exporter;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(@skip_tables);

@skip_tables = ('affymetrixprobeset',
                'affymetrixprobe',
                'affymetrixcel',
                'affymetrixsnp',
                'affymetrixmas5',
                'affymetrixdchip',
                'affymetrixvsn',
                'affymetrixsea',
                'affymetrixplier',
                'affymetrixdabg',
                'affymetrixrma',
                'affymetrixgcrma',
                'affymetrixprobesetstat',
                'gencode_codon_aa',
                'gencode_startcodon',);



1;

