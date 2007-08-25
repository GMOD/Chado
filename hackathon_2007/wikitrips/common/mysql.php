<?php
#common use mysql functions
function do_connect($host, $user,$password,$database){
	$db = mysql_connect($host, $user, $password);

	if(!$db) {
        	echo "unable to connect to database.....".mysql_error()."\n";
        	exit;
	}

	$conn = mysql_select_db($database,$db);
	if (!$conn) echo mysql_error()."\n\n";
	return $db;
}




function do_select($sql){
/*
takes SQL statement as a string 
if it finds anything in the db
        returns 2D array [record number starting with 1] = result associative array key, value
if no matching records
        returns 0

usage example:

$my_query = "SELECT first, last FROM student ORDER BY last";
$result = do_select($my_query);

$result[0]['count'] = the number of rows returned
$result[1]['first'] = the first name of the first found record
$result[1]['last'] = the last name of the first found record

and so on.
*/
	# print "SQL:$sql\n";
	$result = mysql_query($sql);
	if (!$result) {
		die('Invalid query : '.$sql."\n" . mysql_error());
	}
	# print mysql_num_rows($result)." record(s) found.\n ";
	if (mysql_num_rows($result) > 0){
	$whole_result = array(); 
	$whole_result[0]['count'] = mysql_num_rows($result);
		$i = 1;
		while ($row = mysql_fetch_array($result, MYSQL_ASSOC)){ 
				$whole_result[$i] = $row; 
				$i++;
		} 
		mysql_free_result($result);
		return $whole_result; 
	}else{
		return 0;
	}
}
//end do_select

# get_field_where($table, $field, $where)
# returns ONE value
function get_field_where($table, $field, $where){
	$result = do_select("SELECT $field FROM $table WHERE $where");
	if ($result == 0){ 
		return false;
	}else{
		return  $result[1]["$field"];
	}
}

function do_insert($sql){
	$result = mysql_query($sql);
	if(!$result) die ("Query:$sql\n".mysql_error()."\n");
	return mysql_insert_id();
}

function do_query($sql){
	$result = mysql_query($sql);
	if(!$result) die ("Query:$sql\n".mysql_error()."\n");
	return true;
}

function insert_if_new($table, $where, $values, $id){
        #use for rows that should be unique
        $result = do_select("SELECT * from $table WHERE $where");
        if($result == 0){
                return do_insert("INSERT INTO $table VALUES($values)");
        }elseif($result[0]['count'] == 1){
                return $result[1][$id];
        }else{
                return false;
        }

}

?>