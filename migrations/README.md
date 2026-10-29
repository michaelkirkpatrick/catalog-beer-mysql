# Migrations

Each file is dated the day it was written. Its header says what it does, why, and what has to run before it.

**Never edit a migration once it has run anywhere.** Add a new file instead. `2026-10-13` and `2026-10-17` were edited in place after staging had run them (commit 0398e48 dropped the `validation` column from both). Staging kept the column, and every address write there failed until `2026-10-20-drop-location-validation.sql` repaired it.

## Applied where

| Migration | Staging | Production |
|---|---|---|
| everything through `2026-10-05-brewer-status-country.sql` | applied | applied |
| `2026-10-13-international-addresses.sql` | 2026-10-17, original version (had `validation`) | 2026-10-20 (as `claude`; 1,501 rows copied, 1,133 subdivisions) |
| `2026-10-17-location-address-merge.sql` | 2026-10-17, original version (had `validation`) | 2026-10-20 (1,501 locations with `line1`; no `validation` column) |
| `2026-10-20-drop-location-validation.sql` | 2026-10-20 | **never: staging-only repair** |
| `2026-10-17-post.sql` | 2026-10-20 | 2026-10-20 |
| `2026-10-XX-drop-us-addresses.sql` | pending (after the soak) | pending (after the soak) |
| `2026-10-20-last-modified-index.sql` | 2026-10-21 (as `claude`, via `~/withdb.sh`; EXPLAIN on beer uses the index) | 2026-10-21 (as `claude`, via `cbdb.sh`; 161k beers, seconds; EXPLAIN uses the index) |
| `2026-10-21-drop-post-author.sql` | 2026-10-21 (as `claude`, via `~/withdb.sh`, after the API deploy; 33 posts, no FK left) | 2026-10-21 (as `claude`, via `cbdb.sh`, after the API deploy; 33 posts, no FK left) |
| `2026-10-23-review-service.sql` | 2026-10-23 (as `claude`, after the API 6.3.0 deploy; counts matched the archived export: 5 reviews, 3 leads, 489 history rows) | 2026-10-23 (as `claude`, after the API 6.3.0 deploy; counts matched the archived export plus the one history row logged between the export and the deploy: 642 / 491 / 2,486, that row appended to the archive first) |
| `2026-10-29-users-signup-provenance.sql` | 2026-10-29 (as `claude`, via `~/withdb.sh`; 3 users, 0 backfilled) | 2026-10-29 (as `claude`, via `cbdb.sh`, before the API deploy; 719 users, 26 `createdAt` backfilled from `emailAuthSent`, newest 2026-09-02) |
| `2026-10-29-api-logging-response-trim.sql` | pending (after the API 6.4.0 deploy) | pending (after the API 6.4.0 deploy; data cleanup + OPTIMIZE, off-peak) |
| `2026-10-29-drop-algolia-table.sql` | pending (after batch-upload + delete-legacy-ids) | pending (after batch-upload + delete-legacy-ids) |

Production backup before the 6.0 window: `/home/claude/backup-pre-6.0-2026-10-20.sql` on production-2604 (345 MB, 25 tables, `claude` 0600; taken with the wrapper `/home/claude/cbdb.sh`, which loads the API vhost's own DB credentials into the shell). Production as checked on 2026-10-20 before the run (read-only, as `claude`): `US_addresses` present, no `address` table, no address columns on `location`, `subdivisions` without `countryCode` (51 US rows), 1,501 locations, every one with a `US_addresses` row and a numbered street, and 1 with no coordinates.

## Production: API 6.0 (international addresses, address required)

The API 6.0 code reads the address from `location` and rejects the pre-6.0 shape, so the schema change, the API and the frontend go out in one window. The database account in `common/passwords.php` holds ALL PRIVILEGES on `catalogbeer`, so `claude` can run these with the site's own credentials.

1. **Back up first.** Take a full dump of `catalogbeer` to `/home/claude/backup-pre-6.0-<date>.sql`. The fold in step 3 drops a table.
2. **Run `2026-10-13-international-addresses.sql`.** It creates `address`, copies `US_addresses` into it, adds `countryCode`/`sub_type`/`parentCode` to `subdivisions` and seeds 1,082 ISO 3166-2 rows. Check:
   - `SELECT COUNT(*) FROM address` equals `SELECT COUNT(*) FROM US_addresses` (1,501 on 2026-10-20).
   - `SELECT COUNT(*) FROM subdivisions` returns 1,133 (51 + 1,082).
3. **Run `2026-10-17-location-address-merge.sql`.** It adds the ten address columns to `location`, folds `address` into them and drops `address`. Check:
   - `SELECT COUNT(*) FROM location WHERE line1 IS NOT NULL` equals the step 2 count.
   - `SHOW CREATE TABLE location` matches `catalog-beer-schema.sql`: no `validation` column, and `chk_location_address` is `(line1 IS NULL) = (locality IS NULL)`.
   - `SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'location' AND COLUMN_NAME = 'validation'` returns 0. If it returns 1, an old copy of the file was run: run `2026-10-20-drop-location-validation.sql`.
4. **Deploy the API** (`./deploy.sh production`, from `main`; `international-addresses` was merged on 2026-10-20). Then push the Algolia settings (`php algolia/settings.php production`) for the `regions` facet.
5. **Deploy the frontend** in the same window.
6. **Smoke test.** `GET /location/{id}` returns the nested `address`. A `POST /location` with an address returns 201. One without an address returns 400 with "Every location needs its address".
7. **Re-save the Algolia records** (locations, brewers, beers), since pushing settings never re-indexes them.
8. **After the soak** (a week of clean error logs): rename `2026-10-XX-drop-us-addresses.sql` to the date it runs and run it on both databases. That is the point of no return for the legacy copy.

**Do not run** `2026-10-20-drop-location-validation.sql` on production. The files as they stand never create the column.

## Production: posts (`/news` and `/changelog`)

`2026-10-17-post.sql` creates the `post` table behind the API's `/post` routes and the frontend's `/news`, `/changelog` and their RSS feeds. It only adds a table, so it can run before the 6.0 window or in it, but always before the API deploy that carries `/post` (`main` since 2026-10-20).

1. **Run `2026-10-17-post.sql`.** Check that `SHOW CREATE TABLE post` matches `catalog-beer-schema.sql`.
2. **Deploy the API, then the frontend.** Until the API serves `/post`, `/news` and `/changelog` render their empty state instead of failing.
3. **Import the first posts.** The frontend's `scratch/changelog-import/import-posts.php send https://api.catalog.beer <admin-key> --publish` posts every release through v5.4.0 plus the three old `/whats-new` articles. It uses the API, so it runs after step 2. A 409 means the post is already there, so a re-run only adds what is missing.
4. **Write the 6.0 release post** in `/admin/posts`. The import stops at v5.4.0.

## Production: posts, any admin, Markdown bodies (2026-10-21)

`2026-10-21-drop-post-author.sql` drops `post.authorUserID` with its index and foreign key. Nothing read the column: any admin reads and edits any post. It ships with the API change that lets the master key's account act as an admin on `/post` (drafts are returned only on `?status=all`, so the website's public reads still never see one) and the switch of post bodies to Markdown, which the frontend renders; existing HTML bodies render unchanged.

