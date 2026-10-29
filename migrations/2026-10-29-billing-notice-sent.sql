-- billing_charges: noticeSentAt, the once-per-cycle stamp on the billing notice.
--
-- From November 2026 the API bills in two phases (API cron/bill-usage.php):
-- on the 1st it records last month's charges and emails each customer the
-- exact amount and the card it will go on, and on the 4th it invoices. The
-- notice is stamped on every pending row of the key when it is sent, and a
-- key stamped since the start of the current month is skipped, so a re-run
-- of the 1st never emails twice and a send that failed is retried.
--
-- Nullable, no default: every existing row reads as "never noticed", which
-- is true. Run BEFORE the API deploy (the notice query selects the column).

ALTER TABLE `billing_charges` ADD COLUMN `noticeSentAt` int DEFAULT NULL AFTER `status`;
