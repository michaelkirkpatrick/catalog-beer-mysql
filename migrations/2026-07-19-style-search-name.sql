-- ============================================================================
-- Style search, take two: one identity document per style
-- ----------------------------------------------------------------------------
-- Supersedes the ranking approach in 2026-07-17-style-search-fulltext.sql.
--
-- NOTE: the population step below is itself superseded by
-- 2026-07-20-style-search-dedupe.sql, which stores each distinct token once.
-- Concatenating aliases verbatim, as this file does, lets term frequency count
-- alias repetitions — ranking styles by how many synonyms they happen to have.
-- The schema here is still current; only the values are rewritten. This file is
-- left as it was applied so it stays an accurate record of what ran.
--
-- WHY
-- The first cut UNIONed three MATCH() probes — style.canonical_name (x3),
-- style_alias.alias (x2), style_content.description (x1) — and took the best
-- score per style. That cannot rank correctly, for three reasons:
--
--   1. MATCH() relevance is computed from IDF *within one index*. Three tables
--      means three corpora of different sizes, so a score of 0.8 means three
--      different things. The 3/2/1 weights assume a shared scale that does not
--      exist, so no amount of tuning fixes it.
--   2. Field-length normalisation ran per alias row, so the *shortest* alias
--      won. "Black IPA" beat "American IPA" for q=ipa, making alias string
--      length the deciding factor — a property unrelated to user intent.
--   3. Canonical names spell out "India Pale Ale"; the token "IPA" appears in
--      none of them. The x3 name signal was structurally dead for the single
--      most common query on a beer site. Observed on staging: q=ipa ranked
--      american-belgo-ale and american-black-ale above american-ipa, and q=ale
--      returned aged-beer first.
--
-- WHAT
-- search_name holds the canonical name plus every alias as ONE document, so
-- identity terms live in a single column, in a single table, scored against a
-- single corpus. "IPA" now reaches american-ipa through its own name signal.
--
-- The API pairs this with tiered ranking (exact match, then name hit, then
-- description hit), comparing relevance only *within* a tier — same column,
-- same corpus — which is the only place the comparison is meaningful.
--
-- The old indexes from 2026-07-17 are NOT dropped here. The currently deployed
-- API still issues MATCH() against them, and dropping them before that code is
-- replaced would 500 every search in the gap. They are removed by
-- 2026-07-19-style-search-cleanup.sql, which runs AFTER the API deploy.
--
-- RUNBOOK (staging, then production):
--   1. Back up the database (mysqldump catalogbeer > backup.sql)
--   2. mysql catalogbeer < 2026-07-19-style-search-name.sql   (this file)
--   3. Deploy the API. DB-first is safe: this file only adds a column and an
--      index, and the old API never reads either.
--   4. Spot-check (see the verification block at the end of this file).
--   5. mysql catalogbeer < 2026-07-19-style-search-cleanup.sql
--
-- MAINTENANCE
-- search_name is a denormalisation of style_alias, so it goes stale whenever
-- the vocabulary is reseeded. The seed is a mysqldump and would lose anything
-- appended to it, so the rebuild lives in its own re-runnable script:
-- rebuild-style-search-name.sql. Run it after EVERY vocabulary reseed.
-- Triggers were considered and rejected: nothing writes style_alias at runtime,
-- so a trigger would carry maintenance cost for an event that never fires.
-- Revisit if aliases ever become editable through the API.
-- ============================================================================

ALTER TABLE `style`
    ADD COLUMN `search_name` TEXT NULL AFTER `canonical_name`,
    ADD FULLTEXT KEY `ft_style_search_name` (`search_name`);

-- Populate. GROUP_CONCAT truncates silently at group_concat_max_len (default
-- 1024 bytes) — which would quietly corrupt search for exactly the styles that
-- have the most aliases, the ones people search hardest for. Raise it first.
SET SESSION group_concat_max_len = 16384;

UPDATE `style` s
LEFT JOIN (
    SELECT `style_id`, GROUP_CONCAT(`alias` SEPARATOR ' ') AS `aliases`
    FROM `style_alias`
    GROUP BY `style_id`
) a ON a.`style_id` = s.`id`
SET s.`search_name` = CONCAT_WS(' ', s.`canonical_name`, COALESCE(a.`aliases`, ''));

-- ----------------------------------------------------------------------------
-- Verification
-- ----------------------------------------------------------------------------
-- Every style must have a populated search_name (expect 0):
--   SELECT COUNT(*) FROM style WHERE search_name IS NULL OR search_name = '';
--
-- Truncation canary — the style with the most aliases must still end with its
-- last alias rather than a cut-off word:
--   SELECT id, LENGTH(search_name), search_name FROM style
--   ORDER BY LENGTH(search_name) DESC LIMIT 3;
--
-- The abbreviation that motivated all of this must now be present:
--   SELECT id FROM style WHERE MATCH(search_name)
--   AGAINST('IPA' IN NATURAL LANGUAGE MODE);
--   -- american-ipa must appear in the result set.
--
-- Index exists:
--   SHOW INDEX FROM style WHERE Key_name = 'ft_style_search_name';
