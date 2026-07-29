-- Daily catalog-health snapshots, written by catalog-beer-api
-- cron/snapshot-metrics.php (classes/Metrics.class.php).
--
-- Why a snapshot table at all: most of what we want to trend has no history in
-- the schema. cbVerified/brewerVerified are bit flags with no audit trail, and
-- "how many beers had a description" is only ever knowable as of right now. If
-- nobody writes down Tuesday's number on Tuesday, Tuesday is gone. It also
-- gives api_logging aggregates a permanent home: the raw rows are pruned at
-- 3 months, but the nightly trailing-30d counts survive forever.
--
-- Narrow on purpose — (date, metric, dimension, value) rather than one column
-- per metric — so adding a metric is one line of PHP and never a migration.
-- At ~90 rows a night this is ~33k rows/year, which is nothing.
--
-- `dimension` is '' for a plain scalar, or a bucket name for a grouped metric
-- (brewer_url_status/parked, beer_beverage_type/cider, …). It is part of the
-- primary key, so it cannot be NULL — hence the empty-string default.
--
-- Values are raw counts, never composite scores. A "catalog health = 0-100"
-- number should be computed at display time: bake the weights into stored
-- history and the day you change your mind about them, the whole series
-- becomes uninterpretable.

CREATE TABLE `metrics_daily` (
  `snapshotDate` DATE NOT NULL,
  `metric` VARCHAR(64) NOT NULL,
  `dimension` VARCHAR(64) NOT NULL DEFAULT '',
  `value` BIGINT NOT NULL,
  PRIMARY KEY (`snapshotDate`, `metric`, `dimension`),
  KEY `idx_metric_date` (`metric`, `snapshotDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
