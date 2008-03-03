package CXGN::DB::Physical;

######################################################################
#
#  Name : $Name: not supported by cvs2svn $
#  Author : $Author: nm249 $
#
#  This module exists to serve the needs of scripts for the second
#  generation Physical Mapping database.  It replaces the old
#  modules PhysicalDB.pm and BACDB.pm, both of which can now be
#  considered outmoded.
#
######################################################################

=head1 physical_db_tools.pm

This module is designed to provide all the necessary re-usable functionality
for support of the physical database.  Scripts relating to this database
- be they script for its update and maintenance, or cgi scripts to
allow users to navigate and peruse it, should make use of this module
to connect to and query the db.  Additionally, any functionality
which you notice as being used in multiple scripts is probably best
bundled and added to this module.  This will make it easier to keep
things synchronized.

Note that this module replaces two older modules which used to
service the physical db -- Physical.pm and BACDB.pm.  Neither of
there modules should be used any more and calls to them should be weeded
out of functional code wherever they are found.  (I don't think that
there are too many of them left but you should remove them if you do come
across them.)

I am off for a beer now.

=cut

use strict;
use DBI;
use CXGN::DB::Connection;

######################################################################
#
#  Global variables.
#
######################################################################
# New stuff.
my $physical_db_name = 'Physical2';
my %hosts = ('henbane' => {
		 'user' => 'robert',
		 'password' => 'jasminesaville',
		 'db' => 'Physical2'
		 },
	     'amatxu' => {
		 'user' => 'koni',
		 'password' => 'bitchbadass',
		 'db' => 'physical'
		 },
	     'zamolxis' => {
		 'user' => 'web_usr',
		 'password' => 'tomato',
		 'db' => 'physical'
		 },
             'siren' => {
		 'user' => 'web_usr',
		 'password' => 'tomato',
		 'db' => 'physical'
		 },
	     'toblerone' => {
		 'user' => 'web_usr',
		 'password' => 'tomato',
		 'db' => 'physical'
		 },
	     'sunshine' => {
		 'user' => 'web_usr',
		 'password' => 'tomato',
		 'db' => 'physical'
		 },
	     'sabazius' => {
		 'user' => 'web_usr',
		 'password' => 'tomato',
		 'db' => 'physical'
		 });

my %initial_version = ('updated_by' => 1,
		       'comments' => 'This is the original, unexpurgated version containing all data from the lab.  No user modifications have been made to it.');
# Stuff originally from PhysicalDB.pm
my $users = {'ra97' => 'Robert Ahrens',
	     'eas68' => 'Beth Skwarecki',
	     'yx25' => 'Yimin Xu',
	     'yw84' => 'Eileen Wang'};
my $species = {'tomato' => 'Whatever Rod\'s BAC library is.'};
my $plate_summary = 'plate_summary_version_';
my $plate_report = 'deconvolution_report_plate_';
my $all_reports = 'all_deconvolution_report_version_';
# Stuff originally from BACDB.pm
my $cornell_prefix = 'P';
my $arizona_prefix = 'LE_HBa';
my $stop_col = 'I';
my $stop_filter = 'h';
my $dbh;
my $bac_sth = {};
my $konnex = {'db' => 'physical', 'user' => 'robert'};
my $filter;
my $filter_shift;
my $map_id = 9;


######################################################################
#
#  Static data accessor methods.
#
######################################################################



sub get_current_map_id {
  return $map_id;
}

sub get_physical_db_name () {
    return $physical_db_name;
}


sub get_hosts_table () {
    return \%hosts;
}


sub cornell_prefix () {
    return $cornell_prefix;
}


sub arizona_prefix () {
    return $arizona_prefix;
}


sub get_filter_matrices () {
    # If the filter hashes are not already defined then define them now.
    if (!$filter || !$filter_shift) {
	($filter, $filter_shift) = &initialize_filters();
    }
    # Now return the hash references.
    return ($filter, $filter_shift);
}


sub get_users_hashref () {
    return $users;
}


sub get_species_hashref () {
    return $species;
}


sub get_initial_version_hashref () {
    return \%initial_version;
}


