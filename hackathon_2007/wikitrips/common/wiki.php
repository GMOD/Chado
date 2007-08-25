<?php
# Jim Hu Sept 2006
# common functions related to wiki manipulation
# should work for mediawiki 1.6-1.7
# 
# function list:
#	get_latest($page_title, $namespace, $opt=0)	:returns rev_text_id from revisions table given a page_title
#	get_latest_text($page_title, $namespace, $opt=0):returns text of most recent revision  from text table given a page_title
#	fix_title($string)				:returns string where forbidden chars for page_title are removed
#							:note that LocalSettings.php can be modified to allow + character
#

$prettytable = "border='2' cellpadding='4' cellspacing='0' style='margin: 1em 1em 1em 0; background: #f9f9f9; border: 1px #aaa solid; border-collapse: collapse;'";

#class autoloader see http://us2.php.net/manual/en/language.oop5.autoload.php
#function __autoload($class_name) {
#   require_once 'class.'.$class_name . '.php';
#}


function get_page_id($page_title, $namespace){

	$title = Title::newFromText($page_title, $namespace);
	$title->exists();
	return $title->getArticleID();
}

# returns table.id for most recent revision of a page, based on the page title
# options
#	0: exact match for page title
#	1: leading match for page title
#	2: internal match for page_title
# returns number found if either zero or more than one is found.  Requires mysql functions.
function get_latest($page_title, $namespace=0, $opt=0){
	global $db;
	#get page_latest
	$sql = "SELECT * FROM page WHERE ";
	switch ($opt){
		case 1:
                        $sql .= "page_title LIKE '".mysql_real_escape_string($page_title)."%' ";
			break;
		case 2;
                        $sql .= "page_title LIKE '%".mysql_real_escape_string($page_title)."%' ";
			break;
		default:
			$sql .= "page_title = '".mysql_real_escape_string($page_title)."' "; 
	}
	$sql .= " AND page_namespace = $namespace ORDER BY page_id DESC";
	$result = do_select($sql);

	#return false if count isn't one.
	if ($result[0]['count'] <> 1) return false;
        $revision_id = $result[1]['page_latest'];
        $sql = "SELECT * FROM revision WHERE rev_id='$revision_id'";
        $result = do_select($sql);
        $text_page_id = $result[1]['rev_text_id'];
	
	return $text_page_id;

}
function get_latest_text($page_title, $namespace=0, $opt=0){
	global $db;
	$text_id = get_latest($page_title, $namespace, $opt=0);
	if (!$text_id) return false;
	$sql = "SELECT * FROM text WHERE old_id='$text_id'";
        $result = do_select($sql);
        return  $result[1]['old_text'];  
}

function get_wiki_text($page_name, $ns = 'NS_MAIN'){
        $title = Title::newFromText($page_name, $ns);
	if (!$title->exists()) return false;
        $revision = Revision::newFromTitle($title);
        if (! $revision) return false;
        return  trim($revision->getText());
}



#template for xml file
function xml_file_header(){
        return  '<mediawiki xmlns="http://www.mediawiki.org/xml/export-0.3/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.mediawiki.org/xml/export-0.3/http://www.mediawiki.org/xml/export-0.3.xsd"
version="0.3" xml:lang="en">
  <siteinfo>
    <sitename>DevWiki</sitename>
    <base>http://yeastgenome-devwiki.stanford.edu/index.php/Main_Page</base>
    <generator>MediaWiki 1.8.0</generator>
    <case>first-letter</case>
      <namespaces>
      <namespace key="-2">Media</namespace>
      <namespace key="-1">Special</namespace>
      <namespace key="0" />
      <namespace key="1">Talk</namespace>
      <namespace key="2">User</namespace>
      <namespace key="3">User talk</namespace>
      <namespace key="4">DevWiki</namespace>
      <namespace key="5">DevWiki talk</namespace>
      <namespace key="6">Image</namespace>
      <namespace key="7">Image talk</namespace>
      <namespace key="8">MediaWiki</namespace>
      <namespace key="9">MediaWiki talk</namespace>
      <namespace key="10">Template</namespace>
      <namespace key="11">Template talk</namespace>
      <namespace key="12">Help</namespace>
      <namespace key="13">Help talk</namespace>
      <namespace key="14">Category</namespace>
      <namespace key="15">Category talk</namespace>
    </namespaces>
  </siteinfo>';
}#end function xml_file_header

