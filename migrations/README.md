# Migrations

Each file is dated the day it was written. Its header says what it does, why, and what has to run before it.

**Never edit a migration once it has run anywhere.** Add a new file instead. `2026-10-13` and `2026-10-17` were edited in place after staging had run them (commit 0398e48 dropped the `validation` column from both). Staging kept the column, and every address write there failed until `2026-10-20-drop-location-validation.sql` repaired it.

## Applied where

| Migration | Staging | Production |
|---|---|---|
| everything through `2026-10-05-brewer-status-country.sql` | applied | applied |
| `2026-10-13-international-addresses.sql` | 2026-10-17, original version (had `validation`) | **pending** |
| `2026-10-17-location-address-merge.sql` | 2026-10-17, original version (had `validation`) | **pending** |
| `2026-10-20-drop-location-validation.sql` | 2026-10-20 | **never: staging-only repair** |
| `2026-10-17-post.sql` | 2026-10-20 | **pending** |
| `2026-10-XX-drop-us-addresses.sql` | pending (after the soak) | pending (after the soak) |

Production as checked on 2026-10-20 (read-only, as `claude`): `US_addresses` present, no `address` table, no address columns on `location`, `subdivisions` without `countryCode` (51 US rows), 1,501 locations, every one with a `US_addresses` row and a numbered street, and 1 with no coordinates.

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