sub get_last_row () {
    # Yes, this is right.  Don't ask me WHY it's called $stop_col, not
    # $stop_row.  Yes, I gaffed.  If you feel like wading through ALL
    # physical_db code (NOT just this module, but ALL SCRIPTS which
    # might reference this module and this method...) and ensuring
    # compliance with this then, by all means, be my guest.
    return $stop_col;
}


######################################################################
#
#  Database query methods.
#
######################################################################


sub connect_physical_db  {

  my $dbh = CXGN::DB::Connection->new('physical');
  return $dbh;

}


sub disconnect_physical_db ($) {

  return; # bah!

}


sub get_user_id ($$) {

    # Queries the database to find the userid for a given user's net-id.
    my ($dbh, $net_id) = @_;
    my $user_sth = $dbh->prepare("SELECT user_id FROM users WHERE net_id=?");
    $user_sth->execute($net_id);
    my $userid = $user_sth->fetchrow_array;
    $user_sth->finish;
    return ($userid || 0);

}


sub get_current_overgo_version ($) {

    # Returns the value of overgo_version listed as current=1 in the
    # table overgo_version.
    my ($dbh) = @_;
    my $stm = "SELECT overgo_version FROM physical.overgo_version WHERE current=1";
    my $sth = $dbh->prepare($stm);
    $sth->execute;
    my $version = $sth->fetchrow_array;
    $sth->finish();
    return ($version || 0);

}


sub get_current_overgo_version_and_updated_on ($) {

  # As get_current_overgo_version, above, but also returns the udpated_on datetime.
  my ($dbh) = @_;
  my ($overgo_v, $updated) = $dbh->selectrow_array("SELECT overgo_version, updated_on FROM physical.overgo_version WHERE current=1");
  return ($overgo_v, $updated);

}


sub get_latest_overgo_version ($;$) {

    # Returns the latest (that is, highest numbered) version stored
    # in the table physical.overgo_version.
    # If the second argument supplied is an integer then it will be
    # used as a user_id to pare down the choices.  Otherwise, the
    # highest version number in the table will be returned.
    my ($dbh, $userid) = @_;
    my $stm = $userid ? "SELECT overgo_version FROM physical.overgo_version WHERE updated_by=$userid ORDER BY overgo_version DESC" : "SELECT overgo_version FROM overgo_version ORDER BY overgo_version DESC";
    my $sth = $dbh->prepare($stm);
    $sth->execute;
    my $version = $sth->fetchrow_array;
    $sth->finish;
    return ($version || 0);

}


sub get_current_fpc_version ($) {

    # Returns the fpc_version.fpc_version marked current in the db.
    my ($dbh) = @_;
    my $sth = $dbh->prepare("SELECT fpc_version FROM physical.fpc_version WHERE current=1");
    $sth->execute;
    my $fpc_version = $sth->fetchrow_array;
    $sth->finish;
    return ($fpc_version || 0);

}


sub get_current_fpc_version_and_date ($) {

    # Same as above, save that it returns a date as well.
    my ($dbh) = @_;
    my ($fpc_version, $date) = $dbh->selectrow_array("SELECT fpc_version, updated_on FROM physical.fpc_version WHERE current=1");
    return ($fpc_version, $date);

}


sub get_plate_id ($$) {

    my ($dbh, $plateno) = @_;
    my $sth = $dbh->prepare("SELECT plate_id FROM physical.overgo_plates WHERE plate_number=?");
    $sth->execute($plateno);
    my $plate_id = $sth->fetchrow_array;
    $sth->finish;
    #print STDERR "Got plate_id $plate_id with plate number $plateno.\n";
    return ($plate_id || 0);

}


sub get_plate_number_by_plate_id ($$) {

    my ($dbh, $plate_id) = @_;
    my $sth = $dbh->prepare("SELECT plate_number FROM physical.overgo_plates WHERE plate_id=?");
    $sth->execute($plate_id);
    my $plate_number = $sth->fetchrow_array;
    $sth->finish;
    return ($plate_number || 0);

}


sub get_total_number_of_bacs ($) {

    my ($dbh) = @_;
    my $sth = $dbh->prepare("SELECT COUNT(bac_id) FROM physical.bacs WHERE bad_clone!=1");
    $sth->execute;
    my $total_bacs = $sth->fetchrow_array;
    $sth->finish;
    return ($total_bacs || 0);

}