function xml_file_footer(){
        return "</mediawiki>";
}#end function xml_file_footer

#template for each page.  Note that namespace is part of Title
function xml_page_template() {
        return '<page>
<title>{{{TITLE}}}</title>
<id>{{{PAGEID}}}</id>
<revision>
        <id>1</id>
        <timestamp>{{{TIMESTAMP}}}</timestamp>
        <contributor>
                <username>{{{USERNAME}}}</username>
                <id>{{{UID}}}</id>
        </contributor>
        <comment>Automated import of articles</comment>
        <text xml:space="preserve">{{{TEXT}}}</text>
</revision>
</page>';
}#end function xml_page_template

#get make xml block for a page
function make_page($title,$text){
        global $xml_user, $uid, $change_count;
        $page = xml_page_template();
        $page = str_replace("{{{TITLE}}}",fix_title($title),$page);
        $page = str_replace("{{{PAGEID}}}",$change_count,$page);
        $page = str_replace("{{{TIMESTAMP}}}", gmdate("Y-m-d").'T'.gmdate("H:i:s")."Z",$page);
        $page = str_replace("{{{USERNAME}}}",$xml_user,$page);
        $page = str_replace("{{{UID}}}",$uid,$page);
        $page = str_replace("{{{TEXT}}}",htmlentities($text),$page);
        return $page;
}

# certain characters are forbidden in wiki page titles.  Substitute them and unescape '
function fix_title($string){
	$string = strip_tags($string);
	$string = str_replace('[','(',$string);
	$string = str_replace(']',')',$string);
	$string = str_replace('{','(',$string);
	$string = str_replace('}',')',$string);
	$string = str_replace("\'","'",$string);
	$string = replace_sbml($string);
	return utf8_encode($string);
}

function replace_sbml($line){
	$line = str_replace('&alpha;','alpha',$line);
	$line = str_replace('&Alpha;','Alpha',$line);
	$line = str_replace('&beta;','beta',$line);
	$line = str_replace('&Beta;','Beta',$line);
	$line = str_replace('&gamma;','gamma',$line);
	$line = str_replace('&Gamma;','Gamma',$line);
	$line = str_replace('&delta;','delta',$line);
	$line = str_replace('&Delta;','Delta',$line);
	$line = str_replace('&epsilon;','epsilon',$line);
	$line = str_replace('&Epsilon;','Epsilon',$line);
	$line = str_replace('&zeta;','zeta',$line);
	$line = str_replace('&Zeta;','Zeta',$line);
	$line = str_replace('&eta;','eta',$line);
	$line = str_replace('&Eta;','Eta',$line);
	$line = str_replace('&theta;','theta',$line);
	$line = str_replace('&Theta;','Theta',$line);
	$line = str_replace('&iota;','iota',$line);
	$line = str_replace('&Iota;','Iota',$line);
	$line = str_replace('&kappa;','kappa',$line);
	$line = str_replace('&Kappa;','Kappa',$line);
	$line = str_replace('&lamba;','lambda',$line);
	$line = str_replace('&Lamba;','Lambda',$line);
	$line = str_replace('&mu;','mu',$line);
	$line = str_replace('&Mu;','Mu',$line);
	$line = str_replace('&nu;','nu',$line);
	$line = str_replace('&Nu;','Nu',$line);
	$line = str_replace('&xi;','xi',$line);
	$line = str_replace('&Xi;','Xi',$line);
	$line = str_replace('&omicron;','omicron',$line);
	$line = str_replace('&Omicron;','Omicron',$line);
	$line = str_replace('&pi;','pi',$line);
	$line = str_replace('&Pi;','Pi',$line);
	$line = str_replace('&rho;','rho',$line);
	$line = str_replace('&Rho;','Rho',$line);
	$line = str_replace('&sigma;','sigma',$line);
	$line = str_replace('&Sigma;','Sigma',$line);
	$line = str_replace('&tau;','tau',$line);
	$line = str_replace('&Tau;','Tau',$line);
	$line = str_replace('&upsilon;','upsilon',$line);
	$line = str_replace('&Upsilon;','Upsilon',$line);
	$line = str_replace('&phi;','phi',$line);
	$line = str_replace('&Phi;','Phi',$line);
	$line = str_replace('&chi;','chi',$line);
	$line = str_replace('&Chie;','Chi',$line);
	$line = str_replace('&psi;','psi',$line);
	$line = str_replace('&Psi;','Psi',$line);
	$line = str_replace('&omega;','omega',$line);
	$line = str_replace('&Omega;','Omega',$line);
    return $line;
}

