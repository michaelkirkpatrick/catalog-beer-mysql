-- ============================================================================
-- Rebuild style.search_name  —  RUN AFTER EVERY VOCABULARY RESEED
-- ----------------------------------------------------------------------------
-- style.search_name denormalises style.canonical_name + every style_alias row
-- into one FULLTEXT document, so that GET /style/search can score identity
-- terms against a single corpus. See 2026-07-19-style-search-name.sql for why.
--
-- Because it is a denormalisation, it goes stale the moment the vocabulary is
-- reseeded — and it fails *silently*: search keeps returning results, they are
-- just missing the new styles and aliases. Nothing errors. Run this after any
-- style-vocabulary-seed-*.sql.
--
-- This script is re-runnable and idempotent; running it when nothing has
-- changed rewrites the same values.
--
--   mysql catalogbeer < rebuild-style-search-name.sql
-- ============================================================================

-- Default is 1024 bytes. Without this, styles with many aliases get a silently
-- truncated document — the worst possible failure, since those are the styles
-- with the richest vocabulary and the most search traffic.
SET SESSION group_concat_max_len = 16384;

UPDATE `style` s
LEFT JOIN (
    SELECT `style_id`, GROUP_CONCAT(`alias` SEPARATOR ' ') AS `aliases`
    FROM `style_alias`
    GROUP BY `style_id`
) a ON a.`style_id` = s.`id`
SET s.`search_name` = CONCAT_WS(' ', s.`canonical_name`, COALESCE(a.`aliases`, ''));

-- Verify: expect 0 rows.
SELECT `id`, `canonical_name`
FROM `style`
WHERE `search_name` IS NULL OR `search_name` = '';
