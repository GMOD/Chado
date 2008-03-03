use strict;

use Class::DBI;
use CXGN::DB::Connection;



package CXGN::DB::Map_low_level::DBI;

use base "Class::DBI";

__PACKAGE__->connection(CXGN::DB::Connection->new_no_connect("sgn")->get_connection_parameters());

    

package CXGN::DB::Map_low_level::Linkage_group;

use base qw ( CXGN::DB::Map_low_level::DBI );

CXGN::DB::Map_low_level::Linkage_group->table("sgn.linkage_group");
CXGN::DB::Map_low_level::Linkage_group->columns(All=>qw(lg_id lg_name map_version_id lg_order));
CXGN::DB::Map_low_level::Linkage_group->columns(primary_key => 'lg_id');
CXGN::DB::Map_low_level::Linkage_group->has_a(map_version_id => "CXGN::DB::Map_low_level::Map_version");



package CXGN::DB::Map_low_level::Map_version;

use base qw ( CXGN::DB::Map_low_level::DBI );

CXGN::DB::Map_low_level::Map_version->table("sgn.map_version");
CXGN::DB::Map_low_level::Map_version->columns(All=>qw(map_version_id map_id date_loaded current_version default_threshold));
CXGN::DB::Map_low_level::Map_version->columns(primary_key => 'map_version_id');
CXGN::DB::Map_low_level::Map_version->has_a(map_id => "CXGN::DB::Map_low_level::Map");
CXGN::DB::Map_low_level::Map_version->has_many(linkage_groups => "CXGN::DB::Map_low_level::Linkage_group");



package CXGN::DB::Map_low_level::Map;

use base "CXGN::DB::Map_low_level::DBI";

CXGN::DB::Map_low_level::Map->table('sgn.map');
CXGN::DB::Map_low_level::Map->columns(All => qw/map_id short_name long_name abstract map_type parent1 parent2/ );
CXGN::DB::Map_low_level::Map->columns(primary_key => 'map_id');
CXGN::DB::Map_low_level::Map->has_many(map_versions => "CXGN::DB::Map_low_level::Map_version");



package CXGN::DB::Map;

use base "CXGN::DB::Map_low_level::Map";



package CXGN::DB::Linkage_group;

use base "CXGN::DB::Map_low_level::Linkage_group";


