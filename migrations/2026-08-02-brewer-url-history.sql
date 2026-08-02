-- Keeps the evidence behind a removed brewer URL, so a future reader can tell
-- "this brewery has no website" from "this brewery's domain lapsed in 2019 and
-- now redirects to a casino — don't go looking for it".
--
-- Two layers:
--
--   1. brewer.urlLastKnown — the address itself. When the API clears a URL
--      (rather than replacing it), it now writes the old value here and LEAVES
--      urlStatus / urlCheckedAt / urlLastOkAt / urlFinal alone, so the row still
--      carries the monitoring verdict that prompted the removal. Replacing a URL
--      with a different one still resets all of them, urlLastKnown included.
--      urlLastOkAt is the useful signal: the last time that domain served the
--      brewery's own site.
--
--   2. brewer_url_history — append-only, one row per change to brewer.url,
--      written by catalog-beer-api Brewer::logURLChange() from three callers:
--      the API write path ('api'), the check-urls cron's https promotion
--      ('cron'), and bulk curation runs ('cleanup'). Internal only: no endpoint
--      exposes it.
--
-- verdict is the urlStatus the change was reacting to; it repeats the brewer
-- enum rather than referencing it so historical rows keep their meaning if the
-- enum is later extended.

ALTER TABLE `brewer`
  ADD COLUMN `urlLastKnown` VARCHAR(255) DEFAULT NULL AFTER `urlFinal`;

CREATE TABLE `brewer_url_history` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brewerID` CHAR(36) NOT NULL,
  `oldURL` VARCHAR(255) DEFAULT NULL,
  `newURL` VARCHAR(255) DEFAULT NULL,
  `verdict` ENUM(
      'ok','unverified','blocked','moved','parked',
      'url_wrong','server_error','no_answer','gone'
  ) DEFAULT NULL,
  `source` ENUM('api','cron','cleanup') NOT NULL DEFAULT 'api',
  `note` VARCHAR(255) DEFAULT NULL,
  `changedBy` CHAR(36) DEFAULT NULL,
  `changedAt` INT NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_bu_history_brewer` (`brewerID`, `changedAt`),
  CONSTRAINT `fk_bu_history_brewer` FOREIGN KEY (`brewerID`) REFERENCES `brewer` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
