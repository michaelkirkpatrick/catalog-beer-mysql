-- ============================================================================
-- Style search: FULLTEXT indexes for GET /style/search
-- ----------------------------------------------------------------------------
-- Adds the three FULLTEXT indexes behind the API's /style/search endpoint,
-- which ranks matches as the best of three signals: canonical name (×3),
-- alias (×2), and editorial description (×1). One index per table because
-- MATCH() can only use columns from a single table — the endpoint UNIONs the
-- three probes and takes MAX(relevance) per style.
--
-- Mirrors the existing search indexes: ft_brewer_search on `brewer`,
-- ft_beer_search on `beer`.
--
-- RUNBOOK (staging, then production):
--   1. Back up the database (mysqldump catalogbeer > backup.sql)
--   2. mysql catalogbeer < 2026-07-17-style-search-fulltext.sql   (this file)
--   3. Deploy the API (DB-first is safe — the old API never issues these
--      MATCH() queries; the new API 500s without the indexes, so run this
--      file before the deploy).
--   4. Spot-check: GET /style/search?q=NEIPA should return hazy-ipa first
--      (alias match), and GET /style/search?q=hazy should rank
--      hazy-ipa/hazy-imperial-ipa (name matches) above styles that merely
--      mention "hazy" in their descriptions.
-- ============================================================================

ALTER TABLE `style` ADD FULLTEXT KEY `ft_style_search` (`canonical_name`);
ALTER TABLE `style_alias` ADD FULLTEXT KEY `ft_style_alias_search` (`alias`);
ALTER TABLE `style_content` ADD FULLTEXT KEY `ft_style_content_search` (`description`);

-- Verification:
--   SHOW INDEX FROM style WHERE Key_name = 'ft_style_search';
--   SHOW INDEX FROM style_alias WHERE Key_name = 'ft_style_alias_search';
--   SHOW INDEX FROM style_content WHERE Key_name = 'ft_style_content_search';
