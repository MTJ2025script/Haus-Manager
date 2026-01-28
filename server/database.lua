-- Database initialization and schema
-- Framework-agnostic - uses MySQL only

-- Create tables on resource start
CreateThread(function()
    -- Properties table with all columns
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS haus_properties (
            id INT AUTO_INCREMENT PRIMARY KEY,
            property_id VARCHAR(50) UNIQUE NOT NULL,
            property_type VARCHAR(20) NOT NULL,
            property_name VARCHAR(100) NOT NULL,
            coords JSON NOT NULL,
            interior_type VARCHAR(50) NOT NULL DEFAULT 'ClassicApartment',
            price INT NOT NULL DEFAULT 0,
            owner_identifier VARCHAR(50) DEFAULT NULL,
            owned TINYINT(1) NOT NULL DEFAULT 0,
            is_rented TINYINT(1) NOT NULL DEFAULT 0,
            rent_end_date BIGINT DEFAULT NULL,
            rent_period INT DEFAULT NULL,
            marker_visible TINYINT(1) NOT NULL DEFAULT 1,
            marker_radius FLOAT NOT NULL DEFAULT 50.0,
            garage_coords JSON DEFAULT NULL,
            garage_size VARCHAR(20) DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    -- Keys table for property access management
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS haus_keys (
            id INT AUTO_INCREMENT PRIMARY KEY,
            property_id VARCHAR(50) NOT NULL,
            citizen_id VARCHAR(50) NOT NULL,
            granted_by VARCHAR(50) NOT NULL,
            granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_property_citizen (property_id, citizen_id)
        )
    ]])
    
    -- Garage vehicles table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS haus_garage_vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            property_id VARCHAR(50) NOT NULL,
            citizen_id VARCHAR(50) NOT NULL,
            plate VARCHAR(20) NOT NULL,
            vehicle_data JSON NOT NULL,
            stored TINYINT(1) NOT NULL DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_property_owner_plate (property_id, citizen_id, plate)
        )
    ]])
    
    -- Safe storage table - per-owner safe items
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS haus_safe_storage (
            id INT AUTO_INCREMENT PRIMARY KEY,
            property_id VARCHAR(50) NOT NULL,
            owner_identifier VARCHAR(50) NOT NULL,
            stash_name VARCHAR(100) NOT NULL UNIQUE,
            items LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_property_owner (property_id, owner_identifier),
            INDEX idx_stash_name (stash_name)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
    ]])
    
    -- Wait for table creation to complete
    Wait(300)
    
    -- Comprehensive migration: Check and add all missing columns
    print("^3[Haus-Manager]^7 Checking database schema and running migrations...")
    
    -- Define all columns that should exist with their specifications
    local requiredColumns = {
        {name = 'interior_type', definition = 'VARCHAR(50) NOT NULL DEFAULT \'ClassicApartment\'', afterColumn = 'coords'},
        {name = 'price', definition = 'INT NOT NULL DEFAULT 0', afterColumn = 'interior_type'},
        {name = 'owner_identifier', definition = 'VARCHAR(50) DEFAULT NULL', afterColumn = 'price'},
        {name = 'owned', definition = 'TINYINT(1) NOT NULL DEFAULT 0', afterColumn = 'owner_identifier'},
        {name = 'is_rented', definition = 'TINYINT(1) NOT NULL DEFAULT 0', afterColumn = 'owned'},
        {name = 'rent_end_date', definition = 'BIGINT DEFAULT NULL', afterColumn = 'is_rented'},
        {name = 'rent_period', definition = 'INT DEFAULT NULL', afterColumn = 'rent_end_date'},
        {name = 'marker_visible', definition = 'TINYINT(1) NOT NULL DEFAULT 1', afterColumn = 'rent_period'},
        {name = 'marker_radius', definition = 'FLOAT NOT NULL DEFAULT 50.0', afterColumn = 'marker_visible'},
        {name = 'garage_coords', definition = 'JSON DEFAULT NULL', afterColumn = 'marker_radius'},
        {name = 'garage_size', definition = 'VARCHAR(20) DEFAULT NULL', afterColumn = 'garage_coords'},
        {name = 'safe_coords', definition = 'TEXT DEFAULT NULL', afterColumn = 'garage_size'},
        {name = 'wardrobe_coords', definition = 'TEXT DEFAULT NULL', afterColumn = 'safe_coords'},
        {name = 'max_owners', definition = 'TINYINT NOT NULL DEFAULT 1', afterColumn = 'wardrobe_coords'},
        {name = 'current_owner_count', definition = 'TINYINT NOT NULL DEFAULT 0', afterColumn = 'max_owners'},
    }
    
    -- Check and add each column if missing
    for _, column in ipairs(requiredColumns) do
        local columnCheck = MySQL.query.await([[
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'haus_properties' 
            AND COLUMN_NAME = ?
        ]], {column.name})
        
        if not columnCheck or #columnCheck == 0 then
            print(string.format("^3[Haus-Manager]^7 Column '%s' not found, adding it...", column.name))
            local alterQuery = string.format([[
                ALTER TABLE haus_properties 
                ADD COLUMN %s %s 
                AFTER %s
            ]], column.name, column.definition, column.afterColumn)
            
            local success = MySQL.query.await(alterQuery)
            if success then
                print(string.format("^2[Haus-Manager]^7 Successfully added column '%s'", column.name))
            else
                print(string.format("^1[Haus-Manager]^7 Failed to add column '%s'", column.name))
            end
            Wait(50) -- Small delay between alterations
        end
    end
    
    -- Check haus_keys table for granted_by column
    local keysColumnCheck = MySQL.query.await([[
        SELECT COLUMN_NAME 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'haus_keys' 
        AND COLUMN_NAME = 'granted_by'
    ]])
    
    if not keysColumnCheck or #keysColumnCheck == 0 then
        print("^3[Haus-Manager]^7 Adding 'granted_by' column to haus_keys table...")
        MySQL.query.await([[
            ALTER TABLE haus_keys 
            ADD COLUMN granted_by VARCHAR(50) NOT NULL AFTER citizen_id
        ]])
        print("^2[Haus-Manager]^7 Successfully added 'granted_by' column to haus_keys")
    end
    
    -- Create property_owners table for multi-ownership support (without FK constraint for compatibility)
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS haus_property_owners (
            id INT AUTO_INCREMENT PRIMARY KEY,
            property_id VARCHAR(50) NOT NULL,
            citizen_id VARCHAR(50) NOT NULL,
            purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            purchase_price INT NOT NULL DEFAULT 0,
            UNIQUE KEY unique_property_owner (property_id, citizen_id)
        )
    ]])
    
    -- Migrate haus_garage_vehicles table schema
    -- Step 1: Drop ALL existing UNIQUE constraints first
    print("^3[Haus-Manager]^7 Migrating haus_garage_vehicles table schema...")
    local allConstraints = MySQL.query.await([[
        SELECT CONSTRAINT_NAME 
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'haus_garage_vehicles' 
        AND CONSTRAINT_TYPE = 'UNIQUE'
    ]])
    
    if allConstraints and #allConstraints > 0 then
        for _, constraint in ipairs(allConstraints) do
            print(string.format("^3[Haus-Manager]^7 Dropping UNIQUE constraint '%s' from haus_garage_vehicles...", constraint.CONSTRAINT_NAME))
            pcall(function()
                MySQL.query.await(string.format([[
                    ALTER TABLE haus_garage_vehicles 
                    DROP INDEX %s
                ]], constraint.CONSTRAINT_NAME))
                print(string.format("^2[Haus-Manager]^7 Successfully dropped constraint '%s'", constraint.CONSTRAINT_NAME))
            end)
            Wait(100)
        end
    end
    
    -- Step 2: Check and add required columns if missing
    local requiredGarageColumns = {
        {name = 'citizen_id', definition = 'VARCHAR(50) NOT NULL DEFAULT \'\'', afterColumn = 'property_id'},
        {name = 'plate', definition = 'VARCHAR(20) NOT NULL', afterColumn = 'citizen_id'},
        {name = 'vehicle_data', definition = 'JSON NOT NULL', afterColumn = 'plate'},
        {name = 'stored', definition = 'TINYINT(1) NOT NULL DEFAULT 1', afterColumn = 'vehicle_data'}
    }
    
    for _, column in ipairs(requiredGarageColumns) do
        local columnCheck = MySQL.query.await([[
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'haus_garage_vehicles' 
            AND COLUMN_NAME = ?
        ]], {column.name})
        
        if not columnCheck or #columnCheck == 0 then
            print(string.format("^3[Haus-Manager]^7 Adding '%s' column to haus_garage_vehicles table...", column.name))
            pcall(function()
                local alterQuery = string.format([[
                    ALTER TABLE haus_garage_vehicles 
                    ADD COLUMN %s %s AFTER %s
                ]], column.name, column.definition, column.afterColumn)
                MySQL.query.await(alterQuery)
                print(string.format("^2[Haus-Manager]^7 Successfully added '%s' column", column.name))
            end)
            Wait(100)
        end
    end
    
    -- Step 3: Clean up any rows with empty citizen_id (from old schema)
    print("^3[Haus-Manager]^7 Cleaning up invalid garage vehicle entries...")
    pcall(function()
        local deleted = MySQL.query.await([[
            DELETE FROM haus_garage_vehicles WHERE citizen_id = '' OR citizen_id IS NULL
        ]])
        if deleted then
            print("^2[Haus-Manager]^7 Cleaned up old garage vehicle entries")
        end
    end)
    Wait(100)
    
    -- Step 4: Add the correct UNIQUE constraint
    print("^3[Haus-Manager]^7 Adding new UNIQUE constraint to haus_garage_vehicles table...")
    pcall(function()
        MySQL.query.await([[
            ALTER TABLE haus_garage_vehicles 
            ADD UNIQUE KEY unique_property_owner_plate (property_id, citizen_id, plate)
        ]])
        print("^2[Haus-Manager]^7 Successfully added new UNIQUE constraint")
    end)
    
    print("^2[Haus-Manager]^7 Database schema migration completed")
    print("^2[Haus-Manager]^7 Database tables initialized successfully")
