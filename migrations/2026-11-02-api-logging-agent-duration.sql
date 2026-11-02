-- 2026-11-02 — api_logging: the two request facts it lacked.
--
-- userAgent: which client made the request. The vhost access logs have it
-- but are root-only; when the Oct 2026 sign-up wave dumped the catalog from
-- temp-mail accounts, nothing readable said whether a browser, a script or
-- an agent did it. Cut to 255 bytes by the API; NULL when none was sent.
--
-- durationMs: whole milliseconds from REQUEST_TIME_FLOAT to the log write.
-- The API had no latency record of its own; /activity's GET-traffic table
-- shows the average and maximum per endpoint from this. NULL under the CLI
-- and on every row from before the column existed.
--
-- Same release (API 6.7.0): a successful write stores neither body nor
-- response here any more (audit_log holds the result), so the table shrinks
-- as the window rolls; no DDL is needed for that.
--
-- Additive. Run on staging, then production, BEFORE the API 6.7.0 deploy:
-- the INSERT names both columns, and under strict mode an unknown column
-- fails it, which is a request that vanishes from the metering.
--
--   ssh staging-2604    'site-sql api.catalog.beer' < migrations/2026-11-02-api-logging-agent-duration.sql
--   ssh production-2604 'site-sql api.catalog.beer' < migrations/2026-11-02-api-logging-agent-duration.sql

ALTER TABLE api_logging
  ADD COLUMN userAgent varchar(255) DEFAULT NULL AFTER ipAddress,
  ADD COLUMN durationMs int unsigned DEFAULT NULL AFTER responseCode;
