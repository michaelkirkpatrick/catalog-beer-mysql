-- 2026-11-13 — users.sessionGen: a new password signs the account out
-- everywhere else.
--
-- Why: the website's sessions are PHP file sessions that hold only the
-- account's id, and nothing about the account changed when its password did.
-- A session opened before a password change or reset (someone else's included,
-- which is the case a reset exists for) kept working for up to 30 days.
--
-- sessionGen goes up by one each time the password is set (PATCH /users/{id}
-- with `password`, POST /users/password-reset/{key}). The API returns it as
-- `session_gen` on the user object and on POST /login; the website stores it
-- in the session at sign-in and ends any session whose number no longer
-- matches the account's. The API holds no sessions and never reads the column
-- itself. A counter, not a timestamp: the increment is atomic, two changes in
-- one second still differ, and audit_log already records when each change
-- happened.
--
-- Existing accounts start at 0 and sessions from before the website deploy
-- count as 0, so nobody is signed out by the deploy itself.
--
-- Run BEFORE deploying the API that names the column (Users::validate()
-- selects it on every authenticated /users request, Users::login() on every
-- sign-in). Safe to run early: nothing reads it until that deploy.

ALTER TABLE users
  ADD COLUMN sessionGen int NOT NULL DEFAULT 0 AFTER passwordResetKey;
