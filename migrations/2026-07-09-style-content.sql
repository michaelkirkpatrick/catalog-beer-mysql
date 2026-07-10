-- ============================================================================
-- Style content: editorial prose + provenance for the style detail pages
-- ----------------------------------------------------------------------------
-- Adds `style_content` — one row per style holding the authored material from
-- the style library (description, appearance/aroma/flavor/mouthfeel, history,
-- public notes, commercial examples, source citations). Kept separate from
-- `style` so the hot vocabulary table (guided-style resolution, GET /style
-- list) never carries TEXT/JSON payload.
--
-- Content rows are NOT in this file. They are generated from the style
-- library's styles.json by `scripts/migration/seed.py` (which now emits
-- style_content alongside the vocabulary tables). The library's compile step
-- already excludes internal material (## Editorial Notes, OCB research text);
-- only consumer-facing fields ever reach styles.json, and therefore this table.
--
-- RUNBOOK (staging, then production):
--   1. Back up the database (mysqldump catalogbeer > backup.sql)
--   2. mysql catalogbeer < 2026-07-09-style-content.sql          (this file)
--   3. Regenerate the re-seed from the style library:
--        python3 scripts/migration/seed.py --upsert
--      and run it: mysql catalogbeer < seed_upsert.sql
--      (inserts the 196 style_content rows; idempotent)
--   4. Deploy the API (old API ignores the new table, so DB-first is safe)
--   5. Spot-check: GET /style/american-ipa should include description,
--      history, and sources.
-- ============================================================================

CREATE TABLE `style_content` (
  `style_id` varchar(64) NOT NULL,
  `description` text NOT NULL,
  `appearance` text DEFAULT NULL,
  `aroma` text DEFAULT NULL,
  `flavor` text DEFAULT NULL,
  `mouthfeel` text DEFAULT NULL,
  `history` text NOT NULL,
  `notes` text DEFAULT NULL,
  `commercial_examples` json DEFAULT NULL,
  `sources` json DEFAULT NULL,
  PRIMARY KEY (`style_id`),
  CONSTRAINT `fk_style_content_style` FOREIGN KEY (`style_id`) REFERENCES `style` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Verification after seeding (step 3):
--   SELECT COUNT(*) FROM style_content;                          -- expect 196
--   SELECT COUNT(*) FROM style s
--     LEFT JOIN style_content c ON c.style_id = s.id
--     WHERE c.style_id IS NULL;                                  -- expect 0
--   SELECT COUNT(*) FROM style_content
--     WHERE JSON_VALID(commercial_examples) = 0
--        OR JSON_VALID(sources) = 0;                             -- expect 0
