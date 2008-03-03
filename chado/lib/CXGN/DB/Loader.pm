=head1 NAME

CXGN::DB::Loader

=head1 SYNOPSIS

A module for easy creation of command-line, interactive SGN database 
loading programs.

=head1 USAGE

use CXGN::DB::Loader;
 my $loader = CXGN::DB::Loader->new(); 
 $loader->setBasePath('/home/myname/data/');
 $loader->addFile('SIGNALP', 'signalp.txt');
 $loader->addFile('SOMETHING', 'something.txt');
 $loader->addTable({ name=> 'signalp', 
   cols => ['yadda1 PRIMARY KEY REAL', 'yadda2 CHAR REFERENCES cds'] 
   file => 'SIGNALP' #optional, only for 1 file: 1 table
  });

 ## METHOD 1:
 sub signalp_filler {  #Best for multiple files -> one table
	my $self = shift;
	my $file = $self->getFilePath('SIGNALP');
	my $file2 = $self->getFilePath('SOMETHING');
	open(FH2, $file2);
	open(FH, $file);
	$LINE_TOTAL = $self->{file_lines}->{'SIGNALP'}; #globals used for progress bar
	while(<FH>){
		my $line = <FH2>;
		my ($identifier_for_example) = $line =~ /something/;
		my ($yadda1, $yadda2) = /cool_backreffed_regex\t([0-9.]+)\t([A-Z]+)/;
		$LINE++;
		#do more parsing?
		$self->insertRecord('ara_signalp', $var1, $var2);  
		#query handle already created by the time this subroutine executed
		#for efficiency
		
		#Or use:
		#$self->updateRecord('unigene_signalp', '333333', $var1, $var2);
	}
	
 }
 $loader->setFiller('signalp', \&signalp_filler);
 #############

 ## METHOD 2:
 #alternative method, for 1 File to 1 Table (simpler):
 #only insertRecord, not updateRecord can be used this way.
 #Also, we assume that the first column defined for the table is
 #the identifier, and we automatically index this column.
 sub parser {
	my $FH = shift;
	my $line = <$FH>;
	my ($yadda1, $yadda2) = $line =~ /cool_backreffed_regex\t([0-9.]+)\t([A-Z]+)/;
	$LINE++; #for progress bar (increment by more for multiple-line records)
	#more stuff for multi-line parsers...
	#the returned order will be the order that they are filled into the table,	
	return($yadda1, $yadda2); 
 }
 #note that we add parser to FILE identifier, not TABLE name
 $loader->setParser('SIGNALP', \&parser);
 #the following line is unnecessary if you set 'file' attribute of table in addTable()
 $loader->setFillerFile('signalp', 'SIGNALP');  #That's it!
 #############


 $loader->start;  
 # alternatively, you can use $loader->automaticStart;
 # keep in mind that $loader->start has same effect as $loader->automaticStart
 # if the user provides -y (yes-to-all) argument

=head1 AUTHOR

Christopher Carpita <csc32@cornell.edu>

=cut

package CXGN::DB::Loader;

use CXGN::DB::Connection;
CXGN::DB::Connection->verbose(0);
use Getopt::Std; 
our $EXCHANGE_DBH = 1;
use base qw/CXGN::Class::Exporter/;
BEGIN {
	our @EXPORT = qw/ 	
				$LINE 
				$LINE_TOTAL		
				/;
}
our @EXPORT;

use strict;
$| = 1;
our $LINE = 0;  #Line-counter global for progress bar.
our $LINE_TOTAL = 0;

=head1 new()

Initialize loader object, feed it user-provided command line args

=cut

sub new() {
	my $class = shift;
	#command-line params: @_
	my $self = bless {}, $class;
	my($opt_U, $opt_p, $opt_y, $opt_h, $opt_b);
	getopts(qw|U p y h b|);
	if($opt_U){ $self->{dbUser} = $opt_U; }
	if($opt_p) { $self->{dbPass} = $opt_p;}
	if($opt_h) { $self->{dbHost} = $opt_h;}
	if($opt_b) { $self->{dbBranch} = $opt_b;}
	if($self->{dbHost} eq "hyoscine"){
		$self->{dbName} = "cxgn";
	}
	elsif($self->{dbHost} eq "scopolamine") {
		$self->{dbName} = "sandbox";
	}
	if($opt_y) { $self->{automatic} = 1;}
	$self->{tables} = ();
	$self->{table_file} = ();
	$self->{alpha_ordered_tables} = [];
	$self->{ordered_tables} = [];
	$self->{index_firstcol} = ();
	$self->{table_indices} = ();

	$self->{files} = ();
	$self->{file_lines} = ();
	$self->{file_not_found_messages} = [];
	
	$self->{fillers} = ();
	$self->{parsers} = ();
	$self->{lines_parsed} = ();
	$self->{insert_queries} = ();
	$self->{update_queries} = ();
	$self->{permissions} = ();
	$self->{tsearch_actions} = {};
	return $self;
}

