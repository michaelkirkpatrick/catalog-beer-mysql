-- Brewer leads: the queue of breweries the review loop has met that the
-- catalog does not hold, so they can be researched properly later instead of
-- being created badly now, or lost in a review's notes.
--
-- A lead is not a record. It is a pointer to work -- a name, a place, and the
-- page it was read on -- and it becomes a brewer only by being claimed and put
-- through the six steps, ending in a brewer_review row with outcome 'created'.
-- Nothing in this table is ever published.
-- Spec: catalog-beer-api/scratch/brewer-leads-spec.md (v3)
--
-- Two stored states, open/closed. "claimed" is derived: an open row whose
-- claimedAt is within the four-hour TTL, exactly as brewer.claimedAt works.
-- Claims expire on the read side and nothing sweeps them; a stored 'claimed'
-- would go stale the first time a session died mid-claim.
--
-- Dedup on POST is server-side and covers every status, so a closed lead is
-- also the negative cache: the same winery or co-packer is not re-researched
-- every few months by an agent that cannot know it was dismissed. nameKey and
-- urlHost are the two dedup keys, derived on write and never returned; they
-- are indexed but NOT unique -- two genuinely different breweries can
-- normalise alike, and a collision should return the most recently seen row,
-- not throw. A URL host that matches brewer.domainName is refused outright
-- (409): the brewery exists, review it instead.
--
-- sources starts as [sourceUrl] and gets each dedup hit's page appended (cap
-- 20). It adds no fact about the brewery, only the pages that named it -- the
-- corroboration step 0 wants. Nothing else is ever merged into a row on a
-- dedup hit; enrichment happens at research time where verification does.
--
-- The four *By columns hold the userID behind the key, like brewer_review
-- .reviewer, and are deliberately not foreign keys: provenance outlives the
-- account. brewerID IS a foreign key, ON DELETE SET NULL, so a 'created' lead
-- whose brewer is later merged away neither vanishes nor dangles.
--
-- needsDecision/question/decision are the review row's trio, for the one kind
-- of question a lead can raise that no review row can carry: a scope call
-- POLICY is silent on, before the brewer exists. A row with needsDecision=1 is
-- never claimed; once decided, the next claim hands it out first.

CREATE TABLE `brewer_lead` (
  `id` varchar(36) NOT NULL,
  -- Verbatim as the source printed it; same cap as brewer.name.
  `name` varchar(255) NOT NULL,
  -- Dedup key: SearchQuery::brewerNameKey() -- accents folded, punctuation
  -- stripped, generic words (brewing, brewery, co, ...) and a leading "the"
  -- dropped, lowercased. The same test search uses for a name match.
  `nameKey` varchar(255) NOT NULL,
  -- The brewery's site, verbatim as sent. Never fetched: a lead must be able
  -- to carry a dead, slow, or not-yet-live URL. Verifying it is step 1 of the
  -- review that researches the lead, not a precondition of recording it.
  `url` varchar(255) DEFAULT NULL,
  -- Dedup key: lowercased host, www. stripped -- brewer.domainName's rule.
  `urlHost` varchar(255) DEFAULT NULL,
  -- As published; not USPS-corrected.
  `city` varchar(100) DEFAULT NULL,
  `sub_code` varchar(5) DEFAULT NULL,
  -- The page this was read on. "No source, no write", applied to leads.
  `sourceUrl` varchar(255) NOT NULL,
  -- JSON array of URLs: every page that named this brewery.
  `sources` json NOT NULL,
  -- For whoever researches it: what the source said, in prose.
  `note` text,
  `status` enum('open','closed') NOT NULL DEFAULT 'open',
  -- Null while open. created/duplicate carry brewerID; the other two refuse it.
  `resolution` enum('created','duplicate','not_a_brewery','out_of_scope') DEFAULT NULL,
  `brewerID` varchar(36) DEFAULT NULL,
  -- Unix ts. A deferred lead is held out of the claim until then.
  `recheckAfter` int DEFAULT NULL,
  `createdBy` varchar(36) NOT NULL,
  `createdAt` int NOT NULL,
  -- Bumped on every dedup hit; the "how often does this come up" signal.
  `lastSeenAt` int NOT NULL,
  `claimedBy` varchar(36) DEFAULT NULL,
  `claimedAt` int DEFAULT NULL,
  `resolvedBy` varchar(36) DEFAULT NULL,
  `resolvedAt` int DEFAULT NULL,
  `needsDecision` bit(1) NOT NULL DEFAULT b'0',
  `question` varchar(500) DEFAULT NULL,
  `decision` varchar(500) DEFAULT NULL,
  `decidedAt` int DEFAULT NULL,
  `decidedBy` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_lead_name` (`nameKey`,`sub_code`),
  KEY `idx_lead_host` (`urlHost`),
  KEY `idx_lead_claim` (`status`,`recheckAfter`,`createdAt`),
  KEY `idx_lead_decision` (`needsDecision`,`createdAt`),
  KEY `idx_lead_brewer` (`brewerID`),
  CONSTRAINT `fk_lead_brewer` FOREIGN KEY (`brewerID`) REFERENCES `brewer` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
