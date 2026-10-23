-- The brewer review loop leaves the catalog database.
--
-- On 2026-10-23 the loop's queue, claims, records, leads and questions moved
-- to their own service (review.catalog.beer, repo catalog-beer-review, design
-- in Catalog Beer/Claude Ideas/review-service.md). Its data was exported from
-- this database and imported there first; the export is archived in
-- catalog-beer-mysql-archive/2026-10-23-review-service-migration/.
--
-- brewer_url_history goes with it. It was a one-field history table whose
-- cascading FK deleted the evidence with the row; site-wide history is the
-- next project (Claude Ideas/audit-log.md), and that same export is its first
-- backfill. brewer.urlLastKnown and the other URL-health columns stay until
-- the service's URL audit has worked through its seed.
--
-- Run AFTER catalog-beer-api 6.3.0 is deployed: that release stops reading and
-- writing these tables. Nothing else in the catalog references them (no FK
-- points at them; the three brewer columns were only read by the removed
-- Review class).

DROP TABLE IF EXISTS `brewer_review`;
DROP TABLE IF EXISTS `brewer_lead`;
DROP TABLE IF EXISTS `brewer_url_history`;

ALTER TABLE `brewer`
  DROP INDEX `idx_brewer_reviewedAt`,
  DROP INDEX `idx_brewer_claimedAt`,
  DROP COLUMN `reviewedAt`,
  DROP COLUMN `claimedBy`,
  DROP COLUMN `claimedAt`;