1. **Deploy the API first.** Its `INSERT` named the column until this change; under the old API, dropping it breaks every `POST /post`.
2. **Run `2026-10-21-drop-post-author.sql`** on staging, then production. **Check:** `SHOW COLUMNS FROM post LIKE 'authorUserID'` returns no row.
3. **Deploy the frontend.** Until then the editor still asks for drafts without `?status=all` and gets a 404 on them; the public pages are unaffected.

## Production: `modified_since` (API 6.1)

`2026-10-20-last-modified-index.sql` adds an index on `lastModified` to `brewer`, `beer` and `location` for the `?modified_since` filter on the three list endpoints. It is an index only: the API runs without it (the filter is then a full scan on every sync request), so the order against the deploy does not matter, but run it first so the first sync requests are already cheap. In-place online DDL, no table copy; seconds on 58k beers.

1. **Run `2026-10-20-last-modified-index.sql`** on staging, then production.
2. **Check:** `SHOW INDEX FROM beer WHERE Key_name = 'idx_beer_lastModified'` returns one row, and the same for `idx_brewer_lastModified` on `brewer` and `idx_location_lastModified` on `location`.
3. **Deploy the API** (6.1.0). `tests/modified-since.php` in the API repo asserts the index is in the canonical schema.

## Production: database size — log trim and the Algolia re-key (API 6.4.0)

Measured 2026-10-29: 780 MB on disk, of which `api_logging` 488 MB (full entity responses on every write), `beer` 169 MB (112 MB of B-tree indexes, each entry carrying the UUID key), `algolia` 81 MB (four UUID columns, four indexes, pure indirection). `idx_parent`/`idx_class` on `beer` back foreign keys and cannot be dropped; `idx_beverage_type` is a 1-byte enum index (~8 MB). Nothing to do on `beer`.

1. **Deploy API 6.4.0.** From then on a successful write logs a stub (`apiLogging::responseStub()`), and Algolia records are keyed by entity id. The `algolia` table is no longer read.
2. **Run `2026-10-29-api-logging-response-trim.sql`**, one month at a time, then `OPTIMIZE TABLE api_logging` off-peak (online rebuild; needs ~500 MB free disk). Check `SUM(LENGTH(response))` — 164 MB before.
3. **`php algolia/batch-upload.php production`** — re-indexes every record under its entity id. The index holds both copies until step 4, so site search shows duplicate hits for the length of the run.
4. **`php algolia/delete-legacy-ids.php production`** — deletes the old records (reads the ids from the `algolia` table). Check `error_log` for 292/293.
5. **Orphan sweep.** Browse the index and delete every record whose objectID is not a current brewer, beer or location id (styles excepted): the Newman suite's leftovers and anything staging wrote. The one-off script is kept outside the repo (Claude's session scratchpad, 2026-10-29); dry run first.
6. **Run `2026-10-29-drop-algolia-table.sql`.** Then delete `algolia/delete-legacy-ids.php` from the API repo.

**Staging shares production's Algolia index.** Both servers hold the same application id and `Algolia.class.php` accepts only `catalog`, so steps 3–5 are production-only: running them "on staging first" writes staging's snapshot into live search (it did, 2026-10-29: 67,812 staging records upserted and the matching production legacy records deleted; the production re-key and the orphan sweep repair it). On staging run only the trim (step 2) and the drop (step 6).

