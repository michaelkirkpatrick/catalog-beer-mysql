-- api_logging: a covering index for the GET /activity report.
--
-- api_logging had no index but its UUID primary key, so each of the four
-- /activity queries scanned the whole table. The table holds exactly the
-- report's window (prune-api-logging.php keeps 3 months, the report reads 3
-- months), so every row was always in scope, and every row carries the body
-- and response TEXT columns.
--
-- On 2026-10-04 that was 137k rows / 164 MB of data against MySQL 8.4's
-- default 128 MB buffer pool, so each page view re-read the table from disk
-- four times. The admin page gave up at its 10s cURL timeout and rendered
-- "No activity data available"; the FPM slowlog showed every stuck request
-- inside the second scan (Activity.class.php, top contributors). The same
-- report against the same data ran in 0.5s on a machine where it fit in RAM.
--
-- The summary, top-contributors and GET-traffic queries read only these
-- columns, so they are answered from the index (~18 MB) without touching the
-- clustered rows. The recent-activity query needs `response`, so the API picks
-- its 50 ids from this index first and reads only those rows (deferred join).
-- Measured on a copy of production: 219,068 -> 5,957 buffer-pool page reads
-- per report.
--
-- Cost: one more secondary index maintained on every logged API request, and
-- the prune cron's DELETE removes entries from it too.

ALTER TABLE `api_logging`
  ADD INDEX `idx_method_ts` (`method`, `timestamp`, `responseCode`, `apiKey`, `uri`);
