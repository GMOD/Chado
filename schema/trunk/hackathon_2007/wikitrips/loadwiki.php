<?php
/* loadwiki.php version 0.1
Jim Hu at the Hackathon

takes text from Eric's modware dump and 
1) creates page from template in the wiki if needed
2) makes xml for update, including table - updates table in parallel
*/
# argv[0] is the script name

if (!isset($argv[1])){
        echo "USAGE:
        php loadwiki.php input_filename
\n\n";
        exit;
}
$file = $argv[1];

$wiki_dir = "/var/www/wiki";
$tmp_dir = "tmp";
require_once "$wiki_dir/maintenance/commandLine.inc";
require_once "common/wiki.php";

$wgUser = User::newFromName('Wikientrybot');
$wgUser->load();
$uid = $wgUser->getID();

$infile = fopen ($file, 'r');
if (!$infile) die ("can't open $file\n");

$line_count = 0;
$change_count = 0;

while (!feof($infile)){
	$line = fgets($infile, 4096);
	$line_count++; echo "working on line $line_count\n";
	$data = parse_line($line, $template);# print_r($data);
        if (!isset($data['page_name']) || $data['page_name']=='') continue;
	$page_template_text = get_wiki_text($data['page_template'],NS_TEMPLATE);
	$table_template_text = get_wiki_text($data['table_template'],NS_TEMPLATE);
	if ($table_template_text == '' || $page_template_text == ''){
		$err_msg =  "ERROR: Something is missing...";
		if ($page_template_text == '') $err_msg .= "\n\tpage template empty or not found\n";
		if ($table_template_text == '')$err_msg .= "\n\t table template empty or not found\n";
		echo $err_msg;
		continue;
	}
	$title = Title::newFromText($data['page_name']);
 	if ( !$title->exists() || get_wiki_text($data['page_name']) == '' ) {
		echo "adding a page for ".$data['page_name']."\n";
                $article = new Article($title);
                if ( !$title->exists()){
			$article->doEdit( 'placeholder', 'Added by wikibot to create page id', EDIT_NEW | EDIT_FORCE_BOT );
		}
		$box_text = make_box($data['page_name'], $data['table_template'], $data);
                $new_page = str_replace("{{{".strtoupper($data['table_template'])."}}}", $box_text, $page_template_text );

		$article->doEdit( $new_page, 'Added by wikibot', EDIT_UPDATE | EDIT_FORCE_BOT );
               	$change_count++;
               	echo "$gene_count genes processed: ".$data['page_name']." is item $change_count\n";
        }else{
		echo $data['page_name']." already exists\n";

		$box_id = get_wikibox_id($data['page_name'], $data['table_template']);
		$box_uid = get_wikibox_uid($box_id);
		$box = new wikiBox();
		$box->box_uid = $box_uid;
		$box->template = $table_template;
		$box->set_from_DB();
		$rows = get_wikibox_rows($box, $uid, $data['metadata']);
 		if (count($rows) == 0){
 			$row = $box->insert_row('',$uid);
               		$rows[] = $row->row_index; #echo "adding new row row_index = ".$row->row_index."\n";
              		$row->db_save_row();
		}
		#print_r($rows);
                # usually this should only happen once, but it comes as an array.
		$function = "do_".$table_template;
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
 	}
}

echo "done!\n";

# ============ functions =========================
function parse_line($line){
	$tmp = explode("\t",$line);
	$data['page_name'] = trim($tmp[0]);
       	$data['page_template'] = trim($tmp[1]);
	$data['table_template'] = trim($tmp[2]);
       	$data['row_data'] = trim($tmp[3]);
	$data['metadata'] = trim($tmp[4]);
	return $data;
}

# obsolete
function do_gene_info_table($box, $row, $data){
	return $data['row_data'];
}
?>