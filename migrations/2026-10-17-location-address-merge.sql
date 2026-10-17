-- Fold the address into the location: the eleven address columns move onto
-- `location`, `address` is dropped. Run AFTER 2026-10-13-international-addresses.sql
-- (which created `address` and copied US_addresses into it); on a database
-- that has not run that one yet, run both in order.
--
-- Why: a location holds at most one address and the address is keyed by the
-- location's id, so the separate table was a 1:1 row, not a relationship. It
-- dated from a plan for one address table per country that the
-- international-addresses work made unnecessary. Two rows for one fact cost
-- a denormalised countryCode that had to be guarded against drifting, a JOIN
-- in every read, and -- on the API -- a second write request that could fail
-- after the first had succeeded, which the frontend papered over with a
-- "pending location" held in the session. One row makes the create atomic:
-- an address the validator refuses means no location is written.
--
-- A location without an address is still legal (validation IS NULL, line1 IS
-- NULL). The US rules and the telephone shape are CHECKs that apply only when
-- a street is present, so the no-address state never trips them.

ALTER TABLE `location`
  ADD COLUMN `line1`             varchar(255) DEFAULT NULL AFTER `countryCode`,
  ADD COLUMN `line2`             varchar(255) DEFAULT NULL AFTER `line1`,
  ADD COLUMN `locality`          varchar(255) DEFAULT NULL AFTER `line2`,
  ADD COLUMN `dependentLocality` varchar(255) DEFAULT NULL AFTER `locality`,
  ADD COLUMN `sub_code`          varchar(6)   DEFAULT NULL AFTER `dependentLocality`,
  ADD COLUMN `postalCode`        varchar(20)  DEFAULT NULL AFTER `sub_code`,
  ADD COLUMN `formatted`         json         DEFAULT NULL AFTER `postalCode`,
  ADD COLUMN `languageCode`      varchar(8)   DEFAULT NULL AFTER `formatted`,
  ADD COLUMN `telephone`         varchar(16)  DEFAULT NULL AFTER `languageCode`,
  ADD COLUMN `validation`        enum('validated','geocoded','unverified') DEFAULT NULL AFTER `telephone`,
  ADD COLUMN `validatedAt`       int          DEFAULT NULL AFTER `validation`,
  ADD KEY `idx_location_country_sub` (`countryCode`,`sub_code`),
  ADD KEY `idx_location_postal` (`countryCode`,`postalCode`),
  ADD CONSTRAINT `fk_location_sub_code` FOREIGN KEY (`sub_code`) REFERENCES `subdivisions` (`sub_code`),
  ADD CONSTRAINT `chk_location_address` CHECK ((`line1` IS NULL) = (`locality` IS NULL) AND (`line1` IS NULL) = (`validation` IS NULL)),
  ADD CONSTRAINT `chk_location_us_sub` CHECK (`line1` IS NULL OR `countryCode` <> 'US' OR `sub_code` IS NOT NULL),
  ADD CONSTRAINT `chk_location_us_postal` CHECK (`line1` IS NULL OR `countryCode` <> 'US' OR `postalCode` REGEXP '^[0-9]{5}(-[0-9]{4})?$'),
  ADD CONSTRAINT `chk_location_tel` CHECK (`telephone` IS NULL OR `telephone` REGEXP '^\\+[1-9][0-9]{6,14}$');

UPDATE `location` l JOIN `address` a ON a.`locationID` = l.`id` SET
  l.`line1` = a.`line1`,
  l.`line2` = a.`line2`,
  l.`locality` = a.`locality`,
  l.`dependentLocality` = a.`dependentLocality`,
  l.`sub_code` = a.`sub_code`,
  l.`postalCode` = a.`postalCode`,
  l.`formatted` = a.`formatted`,
  l.`languageCode` = a.`languageCode`,
  l.`telephone` = a.`telephone`,
  l.`validation` = a.`validation`,
  l.`validatedAt` = a.`validatedAt`;

DROP TABLE `address`;
