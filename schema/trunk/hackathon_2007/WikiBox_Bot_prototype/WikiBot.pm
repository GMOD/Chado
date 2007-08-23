#! /usr/bin/perl -w
=item
Jim Hu 20070507
Another version based on discussion with Lincoln last week, followed by more thinking

General idea.  
The bot is just a service that does maintenance on the wiki and the wikibox_db.
The bot is invoked by events from TableEdit or from partners

What it has to do
Detect and respond to events

Wiki2Adaptor 
	Accept parameters to convert to an SQL query for wikibox_db
	Map headings to tags based on dictionary
	Return a subset of the wikibox rows as XML-like structures
	
Adaptor2Wiki
	Accept groups of tag-value pairs
	Map tags to headings based on dictionary
	Save or update a set of wikbox rows
	update the wiki via command line php script.	

Tasks for this object class
For Wiki2Adaptor
Adaptor should be able to request information from the bot.
1. Which rows have been updated since last synch.  Adaptor should pass last synch
2. Which rows are from boxes with the desired template.
Return these to the adaptor.

For Adaptor2Wiki

Generic methods
AUTOLOAD based getter/setters for attributes and a 
dump method

=cut

package WikiBot;

use strict;
use Data::Dumper;
use Carp;
use lib "./";
use Data::WikiBotData;
use Data::WikiBotData::WikiBoxRow;
use Data::WikiBotData::Translator;
use IO::Config;
use IO::DB;
use IO::DB::WikiBoxDB;
use CGI qw(:standard);
use XML::Simple;
use Text::Trim;

sub new{
	my $class = shift;
	my $self ={
	};
	bless($self,$class);

=item
object creation for bot
needs to have 
	a configuration object           $self->conf
	a scratch space for wiki data    $self-> wikibox_row
	a dbi for io to the wikibox_db   $self-> wikibox_dbi
=cut
	$self->{start_bot} = time();
	$self->{conf} = Config->new;
	$self->{wikibox_row} = WikiBoxRow->new;
	$self->{wikibox_dbi} = WikiBoxDB->new;
	$self->{conf}->set_from_file($self->{wikibox_dbi},'Conf/wikibox_db.conf');
	return $self;
}

=item
configuration expects 
a string for the adaptor username, which must be a registered user of the wiki 
a pagename for the adaptor
=cut
sub configure{
	my ($self, $user, $adaptor) = @_;
	if ($user){
		if ($self->userid($self->get_uid($user)) == 0){return 0};
		$self->user($user);
	}
	if ($adaptor){
		$self->{adaptor} = XMLin("<xml>".$self->get_latest_wikipage_text("$adaptor",2)."</xml>");	
	}
}


sub load_dictionary{
	my ($self, $dict) = @_;
	my %tmpHash;
	$self->{translator} = Translator->new;
	$self->{conf}->set_from_string($self->{translator},$dict);
#	$self->{translator}->dictionary($dict);
}

=item
get_wiki_rows($params)
params should be a string with "WHERE ..."
headings come from a template.
need to reset dictionary for each record in case they come from differnt templates.
=cut
sub get_wikirows{
	my ($self,$params) = @_;
	my @fields = ('row_id','page_name', 'box_uid', 'template','headings','row_data','page_uid');
	my @tables = ($self->{wikibox_dbi}->db_name.'.box', $self->{wikibox_dbi}->db_name.'.row');
	if ($params && $params ne ''){$params .= ' AND '}else{$params .= ' WHERE '}
	$params = $params .= ' box.box_id = row.box_id ';
	my $results = $self->{wikibox_dbi}->getDataHash(\@fields, \@tables, $params);
	my $wikirows = "<wikirows>\n";
	foreach (@$results){
		$self->{wikibox_row} = WikiBoxRow->new;
		if ($_->{template}){
			$self->{wikibox_row}->template($_->{template});
			$self->headings_from_template($_->{template});

			my @headings = @{$self->{wikibox_row}->headings};
			$self->{wikibox_row}->page_name($_->{page_name});
			$self->{wikibox_row}->page_uid($_->{page_uid});
			$self->{wikibox_row}->row_id($_->{row_id});
			$self->{wikibox_row}->box_uid($_->{box_uid});
			my @data = split('\|\|',$_->{row_data});
			my %datahash;
			for my $i ( 0 .. $#headings){
				$datahash{$headings[$i]} = $data[$i];
			}
			# check for valid dictionary and use if available
			if ($self->{adaptor}->{wikiOut}->{$self->{wikibox_row}->template}->{dictionary}){
				$self->load_dictionary("<dictionary>\n". $self->{adaptor}->{wikiOut}->{$self->{wikibox_row}->template}->{dictionary}. "</dictionary>"); 
				$self->{wikibox_row}->data_from_hash($self->{translator}->translate(\%datahash));
			}else{
				$self->{wikibox_row}->data_from_hash(\%datahash);			
			}
			$wikirows .= "<row>\n".$self->{wikibox_row}->tagged_output."</row>\n";
		}	
	}	
	return $wikirows."</wikirows>\n\n";	
}