sub count_all_bacs_which_hit_all_plates {

    my ($dbh, $overgo_version) = @_;
    $overgo_version ||= &get_current_overgo_version($dbh);
    my $sth = $dbh->prepare("SELECT COUNT(DISTINCT b.bac_id) FROM physical.bacs AS b INNER JOIN overgo_associations AS oa  ON b.bac_id=oa.bac_id INNER JOIN probe_markers AS pm ON oa.overgo_probe_id=pm.overgo_probe_id WHERE oa.overgo_version=?");
    $sth->execute($overgo_version);
    my $bac_count = $sth->fetchrow_array;
    $sth->finish;
    return ($bac_count || 0);

}


sub count_all_bacs_which_hit_plate_n {

    my ($dbh, $plateno, $overgo_version) = @_;
    $overgo_version ||= &get_current_overgo_version($dbh);
    my $sth = $dbh->prepare("SELECT COUNT(DISTINCT b.bac_id) FROM physical.bacs AS b INNER JOIN overgo_associations AS oa ON b.bac_id=oa.bac_id INNER JOIN probe_markers AS pm ON oa.overgo_probe_id=pm.overgo_probe_id INNER JOIN overgo_plates AS op ON pm.overgo_plate_id=op.plate_id WHERE oa.overgo_version=? AND op.plate_number=?");
    $sth->execute($overgo_version, $plateno,);
    my $bac_count = $sth->fetchrow_array;
    $sth->finish;
    return ($bac_count || 0);

}


sub count_all_bacs_which_plausibly_hit_all_plates {

    my ($dbh, $overgo_version, $map_id) = @_;
    $overgo_version ||= &get_current_overgo_version($dbh);
    my $sth = $dbh->prepare("SELECT COUNT(DISTINCT b.bac_id) FROM physical.bacs AS b INNER JOIN overgo_associations AS oa ON b.bac_id=oa.bac_id INNER JOIN oa_plausibility AS oap USING(overgo_assoc_id) INNER JOIN probe_markers AS pm ON oa.overgo_probe_id=pm.overgo_probe_id WHERE oa.overgo_version=? AND oap.plausible=1 AND oap.map_id=$map_id");
    $sth->execute($overgo_version);
    my $bac_count = $sth->fetchrow_array;
    $sth->finish;
    return ($bac_count || 0);

}


sub count_all_bacs_which_plausibly_hit_plate_n {

    my ($dbh, $plateno, $overgo_version, $map_id) = @_;
    $overgo_version ||= &get_current_overgo_version($dbh);
    my $sth = $dbh->prepare("SELECT COUNT(DISTINCT b.bac_id) FROM physical.bacs AS b INNER JOIN physical.overgo_associations AS oa ON b.bac_id=oa.bac_id INNER JOIN oa_plausibility AS oap USING(overgo_assoc_id) INNER JOIN physical.probe_markers AS pm ON oa.overgo_probe_id=pm.overgo_probe_id INNER JOIN physical.overgo_plates AS op ON pm.overgo_plate_id=op.plate_id WHERE oa.overgo_version=? AND oap.plausible=1 AND op.plate_number=? AND oap.map_id=$map_id");
    $sth->execute($overgo_version, $plateno);
    my $bac_count = $sth->fetchrow_array;
    $sth->finish;
    return ($bac_count || 0);

}


sub count_wells_with_plausible_hits_on_plate_n {

    my ($dbh, $plateno, $overgo_version, $map_id) = @_;
    $overgo_version ||= &get_current_overgo_version($dbh);
    my $sth = $dbh->prepare("SELECT COUNT(DISTINCT oa.overgo_probe_id) FROM physical.overgo_plates AS op INNER JOIN probe_markers AS pm ON op.plate_id=pm.overgo_plate_id INNER JOIN overgo_associations AS oa ON pm.overgo_probe_id=oa.overgo_probe_id INNER JOIN physical.oa_plausibility oap USING(overgo_assoc_id) WHERE op.plate_number=? AND oa.overgo_version=? AND oap.plausible=1 AND oap.map_id=?");
    $sth->execute($plateno, $overgo_version, $map_id);
    my $wellswithhits = $sth->fetchrow_array;
    $sth->finish;
    return $wellswithhits;

}


