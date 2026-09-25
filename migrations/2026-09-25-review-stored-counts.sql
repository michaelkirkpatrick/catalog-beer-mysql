-- brewer_review: store the sources and changes counts instead of computing them.
--
-- GET /review returns sourcesCount/changesCount in place of the arrays, and
-- the first cut of that computed them as JSON_LENGTH(r.sources) and
-- JSON_LENGTH(r.changes) in the select list. That 500s:
--
--   Out of sort memory, consider increasing server sort buffer size
--
-- The list orders by reviewedAt with a LIMIT, which filesorts. With addon
-- fields MySQL sizes each sort-buffer row from the DECLARED maximum width of
-- every selected expression, and one derived from a JSON column is declared
-- enormous — so a single row will not fit a 256 KB sort_buffer_size. It is
-- not about how many rows there are or how big the JSON actually is.
--
-- The trap: the query worked before only because it also selected sources,
-- changes and notes. A real blob in the select list pushes MySQL onto the
-- rowid-sort path, which re-reads rows after sorting and never packs them.
-- Removing the blobs to make the endpoint cheap is what exposed it.
--
-- Raising sort_buffer_size is the wrong fix — it is allocated per connection,
-- and the production box is a 1 GB Nanode with a history of OOM kills. The
-- counts are known at INSERT and the arrays are immutable afterwards (PATCH
-- only ever touches notes, question and decision), so a stored column cannot
-- drift.

ALTER TABLE `brewer_review`
  ADD COLUMN `sourcesCount` smallint unsigned NOT NULL DEFAULT '0' AFTER `sources`,
  ADD COLUMN `changesCount` mediumint unsigned NOT NULL DEFAULT '0' AFTER `changes`;

UPDATE `brewer_review`
   SET `sourcesCount` = COALESCE(JSON_LENGTH(`sources`), 0),
       `changesCount` = COALESCE(JSON_LENGTH(`changes`), 0);
