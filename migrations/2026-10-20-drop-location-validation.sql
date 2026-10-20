-- Repair for a database that ran 2026-10-13-international-addresses.sql and
-- 2026-10-17-location-address-merge.sql BEFORE commit 0398e48 (17 Oct 2026),
-- which edited both files in place to drop the `validation` column. That is
-- STAGING ONLY. A database running the two files as they now stand never
-- creates the column, so this file is NOT part of the production sequence --
-- on production the first ALTER fails (no such column), which is harmless,
-- but don't run it there.
--
-- Symptom without it: every location write that carries an address fails
-- with a database error (500, error 3), because the API no longer writes
-- `validation` and the old chk_location_address requires it whenever line1
-- is set.
--
-- Check first -- the column is present only on a database that needs this:
--   SELECT COLUMN_NAME FROM information_schema.COLUMNS
--   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'location' AND COLUMN_NAME = 'validation';
--
-- Run on staging 2026-10-20.

ALTER TABLE `location` DROP CHECK `chk_location_address`;
ALTER TABLE `location` ADD CONSTRAINT `chk_location_address` CHECK ((`line1` IS NULL) = (`locality` IS NULL));
ALTER TABLE `location` DROP COLUMN `validation`;
