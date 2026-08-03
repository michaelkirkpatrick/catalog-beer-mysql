# Catalog.beer MySQL Schema

The MySQL schema that powers [Catalog.beer](https://catalog.beer).

Comments, issues and pull requests welcome.

-Michael

Michael Kirkpatrick
Founder, Catalog.beer

## Indexes

The schema includes performance indexes beyond primary and foreign keys:

- `api_usage.idx_apiKey_year_month` — Unique index for upsert in the usage tracking cron job
- `error_log.idx_resolved_timestamp` — Composite index for the error report endpoint (`GET /error-log`) and daily digest cron, which filter on `resolved` and `timestamp`
- `beer.ft_beer_search` — FULLTEXT index for beer search (`/beer/search`) on `name`, `style`, `description`
- `brewer.ft_brewer_search` — FULLTEXT index for brewer search (`/brewer/search`) on `name`, `description`, `shortDescription`
- `beer.idx_beer_createdAt`, `brewer.idx_brewer_createdAt`, `location.idx_location_createdAt` — Creation timestamps, for the growth metrics collected by the `snapshot-metrics` cron

## Metrics

`metrics_daily` holds one row per catalog-health metric per day, written nightly by the API's `cron/snapshot-metrics.php`. It is narrow — `(snapshotDate, metric, dimension, value)` rather than a column per metric — so adding a metric never requires a migration. `dimension` is `''` for a plain scalar or a bucket name for a grouped metric.

The table exists because most of what it records has no history in the schema: `cbVerified`/`brewerVerified` are bit flags with no audit trail, field completeness is only knowable as of now, and the `api_logging` rows behind the demand metrics are pruned at 3 months.

`createdAt` was added to `beer`, `brewer` and `location` in July 2026 for the same reason — before it, an edit overwrote the only date on the row, so growth over time was unmeasurable. It is backfilled from `lastModified`, which is exact for any row never edited since creation and an upper bound otherwise.

## ZIP codes

`US_addresses.zip5` and `.zip4` are `char(5)` / `char(4)`, not integers, with `CHECK` constraints enforcing the digit format. ZIP codes are fixed-width identifiers with significant leading zeros — 00501–09999 covers New England, New Jersey, Puerto Rico and the Virgin Islands — and nothing ever does arithmetic on one.

## See Also

* [Catalog.beer - GitHub](https://github.com/michaelkirkpatrick/catalog-beer)
* [Catalog.beer API - GitHub](https://github.com/michaelkirkpatrick/catalog-beer-api)
