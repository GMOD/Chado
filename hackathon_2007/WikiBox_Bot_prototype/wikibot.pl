#! /usr/bin/perl -w

use strict;
use Data::Dumper;
use Carp;
use lib "./";
use WikiBot;
use Getopt::Long;

my $bot = WikiBot->new;

my($adaptor, $help, $params, $username, $in, $out, $where, $timestamp, $template) = '';
GetOptions(
	'a=s'		=> \$adaptor,
	'u=s'		=> \$username,
	'p=s'		=> \$params,
	'where=s'	=> \$where,
	'time=s'	=> \$timestamp,
	'template=s'	=> \$template,
	'h'		=> \$help,
	'in'		=> \$in,
	'out'		=> \$out
);
#print "$adaptor, $username, $params, $in, $out\n";
#$bot->configure('JimHu','JimHu/testadaptor1');

# get input from command line, decide what to do
if ($in && $out){
	print "\nCan't do input and output at the same time\n\n";
	print help();
	exit;
}
if ($in && ($username eq '' || $adaptor eq '')){
	print "\nMissing username or adaptor name\n\n";
	print help();
	exit;
}
if ($help || (!$in && !$out)) { 
	print help();
	exit;
};


print "begin...\n";

$bot->configure($username, $adaptor);

if ($in){
	my $line_;
	my $input = '';
	while (defined($_ = <>) && $_ ne '') {
	  # process $line here
	  $input .= $_;
	}
#	$input =~ s/foobar/http:\/\/foobar.org/;
#	print "input:$input\n";
	$bot->save_wikirows($input);


}else{
	# do output
	if (!$where){
		# construct the where clause from params
		if ($timestamp|| $template || $params){$where .= "WHERE 1 "}
		if ($timestamp){$where .= " AND row.timestamp >= '$timestamp' "}
		if ($template){$where .= " AND template = '$template' "}
		if ($params){$where .= "AND ($params) "}
	}
	print $bot->get_wikirows($where);

}

#print $bot->get_wikirows("WHERE template = 'XML_table_test'");
#my $xml = $bot->get_wikirows("WHERE template != 'GO_table_product'");





#$bot->dump;

sub help{
	return "
wikibot.pl takes input and either returns a list of wiki table rows that match some set of criteria or updates a wiki through the TableEdit system.  
General Parameters:

	Required:	
		-in || -out	set the bot for taking input to the wiki or sending output from the wikibox db


For Input
The bot expects input in the form of a pseudo-XML format similar to its own output. Example

		-in
		-u username	<username>	required: username of the bot user
		-a adaptor	<wikipage>	required; page where various other parameters are stored in the wiki 

	when set for input, wikibot.pl listens on STDIN for text in the wikibox bot exchange format described below.

For Output
	
		-out
		-where <where clause> 	optional: the where part of an sql select query.  Be sure to include 'WHERE' in the clause
		-params <conditions>	optional: same as where, but you don't need the word 'WHERE'
		
Wikibot exchange format

\n";	

}

print "done\n";