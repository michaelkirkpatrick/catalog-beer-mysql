-- ============================================================================
-- Style search cleanup — drop the superseded FULLTEXT indexes
-- ----------------------------------------------------------------------------
-- PHASE 2. Run this only AFTER the API carrying the tiered /style/search
-- rewrite is deployed and verified.
--
-- 2026-07-17-style-search-fulltext.sql added three indexes for the original
-- UNION-of-three-probes ranking. Two of them are now unused: the rewritten
-- endpoint matches identity terms against style.search_name instead of
-- style.canonical_name and style_alias.alias, and matches aliases exactly
-- (LOWER(alias) = LOWER(?)), which needs no FULLTEXT index.
--
-- ft_style_content_search is KEPT — the description probe still uses it for
-- tier 2.
--
-- Ordering matters. Dropping these before the new API is live would 500 every
-- search in the gap, because the deployed code still issues MATCH() against
-- them. That is why this is a separate file from
-- 2026-07-19-style-search-name.sql rather than the tail of it.
--
-- Rollback note: if the API is rolled back to the UNION implementation after
-- this runs, re-apply 2026-07-17-style-search-fulltext.sql to restore the two
-- indexes. Nothing else is destroyed here — index drops on 196 rows are cheap
-- and instantly reversible.
-- ============================================================================

ALTER TABLE `style`       DROP INDEX `ft_style_search`;
ALTER TABLE `style_alias` DROP INDEX `ft_style_alias_search`;

-- Verify: both should return an empty set, and ft_style_content_search should
-- still exist.
--   SHOW INDEX FROM style       WHERE Key_name = 'ft_style_search';
--   SHOW INDEX FROM style_alias WHERE Key_name = 'ft_style_alias_search';
--   SHOW INDEX FROM style_content WHERE Key_name = 'ft_style_content_search';
