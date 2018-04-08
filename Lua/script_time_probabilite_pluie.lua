--[[
name : script_time_probabilite_pluie.lua
auteur : papoo
date de création : 04/02/2018
Date de mise à jour : 16/02/2018
Principe : Ce script a pour but d'interroger l'API du site https://www.wunderground.com/ toutes les heures afin de 
récuperer les calculs de probabilités de pluie et de neige sur 36 heures pour une ville donnée. Cette API utilise une clé gratuite pour 500 requêtes par heure
Il faut donc s'inscrire sur weatherunderground pour avoir accès à cette API 
avant l'utilisation de ce script, pensez à créer une variable utilisateur de type chaine pour y stocker votre clé API
pour créer/modifier une variable utilisateur : domoticz => Réglages => Plus d'options => Variables utilisateur
http://pon.fr/probabilite-de-pluie-et-de-neige-en-lua/
http://easydomoticz.com/forum/viewtopic.php?f=17&t=2301#p20893
https://github.com/papo-o/domoticz_scripts/blob/master/Lua/script_time_probabilite_pluie.lua

Ce script utilise Lua-Simple-XML-Parser https://github.com/Cluain/Lua-Simple-XML-Parser
]]--
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = false  			            -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local pays='FRANCE'					            -- Votre pays, nécessaire pour l'API
local api_wu = 'api_weather_underground' 	    -- Nom de la variable utilisateur contenant l'API Weather Underground de 16 caractères préalablement créé (variable de type chaine)
local ville='Limoges'    			            -- Votre ville ou commune 
                                                -- L'api fournie 36 probabilités de pluie, 1 par heure.  
local proba_pluie_h = {}			            -- Ajoutez, modifiez ou supprimez les variables proba_pluie_h[] 
                                                -- en changeant le N° entre [] correspondant à l'heure souhaitée pour l'associer au device concerné dans dz
proba_pluie_h[1]=504    			            -- renseigner l'idx du device % probabilité pluie à 1 heure associé, nil si non utilisé 
proba_pluie_h[2]=505    			            -- renseigner l'idx du device % probabilité pluie à 2 heures associé, nil si non utilisé
proba_pluie_h[4]=639   				            -- renseigner l'idx du device % probabilité pluie à 4 heures associé, nil si non utilisé
proba_pluie_h[6]=506    			            -- renseigner l'idx du device % probabilité pluie à 6 heures associé, nil si non utilisé
proba_pluie_h[12]=507   			            -- renseigner l'idx du device % probabilité pluie à 12 heures associé, nil si non utilisé
proba_pluie_h[24]=508   			            -- renseigner l'idx du device % probabilité pluie à 24 heures associé, nil si non utilisé
                                                -- L'api fournie 36 probabilités de neige, 1 par heure.
local proba_neige_h={}				            -- comme pour la pluie Ajoutez, modifiez ou supprimez les variables proba_neige_h[] 
                                                -- en changeant le N° entre [] correspondant à l'heure souhaitée pour l'associer au device concerné dans dz	
proba_neige_h[1]=771    			            -- renseigner l'idx du device % probabilité neige à 1 heure associé, nil si non utilisé 
proba_neige_h[3]=772    		                -- renseigner l'idx du device % probabilité neige à 2 heures associé, nil si non utilisé
proba_neige_h[6]=773   				            -- renseigner l'idx du device % probabilité neige à 4 heures associé, nil si non utilisé
proba_neige_h[12]=774    			            -- renseigner l'idx du device % probabilité neige à 6 heures associé, nil si non utilisé
proba_neige_h[24]=738   			            -- renseigner l'idx du device % probabilité neige à 12 heures associé, nil si non utilisé
proba_neige_h[36]=775  				            -- renseigner l'idx du device % probabilité neige à 24 heures associé, nil si non utilisé

local seuil_notification= nil	                -- pourcentage au delà duquel vous souhaitez être notifié, nil si non utilisé

--------------------------------------------
----------- Fin variables à éditer ---------
-------------------------------------------- 
local nom_script = 'Probabilite Pluie'
local version = '1.18'
local pluie
local neige
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 
function voir_les_logs (s,debugging)
    if (debugging) then 
		if s ~= nil then
        print ("<font color='#f3031d'> ".. s .." </font>")
		else
		print ("<font color='#f3031d'>aucune valeur affichable</font>")
		end
    end
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
-------------- Fin Fonctions ---------------
-------------------------------------------- 
commandArray = {}
time=os.date("*t")

--if time.min % 2 == 0 then -- exécution du script toutes les X minute(s) 
if ((time.min-1) % 60) == 0 then -- exécution du script toutes les heures à xx:01
	voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
local APIKEY = uservariables[api_wu]

    local rid = assert(io.popen("/usr/bin/curl -m8 http://api.wunderground.com/api/"..APIKEY.."/hourly/lang:FR/q/"..pays.."/"..ville..".xml"))
    voir_les_logs("--- --- --- http://api.wunderground.com/api/"..APIKEY.."/hourly/lang:FR/q/"..pays.."/"..ville..".xml",debugging)
    local testXml = rid:read('*all')
    rid:close()                    

local parsedXml = XmlParser:ParseXmlText(testXml)
	if parsedXml then 
        local abr = parsedXml.response.hourly_forecast	
		for i in pairs(abr:children()) do 
				if proba_pluie_h[i] ~= nil then 
					pluie = tonumber(abr:children()[i]:children()[19]:value())
					voir_les_logs("--- --- --- Probabilite de pluie a ".. i .."h => " .. pluie,debugging)
					commandArray[#commandArray+1] = {['UpdateDevice'] = proba_pluie_h[i]..'|0|'.. pluie}
					if seuil_notification ~= nil and pluie > seuil_notification then
					commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte : '.. pluie ..' % de probabilité de pluie dans '.. i ..'heure(s)'}
					
					end
				end
				if proba_neige_h[i] ~=nil then
					neige = tonumber(abr:children()[i]:children()[18]:children()[2]:value())
					voir_les_logs("--- --- --- probabilite de neige a ".. i .."h => " .. neige,debugging)
					commandArray[#commandArray+1] = {['UpdateDevice'] = proba_neige_h[i]..'|0|'.. neige}
					if seuil_notification ~= nil and neige > seuil_notification then
					commandArray[#commandArray+1] = {['SendNotification'] = 'Alerte : '.. neige ..' % de probabilité de neige dans '.. i ..'heure(s)'}
					end
                    --print(abr:children()[i]:children()[4]:value())
                end
		end
	end	
	voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)
end -- if time
return commandArray