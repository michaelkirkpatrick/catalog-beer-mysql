-- api_logging: two index changes for the admin activity report (API 6.8.0).
--
-- The table (283 MB on 2026-11-04) is larger than the production buffer pool
-- (256 MB), so any query that needs a column the covering index does not
-- hold is planned as a full table scan from disk: 4-7 seconds each on the
-- production box, which put GET /activity past the page's timeout.
--
-- 1. durationMs joins the covering index idx_method_ts, so the reads-by-
--    endpoint timings (avg_ms, max_ms, read since 6.7.0) and the per-key
--    endpoint breakdown are answered from the index alone, like the counts.
--    Same leading columns, same name; every query that used it still does.
--
-- 2. idx_apiKey_ts (apiKey, timestamp): the per-key breakdowns that must
--    read whole rows (userAgent, ipAddress, the search terms in uri) are
--    asked for the busiest keys only, as `apiKey IN (...) AND timestamp >=
--    ?`, and seek those keys' rows instead of scanning the table.
--
-- Online DDL (INPLACE); a few seconds on 486k rows. Run on both servers
-- before deploying API 6.8.0's second cut; the first cut runs without them,
-- slowly.

ALTER TABLE `api_logging`
  DROP INDEX `idx_method_ts`,
  ADD INDEX `idx_method_ts` (`method`, `timestamp`, `responseCode`, `apiKey`, `uri`, `durationMs`),
  ADD INDEX `idx_apiKey_ts` (`apiKey`, `timestamp`),
  ALGORITHM=INPLACE, LOCK=NONE;
