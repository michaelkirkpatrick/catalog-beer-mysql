-- 2026-10-29 — Trim the stored response on api_logging's successful writes,
-- then reclaim the space. Data cleanup, not a schema change.
--
-- Why: a successful write logged the whole entity it returned (~1.1 KB a
-- row), and two bulk-load months of POST /beer (133k rows) put 156 MB of
-- them into a 488 MB table on a box with a 128 MB InnoDB buffer pool. The
-- only reader of the column, /activity's Recent Activity, uses four keys
-- (id, name, brewer.id, brewer.name); the API now stores just those
-- (apiLogging::responseStub()). This replays that rule over the rows
-- written before the deploy, which Usage::pruneLogging() would otherwise
-- carry for up to three months.
--
-- Run AFTER the API deploy (6.4.0), so no new full responses land while it
-- runs. One statement per month keeps each transaction under the 100 MB
-- redo log; each takes seconds to a minute. JSON_OBJECT with JSON_EXTRACT
-- gives the same shape the API now writes; a response with no id is set to
-- '' as the API does. Rows whose response isn't valid JSON (none seen) are
-- left alone by the JSON_VALID guard.
--
-- The UPDATE frees space inside the table but does not return it to the
-- filesystem; OPTIMIZE TABLE rebuilds it (InnoDB: an online copy, needs free
-- disk of about the table's size, ~500 MB, 33 GB was free on 2026-10-29) and
-- is what turns 488 MB into tens of MB. Run it off-peak.

-- Repeat for each month present (SELECT DISTINCT FROM_UNIXTIME(timestamp,'%Y-%m') FROM api_logging):
UPDATE api_logging
   SET response = IF(JSON_EXTRACT(response, '$.id') IS NULL, '',
         JSON_OBJECT('id', JSON_UNQUOTE(JSON_EXTRACT(response, '$.id')),
                     'name', JSON_UNQUOTE(JSON_EXTRACT(response, '$.name')),
                     'brewer', IF(JSON_EXTRACT(response, '$.brewer.id') IS NULL, NULL,
                                  JSON_OBJECT('id', JSON_UNQUOTE(JSON_EXTRACT(response, '$.brewer.id')),
                                              'name', JSON_UNQUOTE(JSON_EXTRACT(response, '$.brewer.name'))))))
 WHERE method <> 'GET'
   AND responseCode BETWEEN 200 AND 299
   AND LENGTH(response) > 300
   AND JSON_VALID(response)
   AND timestamp >= UNIX_TIMESTAMP('2026-07-01') AND timestamp < UNIX_TIMESTAMP('2026-08-01');
-- ... 2026-08, 2026-09, 2026-10, 2026-11 ...

-- Then, off-peak:
OPTIMIZE TABLE api_logging;

-- Check: SELECT ROUND(SUM(LENGTH(response))/1048576,1) FROM api_logging;  -- was 164.0 MB
