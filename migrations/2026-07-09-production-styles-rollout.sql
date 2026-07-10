-- ============================================================================
-- Production rollout: Guided Style Field (style vocabulary + beer columns)
-- ----------------------------------------------------------------------------
-- Production as of the 2026-07-09 export has NO style tables and no
-- classification columns on `beer`. (It already has ft_beer_search on
-- name/style/description and never had style_label, so the style_label
-- migration — 2026-07-09-drop-style-label.sql — does NOT apply to production.)
--
-- The vocabulary seed (style-vocabulary-seed-v2.3.0.sql) is deliberately NOT
-- committed to this public repo. It is a mysqldump of the 7 style tables from
-- the staging database at vocabulary v2.3.0 (canonical schema — staging was
-- normalized 2026-07-09). Regenerate anytime with:
--   mysqldump --single-transaction --no-tablespaces catalogbeer \
--     style_class style_parent style style_alias parent_alias class_alias style_meta
--
-- RUNBOOK (order matters):
--   1. Back up the database (mysqldump catalogbeer > backup.sql)
--   2. mysql catalogbeer < style-vocabulary-seed-v2.3.0.sql
--   3. mysql catalogbeer < 2026-07-09-production-styles-rollout.sql  (this file)
--   4. mysql catalogbeer < 2026-07-09-style-backfill.sql   (classifies all
--      existing beers; review its verification output)
--   5. Deploy the API   (old API ignores the new columns, so DB-first is safe)
--   6. Deploy the frontend
--   7. Re-run the documentation curation PATCH that only exists on staging:
--      Sculpin IPA description (beer 6a7119c6-92a2-40d2-b87a-2e4529c8577a)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- STEP 0 — Pre-flight: the vocabulary must be loaded and internally unique
-- ---------------------------------------------------------------------------

-- Expect: 196 styles / 26 families / 2 classes / version 2.3.0
SELECT (SELECT COUNT(*) FROM style)        AS styles,
       (SELECT COUNT(*) FROM style_parent) AS families,
       (SELECT COUNT(*) FROM style_class)  AS classes,
       (SELECT version FROM style_meta)    AS version;

-- Expect: zero rows (duplicate canonical names would make the backfill
-- nondeterministic — stop and fix the vocabulary if any appear)
SELECT canonical_name, COUNT(*) AS n
FROM style GROUP BY canonical_name HAVING n > 1;

-- ---------------------------------------------------------------------------
-- STEP 1 — Add the classification columns to `beer`
-- ---------------------------------------------------------------------------

ALTER TABLE beer
  ADD COLUMN style_id varchar(64) DEFAULT NULL AFTER style,
  ADD COLUMN parent varchar(64) DEFAULT NULL AFTER style_id,
  ADD COLUMN class varchar(64) DEFAULT NULL AFTER parent,
  ADD COLUMN beverage_type enum('beer','cider','perry','mead') NOT NULL DEFAULT 'beer' AFTER class,
  ADD COLUMN style_confidence varchar(16) DEFAULT NULL AFTER beverage_type,
  ADD KEY idx_beverage_type (beverage_type),
  ADD KEY idx_parent (parent),
  ADD KEY idx_class (class),
  ADD KEY fk_beer_style (style_id),
  ADD CONSTRAINT fk_beer_class FOREIGN KEY (class) REFERENCES style_class (slug),
  ADD CONSTRAINT fk_beer_parent FOREIGN KEY (parent) REFERENCES style_parent (slug),
  ADD CONSTRAINT fk_beer_style FOREIGN KEY (style_id) REFERENCES style (id);

-- Next: run 2026-07-09-style-backfill.sql to classify all existing beers.
