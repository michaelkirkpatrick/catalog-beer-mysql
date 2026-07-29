-- Creation timestamps for the catalog entities.
--
-- Until now these tables carried only `lastModified`, so "how many beers did
-- we add in 2023?" was unanswerable: an edit overwrites the only date we keep,
-- and api_logging (the other record of a POST) is pruned at 3 months and never
-- logs master-key writes at all.
--
-- Backfill: createdAt = lastModified. That is *exact* for any row never edited
-- since it was created — which is ~99% of the catalog, since 60,340 of 60,658
-- beers still carry their 2020 bulk-import timestamp. For rows that have been
-- edited it is an upper bound (the row is at least that old), so every derived
-- growth figure is conservative: it can under-report how long we have had a
-- record, never over-report.
--
-- Written on POST (and on PUT that creates a new id) by Beer/Brewer/Location
-- ::add(); the PUT and PATCH update paths deliberately never touch it.

ALTER TABLE `beer`
  ADD COLUMN `createdAt` INT NOT NULL DEFAULT 0,
  ADD INDEX `idx_beer_createdAt` (`createdAt`);

ALTER TABLE `brewer`
  ADD COLUMN `createdAt` INT NOT NULL DEFAULT 0,
  ADD INDEX `idx_brewer_createdAt` (`createdAt`);

ALTER TABLE `location`
  ADD COLUMN `createdAt` INT NOT NULL DEFAULT 0,
  ADD INDEX `idx_location_createdAt` (`createdAt`);

UPDATE `beer`     SET `createdAt` = `lastModified` WHERE `createdAt` = 0;
UPDATE `brewer`   SET `createdAt` = `lastModified` WHERE `createdAt` = 0;
UPDATE `location` SET `createdAt` = `lastModified` WHERE `createdAt` = 0;
