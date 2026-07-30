-- Stripe usage billing: first 1,000 requests/month free (per-key requestLimit),
-- then $1 per 1,000 requests (rounded up to whole blocks) for keys with a card
-- on file. Run against catalogbeer on staging, then production.
--
-- Companion API change: catalog-beer-api (Stripe.class.php, Billing.class.php,
-- cron/bill-usage.php, index.php gate).

-- Stripe Customer for each user who has started billing setup.
ALTER TABLE `users`
  ADD COLUMN `stripeCustomerID` varchar(255) DEFAULT NULL AFTER `admin`;

-- billingEnabled: flipped on by the Stripe webhook when a default payment
-- method is saved; flipped off when the card is removed or dunning fails.
-- monthlySpendCapCents: runaway-bill protection. Overage requests stop (429)
-- once the month's projected overage charge reaches the cap. Default $50.
ALTER TABLE `api_keys`
  ADD COLUMN `billingEnabled` bit(1) NOT NULL DEFAULT b'0' AFTER `requestBuffer`,
  ADD COLUMN `monthlySpendCapCents` int NOT NULL DEFAULT '5000' AFTER `billingEnabled`;

-- One row per key per month with billable overage. Written by
-- cron/bill-usage.php on the 1st (for the previous month); status advanced by
-- the cron (pending -> invoiced) and by Stripe webhooks (invoiced -> paid /
-- failed / written_off). Rows with status='pending' roll forward until the
-- unbilled total reaches the $5 invoice floor (or the January annual sweep).
-- No foreign keys, matching api_usage/api_logging: rows are billing history
-- and must survive user/key deletion.
CREATE TABLE `billing_charges` (
  `id` varchar(36) NOT NULL,
  `userID` varchar(36) NOT NULL,
  `apiKey` varchar(36) NOT NULL,
  `year` smallint NOT NULL,
  `month` tinyint NOT NULL,
  `totalRequests` int NOT NULL,
  `billableRequests` int NOT NULL,
  `amountCents` int NOT NULL,
  `stripeInvoiceItemID` varchar(255) DEFAULT NULL,
  `stripeInvoiceID` varchar(255) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'pending',
  `createdAt` int NOT NULL,
  `lastUpdated` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_apiKey_year_month` (`apiKey`,`year`,`month`),
  KEY `idx_userID` (`userID`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
