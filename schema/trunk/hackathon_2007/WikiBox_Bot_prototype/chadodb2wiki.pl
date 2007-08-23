#! /usr/bin/perl -w

use strict;
use Data::Dumper;
use Carp;
use lib "./";
use WikiBot;
use Data::WikiBotData;
use Data::WikiBotData::WikiBoxRow;
use Data::WikiBotData::ChadoData;
use Data::WikiBotData::Translator;
use IO::Config;
use IO::DB;
use IO::DB::WikiBoxDB;
use IO::DB::ChadoDB;
use Getopt::Long;


# get options

my($adaptor, $box_uid, $help, $params, $username, $in, $out, $where, $timestamp, $template) = '';
GetOptions(
	'a=s'		=> \$adaptor,
	'box=s'		=> \$box_uid,
	'u=s'		=> \$username,
	'p=s'		=> \$params,
	'where=s'	=> \$where,
	'time=s'	=> \$timestamp,
	'template=s'	=> \$template,
	'h'		=> \$help,
	'in'		=> \$in,
	'out'		=> \$out
);

if !($box_uid){croak "no box_uid provided";}


#print "begin...\n";
my $config_loader = Config->new;

my $db = ChadoDB->new;
$config_loader->set_from_file($db,'Conf/chado_trial.conf');

my @fields = qw(name db_id description urlprefix url);
my @tables = qw(db);
my $where = ' LIMIT 1 OFFSET 30';
$where = '';
my $result = $db->getDataHash(\@fields, \@tables, $where);

my $data;
print "<wikirows>\n";
foreach (@$result) {
#	print Dumper($_);
	$data = ChadoData->new;
	$data->data_from_hash($_);
	print "<row>\n";
	print "<box_uid>$box_uid<box_uid>\n";
	print $data->tagged_output."</row>\n";

}
print "</wikirows>\n";







#$data->pkeyID(30);
#$db->load_data($data);
#$data->dump;

#$db->dump;




#print $bot->get_latest_wikipage_text('Sandbox',0);
#$bot->setup('Conf/test_bot.conf');

#for (my $i = 1; $i < 40; $i++){
#	my %input_params = (
#		pkeyID => $i
#	);
#	$bot->load_input(\%input_params);
#	$bot->translate;
#	$bot->save_output;
#}

#$bot->dump;

# create a generic config loader
#$config_loader->set_attributes($bot,'Conf/test_bot.conf');

=item
my $dict = "<dictionary>
Notes notes
Reference(s) reference
GO_ID go_id
Aspect aspect
</dictionary>
";
#$bot->load_dictionary($dict);
# set up the db i/o for wikibox_db
my $wikibox_db = WikiBoxDB->new;
$config_loader->set_attributes($wikibox_db,'Conf/wikibox_db.conf');
#$wikibox_db->connect_db;

# load from existing wikibox row
print "\n\nload wiki row from db where row is known\n";
my $wiki_row = WikiBoxRow->new;
$wiki_row->row_id(10);
$wikibox_db->load_all($wiki_row);
$wiki_row->dump;
#$wiki_row->destroy;

print "\n\nload wiki row headings from box where row_id is not known\n";
$wiki_row = WikiBoxRow->new;
$wikibox_db->load_headings($wiki_row, 'Chado_db_table');
#$wiki_row->dump;
$wiki_row->destroy;


print "\n\nLoad a chado single table object from a hash";
my $chado_row = ChadoSingleTable->new;
$config_loader->set_attributes($chado_row,'Conf/Chado_db_table.conf');
my %hash = (
	fruit => 'banana',
	'time' => 'arrow',
	dog => 'bark'
);
$chado_row->data_from_hash(\%hash);
$chado_row->dump;
print "\n\nAdd data from a db query to Chado";
my $chado_source = ChadoSingleTableDB->new;


my $translator = Translator->new;
$config_loader->set_attributes($translator,'Dictionary/chadodb2wikitemplate');
$translator->dump;

my $output = $translator->translate($chado_row->data);
$wiki_row->data_from_hash($output);
$wiki_row->box_id(5);
$wiki_row->row_id(13);
$wikibox_db->save_all($wiki_row);
#$wikibox_db->dump;
$wiki_row->dump;

#$chado_source->update_db('foo',\%hash, '');
#print Dumper ($result);
#$chado_row->load_fields($result);

#$wiki_row->load_headings_from_DB('Chado_db_table');
#$wiki_row->row_data($result);
#$wiki_row->data('description','new description');

#$chado_row->dump;
#$wikibox_db->dump;
#$config_loader->dump;
=cut
#print "done\n";