sub count_distinct_anchor_points_on_map_chromosome {

#<<<<<<< .mine
#    my ($dbh, $map_id, $chromonum, $overgo_version) = @_;
#=======
    my ($dbh, $map_id, $chromonum, $overgo_version, $map_id2) = @_;
#>>>>>>> .r635
    $overgo_version ||= &get_current_overgo_version($dbh);
    my $sth = $dbh->prepare("SELECT COUNT(DISTINCT md.loc_id) FROM physical.overgo_associations AS oa INNER JOIN physical.oa_plausibility AS oap USING(overgo_assoc_id) INNER JOIN physical.probe_markers AS pm ON oa.overgo_probe_id=pm.overgo_probe_id INNER JOIN sgn.marker_locations AS ml ON pm.marker_id=ml.marker_id INNER JOIN sgn.mapdata AS md ON ml.loc_id=md.loc_id INNER JOIN sgn.linkage_groups USING(lg_id) WHERE oa.overgo_version=? AND md.map_id=? AND lg.lg_name=? AND oap.map_id=?");
    $sth->execute($overgo_version, $map_id, $chromonum, $map_id2);
    my $count = $sth->fetchrow_array;
    $sth->finish;
    return ($count || 0);

}


sub get_plate_as_hash ($$;$) {
    # Return the names of the markers on the plate in a hash whose keys are the letter names
    # of the plate rows and whose values are arrays corresponding to the row contents.

    # N.B. - In the database we count columns on the plates from 1 to 12, whereas the
    # resulting platehashes count columns CS style - from 0 to 11.  This is a probable
    # source of errors which you should try to be aware of.

    my ($dbh, $plateno, $overgo_version) = @_;
    # Check this plate exists.
    my $plate_stats_sth = $dbh->prepare("SELECT plate_id, row_max, col_max FROM physical.overgo_plates WHERE plate_number=?");
    $plate_stats_sth->execute($plateno);
    my ($plate_id, $row_max, $col_max) = $plate_stats_sth->fetchrow_array;
    $plate_stats_sth->finish;
    $plate_id || return 0;
    # Prepare a blank plate hash.
    my %thisplate=();
    $row_max ++;
    for (my $row='A'; $row ne $row_max; $row ++) {
	for (my $col=0; $col<$col_max; $col ++) {
	    $thisplate{$row}[$col] = '_';
	}
    }
    # If given an overgo version, exclude probe_markers deprecated in that version.
    my $platemarkers_stm = $overgo_version ? "SELECT alias, pm.overgo_plate_row, pm.overgo_plate_col FROM physical.probe_markers AS pm LEFT JOIN sgn.marker AS m ON pm.marker_id=m.marker_id LEFT JOIN sgn.marker_alias AS ma ON (m.marker_id = ma.marker_id) LEFT JOIN physical.deprecated_probes AS dp ON (pm.overgo_probe_id=dp.overgo_probe_id AND dp.overgo_version=$overgo_version) WHERE pm.overgo_plate_id=? AND dp.dp_id IS NULL ORDER BY pm.overgo_plate_row, pm.overgo_plate_col" : "SELECT m.marker_name, pm.overgo_plate_row, pm.overgo_plate_col FROM physical.probe_markers AS pm LEFT JOIN sgn.marker AS m ON pm.marker_id=m.marker_id  LEFT JOIN sgn.marker_alias AS ma ON (m.marker_id = ma.marker_id) WHERE pm.overgo_plate_id=? ORDER BY pm.overgo_plate_row, pm.overgo_plate_col";
    my $platemarkers_sth = $dbh->prepare($platemarkers_stm);
    $platemarkers_sth->execute($plate_id);
    # Now insert the retrieved markers into the hash.
    while (my ($mrkr, $row, $col) = $platemarkers_sth->fetchrow_array) {
	$col --;  # This is a bit hacky.  Should have a better policy than this.
	$thisplate{$row}[$col] = $mrkr;
    }
    $platemarkers_sth->finish;
    return \%thisplate;

}


######################################################################
#
#  Database modification methods.
#
######################################################################


