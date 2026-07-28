-- URL health columns for the check-urls monitoring cron (catalog-beer-api
-- cron/check-urls.php). Report-only: the cron writes these status columns;
-- nothing reads them in the API yet and no URL is ever cleared automatically.
--
-- urlStatus meanings:
--   unverified   never checked (default, backfill state)
--   ok           responded, on-domain, not parked
--   moved        redirects to an unrelated registrable domain (urlFinal holds
--                the observed destination, ready for review)
--   parked       HTTP 200 but parking-service fingerprint or near-empty body
--   blocked      401/403/405/406/418/429/451 — alive, declines bots
--   url_wrong    404/410 — path dead, domain may be healthy
--   server_error 5xx — transient
--   no_answer    no HTTP response / TLS failure (urlFailCount escalation path)
--   gone         DNS NXDOMAIN (urlFailCount escalation path)

ALTER TABLE `brewer`
  ADD COLUMN `urlStatus` ENUM(
      'ok','unverified','blocked','moved','parked',
      'url_wrong','server_error','no_answer','gone'
  ) NOT NULL DEFAULT 'unverified',
  ADD COLUMN `urlCheckedAt` INT DEFAULT NULL,
  ADD COLUMN `urlLastOkAt` INT DEFAULT NULL,
  ADD COLUMN `urlFailCount` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  ADD COLUMN `urlFinal` VARCHAR(255) DEFAULT NULL,
  ADD INDEX `idx_url_check` (`urlCheckedAt`),
  ADD INDEX `idx_url_status` (`urlStatus`);
