 <?php //feeds.php
include("info_db.php");

/* if (!isset($_GET['f1']) || !isset($_GET['v1']))
    die ("v or f is null");

$feeds = $_GET['feeds']; */

$db = mysql_connect($hostname, $db_login, $db_passw);
mysql_select_db($db_name, $db) or die('Erreur SQL !<br>'.mysql_error());
/* $sql = "INSERT INTO ".$db_table." (ffeed, fvalue) VALUES";
for($i=1;$i<=$feeds;$i++){
	$feed = $_GET['f'.$i];
	$value = $_GET['v'.$i];
	if ($i==$feeds){
		$sql.=" (\"".$feed."\", ".$value.")";
	} else {
		$sql.=" (\"".$feed."\", ".$value."),";
	}
} */
$sql = "SELECT DISTINCT ffeed FROM ".$db_table." ORDER BY ffeed ASC";
$req = mysql_query($sql, $db) or die('Erreur SQL !<br>'.mysql_error());

// on recupere le resultat sous forme d'un tableau
//$data = mysql_fetch_array($req);
?>
<!DOCTYPE HTML>
<html manifest="" lang="fr-FR">
<head>
   <meta charset="UTF-8">
<link rel="stylesheet" href="form.css"> 
<meta charset="UTF-8">
 
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>

    <title>Graphiques</title>  
 
 
<script>
 
    $(document).ready(function() {
        $("#checkall").click(function() {
         
            $("input:checkbox").each(function(){
                 
                var checked = $("#checkall").attr("checked");
                 
                if(checked == "checked") {
                     
                    $(this).attr('checked', true);
                } else {
                     
                    $(this).attr('checked', false);
                     
                }  
            });
        });
    });
</script>
</head>
<body>


 
    <form method="get" action="graph.php">
   <p>
       <H2>Sélectionner les graphiques à afficher</H2><br />    
    <div>
        <label for="titre">titre :</label>
        <input type="text" name="titre" id="titre" />
    </div>
    <div>
           <label for="suffix">Unité à afficher</label>
       <select name="suffix" id="suffix">
           <option value=""></option>
           <option value="°C">°C</option>
           <option value="Watt">Watt</option>
           <option value="kWh">kWh</option>
           <option value="%">%</option>
     </div>            
</select><br /> </br>
     
<?php
    // on scanne tous les tuples un par un
while ($data = mysql_fetch_array($req)) {
	// on affiche les résultats
	//echo $data['ffeed']."<br>";

?>       <input type="checkbox" name="feeds[<?php echo $data['ffeed']?>]" id="<?php echo $data['ffeed']?>" /> <label for="<?php echo $data['ffeed']?>"><?php echo $data['ffeed']?></label><br />


<?php   

}


// on libère l'espace mémoire alloué pour cette interrogation de la base
/* mysql_free_result ($req);
mysql_close (); */

?>
<br/>
<input type="checkbox"  id="checkall"/> <label>tout sélectionner</label>
<br/>
</p>
<p><input type="submit" value="OK"></p>
</form></body>

</html>