sub new_overgo_version ($$) {

    # This subroutine requires the DBH and a registered user's net-id.
    # On a successful operation it creates a new version entry in the
    # overgo_version table and returns that version's overgo_version.
    my ($dbh, $user) = @_;
    my $userid = &get_user_id($user);
    $userid ||  die "ERROR: User with net id $user is not authorized to use this database.\n";
    my $current_datetime = &get_and_format_current_datetime();
    my $version_sth = $dbh->prepare("INSERT INTO physical.overgo_version SET updated_by=?, updated_on=?");
    $version_sth->execute($userid, $current_datetime);
    my $version = $version_sth->{'mysql_insertid'};
    $version_sth->finish;
    return $version;

}


sub new_fpc_version ($$$$;$) {

    # This subroutine requires the DBH and a registered user's net-id.
    # On a successful operation it created a new fpc version entry in
    # the fpc_version table and returns that version's fpc_version.
    # Any comments on this FPC version may optionally be added as a fifth
    # argument.
    my ($dbh, $user, $date, $path, $comments) = @_;
    my $userid = &get_user_id($user);
    $userid || die "physical_db_tools ERROR: User $user is not authorized to use this database.\n";
    my $version_sth = $dbh->prepare("INSERT INTO physical.fpc_version SET updated_on=?, updated_by=?, current=0, fpcfile=?, comments=?");
    $version_sth->execute($date, $userid, $path, $comments);
    my $version = $version_sth->{'mysql_insertid'};
    $version_sth->finish;
    return $version;

}


sub set_current_fpc_version ($$) {

    # This subroutine takes in an INT which is an fpc_version value
    # and sets it as the current one, clearing all non-current values
    # en route.
    # To set no version as "current" pass in a $new_cv value of 0.
    my ($dbh, $new_cv) = @_;
    $new_cv =~ /^\d+$/ || return 0;
    $dbh->do("UPDATE physical.fpc_version SET current=0");
    $dbh->do("UPDATE physical.fpc_version SET current=1 WHERE fpc_version=$new_cv");
    return $new_cv;

}


sub remove_plate_by_plate_id ($$) {

    my ($dbh, $pid) = @_;
    # Get the ids for all the overgo probe_markers on this plate.
    my @probemarkers;
    my $probe_sth = $dbh->prepare("SELECT overgo_probe_id overgo_probe_id FROM physical.probe_markers WHERE overgo_plate_id=?");
    $probe_sth->execute($pid);
    while (my $pm = $probe_sth->fetchrow_array) {
	push @probemarkers, $pm;
    }
    $probe_sth->finish;
    # Remove BAC associations to these probes from overgo_associations
    # and tentative overgo_associations.
    my $clear_overgo_assocs_sth = $dbh->prepare("DELETE FROM physical.overgo_associations WHERE overgo_probe_id=?");
    my $clear_tentative_overgo_assocs_sth = $dbh->prepare("DELETE FROM physical.tentative_overgo_associations WHERE overgo_probe_id=?");
    foreach my $pm (@probemarkers) {
	$clear_overgo_assocs_sth->execute($pm);
	$clear_tentative_overgo_assocs_sth->execute($pm);
    }
    $clear_overgo_assocs_sth->finish;
    $clear_tentative_overgo_assocs_sth->finish;
    # Remove the probe markers which are on this plate.
    $dbh->do("DELETE FROM probe_markers WHERE overgo_plate_id=$pid");
    # Remove the plate iteslf from overgo_plates.
    $dbh->do("DELETE FROM overgo_plates WHERE plate_id=$pid");

}


sub remove_overgo_plate_number ($$) {

    # This subroutine removes an overgo plate from the database, entirely.
    # It removes the plate itself from overgo_plates.
    # It removes its probes from probe_markers.
    # It removes associations to those probes from overgo_associations
    #   and tentative_overgo_associations.
    # Use it wisely.
    my ($dbh, $plateno) = @_;
    my $plate_id = &get_plate_id($dbh, $plateno);
    if ($plate_id) {
	&remove_plate_by_plate_id($dbh, $plate_id);
    } else {
	print STDERR "physical_db_tools::remove_overgo_plate_number WARNING: overgo plate $plateno is not found in the physical database.\n";
    }

}


