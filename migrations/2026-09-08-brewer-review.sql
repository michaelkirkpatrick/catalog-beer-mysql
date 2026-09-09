-- Brewer review: the queue and the record for the agent-run review loop.
--
-- Every brewer with a URL is reviewed on a cadence against what the brewery
-- publishes on its own site — six steps (belongs? url, name, description,
-- beers, locations), then one row recording what was done and why. The
-- catalog API is the only door: no dump, no SSH, no CSV on anyone's machine.
-- Design: catalog-beer-cleanup/scratch/Reviewing Brewers — blank page.md
--
-- Two layers:
--
--   1. brewer.reviewedAt / claimedBy / claimedAt — the queue, on the row.
--      POST /review/claim selects the next N brewers (never reviewed first,
--      then a non-ok cron verdict, then oldest reviewedAt) and stamps the
--      claim in the same transaction, so two agents cannot take one brewer.
--      A claim EXPIRES on the read side: the claim query treats claimedAt
--      older than four hours as free. Nothing sweeps claims and nothing has
--      to; a session that dies strands nothing. POST /review/{brewerID}
--      sets reviewedAt and clears the claim.
--
--   2. brewer_review — append-only, one row per completed review of one
--      brewer. Mirrors the columns of the review-log.csv the cleanup
--      directory kept by hand for 949 brewers (Aug 2026), so that log can
--      be imported as the table's first rows. needsDecision is the check-in
--      list: everything a rule did not settle, waiting on a human. sources
--      and changes are what make a review auditable and hand-revertable —
--      the pages actually read, and every field written as before/after.
--
-- reviewer is the userID behind the key, not the key itself (keys rotate;
-- the account is the actor). It is deliberately NOT a foreign key: the
-- provenance of a review must survive the deletion of the account that
-- wrote it. brewerID does cascade — a review of a deleted brewer describes
-- nothing.
--
-- UUID primary key, not AUTO_INCREMENT, because rows are addressed by the
-- API (PATCH /review/{id}) and every routed id in this API is a 36-char UUID.

ALTER TABLE `brewer`
  ADD COLUMN `reviewedAt` int DEFAULT NULL AFTER `createdAt`,
  ADD COLUMN `claimedBy` varchar(36) DEFAULT NULL AFTER `reviewedAt`,
  ADD COLUMN `claimedAt` int DEFAULT NULL AFTER `claimedBy`,
  ADD INDEX `idx_brewer_reviewedAt` (`reviewedAt`),
  ADD INDEX `idx_brewer_claimedAt` (`claimedAt`);

CREATE TABLE `brewer_review` (
  `id` varchar(36) NOT NULL,
  `brewerID` varchar(36) NOT NULL,
  `reviewedAt` int NOT NULL,
  `reviewer` varchar(36) NOT NULL,
  -- The commit of the agent brief (policy + procedure) this review ran under,
  -- so any row can be traced to the rules in force when it was written.
  `briefVersion` varchar(40) DEFAULT NULL,
  -- What happened to the brewer record as a whole. 'deferred' = the site
  -- needs a browser or a human; the brewer stays in the queue.
  `outcome` enum('updated','unchanged','created','skipped','defunct','merged','deferred') NOT NULL,
  -- Step 1. What the review did with brewer.url. 'ok' also stamps
  -- brewer.urlCheckedAt / urlLastOkAt so the cron and the review agree.
  `urlVerdict` enum('ok','cleared','replaced','unchecked') NOT NULL DEFAULT 'unchecked',
  -- Steps 2–3. Comma-separated brewer fields written, e.g. 'name,description'.
  `brewerChanged` varchar(255) DEFAULT NULL,
  -- Steps 4–5. Counts, so the loop's throughput is a query, not a log parse.
  `beersAdded` smallint unsigned NOT NULL DEFAULT '0',
  `beersUpdated` smallint unsigned NOT NULL DEFAULT '0',
  `dupesDeleted` smallint unsigned NOT NULL DEFAULT '0',
  `locationsAdded` smallint unsigned NOT NULL DEFAULT '0',
  `locationsUpdated` smallint unsigned NOT NULL DEFAULT '0',
  `locationsDeleted` smallint unsigned NOT NULL DEFAULT '0',
  -- The pages actually read: a JSON array of URLs. "Reviewed on this date
  -- against these pages" is the provenance a record can later show.
  `sources` json DEFAULT NULL,
  -- Every field written, as [{entity, id, field, before, after}]. The
  -- hand-revert until a server-side revert exists.
  `changes` json DEFAULT NULL,
  `notes` text,
  -- The check-in list. A rule did not settle something; a human answers,
  -- and the next review of this brewer reads the decision.
  `needsDecision` bit(1) NOT NULL DEFAULT b'0',
  `question` varchar(500) DEFAULT NULL,
  `decision` varchar(500) DEFAULT NULL,
  `decidedAt` int DEFAULT NULL,
  `decidedBy` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_review_brewer` (`brewerID`,`reviewedAt`),
  KEY `idx_review_decision` (`needsDecision`,`reviewedAt`),
  KEY `idx_review_reviewedAt` (`reviewedAt`),
  CONSTRAINT `fk_review_brewer` FOREIGN KEY (`brewerID`) REFERENCES `brewer` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Backfill, as a SEPARATE step once the routes exist: import the 949 rows of
-- catalog-beer-cleanup/review-log.csv into brewer_review (reviewer = the
-- account that ran the August chunks, briefVersion NULL), then
--   UPDATE brewer b JOIN (SELECT brewerID, MAX(reviewedAt) AS r
--                        FROM brewer_review GROUP BY brewerID) x
--      ON x.brewerID = b.id SET b.reviewedAt = x.r;
-- so the queue does not hand the agent brewers reviewed by hand last month.
