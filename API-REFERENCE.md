# Quick Reference - Haus-Manager API

## Server-Side Exports

### Datenbank-Funktionen
```lua
-- Get all properties
local properties = exports['haus-manager']:GetAllProperties()

-- Get property by ID
local property = exports['haus-manager']:GetPropertyById(propertyId)

-- Get properties by owner
local myProperties = exports['haus-manager']:GetPropertiesByOwner(citizenId)

-- Create property
local propertyId = exports['haus-manager']:CreateProperty({
    propertyType = "house",
    propertyName = "Test House",
    coords = {x = 0, y = 0, z = 0, heading = 0},
    interiorType = "StandardHouse",
    price = 100000,
    markerVisible = true,
    markerRadius = 50.0
})

-- Update property
exports['haus-manager']:UpdateProperty(propertyId, {
    price = 150000,
    propertyName = "Updated Name"
})

-- Delete property
exports['haus-manager']:DeleteProperty(propertyId)
```

### Schlüssel-Funktionen
```lua
-- Check if player has key
local hasKey = exports['haus-manager']:HasPropertyKey(propertyId, citizenId)

-- Give key to player
local success, error = exports['haus-manager']:GivePropertyKey(propertyId, citizenId, grantedBy)

-- Remove key from player
exports['haus-manager']:RemovePropertyKey(propertyId, citizenId)

-- Get all keys for a property
local keys = exports['haus-manager']:GetPropertyKeys(propertyId)

-- Get all keys for a player
local playerKeys = exports['haus-manager']:GetPlayerKeys(citizenId)
```

### Miet-Funktionen
```lua
-- Calculate rent price
local rentPrice = exports['haus-manager']:CalculateRentPrice(propertyPrice, rentPeriodDays)

-- Calculate rent end date
local endDate = exports['haus-manager']:CalculateRentEndDate(rentPeriodDays)

-- Check if rent is expired
local expired = exports['haus-manager']:IsRentExpired(rentEndDate)
```

## Client-Side Exports

```lua
-- Get all properties
local properties = exports['haus-manager']:GetProperties()

-- Get player keys
local myKeys = exports['haus-manager']:GetPlayerKeys()

-- Check if player has access to property
local hasAccess = exports['haus-manager']:HasAccessToProperty(property)

-- Enter property
exports['haus-manager']:EnterProperty(property)

-- Exit property
exports['haus-manager']:ExitProperty()

-- Check if inside property
local isInside = exports['haus-manager']:IsInsideProperty()
```

## Server Events

### Trigger from Client
```lua
-- Create property (admin only)
TriggerServerEvent('haus-manager:server:createProperty', propertyData)

-- Purchase property
TriggerServerEvent('haus-manager:server:purchaseProperty', propertyId)

-- Rent property
TriggerServerEvent('haus-manager:server:rentProperty', propertyId, rentPeriodDays)

-- Give key to player
TriggerServerEvent('haus-manager:server:giveKey', propertyId, targetPlayerId)

-- Remove key from player
TriggerServerEvent('haus-manager:server:removeKey', propertyId, citizenId)

-- Store vehicle in garage
TriggerServerEvent('haus-manager:server:storeVehicle', propertyId, plate, vehicleData)

-- Spawn vehicle from garage
TriggerServerEvent('haus-manager:server:spawnVehicle', propertyId, plate)
```

### Listen on Server
```lua
RegisterNetEvent('haus-manager:server:createProperty', function(data)
    -- Your code
end)
```

## Client Events

### Trigger from Server
```lua
-- Update properties for clients
TriggerClientEvent('haus-manager:client:updateProperties', source, properties)

-- Update player keys
TriggerClientEvent('haus-manager:client:updateKeys', source, keys)

-- Open admin UI
TriggerClientEvent('haus-manager:client:openAdminUI', source)

-- Open garage UI
TriggerClientEvent('haus-manager:client:openGarageUI', source)

-- Spawn vehicle
TriggerClientEvent('haus-manager:client:spawnVehicle', source, vehicleData, garageCoords)
```

### Listen on Client
```lua
RegisterNetEvent('haus-manager:client:updateProperties', function(properties)
    -- Your code
end)
```

## Callbacks

### Server Callbacks
```lua
-- Get all properties
QBCore.Functions.TriggerCallback('haus-manager:server:getAllProperties', function(properties)
    -- Your code
end)

-- Get player properties
QBCore.Functions.TriggerCallback('haus-manager:server:getPlayerProperties', function(properties)
    -- Your code
end)

-- Get property info
QBCore.Functions.TriggerCallback('haus-manager:server:getPropertyInfo', function(property)
    -- Your code
end, propertyId)

-- Get player keys
QBCore.Functions.TriggerCallback('haus-manager:server:getPlayerKeys', function(keys)
    -- Your code
end)

-- Check if player has key
QBCore.Functions.TriggerCallback('haus-manager:server:hasKey', function(hasKey)
    -- Your code
end, propertyId)

-- Check if player is admin
QBCore.Functions.TriggerCallback('haus-manager:server:isAdmin', function(isAdmin)
    -- Your code
end)

-- Get nearby players
QBCore.Functions.TriggerCallback('haus-manager:server:getNearbyPlayers', function(players)
    -- Your code
end, radius)

-- Get garage vehicles
QBCore.Functions.TriggerCallback('haus-manager:server:getGarageVehicles', function(vehicles)
    -- Your code
end, propertyId)
```

