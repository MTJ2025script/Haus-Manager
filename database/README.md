# Database Installation

This folder contains the complete database schema for the Haus-Manager FiveM Property Management System.

## 📁 Files

- **install.sql** - Complete database installation script (USE THIS!)
- **README.md** - This installation guide

## 🚀 Quick Installation

### Option 1: Command Line (Recommended)

```bash
mysql -u your_username -p your_database_name < install.sql
```

### Option 2: phpMyAdmin

1. Log in to phpMyAdmin
2. Select your FiveM database
3. Click on the "SQL" tab
4. Copy and paste the content of `install.sql`
5. Click "Go"

### Option 3: HeidiSQL / MySQL Workbench

1. Connect to your database
2. Open the `install.sql` file
3. Execute the script

## ⚠️ Important Notes

### Before Installation

**WICHTIG / IMPORTANT: Erstelle ein Backup vor der Installation!**  
**Create a backup before installation!**

The `install.sql` script will:
- ✅ Drop all existing Haus-Manager tables
- ✅ Create fresh tables with the latest schema
- ✅ Add all required indexes and constraints
- ⚠️ **DELETE ALL EXISTING DATA** in Haus-Manager tables

### What Gets Created

The installation script creates the following tables:

#### 1. `haus_properties`
Main property records with:
- Property ID, type, name
- Coordinates and interior type
- Price and ownership information
- Rental information
- Garage configuration (optional)
- Safe coordinates (optional)
- Wardrobe coordinates (optional)
- Multi-ownership support
- Marker settings

#### 2. `haus_keys`
Property key management with:
- Key holders (citizenid)
- Who granted the key
- **Key type** (permanent/temporary)
- **Expiration timestamp** for temporary keys
- Automatic cleanup on property deletion

#### 3. `haus_property_owners`
Multi-ownership support:
- Property ID
- Co-owner citizenid
- Purchase date and price
- Up to 3 owners per property

#### 4. `haus_garage_vehicles`
Vehicle storage in property garages:
- Property association
- Vehicle owner (citizenid)
- Vehicle plate and data
- Storage status (stored/out)

#### 5. `haus_safe_storage`
Safe/stash storage:
- Per-owner safe storage
- Unique stash names
- JSON item storage
- Compatible with QB-Inventory and OX-Inventory

## 🔄 Automatic Migration

The Haus-Manager resource automatically checks and adds missing columns on startup. However, for a fresh installation or major updates, it's recommended to run the `install.sql` script manually.

## 🛠️ Troubleshooting

### Error: "Table already exists"

This is normal. The script uses `DROP TABLE IF EXISTS` to ensure a clean installation.

### Error: "Foreign key constraint fails"

Make sure you're running the complete `install.sql` script in order. The script is designed to create tables in the correct order to satisfy all foreign key constraints.

### Error: "Access denied"

Make sure your MySQL user has the following permissions:
- CREATE
- DROP
- INSERT
- UPDATE
- DELETE
- INDEX
- REFERENCES

### Safe not opening / Inventory errors

After installation:
1. Restart the Haus-Manager resource: `ensure Haus-Manager`
2. Check the server console for any database errors
3. Make sure either `qb-inventory` or `ox_inventory` is running
4. Check `Config.Debug = true` in config file for detailed logs

### Key management not working

The new schema includes temporary key support. Old keys from previous installations will need to be re-granted through the key management UI.

## 📊 Database Schema Version

This schema is compatible with:
- FiveM QB-Core framework
- MySQL 5.7+ / MariaDB 10.2+
- JSON column support required
- InnoDB engine for foreign key support
- utf8mb4 character set for full Unicode support

## 🆕 New Features in Latest Schema

- ✨ **Temporary keys** with expiration support
- ✨ **Multi-ownership** support (up to 3 owners)
- ✨ **Safe coordinates** for in-property safes
- ✨ **Wardrobe coordinates** for clothing storage
- ✨ **Improved indexes** for better performance
- ✨ **Foreign key constraints** for data integrity

## 📝 After Installation

1. Start/restart the Haus-Manager resource
2. Use `/hausadmin` command to access the admin panel
3. Create your first property
4. Properties will appear as markers on the map
5. Players can purchase/rent properties

## 🔗 Additional Documentation

For more information, see:
- `../INSTALLATION.md` - Complete installation guide
- `../DOKUMENTATION.md` - German documentation
- `../API-REFERENCE.md` - API reference for developers

## 💡 Support

If you encounter any issues:
1. Check server console for errors (set `Config.Debug = true`)
2. Verify database permissions
3. Ensure all required columns exist
4. Check the GitHub repository for updates

