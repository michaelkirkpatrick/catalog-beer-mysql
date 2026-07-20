-- ============================================================================
-- Rebuild style.search_name  —  RUN AFTER EVERY VOCABULARY RESEED
-- ----------------------------------------------------------------------------
-- style.search_name denormalises style.canonical_name + every style_alias row
-- into one FULLTEXT document, so GET /style/search can score identity terms
-- against a single corpus. See 2026-07-19-style-search-name.sql for why.
--
-- TOKENS ARE DEDUPLICATED, and that is the whole point of this script rather
-- than a plain GROUP_CONCAT. Concatenating aliases verbatim lets term frequency
-- count alias *repetitions*: hazy-ipa has six aliases all containing "IPA"
-- while american-ipa has one, so a naive concatenation ranked hazy-ipa first
-- and american-ipa fifteenth for q=ipa. Ranking by how many synonyms a style
-- happens to have is no more meaningful than the alias-string-length it
-- replaced.
--
-- In an identity document, "IPA" six times means "this style has six
-- synonyms", not "this style is more IPA than the others". Storing each
-- distinct token once makes term frequency uninformative, which is correct
-- here, and lets IDF and the API's tiebreakers decide the order.
--
-- GROUP_CONCAT(DISTINCT alias) would NOT do this — it dedupes whole alias
-- strings, leaving "Hazy IPA" and "Juicy IPA" both contributing an "IPA".
-- Deduping requires splitting to words, hence the recursive CTE.
--
-- This script is re-runnable and idempotent.
--
--   mysql catalogbeer < rebuild-style-search-name.sql
-- ============================================================================

-- GROUP_CONCAT truncates silently at group_concat_max_len (default 1024
-- bytes), which would quietly corrupt search for exactly the styles with the
-- most aliases — the ones people search hardest for.
SET SESSION group_concat_max_len = 16384;

WITH RECURSIVE base AS (
    -- One space-separated string per style: canonical name + every alias, with
    -- punctuation flattened to spaces. [[:alnum:]] is Unicode-aware in MySQL 8,
    -- so accented characters survive rather than being stripped mid-word.
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
    -- Peel one word at a time off the front. Recursion depth is the word count
    -- of the longest document (tens), far under cte_max_recursion_depth.
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

-- Verify: expect 0 rows.
SELECT `id`, `canonical_name`
FROM `style`
WHERE `search_name` IS NULL OR `search_name` = '';

-- Verify dedup worked — no token may appear twice. Expect 0 rows.
SELECT `id`, `search_name`
FROM `style`
WHERE `search_name` REGEXP '(^| )([[:alnum:]]+)( .*)? \\2( |$)';
