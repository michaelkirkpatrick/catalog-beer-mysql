-- brewer_review.notes: TEXT -> MEDIUMTEXT.
--
-- Review::multiLine() caps notes at 20,000 CHARACTERS, measured with
-- mb_strlen. TEXT holds 65,535 BYTES. UTF-8 runs up to 4 bytes a character,
-- so a note of 16,384 characters or more can exceed the column while passing
-- the cap. Production runs STRICT_TRANS_TABLES, so that is not a silent
-- truncation: it is error 1406 and the INSERT fails — and it fails AFTER the
-- review's catalog writes have landed, losing the audit row for edits that
-- are already live.
--
-- English review notes measure ~1 byte a character and the longest on record
-- is 15,708 characters, so this has never fired. It is a latent failure that
-- gets likelier as notes grow, and MEDIUMTEXT (16 MB) puts the column safely
-- past any value the character cap can admit.
--
-- The 20,000-character cap itself is unchanged: notes are read by a human,
-- and a note that long is already past what anyone reads.

ALTER TABLE `brewer_review`
  MODIFY COLUMN `notes` mediumtext;
