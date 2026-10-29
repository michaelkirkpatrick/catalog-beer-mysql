-- 2026-10-29 — Sign-up provenance on users: createdAt, signupIP, signupNet.
--
-- Why: on 2026-10-29 one person opened nine accounts in two days (seven in
-- fourteen minutes) from temp-mail addresses, verified each from the throwaway
-- inbox and burned every key's free tier dumping the catalog. The table had no
-- creation time and no record of where a sign-up came from, so the only trace
-- was Postmark's outbound log. The API now stores all three on POST /users and
-- caps sign-ups per network (SignupGuard::MAX_PER_NETWORK_PER_DAY, counted on
-- signupNet + createdAt) and per hour site-wide.
--
-- Run BEFORE deploying the API that names these columns in its INSERT. Safe to
-- run early: nothing reads them until that deploy.
--
-- signupIP is the address as seen (up to 45 chars for IPv6); signupNet is the
-- unit the cap counts — the IPv4 address, or the IPv6 /64 ("2a02:2455:a0c6:a000::").
-- Both are NULL for accounts not created through the website (Newman, scripts).

ALTER TABLE users
  ADD COLUMN createdAt int DEFAULT NULL AFTER stripeCustomerID,
  ADD COLUMN signupIP varchar(45) DEFAULT NULL AFTER createdAt,
  ADD COLUMN signupNet varchar(45) DEFAULT NULL AFTER signupIP,
  ADD INDEX idx_users_createdAt (createdAt),
  ADD INDEX idx_users_signupNet_createdAt (signupNet, createdAt);

-- Backfill what can be backfilled. The old schema's only creation-time trace is
-- emailAuthSent, and verification clears it, so this reaches the still-unverified
-- rows only (26 on production on 2026-10-29). Every verified account keeps NULL.
UPDATE users SET createdAt = emailAuthSent WHERE createdAt IS NULL AND emailAuthSent IS NOT NULL;
