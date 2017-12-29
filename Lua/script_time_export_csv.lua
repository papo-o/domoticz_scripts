-- ********************************************************************************
--
-- Called every minute, records current values of device list every 5 minutes
--    1) yeah, current, no avg - want it simple, doesn't need more
--    2) won't see less than 5 min events - sees switches if they last longer than 5min
--
-- comma "," is the separator => european users may double click csv files to Excel
-- Date and Time in 2 different columns, Excel treats days oddly but hours ok,
-- "plot.ly" (see below) recognizes them and concatenate them nicely (thanks, plotly).
--
-- You can mix all kind of devices in device list (temps, switch, meteo, temphum,
-- thermostat, text; etc...)
--
-- easily used with https://plot.ly/     (great, bit slow to load, free for personnal use, ++)
--
-- switch On Off are replaced with 15-0 to be clearly seen with temps around 20°C
-- 
--------------------------------------------
------------ Variables à éditer ------------
-------------------------------------------- 

local debugging = false  	-- true pour voir les logs dans la console log Dz ou false pour ne pas les voir

fichierJournalier="/media/Freebox/Trend/daily.csv"            -- actually, mine is on a tmpfs dir (RAM Drive)
fichierMensuel="/media/Freebox/Trend/monthly.csv"              -- on cifs dir, shared with Windows

devices = {"Compteur Eau Chaude"
      , "Compteur Eau Froide"
      , "Compteur Gaz"
      , "Compteur Lumières"
      , "Compteur Prises"
      , "Compteur Technique"
      , "DJU"
      , "EDF"
      , "Puissance Frigo"
      , "Temperature exterieure"
      --, "Prise 4"

}
--------------------------------------------
----------- Fin variables à éditer ---------
--------------------------------------------
commandArray = {}
--------------------------------------------
---------------- Fonctions -----------------
-------------------------------------------- 

function debug(m)
   print("......CSV "..m)
end
function voir_les_logs (s, debugging)
    if (debugging) then 
		if s ~= nil then
        print ("<font color='#f3031d'>".. s .."</font>")
		else
		print ("<font color='#f3031d'>aucune valeur affichable</font>")
		end
    end
end	
--------------------------------------------
------------ Fin Fonctions -----------------
--------------------------------------------
time=os.date("*t")


-- debug ("Temperature exterieure="..otherdevices_svalues['Temperature exterieure'])
-- debug ("Météo Baromètre="..otherdevices_svalues["Météo Baromètre"])
if ((time.min-1) % 5) == 0 then
-- if time.min % 5 == 0 then
   --print('Export_CSV.lua')
   -- debug("début")
   -- create file if needed : write headers to file
   f=io.open(fichierJournalier, "r")
   if f == nil then
      -- debug("création du fichier journalier")
      f=io.open("/tmp/a.txt", "w")
      f:write("Date,Time")                         -- separator = comma
      for i,d in ipairs(devices) do

    -- special treatment for headers of multi valued datas :
    -- check data type 

    v=otherdevices[d]                        -- v is the value attached to device d
    --debug("d="..d.."="..(v or "nil"))
    if v==nil or v=="" or v=="Open" then                  -- multi valued ?
       v=otherdevices_svalues[d] or ""
       --debug("d="..d.."="..v)
       v,nbCommas=string.gsub(v,";",",")     
       if nbCommas==0 then
          f:write(",", d) 
       else                                  -- write it as Meteo 1, Meteo 2, ...
          for i=1,nbCommas+1 do f:write(",", d.." "..i) end
       end
    else
       f:write(",", d)                       -- separator = comma
    end
    
      end
      f:write("\n")
      f:close()
      -- made to go on a cifs directory, shared with Windows
      os.execute("iconv -f utf8 -t ISO-8859-1 /tmp/a.txt > '"..fichierJournalier.."'")
      os.execute("chmod 666 '"..fichierJournalier.."'")
   else
      f:close()      
   end                                            -- ok, header is time created

   
   -- do the stuff (generate datas)
   -- debug("génération des données")
   f=io.open(fichierJournalier, "a")
   f:write(os.date("%Y-%m-%d,%H:%M"))             -- separator = comma
   for i,d in ipairs(devices) do
      v=otherdevices[d]
      -- debug("d="..d.."="..(v or "nil"))
      if v==nil  or v=="" or v=="Open" then                    -- multi valued ?
    v=otherdevices_svalues[d] or ""
    v=string.gsub(v, ";", ",")               -- separator = comma
      end
      v=string.gsub(v,"On","15")                  -- yeah, On=15, Off=0
      v=string.gsub(v,"Off","0")
      f:write(",", v)                             -- separator = comma
   end
   f:write("\n")
   f:close()

   -- once a day, concat daily file to monthly file,
   -- 1) could be any TIME COMPATIBLE WITH % 5 ABOVE
   -- 2) if fichierMensuel is on a cifs dir, you have to choose
   --    a time where your PC is on.
   if time.hour == 20 and time.min == 35 then
      --debug("concaténation dans le fichier mensuel")
      f=io.open(fichierMensuel, "r")
      if f == nil then
    os.execute("head -n 1 '"..fichierJournalier.."' >> '"..fichierMensuel.."'")
      else
    f:close()
      end
      os.execute("tail -n +2 '"..fichierJournalier.."' >> '"..fichierMensuel.."'")
      fMensuelOk=io.open(fichierMensuel, "r")
      if fMensuelOk == nil then
    --debug("Pas de suppression car impossible de lire "..fichierMensuel)
      else
    os.execute("/bin/rm -f '"..fichierJournalier.."'")
    --debug("Suppression de "..fichierJournalier)
    fMensuelOk:close()
      end
   end
end

-- ********************************************************************************

return commandArray
