-- ============================================================================
-- Drop beer.style_label — consolidate the brewer's label into beer.style
-- ----------------------------------------------------------------------------
-- `style_label` was added during the Guided Style Field v2 transition as a
-- parallel copy of `style` (both columns were written with the same value on
-- every insert/update). The public API field is `style`; the duplicate column
-- and the transition-era request alias are being removed.
--
-- Run in TWO phases, interleaved with the deploys. Order matters:
--
--   1. Run PHASE 1 (below)
--   2. Deploy the frontend  (sends `style`; the old API accepts it as a fallback)
--   3. Deploy the API       (reads/writes `style` only; searches the new index)
--   4. Run PHASE 2 (below)
--
-- Phase 1 is safe while the OLD API code is live; phase 2 must only run once
-- the NEW API code is deployed (the old code selects and writes style_label
-- and searches the old index).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- PHASE 1 — before the API deploy
-- ---------------------------------------------------------------------------

-- Safety net: `style` is the original column and should already hold every
-- label, but make sure no style_label value is lost. Expect 0 rows affected.
UPDATE beer SET style = style_label
WHERE style_label IS NOT NULL AND style_label <> '' AND style <> style_label;

-- New search index on `style`, alongside the old one (the old API keeps using
-- ft_beer_search on style_label until the new code is deployed).
ALTER TABLE beer ADD FULLTEXT KEY `ft_beer_search_style` (`name`,`style`,`description`);

-- ---------------------------------------------------------------------------
-- PHASE 2 — after the API deploy
-- ---------------------------------------------------------------------------

ALTER TABLE beer
  DROP INDEX `ft_beer_search`,
  DROP COLUMN `style_label`,
  RENAME INDEX `ft_beer_search_style` TO `ft_beer_search`;
