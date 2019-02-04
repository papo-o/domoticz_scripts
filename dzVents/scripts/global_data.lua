-- global_data.lua 

function datefr(str)
    if (str) then
	str = string.gsub(str, "January", "Janvier");
	str = string.gsub(str, "February",	"Février")
	str = string.gsub(str, "March",	"Mars")
	str = string.gsub(str, "April",	"Avril")
	str = string.gsub(str, "May",	"Mai")
	str = string.gsub(str, "June",	"Juin")
	str = string.gsub(str, "July",	"Juillet")
	str = string.gsub(str, "August",	"Août")
	str = string.gsub(str, "september",	"Septembre")
	str = string.gsub(str, "October",	"Octobre")
	str = string.gsub(str, "November",	"Novembre")
	str = string.gsub(str, "December",	"Décembre")
	str = string.gsub(str, "Monday",	"Lundi")
	str = string.gsub(str, "Tuesday",	"Mardi")
	str = string.gsub(str, "Wednesday",	"Mercredi")
	str = string.gsub(str, "Thursday", "Jeudi")
    str = string.gsub(str, "Friday", "Vendredi")
    str = string.gsub(str, "Saturday", "Samedi")
    str = string.gsub(str, "Sunday", "Dimanche")

     end
    return (str)
end 
return {
    
        data = {
		                domoticzLocation                        = { initial = "France" },
                        managedNotifications                    = { initial = {}},                        
                  },

	helpers =   {
                    -- xmas = function(dz)
                        -- return dz.time.matchesRule('on 25/12')
                    -- end,
                    
                    -- halloween = function(dz)
                        -- return dz.time.matchesRule('on 23/10-4/11')
                    -- end,
            
                    -- birthday = function(dz)
                        -- return dz.time.matchesRule('on 11/5,19/8')
                    -- end,

                    ------------------------------------------------------------------------------------------------------
-- script original :
-- Universal function notification by waaren: https://www.domoticz.com/forum/viewtopic.php?f=59&t=26542#p204958                    
                    
                    managedNotify = function (dz, subject, message, messageType, muteTimeMin,quietHours) 
                    local now = os.time(os.date('*t'))                  -- seconds since 1/1/1970 00:00:01
                    muteTimeMin = muteTimeMin or 1
                    
                    -- if ( not dz.globalData.managedNotifications[message] ) or 
                       -- (( dz.globalData.managedNotifications[message] + muteTimeMin * 60 ) <= now ) then
                            -- if quietHours and dz.time.matchesRule("at " .. quietHours) then
                                -- dz.log("Période silencieuse: pas de notification.")  
                            -- else
                                -- dz.notify("managedNotification", message,nil,nil,nil,messageType)  
                                -- dz.globalData.managedNotifications[message] = now
                            -- end     
                    -- else
                        -- -- No action required yet.  
                        -- dz.log("le message '" .. message .. "' a été envoyé " .. 
                        -- datefr(os.date("%A, %d %B %Y (%H:%M)",dz.globalData.managedNotifications[message]) ,dz.LOG_FORCE))
                   -- end
                    -- end,
                        if subject == nil or string.lower(subject) == "delete"  then 
                            dz.globalData.managedNotifications[message] = nil 
                            dz.log("le message sélectionné " .. message .. "  a été supprimé",dz.LOG_FORCE)
                            return 3
                        elseif string.lower(subject) ==  "deleteall" then
                            dz.globalData.managedNotifications = nil 
                            dz.log("Tous les messages sélectionnés ont été supprimés",dz.LOG_FORCE)
                            return 4
                        elseif ( not dz.globalData.managedNotifications[message] ) or 
                              (( dz.globalData.managedNotifications[message] + muteTimeMin * 60 ) <= now ) then
                                if quietHours and dz.time.matchesRule("at " .. quietHours) then
                                    dz.log("Période silencieuse: pas de notification.") 
                                    return 1
                                else
                                    dz.notify(subject, message,nil,nil,nil,messageType)  
                                    dz.globalData.managedNotifications[message] = now
                                    local cleanupPeriod = 30 * 24 * 3600                                -- 30 days
                                    for key,timeStamp in pairs(dz.globalData.managedNotifications) do
                                        if ( dz.globalData.managedNotifications[key] + cleanupPeriod ) < now then 
                                            dz.globalData.managedNotifications[key] = nil
                                            dz.log("l\'ancien message " .. key .. "  a été effacé",dz.LOG_FORCE)
                                        end
                                    end
                                    return 0
                                end     
                        else
                            -- No action required yet.  
                            dz.log("le message '" .. message .. "' a été envoyé " .. 
                            datefr(os.date("%A, %d %B %Y (%H:%M)",dz.globalData.managedNotifications[message]) ,dz.LOG_FORCE))
                            return 2        
                        end
                    end,                        
                    ------------------------------------------------------------------------------------------------------                    
                    
                    
                    
                    
                },--helpers
}--return
