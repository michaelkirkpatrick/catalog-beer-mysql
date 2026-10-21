-- brewer, beer, location: an index on lastModified for ?modified_since.
--
-- GET /brewer, /beer and /location take ?modified_since=<unix seconds> (API
-- 6.1) so a client that mirrored the catalog can come back for the rows
-- that changed since its last visit instead of re-listing everything. The
-- filter is `WHERE lastModified >= ?`, and its page count is a COUNT(*) over
-- the same predicate, so every sync request runs two range scans on the
-- column. Without an index each is a full scan of the table (58k beers on
-- 2026-10-20, growing), and a mirror polling every few minutes would be the
-- most expensive reader the API has.
--
-- The three columns are int Unix seconds and already written on every
-- INSERT and UPDATE; nothing changes in how they are maintained. Cost: one
-- more secondary index per table, updated on every write to the row.

ALTER TABLE `brewer`   ADD INDEX `idx_brewer_lastModified` (`lastModified`);
ALTER TABLE `beer`     ADD INDEX `idx_beer_lastModified` (`lastModified`);
ALTER TABLE `location` ADD INDEX `idx_location_lastModified` (`lastModified`);
