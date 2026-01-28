-- Property selling system
-- Uses Framework Bridge (loaded before this file)

-- Open sell property menu
RegisterNetEvent('haus-manager:client:openSellMenu', function(data)
    print("^3[Haus-Manager Sell]^7 openSellMenu event triggered")
    print("^3[Haus-Manager Sell]^7 Data received:", json.encode(data))
    
    local property = data.property
    
    if not property then
        print("^1[Haus-Manager Sell ERROR]^7 No property data received!")
        Framework.Notify("Fehler: Keine Immobiliendaten!", 'error')
        return
    end
    
    print("^3[Haus-Manager Sell]^7 Property:", property.property_name)
    
    -- Verify ownership
    local playerData = Framework.GetPlayerData()
    print("^3[Haus-Manager Sell]^7 Player citizenid:", playerData.citizenid)
    print("^3[Haus-Manager Sell]^7 Owner citizenid:", property.owner_identifier)
    
    if property.owner_identifier ~= playerData.citizenid then
        Framework.Notify("Sie sind nicht der Eigentümer dieser Immobilie!", 'error')
        return
    end
    
    local sellPrice = math.floor(property.price * 0.5)
    print("^3[Haus-Manager Sell]^7 Opening sell menu, price:", property.price, "sell price:", sellPrice)
    
    local menu = {
        {
            header = "🏠 " .. property.property_name .. " verkaufen",
            isMenuHeader = true,
            txt = "Wählen Sie eine Verkaufsoption"
        },
        {
            header = "🏛️ An Stadt verkaufen",
            txt = "Verkaufen Sie die Immobilie zurück an die Stadt<br>Erhält: $" .. sellPrice,
            params = {
                isServer = false,
                event = "haus-manager:client:confirmSellToCity",
                args = {
                    property = property
                }
            }
        },
        {
            header = "👤 An Spieler verkaufen",
            txt = "Verkaufen Sie die Immobilie an einen anderen Spieler",
            params = {
                isServer = false,
                event = "haus-manager:client:sellToPlayer",
                args = {
                    property = property
                }
            }
        },
        {
            header = "❌ Abbrechen",
            params = {
                event = "haus-manager:client:closeMenu"
            }
        }
    }
    
    Menu.Open(menu)
    print("^2[Haus-Manager Sell]^7 Sell menu opened successfully")
end)

-- Confirm sell to city
RegisterNetEvent('haus-manager:client:confirmSellToCity', function(data)
    local property = data.property
    local sellPrice = math.floor(property.price * 0.5)
    
    local menu = {
        {
            header = "⚠️ Bestätigung erforderlich",
            isMenuHeader = true,
            txt = "Sind Sie sicher?"
        },
        {
            header = "📋 Verkaufsdetails",
            txt = string.format(
                "Immobilie: %s<br>" ..
                "Kaufpreis: $%s<br>" ..
                "Verkaufspreis: $%s (50%%)",
                property.property_name,
                FormatMoney(property.price),
                FormatMoney(sellPrice)
            ),
            isMenuHeader = true
        },
        {
            header = "✅ Verkauf bestätigen",
            txt = "Verkaufen Sie die Immobilie an die Stadt",
            params = {
                isServer = true,
                event = "haus-manager:server:sellToCity",
                args = {
                    property.property_id
                }
            }
        },
        {
            header = "❌ Abbrechen",
            params = {
                event = "haus-manager:client:closeMenu"
            }
        }
    }
    
    Menu.Open(menu)
end)

-- Sell to player - open NUI for player selection and price input
RegisterNetEvent('haus-manager:client:sellToPlayer', function(data)
    local property = data.property
    
    -- Get nearby players
    Framework.TriggerCallback('haus-manager:server:getNearbyPlayers', function(players)
        if not players or #players == 0 then
            Framework.Notify("Keine Spieler in der Nähe!", 'error')
            return
        end
        
        -- Open NUI with player list
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openSellToPlayer",
            property = {
                id = property.property_id,
                name = property.property_name,
                type = property.property_type,
                price = property.price
            },
            players = players
        })
    end)
end)

-- Handle NUI callback for selling to player
RegisterNUICallback('sellToPlayer', function(data, cb)
    SetNuiFocus(false, false)
    
    if not data.targetId or not data.price or not data.propertyId then
        Framework.Notify("Ungültige Daten!", 'error')
        cb('error')
        return
    end
    
    -- Trigger server event
    TriggerServerEvent('haus-manager:server:sellToPlayer', data.propertyId, data.targetId, tonumber(data.price))
    cb('ok')
end)

-- Close NUI
RegisterNUICallback('closeSellUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Helper function to format money
function FormatMoney(amount)
    local formatted = tostring(amount)
    local k
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then
            break
        end
    end
    return "$" .. formatted
end
