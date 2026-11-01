-- Drop the seven URL-health columns from `brewer`, and their two indexes.
--
-- They were written by the API's check-urls cron (retired 2026-10-23, when the
-- brewer review loop moved to review.catalog.beer) and reset by Brewer::add()
-- on a URL change. The review service's URL audit read every stored URL with a
-- human-grade pass and finished on 2026-10-29 (4,022 rows; the last four were
-- looked at and deferred). Its seed copied the cron's final verdicts into
-- `url_audit`, and every `urlLastKnown` is held there too: 863 in
-- `brewer_state.url_last_known` (the import) and the other 574 as the clear
-- itself in `review_change` (before_value), checked 2026-11-01.
--
-- Run AFTER the API deploy that stops reading `urlStatus` (Brewer::validate()
-- selects it until then, so this run first would 500 every brewer write).
-- The frontend's /admin/metrics URL-health panel goes in the same window; the
-- `brewer_url_status` rows already in metrics_daily are left as history.

ALTER TABLE `brewer`
  DROP INDEX `idx_url_check`,
  DROP INDEX `idx_url_status`,
  DROP COLUMN `urlStatus`,
  DROP COLUMN `urlCheckedAt`,
  DROP COLUMN `urlLastOkAt`,
  DROP COLUMN `urlFailCount`,
  DROP COLUMN `urlFinal`,
  DROP COLUMN `urlLastKnown`,
  DROP COLUMN `urlDomainRegistered`;