function get_userid($username){
	global $db;
	$sql = "SELECT * FROM user WHERE user_name = '$username'";
	$result = do_select($sql);
	if ($result[0]['count'] > 0){
		return $result[1]['user_id'];
	}
	return 0;
}

# search for the appropriate box, create a new one if not found
function get_wikibox_id($page_name, $template='', $namespace = 0){
	global $wgServerName, $wgDBname,  $wgTableEditDatabase;
        $dbr =& wfGetDB( DB_SLAVE );
	$dbr->selectDB($wgTableEditDatabase);
	$page_uid = get_page_id($page_name, $namespace); 

	$conditions = array('page_name'=> $page_name, 'page_uid' => $page_uid);
	if ($template != '') $conditions['template'] = $template;

	$result = $dbr->selectRow("box",array('box_id'), $conditions);
	$dbr->selectDB($wgDBname);
	if ($result) return $result->box_id;
	$dbw =& wfGetDB( DB_MASTER );
	$dbw->selectDB($wgTableEditDatabase);
 
	$box_uid = md5($wgServerName).".$page_uid.".uniqid(chr(rand(65,90)));
	# box does not exist, need a new one
	$result = $dbw->insert( 
			"box", 
			array(	'template'	=>	$template, 
				'page_name'	=>	$page_name,
				'page_uid'	=> 	$page_uid,
				'box_uid'	=>	$box_uid,
				'timestamp'	=> time()
				)
		);
	$dbw->selectDB($wgDBname);
	return $dbw->insertId();
}

# return box_uid. return 0 if not found.
function get_wikibox_uid($box_id){
	global  $wgServerName, $wgDBname,  $wgTableEditDatabase;
	$dbr =& wfGetDB( DB_SLAVE );
        $dbr->selectDB($wgTableEditDatabase);
	$result = $dbr->selectRow("box", array('box_uid'), array('box_id'=>$box_id));
        $dbr->selectDB($wgDBname);
	if ($result) return $result->box_uid;
	return 0;
}

# return an array of row indices 
function get_wikibox_rows($box, $ownerid= 0, $metadata = ''){
	$row_ids = array(); #echo "\nget_wikibox_rows:\n\t$ownerid\n\t$metadata\n";
	foreach ($box->rows as $row_index=>$row){
		if ($row->owner_uid == $ownerid){
			if ($metadata == '' || match_metadata($row, $metadata)) $row_ids[] = $row_index;
		}
	}
	$result = array_unique($row_ids);
	return $result;
}