=item
pass this method string with row data in tag=>val pairs, similar to the output
save to wikibox_db and then update pages
Have to deal with the possibility of multiple changes to the same page, not necessarily to the same table.
Register the changes and do them all at the end.
=cut
sub save_wikirows{
	my ($self, $input) = @_;
	my $tmp = XMLin($input, KeyAttr=>[]); #turn off stupid code folding default in XML::Simple
	my %changed_pages;
	foreach (@{$tmp->{row}}){
		$self->{wikibox_row} = WikiBoxRow->new;
		my %datahash;

		while (my ($key, $val) = (each %$_)){
		#	print "key:$key val:$val\n";
			if ($key eq 'page_name') {
				$self->{wikibox_row}->page_name($val);
				$changed_pages{$val} = 1;
			}elsif ($key eq 'row_id') {
				$self->{wikibox_row}->row_id($val);
			}elsif ($key eq 'box_uid') {
				$self->{wikibox_row}->box_uid($val);
			}elsif ($key eq 'template') {
				$self->{wikibox_row}->template($val);
				$self->headings_from_template($val);
			}else{
				$datahash{$key} = $val;
			}
		}
		# check for valid dictionary and use if available
		if ($self->{adaptor}->{wikiIn}->{$self->{wikibox_row}->template}->{dictionary}){
			$self->load_dictionary("<dictionary>\n". $self->{adaptor}->{wikiIn}->{$self->{wikibox_row}->template}->{dictionary}. "</dictionary>"); 
			$self->{wikibox_row}->data_from_hash($self->{translator}->translate(\%datahash));
		}else{
			$self->{wikibox_row}->data_from_hash(\%datahash);			
		}
		
	#	$self->{wikibox_row}->dump;
		
		# save to wikibox_db
		if ($self->{wikibox_dbi}->save_row($self->{wikibox_row}, $self->userid) == 1){
			print "saved row ".$self->{wikibox_row}->row_id." at ".time()."\n";
		}else{
			print "save error for ".$self->{wikibox_row}->row_id." at ".time()."\n";
		}

	} # end foreach $tmp->{row}
	# save changes to wiki page via command line php.
	while (my($page, $val) = each (%changed_pages)){
		# val is actually just 1 for all and can be ignored
		my $sql = "SELECT DISTINCT(box_uid), page_uid FROM ".$self->{wikibox_dbi}->db_name.'.box'." WHERE box.timestamp >= '".$self->start_bot."' AND page_name ='$page'";
		my $boxes = $self->{wikibox_dbi}->getData($sql);
		foreach (@$boxes){
		#	print "box_uid:".$_->[0]."\n";
			my $phpcmd = "php5 runTableEdit.php --box=".$_->[0]." --userid=".$self->userid;
			print "\n$phpcmd\n";
			system 	($phpcmd);
		}
	}
}

sub headings_from_template{
	my ($self, $template) = @_;
	my $tmp = XMLin("<xml>".$self->get_latest_wikipage_text($template,10)."</xml>"); 
	if (ref($tmp) && $tmp->{headings}){
		$self->{wikibox_row}->headings(split("\n",trim $tmp->{headings}));
	}else{
		$self->{wikibox_row}->headings(split("\n",trim $tmp));
	}
	my @headings = @{$self->{wikibox_row}->headings};

	for my $i ( 0 .. $#headings){
		my @arr = split('\|\|', $headings[$i]);
		if ($arr[1]){
			my @arr2 = split ('\|',$arr[1]);
			$headings[$i] = $arr2[0];				
		}else{
			$headings[$i] = $arr[0];
		}	
		$headings[$i] =~ s/ /_/g;
	}
	$self->{wikibox_row}->headings(@headings);
}

=item
update_wiki updates the wiki from the changes made to the wikibox_db database
=cut
sub update_wiki{

}
=item
Mediawiki utilties
=cut
#get UID for user from mysql db
sub get_uid{
	my ($self, $user) = @_;
	my   $result = $self->{wikibox_dbi}->getData("SELECT user_id  FROM ".$self->{wikibox_dbi}->wikidb.".user WHERE user_name = '$user'");
	if ($$result[0]){
		return $$result[0][0];
	}else{
		return 0;
	}
}

#get namespace from page_id for user from mysql db
sub get_namespace{
	my ($self, $page_id) = @_;
	my   $result = $self->{wikibox_dbi}->getData("SELECT page_namespace  FROM ".$self->{wikibox_dbi}->wikidb.".page WHERE page_id = '$page_id'");
	if ($$result[0]){
		return $$result[0][0];
	}else{
		return 0;
	}
}

# returns table.id for most recent revision of a page, based on the page title
# options
#	0: exact match for page title
#	1: leading match for page title
#	2: internal match for page_title
# returns number found if either zero or more than one is found.  Requires mysql subs.
sub get_latest_wikipageid{
	my ($self, $page_title, $namespace) = @_;
	#get page_latest
	my $sql = "SELECT page_latest FROM ".$self->{wikibox_dbi}->wikidb.".page WHERE page_title = '$page_title' AND page_namespace = $namespace ORDER BY page_id DESC";
	my $result = $self->{wikibox_dbi}->getData($sql);
	#return false if count isn't one.
	if (!$$result[0]){ return 0};
	my $revision_id = $$result[0][0];
	$sql = "SELECT rev_text_id FROM ".$self->{wikibox_dbi}->wikidb.".revision WHERE rev_id='$revision_id'";
	$result = $self->{wikibox_dbi}->getData($sql);
	if ($$result[0][0]){return $$result[0][0]}
	return 0;

}

sub get_latest_wikipage_text{
	my ($self, $page_title, $namespace) = @_;
	my $text_id = $self->get_latest_wikipageid($page_title, $namespace);
	if ($text_id == 0) {return 0};
	my $sql = "SELECT old_text FROM ".$self->{wikibox_dbi}->wikidb.".text WHERE old_id='$text_id'";
	my $result = $self->{wikibox_dbi}->getData($sql);
	if ($$result[0][0]){return $$result[0][0]}
	return 0;
}


sub AUTOLOAD {
	my $self = shift;
	my $name = our $AUTOLOAD;
	my $prefix = ref ($self);
	$name =~ s/$prefix\:\://;
	return if $name =~/::DESTROY$/;
	if (@_) { return $self->{$name} = shift}
	else	{ return $self->{$name} }
}

sub dump{
	my $self = shift;
	print Dumper($self);
	return 1;
}

1;