sub clear_overgo_associations {

  # This doesn't care about map_id. It clears the associations for ALL
  # map_id's.

    # Clears out the OVERGO_ASSOCIATIONS and TENTATIVE_OVERGO_ASSOCIATIONS
    # tables of data for a given overgo version
    my ($dbh, $overgo_version) = @_;
    # Get tentative_association ids from tentative_overgo_associations.
    my @toa=();
    my $get_toa_ids_sth = $dbh->prepare("SELECT tentative_assoc_id FROM physical.tentative_overgo_associations WHERE overgo_version=?");
    $get_toa_ids_sth->execute($overgo_version);
    while (my $toa_id = $get_toa_ids_sth->fetchrow_array) {
	push @toa, $toa_id;
    }
    $get_toa_ids_sth->finish;
    # Now clear out groups from tentative_association_conflict_groups that match those toa_ids.
    my $clear_tacg_sth = $dbh->prepare("DELETE FROM physical.tentative_association_conflict_groups WHERE tentative_assoc_id=?");
    foreach (@toa) {
	$clear_tacg_sth->execute($_);
    }
    $clear_tacg_sth->finish;

    # delete plausibilities for associations in this overgo version
    my $overgo_assocs = $dbh->selectcol_arrayref("SELECT overgo_assoc_id FROM physical.overgo_associations WHERE overgo_version=$overgo_version");
    my $delete_oap = $dbh->prepare("DELETE FROM physical.oa_plausibility WHERE overgo_assoc_id=?");
    for (@$overgo_assocs){
      $delete_oap->execute($_);
    }

    # Now bulk DELETE from overgo_associations and tentative_overgo_associations.
    $dbh->do("DELETE FROM physical.overgo_associations WHERE overgo_version=$overgo_version");
    $dbh->do("DELETE FROM physical.tentative_overgo_associations WHERE overgo_version=$overgo_version");

}


######################################################################
#
#  Support methods.
#
######################################################################


sub get_and_format_current_datetime () {

    # Uses a system call to get the current date and time and format
    # them appropriately for insertion into a mysql DATETIME field.
    my $system_dt = `date +%Y%m%d%T`;
    if ($system_dt =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d:\d\d:\d\d)/) {
	return $1 . "-" . $2 . "-" . $3 . " " . $4;
    } else {
	die "physical_db_tools ERROR: Ill-formatted date retrieved from system: $system_dt\n";
    }

}


sub auto_configure_db_settings () {

    # Determines the appropriate settings with which to connect to
    # the database, based on which machine we are working on.
    my %hosts = %{ &get_hosts_table() };
    my $hostname = `hostname`;
    chomp $hostname;
    if ($hostname =~ /^([^\.]+)\./) { $hostname = $1; }
    if ($hosts{$hostname}) {
	return $hosts{$hostname};
    } else {
	die "physical_db_tools ERROR: Auto-configuration information not known for host $hostname.\n";
    }

}


sub infer_all_BACs_from_filters ($$;$) {

    # This subroutine generates a load file for the physical.bacs table.
    # It does this by iterating through all of the BAC filters used in
    # generating this library.
    # The first argument is the Database Handle ($dbh).
    # The second argument must be the path to a file containing a "\n"
    # delimited list of bad clones.  If no list is available then this
    # argument should be set to 'nobad'.
    # The third argument is the (optional) path to the output file to
    # be written.  If this is absent then a file named bacs.load will
    # be generated in the current working directory.

    my ($dbh, $badclones, $outfile) = @_;
    $outfile ||= 'bacs.load';
    my @rows = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P');
    my ($filter, $filter_shift) = &get_filter_matrices();

    # Read in the list of bad clones from the file $badclones.
    my %badclones=();
    if ($badclones ne 'nobad') {
	open BAD, "<$badclones"
	    or die "ERROR: Can't read from $badclones.\n";
	my @bc = <BAD>;
	close BAD;
	chomp @bc;
	my $pfx = &cornell_prefix();
	foreach (@bc) {
	    $badclones{($pfx . $_)} = 1;
	}
    }

    # Get the species ID from the DB.
    my $species_sth = $dbh->prepare("SELECT species_id FROM physical.species WHERE short_name='tomato'");
    $species_sth->execute();
    my $species_id = $species_sth->fetchrow_array;
    $species_sth->finish;
    $species_id || die "physical_db_tools ERROR: No species_id found in database.\n";

    # Open the file to write this data to.
    open BACS, ">$outfile"
	or die "ERROR: Can't write to file $outfile.\n";

    # Work through the filters and extrapolate the name of every possible BAC.
    my $bac_id=0;
    foreach my $fltr_code (sort keys %$filter_shift) {
	my $shift = $$filter_shift{$fltr_code};
	foreach my $spot (keys %$filter) {
	    my $spot_code = ($$filter{$spot} + $shift);
	    foreach my $row (@rows) {
		for (my $col=1; $col<=24; $col++) {
		    $bac_id ++;
		    my $cu_name = $cornell_prefix . sprintf("%03d", $spot_code) . $row . sprintf("%02d", $col);
		    my $az_name = $arizona_prefix . sprintf("%04d", $spot_code) . $row . sprintf("%02d", $col);
		    my $sp6_end_seq_id=0;
		    my $t7_end_seq_id=0;
		    my $genbank_accession="";
		    my $estimated_length=0;
		    print BACS "$bac_id\t$cu_name\t$az_name\t$species_id\t$sp6_end_seq_id\t$t7_end_seq_id\t$genbank_accession\t" . ($badclones{$cu_name} || "0") . "\t$estimated_length\n";
		}
	    }
	}
    }

    close BACS;

}


