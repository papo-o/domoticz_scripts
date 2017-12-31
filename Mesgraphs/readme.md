Après avoir stocké vos données dans une base MySql via le script https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_export_mysql.lua passons à leurs mise en forme et exploitation.
pour cela il vous faut récuperer l'ensemble des fichiers de ce projet sur votre serveur web .
Le fichier info_db.php est à personnaliser avec les informations de votre base de données adresse:port, login et mot de passe notamment.
ensuite lancez le fichier feeds.php qui va vous permettre de lister les données contenues dans votre base de données
et afficher celles que vous désirez via un formulaire tout simple dont vous pourrez modifier le style via le fichier form.css