-- ============================================================================
-- Beer/brewer search: name-only FULLTEXT indexes for tiered ranking
-- ----------------------------------------------------------------------------
-- /beer/search and /brewer/search previously ranked by a single blended
-- relevance score across (name, style, description) — a description mention
-- weighed the same as the entity's own name, and FULLTEXT has no stemming,
-- so "triple mash" buried "Dragon's Milk Reserve Triple-Mashed" at position
-- ~23. The endpoints now rank in tiers (exact name, all terms in name as
-- word prefixes, then the natural-language match), which needs MATCH(name)
-- on a name-only index — MATCH() requires an index on exactly the columns
-- it names.
--
-- RUNBOOK (staging, then production):
--   1. Back up the database (mysqldump catalogbeer > backup.sql)
--   2. mysql catalogbeer < 2026-07-19-beer-brewer-name-fulltext.sql  (this file)
--   3. Deploy the API (DB-first is required — the old API never issues
--      MATCH(name) alone; the new API errors without these indexes).
--   4. Spot-check: GET /beer/search?q=triple+mash should return
--      "Dragon's Milk Reserve Triple-Mashed" first; GET /beer/search?q=*
--      should return an empty list (200), not a 500.
-- ============================================================================

ALTER TABLE `beer` ADD FULLTEXT KEY `ft_beer_name` (`name`);
ALTER TABLE `brewer` ADD FULLTEXT KEY `ft_brewer_name` (`name`);

-- Verification:
--   SHOW INDEX FROM beer WHERE Key_name = 'ft_beer_name';
--   SHOW INDEX FROM brewer WHERE Key_name = 'ft_brewer_name';
