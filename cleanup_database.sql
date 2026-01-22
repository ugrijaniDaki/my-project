-- Aura Database Cleanup Script
-- Run this script to clean up NULL values and reset the database

-- Option 1: Complete Reset (Recommended for fresh start)
-- This will drop all tables and let EF Core recreate them with seed data
-- Uncomment the following lines if you want a complete reset:

-- DROP TABLE IF EXISTS "ActivityLogs" CASCADE;
-- DROP TABLE IF EXISTS "TimeSlots" CASCADE;
-- DROP TABLE IF EXISTS "DateOverrides" CASCADE;
-- DROP TABLE IF EXISTS "DaySchedules" CASCADE;
-- DROP TABLE IF EXISTS "Reservations" CASCADE;
-- DROP TABLE IF EXISTS "MenuItems" CASCADE;
-- DROP TABLE IF EXISTS "Users" CASCADE;

-- Option 2: Fix existing NULL values (Keep existing data)

-- Fix Users table
UPDATE "Users" SET "Name" = 'Unknown' WHERE "Name" IS NULL OR "Name" = '';
UPDATE "Users" SET "Email" = 'unknown@example.com' WHERE "Email" IS NULL OR "Email" = '';
UPDATE "Users" SET "Phone" = '' WHERE "Phone" IS NULL;
UPDATE "Users" SET "PasswordHash" = '' WHERE "PasswordHash" IS NULL;
UPDATE "Users" SET "CreatedAt" = NOW() WHERE "CreatedAt" IS NULL;
UPDATE "Users" SET "LoginCount" = 0 WHERE "LoginCount" IS NULL;

-- Fix Reservations table
UPDATE "Reservations" SET "Time" = '12:00' WHERE "Time" IS NULL OR "Time" = '';
UPDATE "Reservations" SET "Guests" = 1 WHERE "Guests" IS NULL OR "Guests" = 0;
UPDATE "Reservations" SET "Status" = 0 WHERE "Status" IS NULL;
UPDATE "Reservations" SET "CreatedAt" = NOW() WHERE "CreatedAt" IS NULL;

-- Fix MenuItems table
UPDATE "MenuItems" SET "Name" = 'Unknown Item' WHERE "Name" IS NULL OR "Name" = '';
UPDATE "MenuItems" SET "Price" = 0 WHERE "Price" IS NULL;
UPDATE "MenuItems" SET "Category" = 0 WHERE "Category" IS NULL;
UPDATE "MenuItems" SET "IsAvailable" = true WHERE "IsAvailable" IS NULL;
UPDATE "MenuItems" SET "IsVegetarian" = false WHERE "IsVegetarian" IS NULL;
UPDATE "MenuItems" SET "IsVegan" = false WHERE "IsVegan" IS NULL;
UPDATE "MenuItems" SET "IsGlutenFree" = false WHERE "IsGlutenFree" IS NULL;
UPDATE "MenuItems" SET "SortOrder" = 0 WHERE "SortOrder" IS NULL;
UPDATE "MenuItems" SET "CreatedAt" = NOW() WHERE "CreatedAt" IS NULL;

-- Fix DaySchedules table
UPDATE "DaySchedules" SET "IsOpen" = true WHERE "IsOpen" IS NULL;
UPDATE "DaySchedules" SET "OpenTime" = '12:00' WHERE "OpenTime" IS NULL;
UPDATE "DaySchedules" SET "CloseTime" = '22:00' WHERE "CloseTime" IS NULL;

-- Fix TimeSlots table
UPDATE "TimeSlots" SET "Time" = '12:00' WHERE "Time" IS NULL OR "Time" = '';
UPDATE "TimeSlots" SET "MaxReservations" = 1 WHERE "MaxReservations" IS NULL;
UPDATE "TimeSlots" SET "IsEnabled" = true WHERE "IsEnabled" IS NULL;

-- Fix DateOverrides table
UPDATE "DateOverrides" SET "IsClosed" = false WHERE "IsClosed" IS NULL;
UPDATE "DateOverrides" SET "CreatedAt" = NOW() WHERE "CreatedAt" IS NULL;

-- Add ActivityLogs table if it doesn't exist
CREATE TABLE IF NOT EXISTS "ActivityLogs" (
    "Id" SERIAL PRIMARY KEY,
    "Type" INTEGER NOT NULL DEFAULT 0,
    "UserId" INTEGER,
    "UserName" VARCHAR(255) NOT NULL DEFAULT '',
    "UserEmail" VARCHAR(255) NOT NULL DEFAULT '',
    "Description" TEXT NOT NULL DEFAULT '',
    "RelatedId" INTEGER,
    "CreatedAt" TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_user FOREIGN KEY ("UserId") REFERENCES "Users"("Id") ON DELETE SET NULL
);

-- Add indexes for ActivityLogs
CREATE INDEX IF NOT EXISTS "IX_ActivityLogs_Type" ON "ActivityLogs" ("Type");
CREATE INDEX IF NOT EXISTS "IX_ActivityLogs_CreatedAt" ON "ActivityLogs" ("CreatedAt");

-- Add new columns to Users if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Users' AND column_name = 'LastLoginAt') THEN
        ALTER TABLE "Users" ADD COLUMN "LastLoginAt" TIMESTAMP;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Users' AND column_name = 'LoginCount') THEN
        ALTER TABLE "Users" ADD COLUMN "LoginCount" INTEGER NOT NULL DEFAULT 0;
    END IF;
END $$;

-- Show summary
SELECT 'Users' as table_name, COUNT(*) as count FROM "Users"
UNION ALL
SELECT 'Reservations', COUNT(*) FROM "Reservations"
UNION ALL
SELECT 'MenuItems', COUNT(*) FROM "MenuItems"
UNION ALL
SELECT 'DaySchedules', COUNT(*) FROM "DaySchedules"
UNION ALL
SELECT 'TimeSlots', COUNT(*) FROM "TimeSlots"
UNION ALL
SELECT 'DateOverrides', COUNT(*) FROM "DateOverrides"
UNION ALL
SELECT 'ActivityLogs', COUNT(*) FROM "ActivityLogs";
