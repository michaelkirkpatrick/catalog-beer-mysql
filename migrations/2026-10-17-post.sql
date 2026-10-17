-- Posts: the /news announcements and the API changelog at /changelog.
--
-- Both used to be hand-edited HTML in the frontend's whats-new.php, which
-- meant a commit and a deploy per announcement and no changelog at all. An
-- admin page cannot write files instead: production ships `git archive HEAD`
-- through rsync --delete, so a post written to disk on the server is gone at
-- the next deploy. Posts are data, so they live here and the API serves them,
-- which also hands developers and agents the changelog as JSON.
--
-- One table, two channels. `news` is prose for everyone; `api` is one row per
-- catalog-beer-api release and is the only channel that carries a `version`
-- or a `breaking` flag (the CHECKs hold that). There is no website changelog
-- channel by design: site news is written by hand as a news post.
--
-- `publishedAt` is the date a reader sees, separate from `createdAt`, so the
-- changelog import can carry each release's push date while the row itself is
-- created today. It is required once a row is published and may be set ahead
-- of time on a draft.
--
-- `body` is admin-authored HTML and is emitted raw by the frontend; only admin
-- keys can write this table (the API enforces that), which is the whole trust
-- boundary. title, summary, slug and version are plain text and are escaped
-- on output like everything else.
--
-- `authorUserID` is SET NULL on user delete: removing an account must not
-- delete the announcements it wrote.
--
-- Deploy order: THIS MIGRATION FIRST, then the API. Nothing reads the table
-- until the API's /post routes ship; the frontend's /news and /changelog come
-- after the API.

CREATE TABLE post (
  id varchar(36) NOT NULL,
  channel enum('news','api') NOT NULL,
  slug varchar(120) NOT NULL,
  title varchar(200) NOT NULL,
  summary varchar(500) DEFAULT NULL,
  body mediumtext NOT NULL,
  version varchar(20) DEFAULT NULL,
  breaking bit(1) NOT NULL DEFAULT b'0',
  status enum('draft','published') NOT NULL DEFAULT 'draft',
  publishedAt int DEFAULT NULL,
  authorUserID varchar(36) DEFAULT NULL,
  createdAt int NOT NULL,
  lastModified int NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_post_slug (channel, slug),
  UNIQUE KEY uq_post_version (channel, version),
  KEY idx_post_feed (channel, status, publishedAt),
  KEY idx_post_author (authorUserID),
  CONSTRAINT fk_post_author FOREIGN KEY (authorUserID) REFERENCES users (id) ON DELETE SET NULL,
  CONSTRAINT chk_post_version CHECK (version IS NULL OR channel = 'api'),
  CONSTRAINT chk_post_breaking CHECK (breaking = b'0' OR channel = 'api'),
  CONSTRAINT chk_post_published CHECK (status = 'draft' OR publishedAt IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
