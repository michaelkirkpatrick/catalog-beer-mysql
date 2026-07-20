-- ============================================================================
-- Deduplicate tokens in style.search_name
-- ----------------------------------------------------------------------------
-- Corrects the population step in 2026-07-19-style-search-name.sql, which
-- concatenated aliases verbatim. That let term frequency count alias
-- repetitions rather than relevance: hazy-ipa carries six aliases all
-- containing "IPA" and american-ipa carries one, so on staging q=ipa ranked
-- hazy-ipa first and american-ipa FIFTEENTH. Ranking by how many synonyms a
-- style happens to have is no more meaningful than the alias-string-length
-- ranking it was brought in to replace.
--
-- No schema change. The column and its FULLTEXT index are unchanged; only the
-- stored values are rewritten, so this is safe to run at any time and against
-- a live API. FULLTEXT indexes update transactionally with the row.
--
-- 2026-07-19-style-search-name.sql is deliberately left as it was applied.
-- Editing an already-applied migration makes it impossible to tell what a
-- given database actually ran.
--
-- The logic here is identical to rebuild-style-search-name.sql, which is the
-- canonical copy and the one to run after a vocabulary reseed. This file
-- exists only so the correction is captured in the migration timeline.
--
-- RUNBOOK:
--   1. mysql catalogbeer < 2026-07-20-style-search-dedupe.sql   (this file)
--   2. Deploy the API (the family-matching fixes ship alongside).
--   3. Spot-check: GET /style/search?q=ipa — american-ipa should sit among the
--      IPAs rather than fifteenth, and the `ipa` family should be returned.
-- ============================================================================

SET SESSION group_concat_max_len = 16384;

WITH RECURSIVE base AS (
    SELECT s.`id`,
           TRIM(REGEXP_REPLACE(
               LOWER(CONCAT_WS(' ', s.`canonical_name`, COALESCE(a.`aliases`, ''))),
               '[^[:alnum:]]+', ' ')) AS `txt`
    FROM `style` s
    LEFT JOIN (
        SELECT `style_id`, GROUP_CONCAT(`alias` SEPARATOR ' ') AS `aliases`
        FROM `style_alias`
        GROUP BY `style_id`
    ) a ON a.`style_id` = s.`id`
),
split AS (
    SELECT `id`,
           SUBSTRING_INDEX(`txt`, ' ', 1) AS `word`,
           CASE WHEN LOCATE(' ', `txt`) > 0
                THEN SUBSTRING(`txt`, LOCATE(' ', `txt`) + 1) ELSE '' END AS `rest`
    FROM base
    WHERE `txt` <> ''
    UNION ALL
    SELECT `id`,
           SUBSTRING_INDEX(`rest`, ' ', 1),
           CASE WHEN LOCATE(' ', `rest`) > 0
                THEN SUBSTRING(`rest`, LOCATE(' ', `rest`) + 1) ELSE '' END
    FROM split
    WHERE `rest` <> ''
),
agg AS (
    SELECT `id`, GROUP_CONCAT(DISTINCT `word` ORDER BY `word` SEPARATOR ' ') AS `search_name`
    FROM split
    WHERE `word` <> ''
    GROUP BY `id`
)
UPDATE `style` s
LEFT JOIN agg ON agg.`id` = s.`id`
SET s.`search_name` = COALESCE(agg.`search_name`, LOWER(s.`canonical_name`));

-- Verification
--   Every style populated (expect 0):
--     SELECT COUNT(*) FROM style WHERE search_name IS NULL OR search_name = '';
--
--   No token repeats (expect 0):
--     SELECT id FROM style
--     WHERE search_name REGEXP '(^| )([[:alnum:]]+)( .*)? \\2( |$)';
--
--   The motivating case still matches:
--     SELECT id FROM style
--     WHERE MATCH(search_name) AGAINST('IPA' IN NATURAL LANGUAGE MODE);
