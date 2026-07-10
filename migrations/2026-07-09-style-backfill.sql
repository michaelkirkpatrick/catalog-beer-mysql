-- ============================================================================
-- Style backfill — derive each beer's classification from its label
-- ----------------------------------------------------------------------------
-- Re-runnable. Clears and re-derives the classification for every beer whose
-- classification is machine-derived (style_confidence IS NULL), leaving rows a
-- person classified through the Guided Style Field untouched.
--
-- Run on:
--   * PRODUCTION — first fill, after 2026-07-09-production-styles-rollout.sql
--   * STAGING    — re-run to correct 481 rows filed under the pre-v2 rules:
--                  umbrella labels ("IPA", "Strong Ale", "Pale Ale") were
--                  snapped to a specific style instead of the family tier,
--                  and "Apple Wine" predates the applewine style (BJCP 2025).
--
-- The stages mirror Beer::resolveStyle() exactly: exact style name -> class
-- alias -> family alias -> style alias. Matching is case-insensitive
-- (utf8mb4_0900_ai_ci on both sides). style_confidence stays NULL: derived
-- classifications carry no user-asserted provenance. lastModified untouched.
-- ============================================================================

-- STEP 1 — Clear machine-derived classifications
UPDATE beer
SET style_id = NULL, parent = NULL, class = NULL, beverage_type = 'beer'
WHERE style_confidence IS NULL;

-- STEP 2a — Exact canonical style name
UPDATE beer b
JOIN style s ON s.canonical_name = b.style
JOIN style_parent p ON p.slug = s.parent
SET b.style_id = s.id,
    b.parent = s.parent,
    b.class = p.class,
    b.beverage_type = s.beverage_type
WHERE b.style_confidence IS NULL
  AND b.style_id IS NULL AND b.parent IS NULL AND b.class IS NULL;

-- STEP 2b — Class alias ("Ale", "Lager", ...)
UPDATE beer b
JOIN class_alias ca ON ca.alias = b.style
JOIN style_class c ON c.slug = ca.class
SET b.class = c.slug,
    b.beverage_type = c.beverage_type
WHERE b.style_confidence IS NULL
  AND b.style_id IS NULL AND b.parent IS NULL AND b.class IS NULL;

-- STEP 2c — Family (parent) alias ("IPA", "Stout", ...)
UPDATE beer b
JOIN parent_alias pa ON pa.alias = b.style
JOIN style_parent p ON p.slug = pa.parent
SET b.parent = p.slug,
    b.class = p.class,
    b.beverage_type = p.beverage_type
WHERE b.style_confidence IS NULL
  AND b.style_id IS NULL AND b.parent IS NULL AND b.class IS NULL;

-- STEP 2d — Style alias ("NEIPA", "West Coast IPA", ...)
UPDATE beer b
JOIN style_alias sa ON sa.alias = b.style
JOIN style s ON s.id = sa.style_id
JOIN style_parent p ON p.slug = s.parent
SET b.style_id = s.id,
    b.parent = s.parent,
    b.class = p.class,
    b.beverage_type = s.beverage_type
WHERE b.style_confidence IS NULL
  AND b.style_id IS NULL AND b.parent IS NULL AND b.class IS NULL;

-- ---------------------------------------------------------------------------
-- Verification
-- ---------------------------------------------------------------------------

-- Rough expectation (staging corpus): ~44k style+family+class,
-- ~16.5k style+family (families with no class rollup), a few hundred
-- family- or class-tier only, ~220 unresolved.
SELECT (style_id IS NOT NULL) AS has_style,
       (parent IS NOT NULL)   AS has_parent,
       (class IS NOT NULL)    AS has_class,
       COUNT(*) AS n
FROM beer GROUP BY 1, 2, 3 ORDER BY n DESC;

-- Rough expectation (staging corpus): beer ~59k / cider ~1.1k / mead ~300 / perry ~10
SELECT beverage_type, COUNT(*) AS n FROM beer GROUP BY beverage_type;

-- The unresolved tail — labels that match nothing in the vocabulary.
-- Informational: these beers keep their label and stay findable; they simply
-- have no canonical classification until someone edits them.
SELECT style, COUNT(*) AS n
FROM beer
WHERE style_id IS NULL AND parent IS NULL AND class IS NULL
GROUP BY style ORDER BY n DESC LIMIT 25;
