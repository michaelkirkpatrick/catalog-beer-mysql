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

## See Also

* [Catalog.beer - GitHub](https://github.com/michaelkirkpatrick/catalog-beer)
* [Catalog.beer API - GitHub](https://github.com/michaelkirkpatrick/catalog-beer-api)
