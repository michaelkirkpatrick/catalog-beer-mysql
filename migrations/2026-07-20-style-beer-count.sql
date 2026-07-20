-- ============================================================================
-- style.beer_count — how many catalogued beers use each style
-- ----------------------------------------------------------------------------
-- A ranking tiebreaker for GET /style/search, and the first signal in this
-- work that actually means something.
--
-- WHY
-- Two attempts at ordering results within a match tier both failed, for the
-- same reason. Concatenated aliases ranked by how many synonyms a style
-- happened to have; deduplicated tokens ranked by how many distinct tokens its
-- identity document contained. Neither has any relationship to what a searcher
-- wants, so q=ipa put experimental-ipa and new-zealand-ipa — used by ZERO
-- beers in the catalogue — above american-ipa, used by 6,530.
--
-- There is no signal inside the style vocabulary that resolves this: every IPA
-- is equally an IPA. The signal lives in the beer table. Observed spread
-- across the ipa family: 6530, 2889, 587, 470, 339, 13, 3, 2, 0, 0, 0 — more
-- than enough to separate the styles people actually use from the ones that
-- exist only in the vocabulary.
--
-- The goal is NOT to make american-ipa win. A search for "ipa" legitimately
-- means any of eleven styles, which is why the endpoint also returns the ipa
-- family. The goal is only to stop ranking unused styles above used ones.
--
-- KNOWN BIAS
-- beer_count measures the catalogue, not the world. hazy-ipa shows 13 beers
-- despite being one of the most brewed styles today, because catalogue
-- coverage skews to older data. This is acceptable *as a tiebreaker*: it only
-- orders results that already match equally well, so a search for "hazy" or
-- "NEIPA" still resolves on relevance and exact matching, where it should.
-- It would NOT be acceptable as a primary ranking signal — that would bury
-- newer styles no matter how precisely they were searched for.
--
-- Denormalised and therefore stale by design: it is a popularity hint, not a
-- fact anyone reads. Refresh with refresh-style-beer-count.sql on the same
-- cadence as the sitemap cron. Drift of a week changes no ordering, because
-- the gaps that matter are three orders of magnitude wide.
--
-- RUNBOOK:
--   1. mysql catalogbeer < 2026-07-20-style-beer-count.sql   (this file)
--   2. Deploy the API.
--   3. Spot-check: GET /style/search?q=ipa — no zero-beer style should sit
--      above american-ipa or double-ipa.
-- ============================================================================

ALTER TABLE `style`
    ADD COLUMN `beer_count` INT NOT NULL DEFAULT 0 AFTER `is_catch_all`;

-- Populate. beer.style_id is nullable and indexed (fk_beer_style), so this
-- groups on the index and skips unassigned beers.
UPDATE `style` s
LEFT JOIN (
    SELECT `style_id`, COUNT(*) AS `n`
    FROM `beer`
    WHERE `style_id` IS NOT NULL
    GROUP BY `style_id`
) b ON b.`style_id` = s.`id`
SET s.`beer_count` = COALESCE(b.`n`, 0);

-- Verification
--   Spread across the IPA family — expect american-ipa far ahead:
--     SELECT id, beer_count FROM style WHERE parent = 'ipa'
--     ORDER BY beer_count DESC;
--
--   Total should equal the number of beers with a style assigned:
--     SELECT SUM(beer_count) FROM style;
--     SELECT COUNT(*) FROM beer WHERE style_id IS NOT NULL;
