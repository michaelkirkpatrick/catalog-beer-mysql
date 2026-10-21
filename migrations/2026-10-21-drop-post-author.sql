-- post: drop authorUserID.
--
-- The column recorded which admin wrote a post, and nothing ever read it:
-- the API never returned it, never filtered on it, and every admin can read
-- and edit every post regardless. It was the one foreign key from post into
-- users, so it also made account deletion touch the posts table for no gain.
-- Posts are the site's, not an account's.
--
-- Same change (2026-10-21), API side: an admin is any key whose account has
-- the admin flag, master keys included, and drafts are returned only when
-- the request says ?status=all or ?status=draft. Until now the master key was
-- refused as an admin so the website's public reads could not see drafts,
-- which also locked the master-key account out of /admin/posts. Body text is
-- now Markdown (raw HTML still allowed); the column type is unchanged and
-- existing HTML bodies render as before, so no data moves.
--
-- Deploy order: API FIRST, then this. The API's INSERT named the column until
-- this change, so dropping it under the old API would 500 every POST /post.
-- Nothing else references it. In-place DDL; the table has a few dozen rows.

ALTER TABLE `post`
  DROP FOREIGN KEY `fk_post_author`,
  DROP INDEX `idx_post_author`,
  DROP COLUMN `authorUserID`;
