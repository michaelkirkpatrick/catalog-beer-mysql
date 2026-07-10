-- ============================================================================
-- Drop the unused `style.sort_order` column
-- ----------------------------------------------------------------------------
-- `style.sort_order` was seeded with each style's index in the style library's
-- styles.json build (itself ordered by parent, then id). Nothing ever read it:
-- GET /style returns styles ORDER BY canonical_name, and the frontend sorts
-- alphabetically within a family. The two sort_order columns that DO drive
-- display order — style_parent.sort_order (curated family order) and
-- style_class.sort_order (Ale before Lager) — are untouched.
--
-- Deploy anytime; no code reads the column, so ordering is deploy-independent.
-- Run before or after the API/frontend deploy — it doesn't matter.
--
-- RUNBOOK:
--   1. Back up the database (mysqldump catalogbeer > backup.sql)
--   2. mysql catalogbeer < 2026-07-09-drop-style-sort-order.sql   (this file)
--   3. Regenerating the seed (seed.py) no longer emits the column, so a later
--      re-seed stays in step.
-- ============================================================================

ALTER TABLE `style` DROP COLUMN `sort_order`;

-- Verification:
--   SHOW COLUMNS FROM `style` LIKE 'sort_order';        -- expect 0 rows
--   SHOW COLUMNS FROM `style_parent` LIKE 'sort_order'; -- expect 1 row (kept)
--   SHOW COLUMNS FROM `style_class`  LIKE 'sort_order'; -- expect 1 row (kept)
