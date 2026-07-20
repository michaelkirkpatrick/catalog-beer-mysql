-- ============================================================================
-- Refresh style.beer_count  —  RUN PERIODICALLY (weekly is ample)
-- ----------------------------------------------------------------------------
-- style.beer_count is a denormalised count of catalogued beers per style, used
-- as a ranking tiebreaker by GET /style/search so that styles no beer uses stop
-- outranking styles thousands of beers use. See 2026-07-20-style-beer-count.sql
-- for why relevance alone could not do this.
--
-- Staleness is harmless here, which is the point of denormalising it. The gaps
-- that decide ordering are three orders of magnitude wide (6,530 beers versus
-- 0), so a week of drift changes nothing. Run it alongside the sitemap cron.
--
-- Re-runnable and idempotent.
--
--   mysql catalogbeer < refresh-style-beer-count.sql
-- ============================================================================

UPDATE `style` s
LEFT JOIN (
    SELECT `style_id`, COUNT(*) AS `n`
    FROM `beer`
    WHERE `style_id` IS NOT NULL
    GROUP BY `style_id`
) b ON b.`style_id` = s.`id`
SET s.`beer_count` = COALESCE(b.`n`, 0);

-- Verify: these two totals must agree.
SELECT (SELECT SUM(`beer_count`) FROM `style`)                        AS `summed_counts`,
       (SELECT COUNT(*) FROM `beer` WHERE `style_id` IS NOT NULL)     AS `assigned_beers`;
