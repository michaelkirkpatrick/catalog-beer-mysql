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

## Brewer status and country

`brewer.status` (`active`/`closed`) is the authoritative closure flag; `foundedYear` and `closedYear` are year-only because that is what sources state and nothing queries finer. A closure with an unknown year is `closed` with a NULL year, so the flag is never derived from the year. Two `CHECK` constraints back the API's validation: a `closedYear` needs `status = 'closed'`, and it cannot precede `foundedYear`.

`brewer.countryCode` and `brewer_lead.countryCode` are ISO 3166-1 alpha-2, the same standard as `location.countryCode`. The brewer carries one because a brewer with no locations has no derivable country. A non-US lead is stored but never handed out by the claim queue, so the open non-US leads are the backlog for any expansion beyond the US.

`sub_code` (ISO 3166-2) is `varchar(6)` in `subdivisions`, `address` and `brewer_lead`: the regional part runs to three characters (`GB-ENG`), and the foreign key needs both sides the same width.

## Addresses

`address` is one table for every country (October 2026; it replaced `US_addresses`, see `migrations/2026-10-13-international-addresses.sql`). The columns follow the vocabulary of Google's `postalAddress`: `line1` (street), `line2` (unit), `locality`, `dependentLocality`, `sub_code`, `postalCode`, plus `formatted` (a JSON array of display lines in the country's own order, without the country name), `languageCode` and `validatedAt`, when the validator last accepted it. `countryCode` always equals the location's; the API refuses a country change on a location that holds an address.

The US rules that used to be column types are now two `CHECK` constraints that apply only when `countryCode = 'US'`: a `sub_code` is required, and `postalCode` must be `NNNNN` or `NNNNN-NNNN`. Outside the US a subdivision is optional (Brussels has no province) and the postal code is whatever Google validated (`8640`, `1018 AL`, `SW1A 1AA`).

`telephone` is an E.164 string (`+15035550100`, `+3257400376`), checked by a `CHECK`. A bigint of ten NANP digits could not hold a Belgian number, and a bare digit string is ambiguous (3257400376 is both +32 57 40 03 76 and a Texas number); the `+` is what says "international form".

`subdivisions` is seeded from ISO 3166-2 for the 40 regions Google Address Validation covers, at the level Google reports as an administrative area, with `countryCode`, `sub_type` (state, province, region, canton, ...) and `parentCode` (Belgian provinces sit under regions). Names are the local official form (`West-Vlaanderen`, `Bayern`).

## Postal codes

Postal codes are identifiers, never numbers: `address.postalCode` is `varchar(20)`. ZIP codes in particular have significant leading zeros — 00501–09999 covers New England, New Jersey, Puerto Rico and the Virgin Islands — and nothing ever does arithmetic on one.

## See Also

* [Catalog.beer - GitHub](https://github.com/michaelkirkpatrick/catalog-beer)
* [Catalog.beer API - GitHub](https://github.com/michaelkirkpatrick/catalog-beer-api)