#Database handle activities:

=head2 setDBH

use $loader->setDBH($dbh) to set your own custom database connection

=cut

sub setDBH {
	my $self = shift;
	$self->{dbh} = shift;
}

=head2 setSchema

Use this to set the schema to be used for any further operations.
Works before or after database connection is made.

=cut

sub setSchema {
	my $self = shift;
	$self->{dbSchema} = shift;
	if($self->{dbh}) {
		$self->{dbh}->do("SET SEARCH_PATH=" . $self->{dbSchema});
	}
}

=head2 setHost

 Sets the database host to use before a connection is made

=cut

=head2 setDBName

 Set the database name

=cut

sub setDBName {
	my $self = shift;
	$self->{dbName} = shift;
}

sub setHost {
	my $self = shift;
	$self->{dbHost} = shift;
}

sub setBranch {
	my $self = shift;
	$self->{dbBranch} = shift;
}

sub setUser {
	my $self = shift;
	$self->{dbUser} = shift;
}

=head2 connect

Connect to the database. Done automatically on start().
Don't use this if you set the DBH manually.

=cut

sub connect {
	my $self = shift;
	my $dbBranch = $self->{dbBranch};
	$dbBranch ||= "production";
	my $dbSchema = $self->{dbSchema};
	$dbSchema ||= "public";
	my $dbHost = $self->{dbHost};
	$dbHost ||= "rubisco";
	my $dbName = $self->{dbName};
	$dbName ||= "cxgn";
	my $dbUser = $self->{dbUser};
	$dbUser||= "postgres";
	my $dbPass = $self->{dbPass};
	$self->{dbName} ||= "cxgn";
	$dbName = $self->{dbName};
	if(!$dbPass){
		print "\nEnter DB password for user $dbUser: ";
		system("stty -echo");
		my $pass = <STDIN>;
		system("stty echo");
		chomp($pass);
		$dbPass = $pass;
	}
	my $dbh = CXGN::DB::Connection->new({
		dbuser=> $dbUser, dbpass=> $dbPass,
		dbbranch => $dbBranch, dbhost=>$dbHost,
		dbname => $dbName, dbschema=>$dbSchema,
		dbargs => {RaiseError=>0, AutoCommit=>1, PrintError=>0}	
		});
	$self->{dbh} = $dbh;	
	$self->{dbBranch} = $dbBranch;
	$self->{dbSchema} = $dbSchema;
	$self->{dbHost} = $dbHost;
	$self->{dbUser} = $dbUser;
	$self->{dbName} = $dbName;
}

#The meat of the database filler defined by the user: 

=head2 setBasePath

Sets the base path for all of the files on which
your loading script draws data

=cut

sub setBasePath {
	my $self = shift;
	$self->{base_path} = shift;
}

=head2 addFile

 Usage: $loader->addFile('Identifier', 'subfolderOfBasePath/something.txt');
 Adds a file to the loader temporary "repository", which you can access
 through its identifier

=cut

sub addFile {
	my $self = shift;
	my ($file_identifier, $file_path) = @_;
	my $base_path = $self->{base_path};
	$base_path ||= ".";
	unless($base_path =~ /\/$/) { $base_path .= "/" }
	unless(-f $base_path . $file_path) { 
		my $message = "\nFile not found at ${base_path}${file_path}";
		$message .= "Remember to set the base bath before adding files, if you need one\n" unless($base_path);
		push(@{$self->{file_not_found_messages}}, $message);	
	}
	${$self->{files}}{$file_identifier} = $file_path;
}

=head2 getFilePath

Gets the path for a file, given an identifier.  Use this
to open a filehandle in your custom loader subs.

=cut

sub getFilePath {
	my $self = shift;
	my $file_ident = shift;
	my $file_name = ${$self->{files}}{$file_ident};
	my $base_path = $self->{base_path};
	$base_path ||= ".";
	unless($base_path =~ /\/$/) { $base_path .= "/" }
	my $file_path = $base_path . $file_name;
	return $file_path;
}

