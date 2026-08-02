-- Stores the RDAP registration date of a brewer's URL domain, which
-- catalog-beer-api cron/check-urls.php previously looked up and printed to the
-- report without keeping.
--
-- The signal: a registration date LATER than the brewer's createdAt means the
-- domain lapsed after we catalogued the brewery and was re-registered by
-- somebody else. That distinguishes "this brewery closed" from "this brewery
-- rebranded" from "a squatter now owns this address" — and unlike urlLastOkAt
-- it works retroactively, because RDAP will answer for those domains today.
--
-- Populated lazily by the cron for the statuses where the question arises
-- (moved, parked, gone, no_answer) and only when the column is still NULL:
-- registration dates do not change, and RDAP is a courtesy service.

ALTER TABLE `brewer`
  ADD COLUMN `urlDomainRegistered` DATE DEFAULT NULL AFTER `urlLastKnown`;
