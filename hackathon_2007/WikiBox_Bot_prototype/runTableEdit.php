<?php
# need to configure with paths to maintenance scripts and TableEdit
$wikiPath = "/Library/WebServer/Documents/wiki";
set_include_path(get_include_path() . PATH_SEPARATOR . $wikiPath);

$tableEditPath = "/Library/WebServer/Documents/wiki/extensions/TableEdit";
require_once "$wikiPath/maintenance/commandline.inc";
require_once "$tableEditPath/class.wikiBox.php";
require_once "$tableEditPath/SpecialTableEdit.body.php";

#print_r($optionsWithArgs);
#print_r($args);
#print_r($options);

if(!isset($options) || isset($options['h'])) echo help();

if (isset($options['box'])){
	global $wgUser;
	$box = new wikiBox($options['box']);
	$tableEdit = new TableEdit();
	
	$box->set_from_db();
	$title = Title::newFromID($box->page_uid);

	if (isset($options['userid'])){
		$wgUser->setID( $options['userid'] );
		$wgUser->loadFromId();
	}

	$tableEdit->save_to_page($title, $box);

#	print_r($wgUser);
#	print_r($tableEdit);

} # end if box

#echo "done\n";

function help(){
	return "
use args

--box=box_uid for an individual box
--userid=user_id for userid
--user=username

other options coming maybe someday 
	
\n";
}
?>