sub getFileLineCount {
	my $self = shift;
	my $id = shift;
	unless($self->{file_lines}->{$id}){
		my $file_name = $self->{files}->{$id};
		my $file_path = $self->getFilePath($id);
		print STDERR "\nCounting lines in file $id => $file_name...";
		my ($linecount) = `wc -l $file_path`;	
		my ($lines) = $linecount =~ /^(\d+)/;	
		print STDERR $lines;
		$self->{file_lines}->{$id} = $lines;
	}
	return $self->{file_lines}->{$id};
}

sub check_files {
	my $self = shift;
	my @fnfs = @{$self->{file_not_found_messages}};
	return 1 unless @fnfs;
	my $message = "";
	$message .= $_ foreach(@fnfs);
	die $message;
}


=head2 addTable

Usage: $loader->addTable({ name=> "imatable",
	                       cols=> ['column1 INT PRIMARY KEY', 'something CHAR'],
						   file=> "Identifier", #optional
						   index_firstcol => 1  #optional
						  });
 This subroutine is for adding tables to be controlled
 by the loading program.  The first column in this ex. will be 
 indexed using the "parser" method, whereas auto-indexing
 does not occur using the "filler" method, even if you
 specify the index_firstcol flag.

=cut

sub addTable {
	my $self = shift;
	my $args = shift;
	my $table_name = $args->{name};
	my @cols = @{$args->{cols}};
	my $file_ident = $args->{file};
	my $first_index = $args->{index_firstcol};
	my $indices = $args->{index};  #array ref of column names

	unless($table_name && @cols) { die "Need to send a 'name' argument and 'cols' argument w/ at least one column to addTable()"; }
	$self->{tables}{$table_name} = \@cols;
	if($file_ident){
		${$self->{table_file}}{$table_name} = $file_ident;
	}
	if($first_index){
		$self->{index_firstcol}->{$table_name} = 1;
	}
	if($indices){
		$self->{table_indices}->{$table_name} = $indices;
	}
	push(@{$self->{ordered_tables}}, $table_name);
}

sub setTableFile {
	my $self = shift;
	my ($table_name, $file_identifier) = @_;
	${$self->{table_file}}{$table_name} = $file_identifier;
}

sub setParser {
	my $self = shift;
	my ($file_identifier, $sub) = @_;
	${$self->{parsers}}{$file_identifier} = $sub; #reference to &subroutine
}

sub setActionOnCreate {
	my $self = shift;
	my ($table_name, $action) = @_;
	$self->{post_create_actions}->{$table_name} = $action;
}

sub setTsearch {
	my $self = shift;
	my ($table_name, $action) = @_;
	$self->{tsearch_actions}->{$table_name} = $action;
}

sub setFiller {
	my $self = shift;
	my ($table_name, $filler) = @_;
	${$self->{fillers}}{$table_name} = $filler; #ref to &filler
}

#Insert/update functions can be called inside user-defined filler functions, so we
#don't use the _private convention:
sub insertRecord {
	my $self = shift;
	my $table_name = shift;
	my $query = ${$self->{insert_queries}}{$table_name};
	$query->execute(@_) or print STDERR $DBI::errstr;
	$self->progress;
}

sub updateRecord {
	my $self = shift;
	my $table_name = shift;
	my $identifier = shift;
	${$self->{update_queries}}{$table_name}->execute(@_, $identifier);
	$self->progress;
}

#These make the filler get its groove on:
sub automaticStart {
	my $self = shift;
	$self->{automatic} = 1;
	$self->start();
}

=head2 start()

Starts the interactive database-filling program.  This is the last thing
you should call on the handle.  Any code after this call will be 
executed after the user quits the filler program

=cut

