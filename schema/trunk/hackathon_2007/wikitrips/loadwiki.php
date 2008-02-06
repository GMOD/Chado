<?php
/* loadwiki.php version 0.2  11/30/2007
Jim Hu at the Hackathon

arguments from command line
-f file with data to be input in IFALT format
-c file with configuration data
*/

# get and load options... initialize

$options = getopt('c:f:'); print_r($options);

if (isset($options['f'])) $file = $options['f'];
if (isset($options['c'])) $config_file = $options['c'];
if (!isset($file) || !isset($config_file)) die ("USAGE:       php loadwiki.php -f input_filename -c config_filename\n\n");

# load config options from the config file
if (is_file("$config_file")) {
	require_once ("$config_file");
}else{
	die ("can't find configuration file at $config_file");
}
if (!isset($wiki_dir)) die ("can't get $wiki_dir from config file\n\n");

if (is_file("$wiki_dir/AdminSettings.php")) {
        unset($_SERVER['REQUEST_METHOD']);
	require_once ("$wiki_dir/AdminSettings.php");
	require_once ("$wiki_dir/maintenance/commandLine.inc");
}else{
	die ("can't find AdminSettings.php - bad wiki path or AdminSettings.php doesn't exist");
}

#load misc. needed functions
require_once "wiki.php";

$wgUser = User::newFromName('Wikientrybot');
$wgUser->load();
$uid = $wgUser->getID();


# open the input file
$infile = fopen ($file, 'r');
if (!$infile) die ("can't open $file\n");

$line_count = 0;
$change_count = 0;

# read the file and process
while (!feof($infile)){
	$line = fgets($infile, 4096);
	if (trim($line) == '') continue;
	$line_count++; #echo "working on line $line_count\n";
	$data = parse_line($line);# print_r($data);
    if (!isset($data['page_name']) || $data['page_name']=='') continue;

	# get the templates
	$page_template_text = get_wiki_text($data['page_template'],NS_TEMPLATE);
	$table_template_text = get_wiki_text($data['table_template'],NS_TEMPLATE);
	if ($table_template_text == '' || $page_template_text == ''){
		$err_msg =  "ERROR: Something is missing...";
		if ($page_template_text == '') $err_msg .= "\n\tpage template empty or not found\n";
		if ($table_template_text == '')$err_msg .= "\n\t table template empty or not found\n";
		echo $err_msg;
		continue;
	}
	
	# look for the page by name
	# need to check behavior on alternate namespaces
	$title = Title::newFromText($data['page_name']);
 	if ( !$title->exists() || get_wiki_text($data['page_name']) == '' ) {
 		# page doesn't exist yet; add a temporary page to create a page_uid
		#echo "adding a page for ".$data['page_name']."\n";
		$article = new Article($title);
		if ( !$title->exists()){
			$article->doEdit( 'placeholder', 'Added by wikibot to create page id', EDIT_NEW | EDIT_FORCE_BOT );
		}
		
		# make the table
		$box_text = make_box($data['page_name'], $data['table_template'], $data); # this adds the data too.
		$new_page = str_replace("{{{".strtoupper($data['table_template'])."}}}", $box_text, $page_template_text );

		$article->doEdit( $new_page, 'Added by wikibot', EDIT_UPDATE | EDIT_FORCE_BOT );
       	$change_count++;
		#echo "$line_count lines processed: ".$data['page_name']." is item $change_count\n";
    }else{
    	# page already exists.  Find the desired box
		#echo $data['page_name']." already exists\n";
		$box_id = get_wikibox_id($data['page_name'], $data['table_template']);
		$box_uid = get_wikibox_uid($box_id);
		$box = new wikiBox();
		$box->box_uid = $box_uid;
		$box->template = $data['table_template'];
		$box->set_from_DB();
		$rows = get_wikibox_rows($box, $uid, $data['metadata']);
 		if (count($rows) == 0){
			$row = $box->insert_row('',$uid);
			$rows[] = $row->row_index; #echo "adding new row row_index = ".$row->row_index."\n";
			$row->db_save_row();
		}
		#print_r($rows);
        # usually this should only happen once, but it comes as an array.

        foreach ($rows as $index=>$row_index){
			$box->rows[$row_index]->row_data = $data['row_data'];
			$box->rows[$row_index]->db_save_row();
			insert_row_metadata($box->rows[$row_index], $data['metadata']);
 		}
 		#print_r($box->rows);
		if ($box){
			$tableEdit = new TableEdit();
			$title = Title::newFromID($box->page_uid);
 			$tableEdit->save_to_page($title, $box);
			unset($box);
		}
 	} # end else - page already exists
} # end while loop reading infile

#echo "done!\n";

# ============ functions =========================
function parse_line($line){
	$tmp = explode("\t",$line);
	if (isset($tmp[6])) parse_str(trim($tmp[6]), $data); # parse column 7
	if (isset($tmp[0])) $data['page_name'] 		= trim($tmp[0]);
    if (isset($tmp[1])) $data['page_template'] 	= trim($tmp[1]);
	if (isset($tmp[2])) $data['table_template'] = trim($tmp[2]);
   	if (isset($tmp[3])) $data['row_data'] 		= trim($tmp[3]);
	if (isset($tmp[4])) $data['metadata'] 		= trim($tmp[4]);
	if (isset($tmp[5])) $data['update_type'] 	= trim($tmp[5]);
	return $data;
}


?>