sub initialize_filters () {

    # This subroutine populates a pair of hashes which contain information
    # about the BAC filters used in the overgo mapping experiments.

    # Prepare the data for filter A:
    my %filter = ();
    my $val = 0;
    for (my $row=1; $row<7; $row ++) {
	my $col='A';
	while ($col ne $stop_col) {
	    $filter{($row . $col)} = ++ $val;
	    $col ++;
	}
    }

    # Handle other filters.
    my %filter_shift = ();
    my $shift = 0;
    my $f='a';
    while ($f ne $stop_filter) {
	$filter_shift{$f} = $shift;
	$shift += 48;
	$f ++;
    }

    return (\%filter, \%filter_shift);

}


sub BAC_CUID_from_filter ($$$) {

    my ($f_code, $spot, $position) = @_;
    my ($filter, $filter_shift) = &get_filter_matrices();
    $f_code = lc $f_code;
    if (not defined $$filter_shift{$f_code}) {
	print STDERR "WARNING: Filter $f_code not defined.\n";
	return "";
    }
    if (not $$filter{$spot}) {
	print STDERR "WARNING: Spot position $spot unknown.\n";
	return "";
    }
    my $cuname;
    if ($position =~ /(\w)(\d+)/) {
	my ($p_prefix, $p_suffix) = ($1, $2);
	$cuname = $cornell_prefix .
	    sprintf("%03d", ($$filter{$spot} + $$filter_shift{$f_code})) .
		$p_prefix . sprintf("%02d", $p_suffix);
    } else {
	print STDERR "WARNING: Badly formed position spec $position.\n";
	$cuname = "";
    }
    return $cuname;

}


sub BAC_AZID_from_filter ($$$) {

    my ($f_code, $spot, $position) = @_;
    my ($filter, $filter_shift) = &get_filter_matrices();
    $f_code = lc $f_code;
    defined ($$filter_shift{$f_code})
	or die "ERROR: Filter $f_code not defined.\n";
    $$filter{$spot} or die "ERROR: Spot position $spot unknown.\n";
    my $azname;
    if ($position =~ /(\w)(\d+)/) {
	my ($p_prefix, $p_suffix) = ($1, $2);
	$azname = $arizona_prefix .
	    sprintf("%04d", ($$filter{$spot} + $$filter_shift{$f_code})) .
		$p_prefix . sprintf("%02d", $p_suffix);
    } else {
	print STDERR "WARNING: Badly formed position spec $position.  Skipping this BAC.\n";
	$azname = "";
    }
    return $azname;

}


sub print_plate_from_hash ($;*) {

    # Takes in a reference to a hash and prints the plate found therein.
    # If given a STREAM as a second argument prints the hash to that stream.
    # Otherwise, prints to STDOUT.

    my ($plate, $stream) = @_;
    (ref $plate) or die "physical_db_tools::print_plate_from_hash ERROR: Must reference a plate-hash in order to print it.\n";
    $stream ||= *STDOUT;

    for (my $row='A'; $row ne $stop_col; $row++) {
	print $stream "" . join("\t", @{$$plate{$row}}) . "\n";
    }

}


return 1;