sub start {
	my $self = shift;
	$self->check_files();
	$self->connect() unless ($self->{dbh});
	$self->_build_queries();
	if($self->{automatic}){
		print "\n!!! Beginning Automated Table Drop/Creation/Filling...";
		$self->_drop_all_tables();
		$self->_create_all_tables();
		$self->_fill_all_tables();
		$self->_grant_permissions();
		print "\n Finished with Automated Process.\n";
		return;
	}
	my @ordered_tables;
	while(my($table_name, @cols) = each %{$self->{tables}}){
		push(@ordered_tables, $table_name);
	}
	@ordered_tables = sort @ordered_tables;
	$self->{alpha_ordered_tables} = \@ordered_tables;

	### MENU MODE ########################################################
	
	my $oper = "init";
	my $dbh = $self->{dbh};

	while(($oper =~ /^[1-9]+[0-9]*$/) || !($oper =~ /^q/)) {
		system("clear");
		print "*** SGNeric Database Loader (tm) ***"; 
		print "\nUse -y flag on startup ('yes to all') for automated mode\n";
		print "\n\tConnected to database '" . $self->{dbName} . "' on '" . $self->{dbHost} . "' as user '" . $self->{dbUser} . "'";
		print "(" . $self->{dbBranch} . " branch) [Schema: " . $self->{dbSchema} . "]";
		print "\n\n\t(D) DROP ALL Tables";
		print "\n\t(C) CREATE ALL Tables";
		print "\n\t(F) FILL ALL Tables";
		print "\n\t(P) Print file paths";
		print "\n\t(G) GRANT 'SELECT' privileges to web_usr";
		print "\n";
		my $j = 1;
		print "\n\tTable Operations:";	
		foreach(@ordered_tables){
			print "\n\t($j) " . $_; 
			$j++;
		}
	
		print "\n\nEnter the number of the operation (q to quit) and press <enter>: ";
		$oper = <STDIN>;
		chomp($oper);

		if($oper =~ /^D$/){
			print "\n\nAre you sure you want to drop all tables? ['y' to confirm]: ";
			my $delete_resp = <STDIN>;
			chomp($delete_resp);
			if($delete_resp eq 'y'){
				print "\n";	
				$self->_drop_all_tables();
				print "\nPress any key to continue...";
				my $dummy = <STDIN>;
			}
		}
		elsif($oper =~ /^C$/){
			print "\n";
			$self->_create_all_tables();
			print "\nPress any key to continue...";
			my $dummy = <STDIN>;
		}
		elsif($oper =~ /^F$/){
			print "\nAre you sure you want to fill all tables? It will take some time! ['y' to confirm]: ";
			my $fill_resp = <STDIN>;
			chomp($fill_resp);
			if($fill_resp eq 'y'){
				$self->_fill_all_tables();
				print "\nPress any key to continue...";
				my $dummy = <STDIN>;
			}
		}
		elsif($oper =~ /^G$/){
			print "\nGranting web_usr privileges...";
			$self->_grant_permissions();
			print "\nPress any key to continue...";
			my $dummy = <STDIN>;
		}
		elsif($oper =~ /^P$/){
			print "\n\nFiles and Paths:";
			my($k, $v);
			print "\n$k\t=>\t$v" while(($k, $v) = each %{$self->{files}});
			print "\nPress any key to continue...";
			<STDIN>;
		}
		elsif($oper =~ /^[1-9][0-9]*$/){
			if($oper <= @ordered_tables ){
				
				my $suboper = 'init';
				while(!($suboper =~ /^0|q$/)){
					my $table = $ordered_tables[$oper-1];
					system("clear");
					print "\nWorking with table: $table";
					my $table_count_q = $dbh->prepare("SELECT COUNT(*) FROM $table");
					my $exists = 0;
					if($table_count_q->execute()) { $exists = 1; }
					my @result = $table_count_q->fetchrow_array();
					my $count = $result[0];
					print "\n\nRecords currently in table: $count";
					print "\n\n\t(q) <---Back to Main Menu";
					print "\n\t(c) CREATE table $table";
					if($exists) {
						print "\n\t(d) DROP table $table";
						print "\n\t(f) Fill table $table";
						print "\n\t(s) View sample row(s)";
					}
					if($exists && $self->{tsearch_actions}->{$table}){
						print "\n\t(t) Create TSearch2 Column/Index";
					}
					print "\n\t(e) Enter custom postgres query";
					print "\n\nEnter the letter of the operation you wish to perform and press <return>: ";
					$suboper = <STDIN>;

					if($suboper =~ /^d$/ && $exists){
						print "\nAre you sure you want to drop this table? ['y' to confirm]:";
						my $d_conf = <STDIN>;
						if($d_conf =~ /^y$/) { 
							$self->_drop_table($table);	
							print "\nPress any key to continue...";
							my $dummy = <STDIN>;
						}
					}
					elsif($suboper =~ /^c$/){
						$self->_create_table($table);
					}
					elsif($suboper =~ /^t$/){
						my $action = $self->{tsearch_actions}->{$table};
						&$action($self, $table);
						print "\nPress any key to continue...";
						<STDIN>;
					}
					elsif($suboper =~ /^f$/ && $exists){
						$self->_fill_table($table);	
						print "\nPress any key to continue...";
						my $dummy = <STDIN>;
					}
					elsif($suboper =~ /^s$/ && $exists){
						print "\n\nEnter number of rows to sample, or press <enter> for default (20): ";
						my $numrows = <STDIN>;
						if($numrows =~ /^$/){ $numrows = 20; }
						$numrows = int($numrows);
						if($numrows > 0){
							my $sample_query = "SELECT * FROM $table LIMIT $numrows";
							my $sample_q = $dbh->prepare($sample_query);
							$sample_q->execute();
							my @fields = @{$sample_q->{'NAME'}};
							print "\n";
							foreach(@fields) { print "$_\t" }
							while(my @samplerow = $sample_q->fetchrow_array()){
								print "\n";
								foreach my $item (@samplerow){
									print "$item\t";
								}
							}
						}
						else { print "\nInvalid number of rows." }
						print "\nPress any key to continue...";
						my $dummy = <STDIN>;
					}
					elsif($suboper =~ /^e$/){
						print "\n\nCustom Query: ";
						my $query = <STDIN>;
						chomp $query;
						next unless $query;
						my $sth = $dbh->prepare($query);
						my $error = '';
						$sth->execute() or $error = $dbh->errstr;
						if($error){
							print "\n$error";
						}
						else{
							my @fields = @{$sth->{NAME}};
							print "\n\n";
							print $_ . "\t" foreach(@fields);
							while(my @row = $sth->fetchrow_array()){
								print "\n";
								print "$_\t" foreach(@row);
							}
						}
						print "\n\nPress any key to continue...";
						<STDIN>;
					}
					elsif($suboper =~ /^q|0$/){ }
				}	
			}
			else{ print "\nValue out of range"; print "\nPress any key to continue..."; my $dummy = <STDIN>; }
		}
	}
}


