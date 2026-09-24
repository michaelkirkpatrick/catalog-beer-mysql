-- Brewers may share a domain: one brewer per homepage, not one per domain.
--
-- An acquired brand that carries on under its own name often loses its own
-- domain -- the buyer folds it into a page on the buyer's site (Whetstone
-- Beer Co. lives at https://northchair.com/whetstone-beer/, and its old
-- domain redirects there). Until now brewer.domainName was UNIQUE, so the
-- catalog could hold the brand or its owner, never both.
--
-- The rule is now enforced in the API (BrewerUrl::conflict()): a domain's
-- root URL belongs to at most one brewer, no two brewers may hold the same
-- page, and any number may hold distinct sub-pages of one domain. unique_url
-- stays as the byte-identical backstop. domainName keeps a plain index for
-- the WHERE domainName=? lookups in Brewer, BrewerLead and Metrics.
--
-- Staff permissions are unchanged and now shared by design: an email at the
-- owner's domain is brewery staff on every brewer that stores that domain,
-- which is the acquirer managing its acquisition.
--
-- Deploy order: THIS MIGRATION FIRST, then the API. The old code enforces
-- uniqueness with its own query and never depends on the index; the new code
-- without this migration would hit a duplicate-key error on INSERT.
--
-- Drop and add in one statement so the column is never unindexed. INPLACE +
-- LOCK=NONE stated so MySQL refuses rather than silently taking a table lock.

ALTER TABLE brewer
  DROP INDEX unique_domain,
  ADD INDEX idx_brewer_domain (domainName),
  ALGORITHM=INPLACE, LOCK=NONE;

-- Hosts are now lowercased on write. The staff check compares the user's
-- email domain (lowercased on store) with PHP ==, so a brewer submitted with
-- an uppercase host has never matched its own staff. Bring existing rows
-- into line; the column is compared _ci by MySQL so nothing else changes.
UPDATE brewer SET domainName = LOWER(domainName)
 WHERE domainName IS NOT NULL AND BINARY domainName <> LOWER(domainName);
