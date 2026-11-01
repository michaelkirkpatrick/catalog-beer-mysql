-- Follow-up to 2026-10-13-international-addresses.sql: drop the legacy US
-- table once the API has shipped on `address` and the Newman suite is green
-- against it. Nothing reads US_addresses after that deploy; this is the point
-- of no return for the copy, so run it after the soak, not with the migration.
--
-- Ran 2026-11-01 on staging and production.

DROP TABLE `US_addresses`;