### Private subs  ######################################################

sub progress {
	return unless($LINE && $LINE_TOTAL);
	if($LINE==1){ print "\n\nProgress:||"}
	my $step_size = int($LINE_TOTAL / 8) - 1;
	if($LINE==$step_size) { print "===12%"; }
	elsif($LINE==2*$step_size) { print "===25%";}
	elsif($LINE==3*$step_size) { print "===37%";}
	elsif($LINE==4*$step_size) { print "===50%";}
	elsif($LINE==5*$step_size) { print "===62%";}
	elsif($LINE==6*$step_size) { print "===75%";}
	elsif($LINE==7*$step_size) { print "===88%";}
	elsif($LINE==8*$step_size) { print "===100%\n";}
}

sub _fill_table {
	my $self = shift;
	my $table_name = shift;
	
	my $indices = $self->{table_indices}->{$table_name};
	if($indices){	
		print "\nDropping indices...";
		foreach(@$indices){
			$self->{dbh}->do("DROP INDEX ${table_name}_$_")
				and print $_ . " ";
		}
	}

	my $success = 0;
			
	#Fill method, harder for programmer, easier for me!	
	if(exists ${$self->{fillers}}{$table_name}){
		$LINE = 0;
		$LINE_TOTAL = 0;
		my $filler = ${$self->{fillers}}{$table_name};
		print "\nFilling table $table_name...";
		&$filler($self);
		$success = 1;	
	}
	#File/Parser method, easy for programmer, grrr's for me
	if(exists ${$self->{table_file}}{$table_name}) {
		my $file_ident = ${$self->{table_file}}{$table_name};
		unless(exists ${$self->{parsers}}{$file_ident}) { print STDERR "\nError: No parser for $file_ident"; return 0; }
		
		my $cols = ${$self->{tables}}{$table_name};
		my @cols = @$cols;
		my $col_size = @cols;
		my $ident = shift @cols;
		($ident) = $ident =~ /(\w+)/;

#USE 'index' ARGUMENT TO addTable INSTEAD:
# 		if(${$self->{index_firstcol}}{$table_name}){  
# 			print "\nDropping index ${table_name}_$ident...";
# 			$self->{dbh}->do("DROP INDEX ${table_name}_$ident");
# 		}


		unless($self->{automatic}){	
			print "\nDeleting current records from table...Hit <enter> to confirm";
			<STDIN>;
		}
		$self->{dbh}->do("DELETE FROM $table_name");

		my $file_path = $self->getFilePath($file_ident);
		my $FH;
		open($FH, $file_path);
		$LINE_TOTAL = ${$self->{file_lines}}{$file_ident};
		my $parser = ${$self->{parsers}}{$file_ident};
	

		print "\nFilling table $table_name...";
		
		my $orig = $LINE;
		my @data = &$parser($FH);
		if($LINE==$orig){
			$LINE++;
			$self->progress;	 #increment $LINES by one if parser doesn't (default behavior)
		}
	
		until(eof($FH)){
			if ((scalar @data)==$col_size) {
				$self->insertRecord($table_name, @data); 
			}
			$orig = $LINE;
			@data = &$parser($FH);
			$LINE++ if ($orig==$LINE);
		}

		my @cols = ${$self->{tables}}{$table_name};
		my $ident = shift @cols;
		($ident) = $ident =~ /(\w+)/;
		close($FH);
		print "\nDone filling table '$table_name'...";
		print "\nLines processed: $LINE";
		$LINE_TOTAL = 0;
		$LINE = 0;
		unless(${$self->{index_firstcol}}{$table_name}){
			return 1;
		}
		print "\nCreating index on $table_name($ident)...";
		$self->{dbh}->do("CREATE INDEX ${table_name}_$ident ON $table_name($ident)");
		$success = 1;
	}

	if($indices){	
		print "\nCreating indices...";
		foreach(@$indices){
			$self->{dbh}->do("CREATE INDEX ${table_name}_$_ on $table_name($_)")
				and print $_ . " ";
		}
	}
	return $success;
}