# look in the row_metadata table for match to data_like
function match_metadata ($row, $metadata){

        global  $wgTableEditDatabase, $wgDBname;
        $dbr  =& wfGetDB( DB_MASTER );
	$dbr->selectDB($wgTableEditDatabase);
	$sql = "SELECT * FROM row_metadata WHERE row_metadata = '".mysql_real_escape_string($metadata)."' AND row_id = '$row->row_id'";
	$result = $dbr->query($sql); 
	$x = $dbr->fetchObject ( $result ); #print_r($x);
	if ($x){
		#echo "found metadata match\n";
	        $dbr->selectDB($wgDBname);
		return true;
	}	
	#echo "no metadata match\n";
        $dbr->selectDB($wgDBname);
	return false;
}
/* this is a replacement for the do_box in the ecoliwiki functions
$data is a hash
$data['metadata'] 
$data['row_data'] actual row data with || delimiters
*/
function make_box($page_name, $template = '', $data, $fill = 1){
        global $db;
        $uid = 0;
        if (isset($data['owner'])) $uid = $data['owner'];
        $metadata = '';
        if (isset($data['metadata'])) $metadata = $data['metadata'];
        # identify the  box
        $box_id = get_wikibox_id($page_name, $template);# echo "\nbox_id:$box_id\n";
        $box_uid = get_wikibox_uid($box_id);# echo "box_uid:$box_uid\n";
        $box = new wikiBox();
        $box->box_uid = $box_uid;
        $box->template = $template;
        $box->set_from_DB();
        # if fill != 1, then we aren't filling a new row.  We just want the box from the database, even if it's empty.
        if ($fill == 1){
                $rows = get_wikibox_rows($box, $uid, $metadata);
        #       echo "found rows owned by $uid and matching $metadata\n"; print_r($rows);#print_r($box->rows);echo "\n";
                if (count($rows) == 0){
                        $row = $box->insert_row('',$uid);
                        $rows[] = $row->row_index; #echo "adding new row row_index = ".$row->row_index."\n";
                }
        #       print_r($box);
        #       print_r($rows);
                foreach ($rows as $row_index){
                        $function = "do_".$template;
                        $row_data = $box->rows[$row_index]->row_data;
                        if ($box->rows[$row_index]->owner_uid == $uid) $row_data = $data['row_data'];
                        $box->rows[$row_index]->row_data = $row_data;
                        if ($box->box_id > 0){
                                $box->rows[$row_index]->row_id = insert_wikibox_row($box->rows[$row_index]);
                                insert_row_metadata($box->rows[$row_index], $metadata);
                        }
                }
        }
#       print_r($box->rows);
        $tableEdit = new TableEdit;
        $table = str_replace("\'","'",$tableEdit->make_wikibox($box));
        return str_replace('\n',"\n",$table);
}

function insert_row_metadata($row, $metadata){
	global  $wgTableEditDatabase, $wgDBname;
	$dbw  =& wfGetDB( DB_MASTER );
#	echo "insert metadata row:";print_r($row);echo "metadata:$metadata";
	if ($metadata == '' || !isset($row->row_id) || match_metadata($row, $metadata))  return; # it's already there
        $dbw->selectDB($wgTableEditDatabase);
	$result = $dbw->insert('row_metadata',array('row_id'=>$row->row_id, 'row_metadata'=>$metadata));
        $dbw->selectDB($wgDBname);

	return;
}

function insert_wikibox_row($row){
        global  $wgTableEditDatabase, $wgDBname;
	if ($row->box_id == 0 ||  $row->row_data == '') return;

        $dbw  =& wfGetDB( DB_MASTER );
        $dbw->selectDB($wgTableEditDatabase);
	if (!isset($row->row_style)) $row->row_style = '';
	if (!isset($row->row_id)){
		$a = array(
			'box_id'	=>	$row->box_id,
			'owner_uid'	=>	$row->owner_uid,
			'row_data'	=>	$row->row_data,
			'row_style'	=>	$row->row_style,
			'row_sort_order'=>	$row->row_sort_order,
			'timestamp'	=>	time()
			);
		$result = $dbw->insert('row',$a); 
		$row->row_id = $dbw->insertID();
	}elseif($row->is_current === true){
		# it's in the DB and it's current, update it.
 		$a = array(
                        'owner_uid'     =>      $row->owner_uid,
                        'row_data'      =>      $row->row_data,
                        'row_style'     =>      $row->row_style,
                        'row_sort_order'=>      $row->row_sort_order,
                        'timestamp'     =>      time()
                        );
		$conds = array( row_id => $row->row_id);
		$result = $dbw->update('row', $a, $conds); 
	}else{
		#it's in the DB but it's not current.  Delete it from the DB
		$sql = "DELETE FROM $wikibox_db.row WHERE row_id = '$this->row_id'"; 
		$result = do_query($sql); 
	}
        $dbw->selectDB($wgDBname);
	return $row->row_id;
}
?>