end)

-- Get all properties
function GetAllProperties()
    -- Use explicit column selection to avoid duplicate column issues
    -- Note: Not selecting 'id' column to support legacy schemas without auto-increment id
    local result = MySQL.query.await([[
        SELECT property_id, property_type, property_name, coords, interior_type,
               price, owner_identifier, owned, is_rented, rent_end_date, rent_period,
               marker_visible, marker_radius, garage_coords, garage_size,
               safe_coords, wardrobe_coords, max_owners, current_owner_count,
               created_at, updated_at
        FROM haus_properties
    ]])
    
    if Config.Debug and result then
        print(string.format("^3[Haus-Manager]^7 GetAllProperties: Retrieved %d properties", #result))
        for i, property in ipairs(result) do
            print(string.format("^3[Haus-Manager]^7   Property %d: '%s' (ID: %s) - marker_visible = %s (type: %s)", 
                i, property.property_name or "N/A", property.property_id or "N/A", 
                tostring(property.marker_visible), type(property.marker_visible)))
        end
    end
    
    return result or {}
end

-- Get property by ID
function GetPropertyById(propertyId)
    local result = MySQL.query.await([[
        SELECT property_id, property_type, property_name, coords, interior_type,
               price, owner_identifier, owned, is_rented, rent_end_date, rent_period,
               marker_visible, marker_radius, garage_coords, garage_size,
               max_owners, current_owner_count,
               created_at, updated_at
        FROM haus_properties 
        WHERE property_id = ?
    ]], {propertyId})
    return result and result[1] or nil
end

-- Get properties by owner
function GetPropertiesByOwner(identifier)
    local result = MySQL.query.await([[
        SELECT property_id, property_type, property_name, coords, interior_type,
               price, owner_identifier, owned, is_rented, rent_end_date, rent_period,
               marker_visible, marker_radius, garage_coords, garage_size,
               max_owners, current_owner_count,
               created_at, updated_at
        FROM haus_properties 
        WHERE owner_identifier = ?
    ]], {identifier})
    return result or {}
end

-- Get owner name from database (ESX: users table with identifier, QB-Core: players table with citizenid)
function GetOwnerName(ownerIdentifier)
    if not ownerIdentifier then 
        return "Unbekannt" 
    end
    
    -- For ESX: Query users table with identifier field
    if FrameworkServer.Type == 'esx' then
        local result = MySQL.query.await([[
            SELECT firstname, lastname 
            FROM users 
            WHERE identifier = ?
            LIMIT 1
        ]], {ownerIdentifier})
        
        if result and result[1] then
            return (result[1].firstname or "") .. " " .. (result[1].lastname or "")
        end
    end
    
    -- For QB-Core: Query players table with citizenid
    if FrameworkServer.Type == 'qb-core' then
        local result = MySQL.query.await([[
            SELECT charinfo 
            FROM players 
            WHERE citizenid = ?
            LIMIT 1
        ]], {ownerIdentifier})
        
        if result and result[1] and result[1].charinfo then
            local charinfo = json.decode(result[1].charinfo)
            if charinfo and charinfo.firstname and charinfo.lastname then
                return charinfo.firstname .. " " .. charinfo.lastname
            end
        end
    end
    
    return "Unbekannt"
end

-- Create new property
function CreateProperty(data)
    local propertyId = data.propertyId or ("property_" .. math.random(100000, 999999))
    
    -- Ensure markerVisible is properly converted to 1 or 0
    local markerVisible = 0
    if data.markerVisible == true or data.markerVisible == 1 or data.markerVisible == "true" or data.markerVisible == "1" then
        markerVisible = 1
    end
    
    -- Set max_owners (default 1, max 3)
    local maxOwners = tonumber(data.maxOwners) or 1
    if maxOwners < 1 then maxOwners = 1 end
    if maxOwners > 3 then maxOwners = 3 end
    
    -- Convert safe and wardrobe coords to JSON if provided
    local safeCoords = data.safeCoords and json.encode(data.safeCoords) or nil
    local wardrobeCoords = data.wardrobeCoords and json.encode(data.wardrobeCoords) or nil
    
    if Config.Debug then
        print(string.format("^3[Haus-Manager]^7 Creating property with markerVisible input: %s (type: %s), converted to: %d", 
            tostring(data.markerVisible), type(data.markerVisible), markerVisible))
        print(string.format("^3[Haus-Manager]^7 Max owners set to: %d", maxOwners))
        if safeCoords then print("^3[Haus-Manager]^7 Safe coords: " .. safeCoords) end
        if wardrobeCoords then print("^3[Haus-Manager]^7 Wardrobe coords: " .. wardrobeCoords) end
    end
    
    local result = MySQL.insert.await([[
        INSERT INTO haus_properties (
            property_id, property_type, property_name, coords, interior_type,
            price, marker_visible, marker_radius, garage_coords, garage_size,
            safe_coords, wardrobe_coords, max_owners, current_owner_count
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        propertyId,
        data.propertyType,
        data.propertyName,
        json.encode(data.coords),
        data.interiorType,
        data.price,
        markerVisible,
        data.markerRadius or 50.0,
        data.garageCoords and json.encode(data.garageCoords) or nil,
        data.garageSize,
        safeCoords,
        wardrobeCoords,
        maxOwners,
        0  -- current_owner_count starts at 0
    })
    
    if Config.Debug and result then
        print(string.format("^2[Haus-Manager]^7 INSERT completed for %s, marker_visible value used: %d", propertyId, markerVisible))
    end

    return result and propertyId or nil
end

-- Update property
function UpdateProperty(propertyId, data)
    local updates = {}
    local values = {}
    
    if data.propertyName then
        table.insert(updates, "property_name = ?")
        table.insert(values, data.propertyName)
    end
    
    if data.price then
        table.insert(updates, "price = ?")
        table.insert(values, data.price)
    end
    
    if data.coords then
        table.insert(updates, "coords = ?")
        table.insert(values, json.encode(data.coords))
    end
    
    if data.markerVisible ~= nil then
        table.insert(updates, "marker_visible = ?")
        -- Properly handle boolean/string/number conversion
        local markerVisible = 0
        if data.markerVisible == true or data.markerVisible == 1 or data.markerVisible == "true" or data.markerVisible == "1" then
            markerVisible = 1
        end
        table.insert(values, markerVisible)
    end
    
    if data.markerRadius then
        table.insert(updates, "marker_radius = ?")
        table.insert(values, data.markerRadius)
    end
    
    if data.garageCoords then
        table.insert(updates, "garage_coords = ?")
        table.insert(values, json.encode(data.garageCoords))
        if Config.Debug then
            print(string.format("^3[Haus-Manager]^7 Updating garage_coords: %s", json.encode(data.garageCoords)))
        end
    end
    
    if data.garageSize then
        table.insert(updates, "garage_size = ?")
        table.insert(values, data.garageSize)
        if Config.Debug then
            print(string.format("^3[Haus-Manager]^7 Updating garage_size: %s", data.garageSize))
        end
    end
    
    if data.safeCoords then
        table.insert(updates, "safe_coords = ?")
        table.insert(values, json.encode(data.safeCoords))
        if Config.Debug then
            print(string.format("^3[Haus-Manager]^7 Updating safe_coords: %s", json.encode(data.safeCoords)))
        end
    end
    
    if data.wardrobeCoords then
        table.insert(updates, "wardrobe_coords = ?")
        table.insert(values, json.encode(data.wardrobeCoords))
        if Config.Debug then
            print(string.format("^3[Haus-Manager]^7 Updating wardrobe_coords: %s", json.encode(data.wardrobeCoords)))
        end
    end
    
    if #updates == 0 then 
        if Config.Debug then
            print("^1[Haus-Manager]^7 UpdateProperty: No updates provided!")
        end
        return false 
    end
    
    table.insert(values, propertyId)
    local query = string.format("UPDATE haus_properties SET %s WHERE property_id = ?", table.concat(updates, ", "))
    
    if Config.Debug then
        print(string.format("^3[Haus-Manager]^7 Update query: %s", query))
        print(string.format("^3[Haus-Manager]^7 Update values: %s", json.encode(values)))
    end
    
    MySQL.query.await(query, values)
    return true
end

-- Delete property
function DeleteProperty(propertyId)
    MySQL.query.await('DELETE FROM haus_properties WHERE property_id = ?', {propertyId})
    return true
end

-- Set property owner
function SetPropertyOwner(propertyId, identifier, isRented, rentEndDate, rentPeriod)
    MySQL.query.await([[
        UPDATE haus_properties 
        SET owner_identifier = ?, owned = 1, is_rented = ?, rent_end_date = ?, rent_period = ?
        WHERE property_id = ?
    ]], {
        identifier,
        isRented and 1 or 0,
        rentEndDate,
        rentPeriod,
        propertyId
    })
    return true
end

-- Remove property owner
function RemovePropertyOwner(propertyId)
    MySQL.query.await([[
        UPDATE haus_properties 
        SET owner_identifier = NULL, owned = 0, is_rented = 0, rent_end_date = NULL, rent_period = NULL
        WHERE property_id = ?
    ]], {propertyId})
    
    -- Also remove all keys
    MySQL.query.await('DELETE FROM haus_keys WHERE property_id = ?', {propertyId})
    return true
end

-- Export functions
exports('GetAllProperties', GetAllProperties)
exports('GetPropertyById', GetPropertyById)
exports('GetPropertiesByOwner', GetPropertiesByOwner)
exports('GetOwnerName', GetOwnerName)
exports('CreateProperty', CreateProperty)
exports('UpdateProperty', UpdateProperty)
exports('DeleteProperty', DeleteProperty)
exports('SetPropertyOwner', SetPropertyOwner)
exports('RemovePropertyOwner', RemovePropertyOwner)