sub _fill_all_tables {
	my $self = shift;
	print "\nFilling all tables...";
	while(my($table_name, @cols) = each %{$self->{tables}}){
		$self->_fill_table($table_name);
	}
}

sub _build_queries {
	my $self = shift;
	print "\nBuilding queries...";
	while(my($table_name, $cols) = each %{$self->{tables}}) {
		my @cols = @$cols;
		@cols = grep { ! /\bSERIAL\b/i } @cols;
		my $num_cols = @cols;
		my @col_names = ();
		foreach(@cols){
			my ($name) = /(\w+)/;
			push(@col_names, $name);
		}
		my $ph_string = "?:" x $num_cols;
		my @place_holders = split ":", $ph_string;
		my $sql = "INSERT INTO $table_name ( " . join(", ", @col_names) . " ) VALUES ( " . join(", ", @place_holders) . " )";
		my $query = $self->{dbh}->prepare($sql);
		${$self->{insert_queries}}{$table_name} = $query;
		my $ident_name = shift @col_names;
		my @update_cols = map { $_ . "=?" } @col_names;
		shift @cols;
		shift @place_holders;
		$sql = "UPDATE $table_name SET " . join(", ", @update_cols) . " WHERE $ident_name=?";
		$query = $self->{dbh}->prepare($sql);
		${$self->{update_queries}}{$table_name} = $query;
	}	
}

sub _create_table {
	my $self = shift;
	my $table_name = shift;
	my @cols = @{$self->{tables}->{$table_name}};
#	print @cols;
	print "\nCreating table $table_name...";
	my $sql = "CREATE TABLE $table_name ( " . join(", ", @cols) . " )";
	$self->{dbh}->do($sql) or die "\nProblem with SQL: " . $self->{dbh}->errstr . "\n";
	my $action = $self->{post_create_actions}->{$table_name};
	&$action($self, $table_name) if $action;
}

sub _create_all_tables {
	my $self = shift;
	foreach my $table_name (@{$self->{ordered_tables}}){
		$self->_create_table($table_name);
	}
}

sub _drop_table {
	my $self = shift;
	my $table_name = shift;
	print STDERR "\nDropping table $table_name...";
	$self->{dbh}->do("DROP TABLE $table_name");
}

sub _drop_all_tables {
	my $self = shift;
	print "\nDropping all specified tables";
	while(my($table_name, @cols) = each %{$self->{tables}} ) {
		$self->_drop_table($table_name);
	}
}

sub _grant_permissions {
	my $self = shift;
	print "\nGranting SELECT to web_usr: ";
	while(my($table_name, @cols) = each %{$self->{tables}}) {
		$self->{dbh}->do("GRANT SELECT ON TABLE $table_name TO web_usr");
		print $table_name . " ";
	}
}

#########################################################################
###	
1;###
###
