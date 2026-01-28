-- ════════════════════════════════════════════════════════════════════════════════
-- HAUS-MANAGER: Complete Database Installation Script
-- ════════════════════════════════════════════════════════════════════════════════
-- 
-- FiveM Property Management System - Complete Database Schema
-- 
-- WICHTIG / IMPORTANT:
-- Dieses Script löscht alle bestehenden Tabellen und erstellt sie neu!
-- Erstelle ein Backup vor der Ausführung!
-- 
-- This script drops all existing tables and recreates them!
-- Create a backup before running!
-- 
-- Ausführung / Execution:
-- 1. Backup erstellen! / Create backup!
-- 2. SQL ausführen / Execute SQL
-- 
-- ════════════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════════
-- STEP 1: Drop existing tables (clean slate)
-- ════════════════════════════════════════════════════════════════════════════════

-- Temporarily disable foreign key checks to allow dropping tables
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `haus_safe_storage`;
DROP TABLE IF EXISTS `haus_garage_vehicles`;
DROP TABLE IF EXISTS `haus_property_owners`;
DROP TABLE IF EXISTS `haus_keys`;
DROP TABLE IF EXISTS `haus_properties`;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- ════════════════════════════════════════════════════════════════════════════════
-- STEP 2: Create main properties table
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE `haus_properties` (
    `id` INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Auto-increment ID',
    `property_id` VARCHAR(50) UNIQUE NOT NULL COMMENT 'Unique property identifier',
    `property_type` VARCHAR(20) NOT NULL COMMENT 'Type: apartment, house, or office',
    `property_name` VARCHAR(100) NOT NULL COMMENT 'Display name of the property',
    `coords` JSON NOT NULL COMMENT 'x, y, z, heading coordinates as JSON',
    `interior_type` VARCHAR(50) NOT NULL DEFAULT 'ClassicApartment' COMMENT 'Interior shell type',
    `price` INT NOT NULL DEFAULT 0 COMMENT 'Purchase price',
    `owner_identifier` VARCHAR(50) DEFAULT NULL COMMENT 'citizenid of owner',
    `owned` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Is property owned (1) or available (0)',
    `is_rented` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Is property rented (1) or owned (0)',
    `rent_end_date` BIGINT DEFAULT NULL COMMENT 'Unix timestamp when rent expires',
    `rent_period` INT DEFAULT NULL COMMENT 'Rental period in days',
    `marker_visible` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Show marker on map (1=yes, 0=no)',
    `marker_radius` FLOAT NOT NULL DEFAULT 50.0 COMMENT 'Marker visibility radius',
    `garage_coords` JSON DEFAULT NULL COMMENT 'Garage coordinates as JSON (optional)',
    `garage_size` VARCHAR(20) DEFAULT NULL COMMENT 'Garage size: small, medium, large',
    `safe_coords` TEXT DEFAULT NULL COMMENT 'Safe coordinates as JSON (optional)',
    `wardrobe_coords` TEXT DEFAULT NULL COMMENT 'Wardrobe coordinates as JSON (optional)',
    `max_owners` TINYINT NOT NULL DEFAULT 1 COMMENT 'Maximum number of owners (1-3)',
    `current_owner_count` TINYINT NOT NULL DEFAULT 0 COMMENT 'Current number of owners',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation timestamp',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    
    -- Indexes for performance
    INDEX `idx_owner` (`owner_identifier`),
    INDEX `idx_property_type` (`property_type`),
    INDEX `idx_owned` (`owned`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Main property records with all configuration';

-- ════════════════════════════════════════════════════════════════════════════════
-- STEP 3: Create keys table (property access management)
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE `haus_keys` (
    `id` INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Auto-increment ID',
    `property_id` VARCHAR(50) NOT NULL COMMENT 'Property identifier',
    `citizen_id` VARCHAR(50) NOT NULL COMMENT 'citizenid of key holder',
    `granted_by` VARCHAR(50) NOT NULL COMMENT 'citizenid of person who granted the key',
    `key_type` ENUM('permanent', 'temporary') NOT NULL DEFAULT 'permanent' COMMENT 'Key type: permanent or temporary',
    `granted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When key was granted',
    `expires_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Expiration time for temporary keys',
    
    -- Constraints
    UNIQUE KEY `unique_property_citizen` (`property_id`, `citizen_id`),
    FOREIGN KEY (`property_id`) REFERENCES `haus_properties`(`property_id`) ON DELETE CASCADE,
    
    -- Indexes for performance
    INDEX `idx_citizen` (`citizen_id`),
    INDEX `idx_property` (`property_id`),
    INDEX `idx_expires` (`expires_at`),
    INDEX `idx_type_expires` (`key_type`, `expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Property key management with temporary key support';

-- ════════════════════════════════════════════════════════════════════════════════
-- STEP 4: Create property owners table (multi-ownership support)
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE `haus_property_owners` (
    `id` INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Auto-increment ID',
    `property_id` VARCHAR(50) NOT NULL COMMENT 'Property identifier',
    `citizen_id` VARCHAR(50) NOT NULL COMMENT 'citizenid of co-owner',
    `purchase_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When ownership was acquired',
    `purchase_price` INT NOT NULL DEFAULT 0 COMMENT 'Purchase price paid',
    
    -- Constraints
    UNIQUE KEY `unique_property_owner` (`property_id`, `citizen_id`),
    FOREIGN KEY (`property_id`) REFERENCES `haus_properties`(`property_id`) ON DELETE CASCADE,
    
    -- Indexes for performance
    INDEX `idx_property` (`property_id`),
    INDEX `idx_citizen` (`citizen_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Multi-ownership support for properties';

-- ════════════════════════════════════════════════════════════════════════════════
-- STEP 5: Create garage vehicles table
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE `haus_garage_vehicles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Auto-increment ID',
    `property_id` VARCHAR(50) NOT NULL COMMENT 'Property identifier',
    `citizen_id` VARCHAR(50) NOT NULL COMMENT 'citizenid of vehicle owner',
    `plate` VARCHAR(20) NOT NULL COMMENT 'Vehicle license plate',
    `vehicle_data` JSON NOT NULL COMMENT 'Full vehicle data (model, mods, etc.)',
    `stored` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Is vehicle stored (1) or out (0)',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When vehicle was added',
    
    -- Constraints
    UNIQUE KEY `unique_property_owner_plate` (`property_id`, `citizen_id`, `plate`),
    FOREIGN KEY (`property_id`) REFERENCES `haus_properties`(`property_id`) ON DELETE CASCADE,
    
    -- Indexes for performance
    INDEX `idx_property` (`property_id`),
    INDEX `idx_plate` (`plate`),
    INDEX `idx_citizen` (`citizen_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Vehicle storage in property garages';

-- ════════════════════════════════════════════════════════════════════════════════
-- STEP 6: Create safe storage table
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE `haus_safe_storage` (
    `id` INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Auto-increment ID',
    `property_id` VARCHAR(50) NOT NULL COMMENT 'Property identifier',
    `owner_identifier` VARCHAR(50) NOT NULL COMMENT 'citizenid of owner',
    `stash_name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'Unique stash identifier',
    `items` LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Stored items as JSON',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When storage was created',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    
    -- Indexes for performance
    INDEX `idx_property_owner` (`property_id`, `owner_identifier`),
    INDEX `idx_stash_name` (`stash_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Safe storage items per property owner';

-- ════════════════════════════════════════════════════════════════════════════════
-- INSTALLATION COMPLETE!
-- ════════════════════════════════════════════════════════════════════════════════
-- 
-- Die folgenden Tabellen wurden erstellt:
-- The following tables have been created:
-- 
-- ✓ haus_properties - Main property records
-- ✓ haus_keys - Property key management (permanent & temporary)
-- ✓ haus_property_owners - Multi-ownership support
-- ✓ haus_garage_vehicles - Vehicle storage
-- ✓ haus_safe_storage - Safe/stash storage
-- 
-- Alle Tabellen sind leer und bereit für die Nutzung.
-- All tables are empty and ready for use.
-- 
-- Das Haus-Manager Script wird automatisch Eigenschaften erstellen
-- wenn Admins diese über das /hausadmin UI hinzufügen.
-- 
-- The Haus-Manager script will automatically create properties
-- when admins add them via the /hausadmin UI.
-- 
-- ════════════════════════════════════════════════════════════════════════════════
