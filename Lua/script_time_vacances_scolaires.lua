--[[
name : script_time_vacances_scolaires.lua
auteur : papoo
Mise à jour : 28/04/2018
date : 05/08/2017
Principe :
 Ce script a pour but de remonter les informations du site http://telechargement.index-education.com/vacances.xml
]]--
--------------------------------------------
-- Variables à éditer
--------------------------------------------
local debugging = false                             -- true pour voir les logs dans la console log Dz ou false pour ne pas les voir
local script_actif = true                           -- active (true) ou désactive (false) ce script simplement
local zoneSelect = "A"                              --Indiquer ici la zone 
local dzVacancesScolaires = "Vacances Scolaires"    -- Renseigner ici le nom du switch à mettre a jour dans domoticz, nil si inutilisé 
local Scene_Vacances_Scolaires = "Vacances"         -- Renseigner ici le nom du scénario à mettre a jour dans domoticz, nil si inutilisé
local checkHour = 1
local checkMinute = 12

--------------------------------------------
-- Fin Variables à éditer
--------------------------------------------
local nom_script = "Vacances Scolaires"
local version = "1.05"
local DateDuJour = os.date("%Y/%m/%d")
local abr
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
--]]
---------------------------------------------
function libelleVacances(P_idLibelle)
   for i in pairs(abr:children()[2]:children() ) do
     id = abr:children()[2]:children()[i]["@id"]
     if ( tostring(P_idLibelle) == id ) then
        return abr:children()[2]:children()[i]:value()
     end
  end
end
--------------------------------------------
-- Lua-Simple-XML-Parser
--------------------------------------------
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

--if time.min % 1 == 0 then -- éxécution du script toutes les X minute(s) 
--if ((time.min-1) % 60) == 0 then -- éxécution du script toutes les heures à xx:01
if time.hour == checkHour and time.min == checkMinute and script_actif == true then
    voir_les_logs("=========== ".. nom_script .." (v".. version ..") ===========",debugging)
    voir_les_logs("=========== la date du jour : " .. DateDuJour .." ===========",debugging)
    local rid = assert(io.popen("/usr/bin/curl -m5 http://telechargement.index-education.com/vacances.xml"))
    local testXml = rid:read('*all')
            rid:close()
    local parsedXml = XmlParser:ParseXmlText(testXml)
    if (parsedXml) then abr = parsedXml.root 
    --La fonction est défini ici sinon erreur  parsedXml non défini
        for i in pairs(abr.calendrier:children()) do
            voir_les_logs("=========== Zones disponibles : " .. abr.calendrier:children()[i]["@libelle"] .." ===========",debugging)
            if (abr.calendrier:children()[i]["@libelle"] == zoneSelect ) then
                voir_les_logs("=========== Zone : " .. zoneSelect .." ===========",debugging)     
                voir_les_logs("=========== Listes des périodes de vacances ===========",debugging)          
                for j in pairs(abr.calendrier:children()[i]:children() ) do
                    --Verifie si la date est dans la période de vacances
                    voir_les_logs("=========== date dans la période : du " .. abr.calendrier:children()[i]:children()[j]["@debut"].." au "..abr.calendrier:children()[i]:children()[j]["@fin"].." id "..abr.calendrier:children()[i]:children()[j]["@libelle"] .." ===========",debugging)          
                    if (tostring(DateDuJour) >= tostring(abr.calendrier:children()[i]:children()[j]["@debut"]) and 
                    tostring(DateDuJour) < tostring(abr.calendrier:children()[i]:children()[j]["@fin"]) ) then
                        tmpIdLibelle = abr.calendrier:children()[i]:children()[j]["@libelle"]
                        voir_les_logs("=========== La journée est pendant les vacances scolaires de la zone ".. zoneSelect ..", passage du switch à On ===========",debugging)                   
                        voir_les_logs("=========== du ".. abr.calendrier:children()[i]:children()[j]["@debut"] .." au ".. abr.calendrier:children()[i]:children()[j]["@fin"] .." id ".. abr.calendrier:children()[i]:children()[j]["@libelle"] .." ===========",debugging)
                        vacancesScolaires = true
                        debutVac = abr.calendrier:children()[i]:children()[j]["@debut"]
                        finVac = abr.calendrier:children()[i]:children()[j]["@fin"]
                        libelleVac = libelleVacances(tmpIdLibelle)
                        break
                    else
                        voir_les_logs("=========== La journée n\'est pas pendant les vacances scolaires de la zone ".. zoneSelect ..", passage du switch à Off ===========",debugging) 
                        
                        vacancesScolaires = false
                    end
                end
            end
        end
        if vacancesScolaires == true then
            if dzVacancesScolaires ~= nil then
                commandArray[dzVacancesScolaires] = 'On'
                voir_les_logs("=========== La journée est pendant les vacances scolaires de la zone ".. zoneSelect ..", passage du switch à On ===========",debugging)
            end
            if Scene_Vacances_Scolaires ~= nil then
                commandArray['Scene:'.. Scene_Vacances_Scolaires] = "On"
                voir_les_logs("=========== La journée est pendant les vacances scolaires de la zone ".. zoneSelect ..", passage du scénario à On ===========",debugging)
            end
        else
            if dzVacancesScolaires ~= nil then        
            commandArray[dzVacancesScolaires] = 'Off'
            voir_les_logs("=========== La journée n\'est pas pendant les vacances scolaires de la zone ".. zoneSelect ..", passage du switch à Off ===========",debugging)
            end
            if Scene_Vacances_Scolaires ~= nil then
                commandArray['Scene:'.. Scene_Vacances_Scolaires] = "Off"
                voir_les_logs("=========== La journée n\'est pas pendant les vacances scolaires de la zone ".. zoneSelect ..", passage du scénario à Off ===========",debugging)
            end            
        end

    end
voir_les_logs("========= Fin ".. nom_script .." (v".. version ..") =========",debugging)	
end -- if time
return commandArray
