--[[
name : script_time_fete_du_jour.lua
auteur : papoo
MAJ : 22/12/2018
date : 28/05/2016
Principe : Ce script a pour but d'afficher dans un device texte l'évenement (anniversaire, jour férié ou fête) du jour et du lendemain
http://pon.fr/fete-du-jour-et-du-lendemain-en-lua/
https://easydomoticz.com/forum/viewtopic.php?f=10&t=1878
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = true  						-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local fete_text_idx = nil --391   				-- idx du capteur texte saint du jour, nil si inutilisé
local fete_demain_text_idx = nil --703 			-- idx du capteur texte saint du lendemain, nil si inutilisé
local anniversaire_text_idx = nil   			-- idx du capteur texte anniversaire du jour pour afficher les anniversaires dans un device séparé, nil si inutilisé
local anniversaire_demain_text_idx = nil  		-- idx du capteur texte anniversaire du lendemain pour afficher les anniversaires dans un device séparé, nil si inutilisé
local jour_ferie_switch = "Jour Ferie" 			-- nom du capteur switch jour férié, nil si inutilisé
local jour_ferie_scene = "Jour Férié" 			-- nom du scénario jour férié entre, nil si inutilisé
local variable_jour = "Saint_Jour"				-- nom de la variable jour, nil si inutilisé
local variable_lendemain = "Saint_Lendemain" 	-- nom de la variable lendemain, nil si inutilisé
local variable_jour_ferie = "Jour_ferie"		-- nom de la variable
local Scene_Semaine_Paire = "Semaine Paire"     -- nom du scénario semaine paire, nil si inutilisé
local Scene_Semaine_Impaire = "Semaine Impaire" -- nom du scénario semaine impaire, nil si inutilisé
local Scene_Week_End = "Week-End"               -- nom du scénario Week-End, nil si inutilisé
local date_mariage = 1900	                    -- année de votre date de mariage
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = 'Fete du jour et du lendemain'
local version = "1.65"							-- version du script
local fete_jour = ''
local fete_demain = ''
local ferie =  ''
local anniversaire = {}	
local saint_jour = {}
local jour_ferie = {}
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
package.path = package.path..";/home/pi/domoticz/scripts/lua/fonctions/?.lua"   -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script
require('fonctions_perso')                                                      -- ligne à commenter en cas d'utilisation des fonctions directement dans ce script

-- ci-dessous les lignes à décommenter en cas d'utilisation des fonctions directement dans ce script( supprimer --[[ et --]])
--[[function voir_les_logs (s, debugging) -- nécessite la variable local debugging
    if (debugging) then 
		if s ~= nil then
        print (s)
		else
		print ("aucune valeur affichable")
		end
    end
end	-- usage voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
--------------------------------------------
function year_difference(s)
    return tostring(os.date("%Y")) - tostring(s)
end
--]]
--------------------------------------------
------------- Fin Fonctions ----------------
-------------------------------------------- 
commandArray = {}
time = os.date("*t")
-- Trigger at 00:20 
--[[time = os.date("*t")]] --

--if time.hour % 2 == 0 then -- toutes les deux heures
if (time.hour%2 == 0 and time.min == 10) then  --Toutes les 2 heures et 10 minutes
--if time.min % 1 == 0 then 

voir_les_logs("=========== Fete du jour (v".. version ..") ===========",debugging)
local today=tostring(os.date("%d:%m"))
voir_les_logs("--- --- --- Date du jour : ".. today,debugging) 
local tomorrow=tostring(os.date("%d:%m",os.time()+24*60*60))
voir_les_logs("--- --- --- Date de demain : ".. tomorrow,debugging) 
local annee_mariage = tostring(os.date("%Y")) - tostring(date_mariage)
local annee_mariage = year_difference(date_mariage)
local jour = tonumber(os.date("%w"))
if (jour == 0) or (jour == 6) then
	voir_les_logs("--- --- --- jour ".. jour .." c\'est le week-end ",debugging)    
        if Scene_Week_End ~= nil then
            commandArray['Scene:'..Scene_Week_End] = 'On'
			voir_les_logs("--- --- --- Mise à jour scénario  ".. Scene_Week_End .." => On",debugging)            
        end   
else
    voir_les_logs("--- --- --- jour ".. jour .." c\'est la semaine",debugging)
        if Scene_Week_End ~= nil then
            commandArray['Scene:'..Scene_Week_End] = 'Off'        
			voir_les_logs("--- --- --- Mise à jour scénario  ".. Scene_Week_End .." => Off",debugging)        
        end
end
anniversaire["28:05"]="l\'anniversaire&nbsp;de&nbsp;Pierre"
anniversaire["29:05"]="l\'anniversaire&nbsp;de&nbsp;Paul"
anniversaire["30:05"]="l\'anniversaire&nbsp;de&nbsp;Jacques"
anniversaire["01:06"]="nos&nbsp;".. annee_mariage .."&nbsp;ans&nbsp;de&nbsp;mariage"

--------------------------------------------============
saint_jour["01:01"]="le&nbsp;jour&nbsp;de&nbsp;l\'An"
saint_jour["02:01"]="les&nbsp;Basile"
saint_jour["03:01"]="les&nbsp;Geneviève"
saint_jour["04:01"]="les&nbsp;Odilon"
saint_jour["05:01"]="les&nbsp;Édouard"
saint_jour["06:01"]="les&nbsp;André"
saint_jour["07:01"]="les&nbsp;Raymond"
saint_jour["08:01"]="les&nbsp;Lucien"
saint_jour["09:01"]="les&nbsp;Alix&nbsp;de&nbsp;Ch."
saint_jour["10:01"]="les&nbsp;Guillaume"
saint_jour["11:01"]="les&nbsp;Paulin&nbsp;d&nbsp;Aquilee"
saint_jour["12:01"]="les&nbsp;Tatiana"
saint_jour["13:01"]="les&nbsp;Yvette"
saint_jour["14:01"]="les&nbsp;Nina"
saint_jour["15:01"]="les&nbsp;Rémi"
saint_jour["16:01"]="les&nbsp;Marcel"
saint_jour["17:01"]="les&nbsp;Roseline"
saint_jour["18:01"]="les&nbsp;Prisca"
saint_jour["19:01"]="les&nbsp;Marius"
saint_jour["20:01"]="les&nbsp;Sébastien"
saint_jour["21:01"]="les&nbsp;Agnès"
saint_jour["22:01"]="les&nbsp;Vincent"
saint_jour["23:01"]="les&nbsp;Barnard"
saint_jour["24:01"]="les&nbsp;François"
saint_jour["25:01"]="la&nbsp;Conversion&nbsp;de&nbsp;Paul"
saint_jour["26:01"]="les&nbsp;Paule"
saint_jour["27:01"]="les&nbsp;Angèle"
saint_jour["28:01"]="les&nbsp;Thomas"
saint_jour["29:01"]="les&nbsp;Gildas"
saint_jour["30:01"]="les&nbsp;Martine"
saint_jour["31:01"]="les&nbsp;Marcelle"
saint_jour["01:02"]="les&nbsp;Ella"
saint_jour["02:02"]="les&nbsp;Theophane"
saint_jour["03:02"]="les&nbsp;Blaise"
saint_jour["04:02"]="les&nbsp;Véronique"
saint_jour["05:02"]="les&nbsp;Agathe"
saint_jour["06:02"]="les&nbsp;Gaston"
saint_jour["07:02"]="les&nbsp;Eugénie"
saint_jour["08:02"]="les&nbsp;Jacqueline"
saint_jour["09:02"]="les&nbsp;Apolline"
saint_jour["10:02"]="les&nbsp;Arnaud"
saint_jour["11:02"]="les&nbsp;Severin"
saint_jour["12:02"]="les&nbsp;Felix"
saint_jour["13:02"]="les&nbsp;Beatrice"
saint_jour["14:02"]="les&nbsp;Valentin"
saint_jour["15:02"]="les&nbsp;Claude"
saint_jour["16:02"]="les&nbsp;Julienne"
saint_jour["17:02"]="les&nbsp;Alexis"
saint_jour["18:02"]="les&nbsp;Bernadette"
saint_jour["19:02"]="les&nbsp;Gabin"
saint_jour["20:02"]="les&nbsp;Aimee"
saint_jour["21:02"]="les&nbsp;Damien"
saint_jour["22:02"]="les&nbsp;Isabelle"
saint_jour["23:02"]="les&nbsp;Lazare"
saint_jour["24:02"]="les&nbsp;Modeste"
saint_jour["25:02"]="les&nbsp;Romeo"
saint_jour["26:02"]="les&nbsp;Nestor"
saint_jour["27:02"]="les&nbsp;Honorine"
saint_jour["28:02"]="les&nbsp;Romain"
saint_jour["29:02"]="les&nbsp;Augula"
saint_jour["01:03"]="les&nbsp;Aubin"
saint_jour["02:03"]="les&nbsp;Charles"
saint_jour["03:03"]="les&nbsp;Gwenole"
saint_jour["04:03"]="les&nbsp;Casimir"
saint_jour["05:03"]="les&nbsp;Olive"
saint_jour["06:03"]="les&nbsp;Colette"
saint_jour["07:03"]="les&nbsp;Félicité"
saint_jour["08:03"]="les&nbsp;Jean"
saint_jour["09:03"]="les&nbsp;Françoise"
saint_jour["10:03"]="les&nbsp;Vivien"
saint_jour["11:03"]="les&nbsp;Rosine"
saint_jour["12:03"]="les&nbsp;Justine"
saint_jour["13:03"]="les&nbsp;Rodrigue"
saint_jour["14:03"]="les&nbsp;Maud"
saint_jour["15:03"]="les&nbsp;Louise"
saint_jour["16:03"]="les&nbsp;Benedicte"
saint_jour["17:03"]="les&nbsp;Patrick"
saint_jour["18:03"]="les&nbsp;Cyrille"
saint_jour["19:03"]="les&nbsp;Joseph"
saint_jour["20:03"]="les&nbsp;Herbert"
saint_jour["21:03"]="les&nbsp;Clemence"
saint_jour["22:03"]="les&nbsp;Lea"
saint_jour["23:03"]="les&nbsp;Victorien"
saint_jour["24:03"]="les&nbsp;Catherine"
saint_jour["25:03"]="les&nbsp;Humbert"
saint_jour["26:03"]="les&nbsp;Larissa"
saint_jour["27:03"]="les&nbsp;Habib"
saint_jour["28:03"]="les&nbsp;Gontran"
saint_jour["29:03"]="les&nbsp;Gwladys"
saint_jour["30:03"]="les&nbsp;Amedee"
saint_jour["31:03"]="les&nbsp;Benjamin"
saint_jour["01:04"]="les&nbsp;Hugues"
saint_jour["02:04"]="les&nbsp;Sandrine"
saint_jour["03:04"]="les&nbsp;Richard"
saint_jour["04:04"]="les&nbsp;Isidore"
saint_jour["05:04"]="les&nbsp;Irene"
saint_jour["06:04"]="les&nbsp;Marcellin"
saint_jour["07:04"]="les&nbsp;Jean-Baptiste"
saint_jour["08:04"]="les&nbsp;Julie"
saint_jour["09:04"]="les&nbsp;Gautier"
saint_jour["10:04"]="les&nbsp;Fulbert"
saint_jour["11:04"]="les&nbsp;Stanislas"
saint_jour["12:04"]="les&nbsp;Jules&nbsp;1er"
saint_jour["13:04"]="les&nbsp;Ida"
saint_jour["14:04"]="les&nbsp;Maxime"
saint_jour["15:04"]="les&nbsp;Paterne"
saint_jour["16:04"]="les&nbsp;Benoît"
saint_jour["17:04"]="les&nbsp;Étienne"
saint_jour["18:04"]="les&nbsp;Parfait"
saint_jour["19:04"]="les&nbsp;Emma"
saint_jour["20:04"]="les&nbsp;Odette"
saint_jour["21:04"]="les&nbsp;Anselme"
saint_jour["22:04"]="les&nbsp;Alexandre"
saint_jour["23:04"]="les&nbsp;Georges"
saint_jour["24:04"]="les&nbsp;Fidèle"
saint_jour["25:04"]="les&nbsp;Marc"
saint_jour["26:04"]="les&nbsp;Alida"
saint_jour["27:04"]="les&nbsp;Zita"
saint_jour["28:04"]="les&nbsp;Valérie"
saint_jour["29:04"]="les&nbsp;Catherine"
saint_jour["30:04"]="les&nbsp;Robert"
saint_jour["01:05"]="les&nbsp;Joseph"
saint_jour["02:05"]="les&nbsp;Boris"
saint_jour["03:05"]="les&nbsp;Philippe"
saint_jour["04:05"]="les&nbsp;Sylvain"
saint_jour["05:05"]="les&nbsp;Judith"
saint_jour["06:05"]="les&nbsp;Prudence"
saint_jour["07:05"]="les&nbsp;Gisèle"
saint_jour["08:05"]="les&nbsp;Desire"
saint_jour["09:05"]="les&nbsp;Pacôme"
saint_jour["10:05"]="les&nbsp;Solange"
saint_jour["11:05"]="les&nbsp;Estelle"
saint_jour["12:05"]="les&nbsp;Achille"
saint_jour["13:05"]="les&nbsp;Rolande"
saint_jour["14:05"]="les&nbsp;Matthias"
saint_jour["15:05"]="les&nbsp;Denise"
saint_jour["16:05"]="les&nbsp;Honore"
saint_jour["17:05"]="les&nbsp;Pascal"
saint_jour["18:05"]="les&nbsp;Éric"
saint_jour["19:05"]="les&nbsp;Yves"
saint_jour["20:05"]="les&nbsp;Bernardin"
saint_jour["21:05"]="les&nbsp;Constantin"
saint_jour["22:05"]="les&nbsp;Émile"
saint_jour["23:05"]="les&nbsp;Didier"
saint_jour["24:05"]="les&nbsp;Donatien"
saint_jour["25:05"]="les&nbsp;Sophie"
saint_jour["26:05"]="les&nbsp;Bérenger"
saint_jour["27:05"]="les&nbsp;Augula"
saint_jour["28:05"]="les&nbsp;Germain"
saint_jour["29:05"]="les&nbsp;Aymard"
saint_jour["30:05"]="les&nbsp;Ferdinand"
saint_jour["31:05"]="les&nbsp;Perrine"
saint_jour["01:06"]="les&nbsp;Justin"
saint_jour["02:06"]="les&nbsp;Blandine"
saint_jour["03:06"]="les&nbsp;Charles"
saint_jour["04:06"]="les&nbsp;Clotilde"
saint_jour["05:06"]="les&nbsp;Igor"
saint_jour["06:06"]="les&nbsp;Norbert"
saint_jour["07:06"]="les&nbsp;Gilbert"
saint_jour["08:06"]="les&nbsp;Médard"
saint_jour["09:06"]="les&nbsp;Diane"
saint_jour["10:06"]="les&nbsp;Landry"
saint_jour["11:06"]="les&nbsp;Barnabé"
saint_jour["12:06"]="les&nbsp;Guy"
saint_jour["13:06"]="les&nbsp;Antoine"
saint_jour["14:06"]="les&nbsp;Élisée"
saint_jour["15:06"]="les&nbsp;Germaine"
saint_jour["16:06"]="les&nbsp;Jean-François"
saint_jour["17:06"]="les&nbsp;Hervé"
saint_jour["18:06"]="les&nbsp;Leonce"
saint_jour["19:06"]="les&nbsp;Romuald"
saint_jour["20:06"]="les&nbsp;Silvère"
saint_jour["21:06"]="les&nbsp;Rodolphe"
saint_jour["22:06"]="les&nbsp;Alban"
saint_jour["23:06"]="les&nbsp;Audrey"
saint_jour["24:06"]="les&nbsp;Jean-Baptiste"
saint_jour["25:06"]="les&nbsp;Prosper"
saint_jour["26:06"]="les&nbsp;Anthelme"
saint_jour["27:06"]="les&nbsp;Fernand"
saint_jour["28:06"]="les&nbsp;Irénée"
saint_jour["29:06"]="les&nbsp;Pierre&nbsp;et&nbsp;Paul"
saint_jour["30:06"]="les&nbsp;Martial"
saint_jour["01:07"]="les&nbsp;Thierry"
saint_jour["02:07"]="les&nbsp;Martinien"
saint_jour["03:07"]="les&nbsp;Thomas"
saint_jour["04:07"]="les&nbsp;Florent"
saint_jour["05:07"]="les&nbsp;Antoine"
saint_jour["06:07"]="les&nbsp;Mariette"
saint_jour["07:07"]="les&nbsp;Raoul"
saint_jour["08:07"]="les&nbsp;Thibaud"
saint_jour["09:07"]="les&nbsp;Amandine"
saint_jour["10:07"]="les&nbsp;Ulric"
saint_jour["11:07"]="les&nbsp;Benoit"
saint_jour["12:07"]="les&nbsp;Olivier"
saint_jour["13:07"]="les&nbsp;Joëlle"
saint_jour["14:07"]="les&nbsp;Camille"
saint_jour["15:07"]="les&nbsp;Donald"
saint_jour["16:07"]="les&nbsp;Elvire"
saint_jour["17:07"]="les&nbsp;Charlotte"
saint_jour["18:07"]="les&nbsp;Frédéric"
saint_jour["19:07"]="les&nbsp;Arsène"
saint_jour["20:07"]="les&nbsp;Marina"
saint_jour["21:07"]="les&nbsp;Victor"
saint_jour["22:07"]="les&nbsp;Marie-Madeleine"
saint_jour["23:07"]="les&nbsp;Brigitte"
saint_jour["24:07"]="les&nbsp;Christine"
saint_jour["25:07"]="les&nbsp;Jacques"
saint_jour["26:07"]="les&nbsp;Anne"
saint_jour["27:07"]="les&nbsp;Nathalie"
saint_jour["28:07"]="les&nbsp;Samson"
saint_jour["29:07"]="les&nbsp;Marthe"
saint_jour["30:07"]="les&nbsp;Juliette"
saint_jour["31:07"]="les&nbsp;Ignace"
saint_jour["01:08"]="les&nbsp;Alphonse"
saint_jour["02:08"]="les&nbsp;Julien"
saint_jour["03:08"]="les&nbsp;Lydie"
saint_jour["04:08"]="les&nbsp;Jean-Marie"
saint_jour["05:08"]="les&nbsp;Abel"
saint_jour["06:08"]="les&nbsp;Octavien"
saint_jour["07:08"]="les&nbsp;Gaetan"
saint_jour["08:08"]="les&nbsp;Dominique"
saint_jour["09:08"]="les&nbsp;Amour"
saint_jour["10:08"]="les&nbsp;Laurent"
saint_jour["11:08"]="les&nbsp;Claire"
saint_jour["12:08"]="les&nbsp;Clarisse"
saint_jour["13:08"]="les&nbsp;Hippolyte"
saint_jour["14:08"]="les&nbsp;Evrard"
saint_jour["15:08"]="les&nbsp;Marie"
saint_jour["16:08"]="les&nbsp;Armel"
saint_jour["17:08"]="les&nbsp;Hyacinthe"
saint_jour["18:08"]="les&nbsp;Hélène"
saint_jour["19:08"]="les&nbsp;Eudes"
saint_jour["20:08"]="les&nbsp;Bernard"
saint_jour["21:08"]="les&nbsp;Christophe"
saint_jour["22:08"]="les&nbsp;Fabrice"
saint_jour["23:08"]="les&nbsp;Rose"
saint_jour["24:08"]="les&nbsp;Barthélemy"
saint_jour["25:08"]="les&nbsp;Louis"
saint_jour["26:08"]="les&nbsp;Natacha"
saint_jour["27:08"]="les&nbsp;Monique"
saint_jour["28:08"]="les&nbsp;Augustin"
saint_jour["29:08"]="les&nbsp;Sabine"
saint_jour["30:08"]="les&nbsp;Fiacre"
saint_jour["31:08"]="les&nbsp;Aristide"
saint_jour["01:09"]="les&nbsp;Gilles"
saint_jour["02:09"]="les&nbsp;Ingrid"
saint_jour["03:09"]="les&nbsp;Grégoire"
saint_jour["04:09"]="les&nbsp;Rosalie"
saint_jour["05:09"]="les&nbsp;Raïssa"
saint_jour["06:09"]="les&nbsp;Bertrand"
saint_jour["07:09"]="les&nbsp;Reine"
saint_jour["08:09"]="les&nbsp;Adrien"
saint_jour["09:09"]="les&nbsp;Alain"
saint_jour["10:09"]="les&nbsp;Inès"
saint_jour["11:09"]="les&nbsp;Adelphe"
saint_jour["12:09"]="les&nbsp;Apollinaire"
saint_jour["13:09"]="les&nbsp;Aime"
saint_jour["14:09"]="les&nbsp;Lubin"
saint_jour["15:09"]="les&nbsp;Roland"
saint_jour["16:09"]="les&nbsp;Édith"
saint_jour["17:09"]="les&nbsp;Renaud"
saint_jour["18:09"]="les&nbsp;Nadège"
saint_jour["19:09"]="les&nbsp;Émilie"
saint_jour["20:09"]="les&nbsp;Davy"
saint_jour["21:09"]="les&nbsp;Matthieu"
saint_jour["22:09"]="les&nbsp;Maurice"
saint_jour["23:09"]="les&nbsp;Constant"
saint_jour["24:09"]="les&nbsp;Thecle"
saint_jour["25:09"]="les&nbsp;Hermann"
saint_jour["26:09"]="les&nbsp;Damien"
saint_jour["27:09"]="les&nbsp;Vincent"
saint_jour["28:09"]="les&nbsp;Venceslas"
saint_jour["29:09"]="les&nbsp;Michel"
saint_jour["30:09"]="les&nbsp;Jérôme"
saint_jour["01:10"]="les&nbsp;Thérèse"
saint_jour["02:10"]="les&nbsp;Léger"
saint_jour["03:10"]="les&nbsp;Gérard"
saint_jour["04:10"]="les&nbsp;François"
saint_jour["05:10"]="les&nbsp;Fleur"
saint_jour["06:10"]="les&nbsp;Bruno"
saint_jour["07:10"]="les&nbsp;Serge"
saint_jour["08:10"]="les&nbsp;Pélagie"
saint_jour["09:10"]="les&nbsp;Denis"
saint_jour["10:10"]="les&nbsp;Ghislain"
saint_jour["11:10"]="les&nbsp;Firmin"
saint_jour["12:10"]="les&nbsp;Wilfrid"
saint_jour["13:10"]="les&nbsp;Géraud"
saint_jour["14:10"]="les&nbsp;Juste"
saint_jour["15:10"]="les&nbsp;Thérèse"
saint_jour["16:10"]="les&nbsp;Edwige"
saint_jour["17:10"]="les&nbsp;Baudouin"
saint_jour["18:10"]="les&nbsp;Luc"
saint_jour["19:10"]="les&nbsp;René&nbsp;Goupil"
saint_jour["20:10"]="les&nbsp;Lina"
saint_jour["21:10"]="les&nbsp;Céline"
saint_jour["22:10"]="les&nbsp;Elodie"
saint_jour["23:10"]="les&nbsp;Jean"
saint_jour["24:10"]="les&nbsp;Florentin"
saint_jour["25:10"]="les&nbsp;Crépin"
saint_jour["26:10"]="les&nbsp;Dimitri"
saint_jour["27:10"]="les&nbsp;Émeline"
saint_jour["28:10"]="les&nbsp;Simon"
saint_jour["29:10"]="les&nbsp;Narcisse"
saint_jour["30:10"]="les&nbsp;Bienvenue"
saint_jour["31:10"]="les&nbsp;Quentin"
saint_jour["01:11"]="la&nbsp;Toussaint"
saint_jour["02:11"]="les&nbsp;defunts"
saint_jour["03:11"]="les&nbsp;Hubert"
saint_jour["04:11"]="les&nbsp;Charles"
saint_jour["05:11"]="les&nbsp;Sylvie"
saint_jour["06:11"]="les&nbsp;Bertille"
saint_jour["07:11"]="les&nbsp;Carine"
saint_jour["08:11"]="les&nbsp;Geoffroy"
saint_jour["09:11"]="les&nbsp;Theodore"
saint_jour["10:11"]="les&nbsp;Leon"
saint_jour["11:11"]="les&nbsp;Martin"
saint_jour["12:11"]="les&nbsp;Christian"
saint_jour["13:11"]="les&nbsp;Brice"
saint_jour["14:11"]="les&nbsp;Sidoine"
saint_jour["15:11"]="les&nbsp;Albert"
saint_jour["16:11"]="les&nbsp;Marguerite"
saint_jour["17:11"]="les&nbsp;Élisabeth"
saint_jour["18:11"]="les&nbsp;Aude"
saint_jour["19:11"]="les&nbsp;Tanguy"
saint_jour["20:11"]="les&nbsp;Edmond"
saint_jour["21:11"]="les&nbsp;Albert"
saint_jour["22:11"]="les&nbsp;Cécile"
saint_jour["23:11"]="les&nbsp;Clement"
saint_jour["24:11"]="les&nbsp;Flora"
saint_jour["25:11"]="les&nbsp;Catherine"
saint_jour["26:11"]="les&nbsp;Delphine"
saint_jour["27:11"]="les&nbsp;Severin"
saint_jour["28:11"]="les&nbsp;Jacques"
saint_jour["29:11"]="les&nbsp;Saturnin"
saint_jour["30:11"]="les&nbsp;Andre"
saint_jour["01:12"]="les&nbsp;Florence"
saint_jour["02:12"]="les&nbsp;Viviane"
saint_jour["03:12"]="les&nbsp;Xavier"
saint_jour["04:12"]="les&nbsp;Barbara"
saint_jour["05:12"]="les&nbsp;Gerald"
saint_jour["06:12"]="les&nbsp;Nicolas"
saint_jour["07:12"]="les&nbsp;Ambroise"
saint_jour["08:12"]="les&nbsp;Elfie"
saint_jour["09:12"]="les&nbsp;Pierre"
saint_jour["10:12"]="les&nbsp;Romaric"
saint_jour["11:12"]="les&nbsp;Daniel"
saint_jour["12:12"]="les&nbsp;Chantal"
saint_jour["13:12"]="les&nbsp;Lucie"
saint_jour["14:12"]="les&nbsp;Odile"
saint_jour["15:12"]="les&nbsp;Ninon"
saint_jour["16:12"]="les&nbsp;Alice"
saint_jour["17:12"]="les&nbsp;Gael"
saint_jour["18:12"]="les&nbsp;Gatien"
saint_jour["19:12"]="les&nbsp;Urbain"
saint_jour["20:12"]="les&nbsp;Theophile"
saint_jour["21:12"]="les&nbsp;Pierre"
saint_jour["22:12"]="les&nbsp;Xaviere"
saint_jour["23:12"]="les&nbsp;Armand"
saint_jour["24:12"]="les&nbsp;Adele"
saint_jour["25:12"]="Noel"
saint_jour["26:12"]="les&nbsp;Etienne"
saint_jour["27:12"]="les&nbsp;Jean"
saint_jour["28:12"]="les&nbsp;Innocents"
saint_jour["29:12"]="les&nbsp;David"
saint_jour["30:12"]="les&nbsp;Roger"
saint_jour["31:12"]="les&nbsp;Sylvestre"
--------------------------------------------============
jour_ferie["01:01"] = "Le&nbsp;1er&nbsp;janvier"
jour_ferie["01:05"] = "La&nbsp;Fête&nbsp;du&nbsp;travail"
jour_ferie["08:05"] = "La&nbsp;Victoire&nbsp;des&nbsp;alliés"
jour_ferie["14:07"] = "La&nbsp;Fête&nbsp;nationale"
jour_ferie["15:08"] = "L'Assomption"
jour_ferie["01:11"] = "La&nbsp;Toussaint"
jour_ferie["11:11"] = "L'Armistice"
jour_ferie["25:12"] = "Noël"

--[[
calcule du jour de la fête de mères
la fête des mères est fixée au dernier dimanche de mai sauf si cette date coïncide avec celle de la Pentecôte
auquel cas elle a lieu le premier dimanche de juin.
la fête des pères est fixée au 3e dimanche de juin.
Pentecôte = Pâques + 49 jours
--]]

function getJourPaques(annee)
   
    local a=math.floor(annee/100)
    local b=math.fmod(annee,100)
    local c=math.floor((3*(a+25))/4)
    local d=math.fmod((3*(a+25)),4)
    local e=math.floor((8*(a+11))/25)
    local f=math.fmod((5*a+b),19)
    local g=math.fmod((19*f+c-e),30)
    local h=math.floor((f+11*g)/319)
    local j=math.floor((60*(5-d)+b)/4)
    local k=math.fmod((60*(5-d)+b),4)
    local m=math.fmod((2*j-k-g+h),7)
    local n=math.floor((g-h+m+114)/31)
    local p=math.fmod((g-h+m+114),31)
    local jour=p+1
    local mois=n
    getJourPaquesEpochPaque=os.time{year=annee,month=mois,day=jour,hour=12,min=0}
   return getJourPaquesEpochPaque
end



local annee = os.date("%Y")
--local annee = "2017"
local epochPaques=getJourPaques(annee)

local paques = os.date("%d:%m",epochPaques) 
local lundi_paques = os.date("%d:%m",epochPaques+24*60*60) -- Lundi de Pâques = Pâques + 1 jour
local ascension = os.date("%d:%m",epochPaques+24*60*60*39) -- Ascension = Pâques + 39 jours
local pentecote = os.date("%d:%m",epochPaques+24*60*60*49)      -- Pentecôte = Pâques + 49 jours
local lundi_pentecote = os.date("%d:%m",epochPaques+24*60*60*50)      -- Lundi Pentecôte = Pâques + 50 jours

local derJourMai = tonumber(os.date("%w",os.time{year=annee,month=5,day=31}))      -- dernier jour de Mai

local derDimMai = 31-derJourMai..":05"
voir_les_logs("--- --- --- derDimMai : ".. derDimMai,debugging)
local premDimJuin = 7-derJourMai..":06"
voir_les_logs("--- --- --- premDimJuin : ".. premDimJuin,debugging)
local troisDimJuin = 21-derJourMai..":06"
voir_les_logs("--- --- --- troisDimJuin : ".. troisDimJuin,debugging)

if derDimMai == pentecote then
   meres = premDimJuin
else
   meres = derDimMai
end

voir_les_logs("--- --- --- fête des mères : ".. meres,debugging)
voir_les_logs("--- --- --- fête des pères : ".. troisDimJuin,debugging)
--===========================================================
    if jour_ferie[today] ~= nil then ferie = true end --passage de la variable à true si jour ferié 

    if meres == today then 
        fete_jour = "la&nbsp;Fête&nbsp;des&nbsp;Mères"
        voir_les_logs("--- --- --- Aujourd&apos;hui : ".. fete_jour,debugging)		
    elseif troisDimJuin == today then 
        fete_jour = "la&nbsp;Fête&nbsp;des&nbsp;pères"
        voir_les_logs("--- --- --- Aujourd&apos;hui : ".. fete_jour,debugging)			
    elseif paques == today then 
        fete_jour = "Pâques"
        ferie = true
            voir_les_logs("--- --- --- Aujourd&apos;hui : ".. fete_jour,debugging)	
    elseif lundi_paques == today then 
        fete_jour = "Lundi de Pâques"
        ferie = true
            voir_les_logs("--- --- --- Aujourd&apos;hui : ".. fete_jour,debugging)
    elseif ascension == today then 
        fete_jour = "Ascension"
        ferie = true
        voir_les_logs("--- --- --- Aujourd&apos;hui : ".. fete_jour,debugging)					
    elseif pentecote == today then 
        fete_jour = "la&nbsp;Pentecôte"
        ferie = true
        voir_les_logs("--- --- --- Aujourd&apos;hui : ".. fete_jour,debugging)
    elseif lundi_pentecote == today then 
        fete_jour = "Lundi&nbsp;de&nbsp;Pentecôte"
        ferie = true
        voir_les_logs("--- --- --- Aujourd&apos;hui : ".. fete_jour,debugging)
    elseif jour_ferie[today] ~= nil then 
        fete_jour = jour_ferie[today]
        voir_les_logs("--- --- --- Aujourd&apos;hui : ".. fete_jour,debugging)					
    else fete_jour = saint_jour[today] 
        voir_les_logs("--- --- --- Fête du jour : ".. saint_jour[today],debugging)
	end
    
    if anniversaire[today] ~= nil then  -- on priorise l'affichage des anniversaires sur les jours fériés sur les saints du jour
		if anniversaire_text_idx ~= nil then -- on affiche les anniversaires dans un device séparé si un idx a été défini
            anniversaire_jour = anniversaire[today]
        else 
        fete_jour = anniversaire[today]
        end
		voir_les_logs("--- --- --- Anniversaire du jour : ".. anniversaire[today],debugging)
    end    
    
    

	if anniversaire[tomorrow] ~= nil then
        if anniversaire_demain_text_idx ~= nil then -- on affiche les anniversaires dans un device séparé si un idx a été défini
            anniversaire_demain = anniversaire[tomorrow]
        else 
            fete_demain = anniversaire[tomorrow]
        end
		voir_les_logs("--- --- --- Anniversaire de demain : ".. anniversaire[tomorrow],debugging)				
    elseif meres == tomorrow then 
        fete_demain = "la&nbsp;Fête&nbsp;des&nbsp;Mères"
        voir_les_logs("--- --- --- Demain : ".. fete_demain,debugging)		
    elseif troisDimJuin == tomorrow then 
        fete_demain = "la&nbsp;Fête&nbsp;des&nbsp;pères"
        voir_les_logs("--- --- --- Demain : ".. fete_demain,debugging)			
    elseif paques == tomorrow then 
        fete_demain = "Pâques"
        voir_les_logs("--- --- --- Demain : ".. fete_demain,debugging)			
    elseif pentecote == tomorrow then 
        fete_demain = "la&nbsp;Pentecôte"
        voir_les_logs("--- --- --- Demain : ".. fete_demain,debugging)
    elseif lundi_pentecote == tomorrow then 
        fete_demain = "Lundi&nbsp;de&nbsp;Pentecôte"
        voir_les_logs("--- --- --- Demain : ".. fete_demain,debugging)
    else fete_demain = saint_jour[tomorrow]
        voir_les_logs("--- --- --- Fête de demain : ".. saint_jour[tomorrow],debugging)		
	end 
    
    if anniversaire_text_idx ~= nil then -- on affiche les anniversaires dans un device séparé si un idx a été défini
        if anniversaire[today] == nil then anniversaire_jour = "aucun anniversaire" end
        commandArray[#commandArray+1] = {['UpdateDevice'] = anniversaire_text_idx .. '|0|Aujourd&apos;hui&nbsp;nous&nbsp;fêtons&nbsp;' .. anniversaire_jour}
        voir_les_logs("--- --- --- Mise à jour device texte".. anniversaire_text_idx .." ".. anniversaire_jour,debugging)
    end
    if anniversaire_demain_text_idx ~= nil then -- on affiche les anniversaires dans un device séparé si un idx a été défini 
        if anniversaire[tomorrow] == nil then anniversaire_demain = "aucun anniversaire" end    
        commandArray[#commandArray+1] = {['UpdateDevice'] = anniversaire_demain_text_idx .. '|0|Demain&nbsp;nous&nbsp;fêterons&nbsp;' .. anniversaire_demain}
        voir_les_logs("--- --- --- Mise à jour device texte".. anniversaire_demain_text_idx .." ".. anniversaire_demain,debugging)
    end        
    
	if fete_text_idx ~= nil then
        commandArray[#commandArray+1] = {['UpdateDevice'] = fete_text_idx .. '|0|Aujourd&apos;hui&nbsp;nous&nbsp;fêtons&nbsp;' .. fete_jour}
        voir_les_logs("--- --- --- Mise à jour device texte".. fete_text_idx .." ".. fete_jour,debugging)
	end
	if fete_demain_text_idx ~= nil then 
        commandArray[#commandArray+1] = {['UpdateDevice'] = fete_demain_text_idx .. '|0|Demain&nbsp;nous&nbsp;fêterons&nbsp;' .. fete_demain}
        voir_les_logs("--- --- --- Mise à jour device texte ".. fete_demain_text_idx .." ".. fete_demain,debugging)
	end
    
    
    
	if jour_ferie_switch ~= nil then 
		if ferie == true then
			commandArray[jour_ferie_switch] = 'On'
			voir_les_logs("--- --- --- Mise à jour device  "..jour_ferie_switch .." => On",debugging)
		else
			commandArray[jour_ferie_switch] = 'Off'
			voir_les_logs("--- --- --- Mise à jour device  "..jour_ferie_switch .. " => Off",debugging)
		end
	end
	if jour_ferie_scene ~= nil then 
		if ferie == true then
			commandArray['Scene:'..jour_ferie_scene] = 'On'
			voir_les_logs("--- --- --- Mise à jour scénario  "..jour_ferie_scene .." => On",debugging)
		else
			commandArray['Scene:'..jour_ferie_scene] = 'Off'
			voir_les_logs("--- --- --- Mise à jour scénario  "..jour_ferie_scene .. " => Off",debugging)
		end
	end    
    
    
    
	if variable_jour ~= nil then	
	commandArray[#commandArray+1] = {['Variable:'.. variable_jour] = tostring('Aujourd&apos;hui&nbsp;nous&nbsp;fêtons&nbsp;' .. fete_jour)} -- écriture variable Saint du Jour
	
	voir_les_logs("--- --- --- Mise à jour variable ".. variable_jour .." ".. fete_jour,debugging)
	end
	if variable_lendemain ~= nil then
	commandArray[#commandArray+1] = {['Variable:'.. variable_lendemain] = tostring('Demain&nbsp;nous&nbsp;fêterons&nbsp;' .. fete_demain)} -- écriture variable	Saint du lendemain 
	
	voir_les_logs("--- --- --- Mise à jour variable ".. variable_lendemain .." ".. fete_demain,debugging)
	end
	if variable_jour_ferie ~= nil then
	
		if ferie == true then
			commandArray[#commandArray+1] = {['Variable:'.. variable_jour_ferie] = tostring('oui')} -- écriture variable	jour férié
			
			voir_les_logs("--- --- --- Mise à jour variable ".. variable_jour_ferie .." => oui",debugging)
		else 
			commandArray[#commandArray+1] = {['Variable:'.. variable_jour_ferie] = tostring('non')} -- écriture variable	jour férié
			
			voir_les_logs("--- --- --- Mise à jour variable ".. variable_jour_ferie .." => non",debugging)
		end
	end
    if os.date("%W")%2 == 0 then 	-- semaine paire et impaire
        voir_les_logs("--- --- --- semaine paire",debugging)
        if Scene_Semaine_Paire ~= nil and Scene_Semaine_Impaire ~= nil then
            commandArray['Scene:'..Scene_Semaine_Paire] = 'On'
            commandArray['Scene:'..Scene_Semaine_Impaire] = 'Off'
			voir_les_logs("--- --- --- Mise à jour scénario  "..Scene_Semaine_Paire .." => On",debugging)
			voir_les_logs("--- --- --- Mise à jour scénario  "..Scene_Semaine_Impaire .." => Off",debugging)            
        end
    else
        voir_les_logs("--- --- --- semaine impaire",debugging)
        if Scene_Semaine_Paire ~= nil and Scene_Semaine_Impaire ~= nil then
            commandArray['Scene:'..Scene_Semaine_Paire] = 'Off'
            commandArray['Scene:'..Scene_Semaine_Impaire] = 'On'
			voir_les_logs("--- --- --- Mise à jour scénario  "..Scene_Semaine_Paire .." => Off",debugging)
			voir_les_logs("--- --- --- Mise à jour scénario  "..Scene_Semaine_Impaire .." => On",debugging)            
        end        
    end
    
voir_les_logs("========= Fin Fete du jour (v".. version ..") =========",debugging)

end
return commandArray
