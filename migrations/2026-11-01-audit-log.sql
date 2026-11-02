-- audit_log: the append-only record of every change to a catalog record
-- (brewer, beer, location) and to every account setting that matters (spend
-- cap, billing on/off, email, password, API key, brewery privileges), with the
-- acting user, key, IP and time. Design: catalog-beer-api
-- `Claude Ideas/audit-log.md`; code: `public_html/classes/Audit.class.php`.
--
-- Catalog rows carry `snapshot`, the complete database row as it stood AFTER
-- the change (a revert writes row N-1 back; a delete is recoverable from the
-- previous row). Settings rows carry `field`, `oldValue`, `newValue`. The two
-- kinds share one table so there is one helper, one history query and one
-- never-prune rule.
--
-- Three rules, each enforced by the shape of this DDL:
--   1. No foreign key to any entity table. A cascading history means a
--      malicious delete erases its own evidence. entityID is a bare char(36).
--   2. NEVER pruned and NEVER cascaded. If this table is ever trimmed it is
--      api_logging with more steps. Excluded by name from
--      cron/prune-api-logging.php and anything like it.
--   3. Deletes write a row (action='delete', snapshot NULL); the previous row
--      for that entity holds the last content.
--
-- The previous revision of an entity is the previous row with the same
-- (entityType, entityID); idx_audit_entity answers that directly, so there is
-- no priorID column. Rows older than the first live write are the baseline
-- backfill (action='create', source='backfill', changedAt = the row's
-- createdAt), one per existing catalog row, written by
-- cron/backfill-audit.php.
--
-- Run BEFORE the API deploy that carries Audit.class.php: every write path
-- inserts here, and a missing table would log one error (371) per write.
-- Additive: no existing table changes.

CREATE TABLE `audit_log` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entityType` enum('brewer','beer','location','user','api_key','privilege') NOT NULL,
  `entityID` char(36) NOT NULL,
  `action` enum('create','update','delete','revert','set') NOT NULL,
  `snapshot` json DEFAULT NULL,
  `field` varchar(64) DEFAULT NULL,
  `oldValue` text DEFAULT NULL,
  `newValue` text DEFAULT NULL,
  `revertOf` bigint unsigned DEFAULT NULL,
  `actorID` char(36) DEFAULT NULL,
  `actorKey` char(36) DEFAULT NULL,
  `source` enum('api','admin','webhook','cron','cleanup','backfill') NOT NULL,
  `ipAddress` varchar(45) DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  `changedAt` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_audit_entity` (`entityType`,`entityID`,`id`),
  KEY `idx_audit_actor` (`actorID`,`id`),
  KEY `idx_audit_time` (`changedAt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
