-- Brewer status, operating years and country; lead country; ISO 3166-2 width.
--
-- A closed brewery used to be recorded only in prose: the review loop rewrote
-- the description to past tense and posted outcome `defunct` on the review
-- row. Nothing downstream could read that -- the frontend could not label it,
-- search could not rank it, the URL cron kept reporting its dead site as a
-- finding, and a stale page could put a closed brewery's taproom back on the
-- map. `status` is the authoritative flag; `foundedYear`/`closedYear` are
-- year-only because that is what every source states ("est. 2014", "closed in
-- 2023") and nothing anyone queries needs more. A closure whose year is
-- unknown is status=closed with closedYear NULL, so the flag is not derivable
-- from the year.
--
-- `countryCode` is ISO 3166-1 alpha-2, the standard location.countryCode and
-- the public docs already use. It lives on the brewer because a brewer with no
-- locations (contract brewers, every closed one) has no derivable country, and
-- on the lead so a non-US discovery is filed instead of thrown away: the
-- claim queue hands out US rows only, so the open non-US leads are the backlog
-- for any future expansion.
--
-- ISO 3166-2 codes run to six characters (GB-ENG, FR-ARA); the three sub_code
-- columns were varchar(5), wide enough for every US code and no three-letter
-- region. Widened together because US_addresses.sub_code references
-- subdivisions.sub_code and the two sides of a foreign key must match, which
-- also means the constraint has to be dropped around the change.
--
-- Deploy order: THIS MIGRATION FIRST, then the API. The old code never reads
-- the new columns; the new code SELECTs them on every brewer read.

ALTER TABLE brewer
  ADD COLUMN status enum('active','closed') NOT NULL DEFAULT 'active' AFTER brewerVerified,
  ADD COLUMN foundedYear smallint unsigned DEFAULT NULL AFTER status,
  ADD COLUMN closedYear smallint unsigned DEFAULT NULL AFTER foundedYear,
  ADD COLUMN countryCode char(2) NOT NULL DEFAULT 'US' AFTER closedYear,
  ADD INDEX idx_brewer_status (status),
  ADD CONSTRAINT chk_brewer_closed_year CHECK (closedYear IS NULL OR status = 'closed'),
  ADD CONSTRAINT chk_brewer_years CHECK (foundedYear IS NULL OR closedYear IS NULL OR closedYear >= foundedYear);

ALTER TABLE brewer_lead
  ADD COLUMN countryCode char(2) NOT NULL DEFAULT 'US' AFTER sub_code,
  MODIFY COLUMN sub_code varchar(6) DEFAULT NULL,
  ADD INDEX idx_lead_country (countryCode, status);

ALTER TABLE US_addresses DROP FOREIGN KEY fk_sub_code;
ALTER TABLE subdivisions MODIFY COLUMN sub_code varchar(6) NOT NULL;
ALTER TABLE US_addresses MODIFY COLUMN sub_code varchar(6) NOT NULL;
ALTER TABLE US_addresses
  ADD CONSTRAINT fk_sub_code FOREIGN KEY (sub_code) REFERENCES subdivisions (sub_code) ON DELETE CASCADE;
