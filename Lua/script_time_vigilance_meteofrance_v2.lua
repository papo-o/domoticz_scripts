--[[
name : script_time_vigilance_meteofrance_V2.lua
auteur : papoo
date de création : 11/12/2017
Date de mise à jour : 01/03/2018
Principe : Ce script a pour but de remonter les informations de vigilance de météoFrance 3 fois par jour à 07H15 13H15 et 18H15 
Les informations disponibles sont :
- couleur vigilance météo (Rouge, Orange, Jaune, Vert)
- risque associé : vent violent, pluie-inondation, orages, inondations, neige-verglas, canicule, grand-froid, avalanche, vagues-submersion
Une vigilance peut ne pas être associée à un risque. dans ce cas, affichage de la mention "vigilance météo".
- Conseils météo 
- commentaires météo
URL forum : http://easydomoticz.com/forum/viewtopic.php?f=17&t=5492
URL blog : http://pon.fr/vigilance-meteofrance-v2/
Ce script utilise Lua-Simple-XML-Parser https://github.com/Cluain/Lua-Simple-XML-Parser
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 
local debugging = true  			                -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local departement = 87				                -- renseigner votre numéro de département sur 2 chiffres exemples : 01 ou 07 ou 87 
local dev_vigilance_alert = 'Vigilance Météo'		-- renseigner le nom du device alert vigilance météo associé (dummy - alert)
local dev_alert_vague = 'Vigilance Crue'			-- renseigner le nom du device alert vigilance vague submersion associé (dummy - alert)
local dev_conseil_meteo =  nil		                -- renseigner le nom du device texte Conseils Météo associé si souhaité, sinon nil 
local dev_commentaire_meteo = nil 	                -- renseigner le nom du device texte Commentaire Météo associé si souhaité, sinon nil
local send_notification = 3 		                -- 0: aucune notification, 1: toutes (même verte), 2: vigilances jaune, orange et rouge, 3: vigilances orange et rouge 4: seulement vigilance rouge
local send_notification_vague = 3 	                -- 0: aucune notification, 1: toutes (même verte), 2: vigilances jaune, orange et rouge, 3: vigilances orange et rouge 4: seulement vigilance rouge
local display_conseils = false  	                -- true pour voir les conseils sans condition, false seulement en cas de vigilance dans le département sélectionné
local display_commentaire = false 	                -- true pour voir les commentaires sans condition, false seulement en cas de vigilance dans le département sélectionné

--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
local nom_script = 'vigilance meteofrance V2'
local version = '1.06'
local risques = {}
local vigilances = ""
local departementsub = tonumber(departement .. 10)
local CouleurVigilance = 0
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
function voir_les_logs (s, debugging)
    if (debugging) then 
		if s ~= nil then
        print ("<font color='#f3031d'>".. s .."</font>")
		else
		print ("<font color='#f3031d'>aucune valeur affichable</font>")
		end
    end
end	

function risqueTxt(nombre)
      if nombre == 1 then return "vent violent" 
      elseif nombre == 2 then return "pluie-inondation" 
      elseif nombre == 3 then return "orages" 
      elseif nombre == 4 then return "inondations" 
      elseif nombre == 5 then return "neige-verglas" 
      elseif nombre == 6 then return "canicule" 
      elseif nombre == 7 then return "grand-froid" 
      elseif nombre == 8 then return "avalanche"
      elseif nombre == 9 then return "vagues-submersion"	  
	 -- else return "risque non défini" end
	else return "Vigilance Meteo" end
end

---------------------------------------------------------------------------------
-- Lua-Simple-XML-Parser
---------------------------------------------------------------------------------
    XmlParser = {};
	self = {};

    function XmlParser:ToXmlString(value)
        value = string.gsub(value, "&", "&amp;"); -- '&' -> "&amp;"
        value = string.gsub(value, "<", "&lt;"); -- '<' -> "&lt;"
        value = string.gsub(value, ">", "&gt;"); -- '>' -> "&gt;"
        value = string.gsub(value, "\"", "&quot;"); -- '"' -> "&quot;"
        value = string.gsub(value, "([^%w%&%;%p%\t% ])",
            function(c)
                return string.format("&#x%X;", string.byte(c))
            end);
        return value;
    end

    function XmlParser:FromXmlString(value)
        value = string.gsub(value, "&#x([%x]+)%;",
            function(h)
                return string.char(tonumber(h, 16))
            end);
        value = string.gsub(value, "&#([0-9]+)%;",
            function(h)
                return string.char(tonumber(h, 10))
            end);
        value = string.gsub(value, "&quot;", "\"");
        value = string.gsub(value, "&apos;", "'");
        value = string.gsub(value, "&gt;", ">");
        value = string.gsub(value, "&lt;", "<");
        value = string.gsub(value, "&amp;", "&");
        return value;
    end

    function XmlParser:ParseArgs(node, s)
        string.gsub(s, "(%w+)=([\"'])(.-)%2", function(w, _, a)
            node:addProperty(w, self:FromXmlString(a))
        end)
    end

    function XmlParser:ParseXmlText(xmlText)
        local stack = {}
        local top = newNode()
        table.insert(stack, top)
        local ni, c, label, xarg, empty
        local i, j = 1, 1
        while true do
            ni, j, c, label, xarg, empty = string.find(xmlText, "<(%/?)([%w_:]+)(.-)(%/?)>", i)
            if not ni then break end
            local text = string.sub(xmlText, i, ni - 1);
            if not string.find(text, "^%s*$") then
                local lVal = (top:value() or "") .. self:FromXmlString(text)
                stack[#stack]:setValue(lVal)
            end
            if empty == "/" then -- empty element tag
                local lNode = newNode(label)
                self:ParseArgs(lNode, xarg)
                top:addChild(lNode)
            elseif c == "" then -- start tag
                local lNode = newNode(label)
                self:ParseArgs(lNode, xarg)
                table.insert(stack, lNode)
		top = lNode
            else -- end tag
                local toclose = table.remove(stack) -- remove top

                top = stack[#stack]
                if #stack < 1 then
                    error("XmlParser: nothing to close with " .. label)
                end
                if toclose:name() ~= label then
                    error("XmlParser: trying to close " .. toclose.name .. " with " .. label)
                end
                top:addChild(toclose)
            end
            i = j + 1
        end
        local text = string.sub(xmlText, i);
        if #stack > 1 then
            error("XmlParser: unclosed " .. stack[#stack]:name())
        end
        return top
    end

    function XmlParser:loadFile(xmlFilename, base)
        if not base then
            base = system.ResourceDirectory
        end

        local path = system.pathForFile(xmlFilename, base)
        local hFile, err = io.open(path, "r");

        if hFile and not err then
            local xmlText = hFile:read("*a"); -- read file content
            io.close(hFile);
            return self:ParseXmlText(xmlText), nil;
        else
            print(err)
            return nil
        end
    end

function newNode(name)
    local node = {}
    node.___value = nil
    node.___name = name
    node.___children = {}
    node.___props = {}

    function node:value() return self.___value end
    function node:setValue(val) self.___value = val end
    function node:name() return self.___name end
    function node:setName(name) self.___name = name end
    function node:children() return self.___children end
    function node:numChildren() return #self.___children end
    function node:addChild(child)
        if self[child:name()] ~= nil then
            if type(self[child:name()].name) == "function" then
                local tempTable = {}
                table.insert(tempTable, self[child:name()])
                self[child:name()] = tempTable
            end
            table.insert(self[child:name()], child)
        else
            self[child:name()] = child
        end
        table.insert(self.___children, child)
    end

    function node:properties() return self.___props end
    function node:numProperties() return #self.___props end
    function node:addProperty(name, value)
        local lName = "@" .. name
        if self[lName] ~= nil then
            if type(self[lName]) == "string" then
                local tempTable = {}
                table.insert(tempTable, self[lName])
                self[lName] = tempTable
            end
            table.insert(self[lName], value)
        else
            self[lName] = value
        end
        table.insert(self.___props, { name = name, value = self[name] })
    end

    return node
end
--------------------------------------------
function TronquerTexte(texte, nb)  --texte à tronquer, nb limite de caractère à afficher (240 max pour un device text)
local sep ='[!?.]'
local DernierIndex = nil
texte = string.sub(texte, 1, nb)
local p = string.find(texte, sep, 1)
DernierIndex = p
while p do
    p = string.find(texte, sep, p + 1)
    if p then
        DernierIndex = p
    end
end
return(string.sub(texte, 1, DernierIndex))
end

--------------------------------------------
-------------- Fin Fonctions ---------------
--------------------------------------------
commandArray = {}
time=os.date("*t")
if (time.min == 15 and ((time.hour == 7) or (time.hour == 13) or (time.hour == 18))) then -- 3 exécutions du script par jour à 7H15, 13h15 et 18H15
--if (time.min-1) % 2 == 0 then -- exécution du script toutes les X minutes
voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
    
local dz_vigilance_alert    = otherdevices_idx[dev_vigilance_alert]
local dz_alert_vague        = otherdevices_idx[dev_alert_vague]
local dz_conseil_meteo      = otherdevices_idx[dev_conseil_meteo]
local dz_commentaire_meteo  = otherdevices_idx[dev_commentaire_meteo] 
 
local rid = assert(io.popen("/usr/bin/curl -m5 http://vigilance.meteofrance.com/data/NXFR33_LFPW_.xml")) --merci jacklayster
local testXml = rid:read('*all')
rid:close() 

local parsedXml = XmlParser:ParseXmlText(testXml)

if (parsedXml) then local abr = parsedXml.CV 	

    for i in pairs(abr:children()) do 
        if (abr:children()[i]:name() == "DV") then 

            if (tonumber(abr:children()[i]["@dep"]) == departement) then -- si les informations concernent le département
            Couleur_vigilance = tonumber(abr:children()[i]["@coul"])
                if tonumber(CouleurVigilance) < tonumber(Couleur_vigilance) then CouleurVigilance = Couleur_vigilance 
            voir_les_logs("--- --- --- Couleur Vigilance : ".. CouleurVigilance .. " pour le departement : ".. departement,debugging) 
                 if (#abr:children()[i]:children() > 0) then 
                     for j = 1, #abr:children()[i]:children() do 
                         if (abr:children()[i]:children()[j]:name() == "risque") then 
                         risque = tonumber(abr:children()[i]:children()[j]["@val"])
                         risques[j-1] = tonumber(abr:children()[i]:children()[j]["@val"])
                             if risque ~= nil then
                             voir_les_logs("--- --- --- risque trouv&eacute;e : ".. risque,debugging) 
                             else
                             voir_les_logs("--- --- --- pas d'information risque trouv&eacute;e",debugging)
                             end
                         end
                     end 
                 end
            end
               
            elseif (tonumber(abr:children()[i]["@dep"]) == departementsub) then -- Recherche risque vague submersion
            Couleur_vigilance = tonumber(abr:children()[i]["@coul"])
                if tonumber(CouleurVigilance) < tonumber(Couleur_vigilance) then CouleurVigilance = Couleur_vigilance 
                voir_les_logs("--- --- --- Couleur Vigilance Vague submersion : ".. CouleurVigilance .. " pour le departement : ".. departement,debugging) 
                    if (#abr:children()[i]:children() > 0) then 
                        for j = 1, #abr:children()[i]:children() do 
                            if (abr:children()[i]:children()[j]:name() == "risque") then 
                                vague_sub = tonumber(abr:children()[i]:children()[j]["@val"])
                                    if vague_sub ~= nil then
                                    voir_les_logs("--- --- --- risque Vague submersiontrouv&eacute;e : ".. vague_sub,debugging) 
                                    else
                                    voir_les_logs("--- --- --- pas d'information risque Vague submersion trouv&eacute;e",debugging)
                                    end
                                elseif (abr:children()[i]:children()[j]:name() == "risque") then 
                                vague_sub = tonumber(abr:children()[i]:children()[j]["@valeur"]) 
                                voir_les_logs("--- --- --- Risque Vague submersion trouv&eacute;e : ".. vague_sub,debugging) 
                                end
                            end    
                        end 
                    end
                end
           
            elseif (abr:children()[i]:name() == "EV") then -- recherche commentaires
                 for j in pairs(abr:children()[i]:children()) do 
                     if (abr:children()[i]:children()[j]:name() == "VCOMMENTAIRE") then 
                     commentaire = abr:children()[i]:children()[j]["@texte"] 
                        if commentaire ~= nil then
                    voir_les_logs("--- --- --- Commentaire : " ..TronquerTexte(commentaire,240),debugging)
                        else
                    voir_les_logs("--- --- --- pas de Commentaire",debugging)	
                        end
                     end
                     if (abr:children()[i]:children()[j]:name() == "VCONSEIL") then -- recherche conseils
                     conseil = abr:children()[i]:children()[j]["@texte"] 
                        if conseil ~= nil then
                    voir_les_logs("--- --- --- Conseils : ".. TronquerTexte(conseil,240),debugging)
                        end
                     end 
                 end 
            end
    end	
else
print("erreur parsedXml")
end	

risque = risqueTxt(risque)
 if risques ~= nil then


     for k,v in pairs(risques) do
        voir_les_logs("--- --- --- vigilance  : ".. risqueTxt(v),debugging)
        vigilances = vigilances .. ", " .. risqueTxt(v)
     end -- end for
     vigilances = string.gsub (vigilances, "^, ", "")
     voir_les_logs("--- --- --- vigilances  : ".. vigilances,debugging)
 end

	if CouleurVigilance == nil then
        voir_les_logs("--- --- --- Aucune donn&eacute;e disponible pour la departement : ".. departement,debugging)
            if dz_vigilance_alert ~= nil then
                commandArray[#commandArray+1] = {['UpdateDevice'] = dz_vigilance_alert ..'|0|Vigilance Meteo'}
            end	 
	end	


	if CouleurVigilance	~= nil then	
		voir_les_logs("--- --- --- CouleurVigilance : ".. CouleurVigilance,debugging)
		if tonumber(CouleurVigilance) == 1   then -- niveau 1
			if dz_vigilance_alert ~= nil then
				 commandArray[#commandArray+1] = {['UpdateDevice'] = dz_vigilance_alert..'|1|Pas de vigilance'}
				 
			end
			if send_notification > 0 and send_notification < 2 then
				 commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte vigilance meteo#Pas de vigilance'}
				 
			end
			  voir_les_logs("--- --- --- Pas de vigilance --- --- ---",debugging)
		elseif tonumber(CouleurVigilance) == 2   then -- niveau 2
			if dz_vigilance_alert ~= nil then
				 commandArray[#commandArray+1] = {['UpdateDevice'] = dz_vigilance_alert..'|2|'.. vigilances}
				 
			end
			if send_notification > 0 and send_notification < 3 then
				 commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte vigilance meteo#'.. vigilances}
				 
			end
			  voir_les_logs("--- --- --- vigilance faible ".. vigilances.. " --- --- ---",debugging)   
		elseif tonumber(CouleurVigilance) == 3   then -- niveau 3
			if dz_vigilance_alert ~= nil then
				 commandArray[#commandArray+1] = {['UpdateDevice'] = dz_vigilance_alert..'|3|'.. vigilances}
				 
			end
			if send_notification > 0 and send_notification < 4 then
				 commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte vigilance meteo#'.. vigilances}
				 
			end
			  voir_les_logs("--- --- --- vigilance Forte ".. vigilances.. " --- --- ---",debugging)      
		elseif tonumber(CouleurVigilance) > 3  then -- niveau 4
			if dz_vigilance_alert ~= nil then
				 commandArray[#commandArray+1] = {['UpdateDevice'] = dz_vigilance_alert..'|4|'.. vigilances}
				 
			end
			if send_notification > 0 and send_notification < 5 then
				 commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte vigilance meteo#'.. vigilances}
				 
			end
			  voir_les_logs("--- --- --- vigilance très forte ".. vigilances.. " --- --- ---",debugging)
		else
		  print("niveau non défini")
		end
	end
	   
-- ====================================================================================================================	
-- Conseil météo	  
-- ====================================================================================================================			
			if ( dz_conseil_meteo ~= nil and conseil ~= nil and CouleurVigilance > 1 ) or ( dz_conseil_meteo ~= nil and conseil ~= nil and display_conseils == true ) then -- Mise à jour du devise texte conseil météo si il existe
			 commandArray[#commandArray+1] = {['UpdateDevice'] = dz_conseil_meteo..'|0|'.. TronquerTexte(conseil,240)}
			 
			elseif (dz_conseil_meteo ~= nil and conseil == nil) or ( dz_conseil_meteo ~= nil and conseil ~= nil and display_conseils == false ) then -- Mise à jour du devise texte conseil météo si il existe même s'il n'y a pas de conseil disponible
			 commandArray[#commandArray+1] = {['UpdateDevice'] = dz_conseil_meteo..'|0|Aucun conseil disponible'}
			 	  
			end
-- ====================================================================================================================	
-- Commentaire météo	  
-- ====================================================================================================================		  
	  
			if ( dz_commentaire_meteo ~= nil and commentaire ~= nil and CouleurVigilance > 1 ) or ( dz_commentaire_meteo ~= nil and commentaire ~= nil and display_commentaire == true ) then -- Mise à jour du devise texte commentaire météo si il existe
			 commandArray[#commandArray+1] = {['UpdateDevice'] = dz_commentaire_meteo..'|0|'.. commentaire}
			 
			 
			elseif (dz_commentaire_meteo ~= nil and commentaire == nil ) or ( dz_commentaire_meteo ~= nil and commentaire ~= nil and display_commentaire == false ) then -- Mise à jour du devise texte commentaire météo si il existe même s'il n'y a pas de commentaire disponible
			 commandArray[#commandArray+1] = {['UpdateDevice'] = dz_commentaire_meteo..'|0|Aucun commentaire disponible'}
			 
			end
 
-- ====================================================================================================================	
-- vigilance vague submersion	  
-- ====================================================================================================================
if vague_sub == nil and dz_alert_vague ~= nil then -- pas de donnée
	 
	commandArray[#commandArray+1] = {['UpdateDevice'] = dz_alert_vague..'|1|Aucune donn&eacute;e vague submersion'}
             
elseif dz_alert_vague ~= nil and vague_sub ~= nil then	
		voir_les_logs("--- --- --- Vigilance vague submersion : ".. vague_sub,debugging)
              
		if tonumber(vague_sub) == 1   then -- niveau 1
			  if dz_alert_vague ~= nil then
				 commandArray[#commandArray+1] = {['UpdateDevice'] = dz_alert_vague..'|1|Pas de vigilance vague submersion'}
				 
			  end
			  if send_notification_vague > 0 and send_notification_vague < 2 then
				 commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte vigilance vague submersion#Pas de vigilance vague submersion'}
				 
			  end
			  voir_les_logs("--- --- --- Pas de vigilance vague submersion --- --- ---",debugging)
		elseif tonumber(vague_sub) == 2   then -- niveau 2
			  if dz_alert_vague ~= nil then
				 commandArray[#commandArray+1] = {['UpdateDevice'] = dz_alert_vague..'|2|Risque de vague submersion g&eacute;n&eacute;ratrice de d&eacute;bordements localis&eacute;s'}
				 
			  end
			  if send_notification_vague > 0 and send_notification_vague < 3 then
				 commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte vigilance vague submersion#Risque de vague submersion génératrice de débordements localisés'}
				 
			  end
			  voir_les_logs("--- --- --- vigilance faible vague submersion --- --- ---",debugging)   
		elseif tonumber(vague_sub) == 3   then -- niveau 3
			  if dz_alert_vague ~= nil then
				 commandArray[#commandArray+1] = {['UpdateDevice'] = dz_alert_vague..'|3|Risque de vague submersion g&eacute;n&eacute;ratrice de d&eacute;bordements importants'}
				 
			  end
			  if send_notification_vague > 0 and send_notification_vague < 4 then
				 commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte vigilance vague submersion#Risque de vague submersion génératrice de débordements importants'}
				 
			  end
			  voir_les_logs("--- --- --- vigilance Forte vague submersion --- --- ---",debugging)      
		elseif tonumber(vague_sub) > 3  then -- niveau 4
			  if dz_alert_vague ~= nil then
				 commandArray[#commandArray+1] = {['UpdateDevice'] = dz_alert_vague..'|4|Risque de vague submersion majeur'}
				 
			  end
			  if send_notification_vague > 0 and send_notification_vague < 5 then
				 commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte vigilance vague submersion#Risque de vague submersion majeur'}
				 
			  end
			  voir_les_logs("--- --- --- vigilance très forte vague submersion --- --- ---",debugging)
		else
		  print("niveau non defini")
		end		  
		if dz_alert_vague ~= nil and vague_sub == nil then
		commandArray[#commandArray+1] = {['UpdateDevice'] = dz_alert_vague..'|0|Pas d\'information vigilance vague submersion'}
		
		end
 	end			
-- ====================================================================================================================	
-- fin vigilance vague submersion	  
-- ====================================================================================================================	
voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
end -- if time
return commandArray