-- Aura Database Complete Reset Script
-- WARNING: This will DELETE ALL DATA and recreate the database schema
-- Run this for a completely fresh start

-- Drop all tables in correct order (respecting foreign keys)
DROP TABLE IF EXISTS "ActivityLogs" CASCADE;
DROP TABLE IF EXISTS "TimeSlots" CASCADE;
DROP TABLE IF EXISTS "DateOverrides" CASCADE;
DROP TABLE IF EXISTS "DaySchedules" CASCADE;
DROP TABLE IF EXISTS "Reservations" CASCADE;
DROP TABLE IF EXISTS "MenuItems" CASCADE;
DROP TABLE IF EXISTS "Users" CASCADE;

-- After running this script, restart your backend application
-- EF Core will recreate all tables and seed the data automatically

SELECT 'Database reset complete. Restart your backend application to recreate tables and seed data.' as message;
