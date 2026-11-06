-- 2026-11-06 — A pending email change on users: pendingEmail, pendingEmailAuth,
-- pendingEmailSent.
--
-- Why: until API 6.10.0 a change of email was applied at once. A new domain
-- then reset emailVerified and deleted the account's API key (taking
-- billingEnabled, the spend cap, a custom requestLimit and the month's usage
-- with it), and a same-domain change was never verified at all. From 6.10.0 a
-- verified account's email changes only when the new inbox confirms it: the
-- request is stored here, the confirmation link carries pendingEmailAuth, and
-- POST /users/confirm-email/{code} moves pendingEmail into email. The key is
-- never touched. Design: Claude Ideas/email-change-pending-confirmation.md.
--
-- emailAuth / emailAuthSent are deliberately NOT reused: they mean "this
-- account's own email is unproven" (a sign-up), and the two codes are exposed
-- under different rules.
--
-- Run BEFORE deploying the API that names these columns (Users::validate()
-- selects them on every authenticated /users request). Safe to run early:
-- nothing reads them until that deploy. All three are NULL as a block when no
-- change is pending.

ALTER TABLE users
  ADD COLUMN pendingEmail varchar(255) DEFAULT NULL AFTER emailAuthSent,
  ADD COLUMN pendingEmailAuth varchar(36) DEFAULT NULL AFTER pendingEmail,
  ADD COLUMN pendingEmailSent int DEFAULT NULL AFTER pendingEmailAuth,
  ADD UNIQUE KEY unique_pendingEmailAuth (pendingEmailAuth);
