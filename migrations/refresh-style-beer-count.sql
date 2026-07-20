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
-- Re-runnable and idempotent. Safe to run against a live API: it rewrites 196
-- rows in `style` and only reads `beer`.
--
--   mysql catalogbeer < refresh-style-beer-count.sql
--
-- CRON
--   0 4 * * 0  mysql --defaults-file=~/.my.cnf catalogbeer < /path/refresh-style-beer-count.sql
--
-- This script is silent when healthy and prints only on failure, which is what
-- makes it safe to run unattended: cron mails you only when there is output, so
-- silence means success and any mail is a real problem. A version that printed
-- its totals on every run would either train you to ignore the mail or bury the
-- one week it mattered.
-- ============================================================================

UPDATE `style` s
LEFT JOIN (
    SELECT `style_id`, COUNT(*) AS `n`
    FROM `beer`
    WHERE `style_id` IS NOT NULL
    GROUP BY `style_id`
) b ON b.`style_id` = s.`id`
SET s.`beer_count` = COALESCE(b.`n`, 0);

-- Verify. Returns NO ROWS when the refresh is correct, and one row naming the
-- discrepancy when it is not — so under cron, output means something is wrong.
--
-- A transient mismatch is possible if beers are written between the UPDATE and
-- this check; the two totals are not read atomically. Treat a single alert as
-- worth re-running by hand, and a repeated one as a real fault.
SELECT 'MISMATCH: style.beer_count does not sum to the assigned beer count' AS `alert`,
       s.`summed_counts`,
       a.`assigned_beers`
FROM (SELECT SUM(`beer_count`) AS `summed_counts` FROM `style`) s,
     (SELECT COUNT(*) AS `assigned_beers` FROM `beer` WHERE `style_id` IS NOT NULL) a
WHERE s.`summed_counts` <> a.`assigned_beers`;
