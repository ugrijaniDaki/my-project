-- Aura Database Migration Script
-- This adds the new columns and tables needed for activity tracking

-- Add new columns to Users table if they don't exist
DO $$
BEGIN
    -- Add LastLoginAt column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'Users' AND column_name = 'LastLoginAt') THEN
        ALTER TABLE "Users" ADD COLUMN "LastLoginAt" TIMESTAMP;
        RAISE NOTICE 'Added LastLoginAt column to Users';
    END IF;

    -- Add LoginCount column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'Users' AND column_name = 'LoginCount') THEN
        ALTER TABLE "Users" ADD COLUMN "LoginCount" INTEGER NOT NULL DEFAULT 0;
        RAISE NOTICE 'Added LoginCount column to Users';
    END IF;
END $$;

-- Create ActivityLogs table if it doesn't exist
CREATE TABLE IF NOT EXISTS "ActivityLogs" (
    "Id" SERIAL PRIMARY KEY,
    "Type" INTEGER NOT NULL DEFAULT 0,
    "UserId" INTEGER,
    "UserName" VARCHAR(255) NOT NULL DEFAULT '',
    "UserEmail" VARCHAR(255) NOT NULL DEFAULT '',
    "Description" TEXT NOT NULL DEFAULT '',
    "RelatedId" INTEGER,
    "CreatedAt" TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT "FK_ActivityLogs_Users_UserId" FOREIGN KEY ("UserId")
        REFERENCES "Users"("Id") ON DELETE SET NULL
);

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS "IX_ActivityLogs_Type" ON "ActivityLogs" ("Type");
CREATE INDEX IF NOT EXISTS "IX_ActivityLogs_CreatedAt" ON "ActivityLogs" ("CreatedAt");
CREATE INDEX IF NOT EXISTS "IX_ActivityLogs_UserId" ON "ActivityLogs" ("UserId");

-- Fix any NULL values in existing tables
UPDATE "Users" SET "Name" = 'Unknown' WHERE "Name" IS NULL OR "Name" = '';
UPDATE "Users" SET "Email" = 'unknown@example.com' WHERE "Email" IS NULL OR "Email" = '';
UPDATE "Users" SET "Phone" = '' WHERE "Phone" IS NULL;
UPDATE "Users" SET "CreatedAt" = NOW() WHERE "CreatedAt" IS NULL;
UPDATE "Users" SET "LoginCount" = 0 WHERE "LoginCount" IS NULL;

UPDATE "Reservations" SET "Time" = '12:00' WHERE "Time" IS NULL OR "Time" = '';
UPDATE "Reservations" SET "Guests" = 1 WHERE "Guests" IS NULL OR "Guests" < 1;
UPDATE "Reservations" SET "Status" = 0 WHERE "Status" IS NULL;
UPDATE "Reservations" SET "CreatedAt" = NOW() WHERE "CreatedAt" IS NULL;

UPDATE "MenuItems" SET "Name" = 'Unknown Item' WHERE "Name" IS NULL OR "Name" = '';
UPDATE "MenuItems" SET "Price" = 0 WHERE "Price" IS NULL;
UPDATE "MenuItems" SET "Category" = 0 WHERE "Category" IS NULL;
UPDATE "MenuItems" SET "IsAvailable" = true WHERE "IsAvailable" IS NULL;
UPDATE "MenuItems" SET "IsVegetarian" = false WHERE "IsVegetarian" IS NULL;
UPDATE "MenuItems" SET "IsVegan" = false WHERE "IsVegan" IS NULL;
UPDATE "MenuItems" SET "IsGlutenFree" = false WHERE "IsGlutenFree" IS NULL;
UPDATE "MenuItems" SET "SortOrder" = 0 WHERE "SortOrder" IS NULL;
UPDATE "MenuItems" SET "CreatedAt" = NOW() WHERE "CreatedAt" IS NULL;

UPDATE "DaySchedules" SET "IsOpen" = true WHERE "IsOpen" IS NULL;
UPDATE "DaySchedules" SET "OpenTime" = '12:00' WHERE "OpenTime" IS NULL;
UPDATE "DaySchedules" SET "CloseTime" = '22:00' WHERE "CloseTime" IS NULL;

UPDATE "TimeSlots" SET "Time" = '12:00' WHERE "Time" IS NULL OR "Time" = '';
UPDATE "TimeSlots" SET "MaxReservations" = 1 WHERE "MaxReservations" IS NULL;
UPDATE "TimeSlots" SET "IsEnabled" = true WHERE "IsEnabled" IS NULL;

-- Show current state
SELECT 'Schema migration complete!' as status;

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
SELECT 'ActivityLogs', COUNT(*) FROM "ActivityLogs";
