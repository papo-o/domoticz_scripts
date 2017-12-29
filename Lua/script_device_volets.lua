---------------------------------------------------------------------------
--[[ 
Script : script_device_volets.lua

auteur : papoo
version : 1.03
MAJ : 11/08/2016
date : 22/05/2016

Principe : permettre  la gestion des volets roulants 
quels que soit leurs modeles et Groupe. ]]--
---------------------------------------------------------------------------
-- Les différents états d'un volet Stopped Open Closed
---------------------------------------------------------------------------
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = false  			-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local volets_bas = 'Volets_du_Bas' 	-- nom de l'interrupteur virtuel commandant les volets du bas
local volets_haut = 'Volets_du_Haut' -- nom de l'interrupteur virtuel commandant les volets du Haut

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------

---------------------------------------------------------------------------
-- Tableau des volets
---------------------------------------------------------------------------
local les_volets = {};
-- 1ere volet : nom du device volet 1
les_volets[1] = {volet="Salon sur Rue", idx=361, Type="somfy", Groupe="bas"} -- Possibilité d'ajouter des équipements en relation, comme température piece, etat ouverture fenetre, etc (séparé par une  virgule)
-- 2eme volet : nom du device volet 2 
les_volets[2] = {volet="Salon sur Jardin", idx=362, Type="somfy", Groupe="bas"} -- exemple {volet="Salon sur Jardin", temperature="Temperature Salon", fenetre="Fenetre Salon sur Jardin"}
-- 3eme volet : nom du device volet 3
les_volets[3] = {volet="Cuisine", idx=363, Type="somfy", Groupe="bas"} -- La déclaration de l'idx {idx=xxx} ne sert qu'en cas d'utilisation de la commande via json, (ligne à décommenter)
-- 4eme volet : nom du device volet 4 
les_volets[4] = {volet="Chambre Parents", idx=364, Type="somfy", Groupe="haut"}
-- 5eme volet : nom du device volet 5 
les_volets[5] = {volet="Chambre Maud", idx=365, Type="somfy", Groupe="haut"}
-- 6eme volet : nom du device volet 6 
les_volets[6] = {volet="Chambre Audrey", idx=473, Type="velux", Groupe="haut"}
-- 7eme volet : nom du device volet 7 
-- les_volets[7] = {volet="Volet Douche", idx=628, Type="velux", Groupe="haut"}

--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
function voir_les_logs (s, debbuging)
    if (debugging) then 
		if s ~= nil then
        print ("<font color='#f3031d'>".. s .."</font>");
		else
		print ("<font color='#f3031d'>aucune valeur affichable</font>");
		end
    end
end	
-------------------------------------------- 
commandArray = {}

if ( devicechanged[volets_bas] == 'Open')	then
voir_les_logs ('--- --- --- La scène  : "'..volets_bas..'" est Open',debugging)
	for k,v in pairs(les_volets) do-- On parcourt chaque volet

			if (v.Groupe == "bas") then
						if ( v.Type == "somfy") then
						commandArray[v.volet]='Off'
						else
						commandArray[v.volet]='On'
						end
			end

	end
end
if ( devicechanged[volets_bas] == 'Closed')	then
voir_les_logs ('--- --- --- La scène  : "'..volets_bas..'" est Closed',debugging)
	for k,v in pairs(les_volets) do-- On parcourt chaque volet

			if (v.Groupe == "bas") then
						if ( v.Type == "somfy") then
						commandArray[v.volet]='On'
						else
						commandArray[v.volet]='Off'
						end
			end

	end
end
if ( devicechanged[volets_haut] == 'Open')	then
voir_les_logs ('--- --- --- La scène  : "'..volets_haut..'" est Open',debugging)
	for k,v in pairs(les_volets) do-- On parcourt chaque volet

			if (v.Groupe == "haut") then
						if ( v.Type == "somfy") then
						commandArray[v.volet]='Off'
						else
						commandArray[v.volet]='On'
						end
			end


	end
end
if ( devicechanged[volets_haut] == 'Closed')	then
voir_les_logs ('--- --- --- La scène  : "'..volets_haut..'" est Closed',debugging)
	for k,v in pairs(les_volets) do-- On parcourt chaque volet

			if (v.Groupe == "haut") then
						if ( v.Type == "somfy") then
						commandArray[v.volet]='On'
						else
						commandArray[v.volet]='Off'
						end
			end


	end
end
return commandArray 