## NUI Callbacks

### From JavaScript to Client
```javascript
// Close UI
$.post('https://haus-manager/closeUI', JSON.stringify({}));

// Create property
$.post('https://haus-manager/createProperty', JSON.stringify(propertyData));

// Update property
$.post('https://haus-manager/updateProperty', JSON.stringify({
    propertyId: propertyId,
    updates: updateData
}));

// Delete property
$.post('https://haus-manager/deleteProperty', JSON.stringify({
    propertyId: propertyId
}));

// Purchase property
$.post('https://haus-manager/purchaseProperty', JSON.stringify({
    propertyId: propertyId
}));

// Rent property
$.post('https://haus-manager/rentProperty', JSON.stringify({
    propertyId: propertyId,
    rentPeriod: days
}));

// Get player position
$.post('https://haus-manager/getPlayerPosition', JSON.stringify({}), function(coords) {
    console.log(coords.x, coords.y, coords.z, coords.heading);
});
```

### From Client to JavaScript
```lua
-- Open admin UI
SendNUIMessage({
    action = "openAdminUI",
    properties = properties,
    config = Config
})

-- Open garage UI
SendNUIMessage({
    action = "openGarageUI",
    properties = properties,
    config = Config
})

-- Open property UI
SendNUIMessage({
    action = "openPropertyUI",
    property = property,
    config = Config
})
```

## Config Examples

### Add Custom Interior
```lua
Config.Interiors["CustomInterior"] = {
    label = "Custom Interior Name",
    type = "house", -- apartment, house, or office
    shell = "ShellName", -- QB-Interior shell
    spawn = vector4(0.0, 0.0, 0.0, 0.0)
}
```

### Modify Garage Sizes
```lua
Config.GarageSizes.medium = {
    label = "Mittel",
    slots = 10, -- Changed from 6 to 10
    price = 20000 -- Changed from 15000 to 20000
}
```

### Change Rent Multipliers
```lua
Config.RentPeriods[1] = {
    label = "1 Woche",
    days = 7,
    multiplier = 0.10 -- Changed from 0.05 to 0.10 (10%)
}
```

### Modify Marker Settings
```lua
Config.Markers = {
    Enabled = true,
    Type = 27, -- Different marker type
    DrawDistance = 100.0, -- Increased draw distance
    Color = { r = 255, g = 0, b = 0 }, -- Red instead of yellow-green
}
```

## Commands

### Admin Commands
```
/hausadmin - Open property management UI
/hausgarage - Open garage management UI
/hausdebug - Show debug information (if Config.Debug = true)
```

### Player Commands
```
/togglemarkers - Toggle marker visibility
```

## Database Direct Access

### Property Fields
```sql
SELECT 
    property_id,        -- Unique ID
    property_type,      -- apartment/house/office
    property_name,      -- Display name
    coords,            -- JSON: {x, y, z, heading}
    interior_type,     -- Interior shell name
    price,             -- Property price
    owner_identifier,  -- Owner's citizenid (NULL if not owned)
    owned,             -- 0 or 1
    is_rented,         -- 0 or 1
    rent_end_date,     -- Unix timestamp (NULL if not rented)
    marker_visible,    -- 0 or 1
    marker_radius      -- Float (meters)
FROM haus_properties
WHERE property_id = 'property_123456'
```

### Key Fields
```sql
SELECT 
    property_id,
    citizen_id,        -- Player who has the key
    granted_by,        -- Who gave the key
    granted_at         -- Timestamp
FROM haus_keys
WHERE property_id = 'property_123456'
```

### Vehicle Fields
```sql
SELECT 
    property_id,
    plate,
    vehicle_data,      -- JSON: QB-Core vehicle props
    stored             -- 0 (out) or 1 (stored)
FROM haus_garage_vehicles
WHERE property_id = 'property_123456'
```

## Common Use Cases

### Check if player owns any property
```lua
local Player = QBCore.Functions.GetPlayer(source)
local properties = exports['haus-manager']:GetPropertiesByOwner(Player.PlayerData.citizenid)
local ownsProperty = #properties > 0
```

### Give all online players access to a property
```lua
local players = QBCore.Functions.GetQBPlayers()
for _, Player in pairs(players) do
    exports['haus-manager']:GivePropertyKey(propertyId, Player.PlayerData.citizenid, "system")
end
```

### Auto-create properties from table
```lua
local propertiesData = {
    {name = "House 1", type = "house", coords = vector4(100, 200, 30, 0), price = 100000},
    {name = "House 2", type = "house", coords = vector4(110, 210, 30, 0), price = 120000},
}

for _, data in ipairs(propertiesData) do
    exports['haus-manager']:CreateProperty({
        propertyType = data.type,
        propertyName = data.name,
        coords = data.coords,
        interiorType = "StandardHouse",
        price = data.price,
        markerVisible = true,
        markerRadius = 50.0
    })
end
```

---

**Note**: All coordinates use vector4 format: `vector4(x, y, z, heading)`
