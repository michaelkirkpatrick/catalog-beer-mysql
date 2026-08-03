-- ============================================================================
-- ZIP codes become fixed-width strings
-- ----------------------------------------------------------------------------
-- US_addresses.zip5 and .zip4 are `int`. ZIP codes are not numbers — they are
-- fixed-width identifiers with significant leading zeros (00501–09999 covers
-- New England, New Jersey, Puerto Rico and the Virgin Islands) and they are
-- never arithmetic operands. Stored as int, the leading zero is dropped.
--
-- 14 of 486 locations are affected today: every MA / NH / RI / CT / NJ address
-- in the catalog. Westfield MA 01085 reads back from the API as 1085.
--
-- This is not merely cosmetic. The API *accepts* a string on write but
-- *returns* an integer, so any read-modify-write round-trip is lossy for those
-- 14 rows — re-submitting the 4-digit value fails validation with
-- valid_state.zip5 = "invalid". That is a live bug: it broke the 2026-08-03
-- re-geocoding pass, which had to zero-pad by hand to get Bright Ideas Brewing
-- (Westfield MA) to geocode at all.
--
-- Nothing is unrecoverable, because the width is always exactly 5 — LPAD
-- restores every value. That is why this migration can backfill rather than
-- needing the true ZIPs looked up again.
--
-- char(5) rather than varchar(5): the width is invariant, so char is a flat
-- 5 bytes with no length prefix and it documents the invariant. This matches
-- how `subdivisions.sub_code` (varchar(5)) already treats a code as text.
--
-- telephone stays `bigint` on purpose: NANP area codes never begin with 0 or 1,
-- so a US phone number has no leading zero to lose.
--
-- RUNBOOK (staging, then production):
--   1. Back up the database (mysqldump catalogbeer > backup.sql)
--   2. mysql catalogbeer < 2026-08-03-zip-code-char.sql   (this file)
--   3. Run the verification queries at the bottom — all three must return 0
--      before continuing.
--   4. Deploy the API. It must stop casting zip5/zip4 to int on output, so the
--      JSON becomes "zip5": "01085" instead of 1085. Grep the API for
--      intval/(int)/absint around zip and for `zip5` in the address serializer.
--   5. Update the docs that promise an integer:
--        catalog-beer skill -> references/locations.md, "The US address object"
--        currently reads `zip5` (**integer**) / `zip4` (integer, nullable).
--
-- DB-FIRST IS REQUIRED. Under strict mode the reverse order is what breaks: a
-- new API writing "01085" into an int column silently truncates it to 1085.
--
-- CONSUMER-VISIBLE CHANGE: zip5/zip4 change JSON type from number to string.
-- Anything doing arithmetic or a === comparison on them will need updating —
-- though nothing should be doing arithmetic on a ZIP code.
--
-- IF YOU NEED TO RE-RUN THIS FILE: steps 1 and 2 are idempotent, step 3 is not.
-- A second run fails with "Duplicate check constraint name". MySQL has no
-- ADD CONSTRAINT IF NOT EXISTS and no DROP CHECK IF EXISTS, so drop them by
-- hand first:
--   ALTER TABLE `US_addresses` DROP CHECK `chk_zip5_format`;
--   ALTER TABLE `US_addresses` DROP CHECK `chk_zip4_format`;
--
-- NOTE ON THE ALTER: an int -> char type change rebuilds the table (COPY
-- algorithm) and re-validates the foreign keys as it goes. On ~500 rows that is
-- instant, but it does mean an orphaned US_addresses row would abort step 1
-- with a fk_locationID error rather than a type error. Nothing changes if it
-- aborts there.
--
-- TESTED 2026-08-03 against MySQL 9.6 on a scratch database loaded from the
-- pre-change schema and seeded with all 14 real leading-zero addresses plus
-- three controls: applied cleanly, all three verification queries returned 0,
-- the 14 padded (1085 -> 01085), the 3 controls untouched, both CHECK
-- constraints rejected a 4-digit / non-numeric / short-zip4 write, and the
-- resulting table definition was byte-identical to catalog-beer-schema.sql.
-- ============================================================================

-- 0. PRE-FLIGHT. Run these two first; both must return 0. A value wider than
--    the target char() would be truncated by step 1 rather than rejected, and
--    a negative one would not survive the CHECK in step 3. Neither should
--    exist, but a silent truncation here is unrecoverable without the backup.
--      SELECT COUNT(*) FROM US_addresses WHERE zip5 > 99999 OR zip5 < 0;
--      SELECT COUNT(*) FROM US_addresses WHERE zip4 IS NOT NULL AND (zip4 > 9999 OR zip4 < 0);

-- 1. Widen the type. int -> char converts 1085 to '1085' WITHOUT padding,
--    so the backfill in step 2 is not optional.
ALTER TABLE `US_addresses`
  MODIFY `zip5` char(5) NOT NULL,
  MODIFY `zip4` char(4) DEFAULT NULL;

-- 2. Restore the leading zeros the int column had been dropping.
UPDATE `US_addresses`
   SET `zip5` = LPAD(`zip5`, 5, '0')
 WHERE CHAR_LENGTH(`zip5`) < 5;

UPDATE `US_addresses`
   SET `zip4` = LPAD(`zip4`, 4, '0')
 WHERE `zip4` IS NOT NULL
   AND CHAR_LENGTH(`zip4`) < 4;

-- 3. Stop it recurring. Added AFTER the backfill — these constraints would
--    reject the un-padded rows if added first.
ALTER TABLE `US_addresses`
  ADD CONSTRAINT `chk_zip5_format` CHECK (`zip5` REGEXP '^[0-9]{5}$'),
  ADD CONSTRAINT `chk_zip4_format` CHECK (`zip4` IS NULL OR `zip4` REGEXP '^[0-9]{4}$');

-- Verification (all three must return 0):
--   SELECT COUNT(*) FROM US_addresses WHERE CHAR_LENGTH(zip5) <> 5;
--   SELECT COUNT(*) FROM US_addresses WHERE zip4 IS NOT NULL AND CHAR_LENGTH(zip4) <> 4;
--   SELECT COUNT(*) FROM US_addresses WHERE zip5 NOT REGEXP '^[0-9]{5}$';
--
-- Expect ~14 rows to have changed. To see them before running:
--   SELECT locationID, address2, city, sub_code, zip5
--     FROM US_addresses WHERE zip5 < 10000 ORDER BY sub_code;
--
-- Spot-check afterwards — Bright Ideas Brewing, Westfield MA, should read
-- '01085' and GET /location/95c14858-305b-4ac8-a7cc-7545bad8b1d7 should return
-- "zip5": "01085".
