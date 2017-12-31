<?php
include("info_db.php");

if (!isset($_GET['f1']) || !isset($_GET['v1']))
    die ("v or f is null");

$feeds = $_GET['feeds'];

$db = mysql_connect($hostname, $db_login, $db_passw);
mysql_select_db($db_name, $db) or die('Erreur SQL !<br>'.mysql_error());
$sql = "INSERT INTO ".$db_table." (ffeed, fvalue) VALUES";
for($i=1;$i<=$feeds;$i++){
	$feed = $_GET['f'.$i];
	$value = $_GET['v'.$i];
	if ($i==$feeds){
		$sql.=" (\"".$feed."\", ".$value.")";
	} else {
		$sql.=" (\"".$feed."\", ".$value."),";
	}
}
echo "$sql";
mysql_query($sql, $db) or die('Erreur SQL !<br>'.mysql_error());
echo "OK";
?>
