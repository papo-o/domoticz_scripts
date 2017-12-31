<!DOCTYPE HTML>
<html manifest="" lang="fr-FR">
<head>
   <meta charset="UTF-8">
<?php
//Connexion a la base de données
include("info_db.php");
$Conn = mysql_pconnect($hostname, $db_login, $db_passw); 
?>
<?php
//$_GET = array_map('htmlentities', $_GET); // On applique la fonction htmlentities()
if (isset($_GET['titre'])) $title = $_GET['titre'];
else $title = "Sans titre";

if (isset($_GET['suffix'])) $suffix = $_GET['suffix'];
else $suffix = "";

$feeds=$_GET['feeds'];

$a = array(); // On itinialise notre liste de flux
$b = array(); // On itinialise notre liste de nom de flux
$i = 0; // Notre variable qui sera incrémentée dans la boucle

foreach($feeds as $id => $nom) {
//foreach($_GET as $var) { // Pour chaque valeur du tableau $_GET on crée une variable $var
	$a[$i] = $id; // On met la valeur dans le tableau avec la valeur de $i
    //echo $a[$i];
	$b[$i] = $id;
    //echo $b[$i];
	$i++; // On incrémente
}
?>
<title>Graph</title>
<!-- Chargement des librairies: Jquery & highcharts -->
<script type='text/javascript' src='highstock1.37/jquery.min.js'></script>
<script type="text/javascript" src="highstock1.37/highstock.js" ></script>
<script type="text/javascript" src="highstock1.37/themes/gray.js" ></script>

<!-- Chargement des traductions -->
<script type="text/javascript" src="highstock1.37/options.js"></script>
<!-- Chargement des variables, et paramètres tde Highcharts -->
<script type="text/javascript">
$(function() {
		$('#container').highcharts('StockChart', {
				//RangeSelector correspond aux boutons de zoom qui se trouvent en haut à gauche du graphique
				rangeSelector : {
					buttons: [
					//Ici, nous définissons les boutons, et la taille de leur zoom
					//type: On définie s’il faut compter en jour, mois ou année
					//count: Le nombre de jours, mois, ou années à afficher
					//text: Le texte à afficher dans le bouton
					{type: 'day',count: 1,text: '1j'},
					{type: 'day',count: 3,text: '3j'},
					{type: 'day',count: 7,text: '7j'},
					{type: 'month',count: 1,text: '1m'},
					{type: 'year',count: 1,text: '1a'},
					{type: 'all',text: 'Tout'}],
					//selected : 5 = Par défault, nous sélectionnons le cinquième bouton "Tout".
					//Pour compter les boutons, il faut partir de 0, et non de 1
					selected: 1,
					inputDateFormat: '%e %b %Y',
					inputEditDateFormat: '%e %b %Y'
				},
				credits: {
					enabled: false
				},
				legend:
				//Legend permet d'afficher la légende sous le graphique.
				//La légende affiche, le nom de la courbe, ainsi sa couleur
				{
					//verticalAlign: Nous affichons la légende en haut du graphique
					verticalAlign: 'top',
					floating : false,
					//y: Nous décalons la légende de 25 par rapport au haut du graphique
					//afin que le titre et la légende ne se chevauchent pas
					y: 25,
					//enabled: false pour désactiver et true pour activer
					enabled: true
				},
				yAxis: {
					title: {
						text: '<?php echo $title; ?> (<?php echo $suffix; ?>)'
					}
				},
				xAxis: {
					dateTimeLabelFormats:{
						millisecond: '%H:%M:%S.%L',
						second: '%H:%M:%S',
						minute: '%H:%M',
						hour: '%H:%M',
						day: '%e %b',
						week: '%e %b',
						month: '%b %y',
						year: '%Y'
					}
				},
				navigator: {
					xAxis: {
					dateTimeLabelFormats:{
						millisecond: '%H:%M:%S.%L',
						second: '%H:%M:%S',
						minute: '%H:%M',
						hour: '%H:%M',
						day: '%e %b',
						week: '%e %b',
						month: '%b %y',
						year: '%Y'
					}
					}
				},
				tooltip: {
					shared: true,
					xDateFormat: '%H:%M, %A %e %b',
					//Ajout d'une unité de mesure lors du survole d'un point du graphique
					valueSuffix: ' <?php echo $suffix; ?>'
				},
				title: {
					//Titre du graphique
					text : '<?php echo $title; ?>'
				},
				
				series: [
				<?php
                
				mysql_select_db($db_name, $Conn);
                
				foreach ($a as $key =>  $valeur) {

					//Requête SQL permettant de récupérer l'heure, et la valeur correspondante
					$query_info = "SELECT ftimestamp, fvalue FROM graph_tbl WHERE ffeed LIKE '".$valeur."' ORDER BY ftimestamp ASC";

					$info = mysql_query($query_info, $Conn);
					$row_info = mysql_fetch_assoc($info);
					$totalRows_info = mysql_num_rows($info);
				?>
				{
				name: '<?php echo $b[$key] ?>',
				//Formatage de la date sous la forme: Année, Mois, Jour, Heure, minute
				//En suivant, nous ajoutons la valeur de la consommation
				//Exemple: Avec un relevé le 16/08/2013 à 12h00 de 256W, et un relevé de 16/08/2013 à 12h30 de 354W
				//Cela donne: [[Date.UTC(2013, 08, 16, 12, 00), 256], [Date.UTC(2013, 08, 16, 12, 30), 354]],
				data: [
					<?php do { ?>
					[Date.UTC(<?php echo date("Y", strtotime("".$row_info['ftimestamp'])).", ".(date("m", strtotime("".$row_info['ftimestamp'])) - 1).", ".date("d, H, i", strtotime("".$row_info['ftimestamp'])); ?>), <?php echo $row_info['fvalue']; ?>],
					<?php } while ($row_info = mysql_fetch_assoc($info)); ?>
				]
				},
				<?php } ?>]
		});
});
</script>
</head>

<body>
<!-- Affichage du graphique -->
	<div id="container" style="height: 100%; width: 100%; position: absolute;"></div>
</body>
</html>
