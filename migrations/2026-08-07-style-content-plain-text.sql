-- ============================================================================
-- Style vocabulary: the last eleven Markdown spans become plain text
-- ----------------------------------------------------------------------------
-- Clears item E10 in catalog-beer-cleanup/OPEN-ITEMS.md.
--
-- THIS IS NOT A MARKDOWN-TO-HTML CONVERSION, AND IT MUST NOT BECOME ONE.
-- The frontend's escaping rewrite (Aug 2026) routes every one of these columns
-- through h() — htmlspecialchars() — at the moment of output:
--
--     style.php:188   echo '<div class="cb-prose__text">' . h($styleData->history) . '</div>';
--     style.php:194   echo '<div class="cb-prose__text">' . h($styleData->notes) . '</div>';
--
-- So storing <em>All About Beer</em> would render the literal characters
-- "<em>All About Beer</em>" on the page — a worse bug than the one it was
-- meant to fix, and one that also poisons the API, whose JSON is consumed by
-- clients that have never agreed to receive HTML. The database holds raw text;
-- the frontend escapes at output; a value is escaped exactly once. HTML in a
-- text column breaks that contract at the storage end.
--
-- Emphasis has no plain-text encoding, so each span is re-authored instead:
-- titles take quotes, everything else drops its markers.
--
-- FIX THE STYLE LIBRARY FIRST, OR THIS COMES BACK. The prose is authored in
-- the style library (Documents/Claude/Projects/Catalog.beer/style-library),
-- in styles/*.md, compiled to styles.json, and seeded here by
-- scripts/migration/seed.py --upsert. E10's note that "no committed seed
-- carries this prose" is true of THIS repo and misleading beyond it — the seed
-- is generated, so a re-seed would have overwritten every fix in this file.
-- Corrected in library v2.7.1 (2026-08-07): the twelve spans are re-authored at
-- source, and compile.py now REJECTS Markdown in the seven consumer prose
-- fields, so the next author is told at compile time.
--
-- That leaves two ways to land the change, and they converge:
--   A. This migration — smallest blast radius, touches 9 rows and nothing else.
--   B. `python3 seed.py --upsert` then apply seed_upsert.sql — canonical, but
--      it also upserts style/style_parent/style_alias and re-stamps style_meta,
--      so it moves any other library-to-DB drift at the same time.
-- Take A if the escaping deploy is imminent and you want a quiet change; take B
-- if the databases are behind the library anyway (see the Shandy note below).
-- Running A then B is safe and idempotent: B writes the same bytes.
--
-- WHAT IS CHANGING — 12 spans across 10 column values in 9 rows (old-ale is hit
-- in both history and notes), measured against library v2.7.0. E10 says "eleven
-- spans, nine rows"; it missed Shandy, for the reason in the next note.
--
-- SHANDY MAY OR MAY NOT NEED ITS SPAN FIXED — CHECK BEFORE YOU RUN.
-- The snapshot E10 censused (`cb_aug05`) is at style_meta version **2.6.0, 196
-- styles**, not the v2.7.0/197 that E10 and the project notes both claim. It
-- was taken before the Shandy re-seed. So `shandy` was absent from the census
-- and its *maß* span went unrecorded. The statement below is guarded on the
-- row's content, so it is a no-op on a database that has not seeded Shandy yet
-- and correct on one that has. Confirm which you are on:
--     SELECT version, last_updated FROM style_meta;
--     SELECT COUNT(*) FROM style;
-- If a database is still on 2.6.0, it is missing Shandy entirely and wants the
-- full re-seed (option B), not this file.
--
--   style_id                     col      before                          after
--   ---------------------------  -------  ------------------------------  -----
--   american-imperial-stout      history  *All About Beer*                "All About Beer"
--   english-barleywine           history  *The London and Country Brewer* "The London and Country Brewer"
--   english-ipa                  history  *Calcutta Gazette*              "Calcutta Gazette"
--   oatmeal-stout                history  *World Guide to Beer*           "World Guide to Beer"
--   british-imperial-stout       history  *Olivia*                        Olivia
--   old-ale                      history  *Brettanomyces*                 Brettanomyces
--   old-ale                      notes    *Brettanomyces*                 Brettanomyces
--   shandy                       history  *maß*                           maß
--   american-dark-lager          notes    `munich-dunkel`                 Munich-Style Dunkel
--   american-dark-lager          notes    `schwarzbier`                   German-Style Schwarzbier
--   american-marzen-oktoberfest  notes    the German `german-style maerzen`  the German-Style Maerzen
--   american-marzen-oktoberfest  notes    `german-festbier`               Festbier
--
-- The three rules behind those choices:
--
--   1. Book, journal and newspaper titles were italicized. In plain text the
--      convention is quotation marks. Straight double quotes, to match the
--      quoting already in this prose ("to be of a Vinous Nature," 'Oat Malt
--      Stout') — SmartyPants is gone and curling is nobody's job now.
--   2. A ship name (Olivia), a genus (Brettanomyces) and a foreign word used as
--      a word (maß) are italicized by convention, and the convention when
--      italics are unavailable is plain text, NOT quotes. Quoting a genus would
--      assert something different, and "maß" would sit next to the "cyclist's
--      liter" gloss it already has.
--   3. The backticks marked style slugs, which were never meant for readers.
--      They become the canonical display names from the `style` table, so the
--      prose names styles the same way the rest of the site does. Two
--      concessions to readability: "Compared with the German `german-style
--      maerzen`" would become "the German German-Style Maerzen", so it drops
--      the redundant "German"; and the full "German-Style Oktoberfest/
--      Festbier" reads badly mid-sentence as "the pale, lean ... profile", so
--      that one is just "Festbier".
--
-- NO DEPLOY ORDER, NO CODE CHANGE, NO ALGOLIA REINDEX. Nothing reads these
-- columns except GET /style/{id} and style.php, both of which pass the bytes
-- through. generateStyleSearchObjects() indexes `description` only (Style.class.php:1166),
-- and no `description` row is touched here, so every Algolia record is
-- byte-identical before and after. Run it whenever; the escaping deploy does
-- not wait on it. Until it runs, eight style pages show literal * and `.
--
-- RUNBOOK (staging, then production):
--   1. Back up:  mysqldump catalogbeer style_content > style_content-backup.sql
--   2. Pre-flight census — 9 rows expected on production, unknown on staging:
--        SELECT style_id, 'history' AS col FROM style_content WHERE history REGEXP '[*`_]'
--        UNION ALL
--        SELECT style_id, 'notes' FROM style_content WHERE notes REGEXP '[*`_]';
--   3. mysql catalogbeer < 2026-08-07-style-content-plain-text.sql   (this file)
--   4. Verify — the same census must return zero rows (see the bottom of this
--      file), then load /style/american-imperial-stout and /style/old-ale and
--      read the Origin and Notes prose.
--
-- Every statement is idempotent: each one matches the exact span it replaces,
-- so a second run changes nothing and a row that never had the markup is
-- untouched. Staging can run the identical file even if its vocabulary drifted.
--
-- Dry-run 2026-08-07 against a scratch copy of the 2026-08-05 snapshot: ran
-- clean twice, exactly 8 rows differ from the source, the seven-column census
-- returns zero rows afterward, and all 11 rewritten spans were read back in
-- context. No column other than history and notes was touched.
-- ============================================================================

SET NAMES utf8mb4;

-- --- Rule 1: italicized titles take straight double quotes --------------------

UPDATE `style_content`
   SET `history` = REPLACE(`history`, '*All About Beer*', '"All About Beer"')
 WHERE `style_id` = 'american-imperial-stout'
   AND `history` LIKE '%*All About Beer*%';

UPDATE `style_content`
   SET `history` = REPLACE(`history`, '*The London and Country Brewer*', '"The London and Country Brewer"')
 WHERE `style_id` = 'english-barleywine'
   AND `history` LIKE '%*The London and Country Brewer*%';

UPDATE `style_content`
   SET `history` = REPLACE(`history`, '*Calcutta Gazette*', '"Calcutta Gazette"')
 WHERE `style_id` = 'english-ipa'
   AND `history` LIKE '%*Calcutta Gazette*%';

UPDATE `style_content`
   SET `history` = REPLACE(`history`, '*World Guide to Beer*', '"World Guide to Beer"')
 WHERE `style_id` = 'oatmeal-stout'
   AND `history` LIKE '%*World Guide to Beer*%';

-- --- Rule 2: a ship name and a genus go bare, not quoted ---------------------

UPDATE `style_content`
   SET `history` = REPLACE(`history`, '*Olivia*', 'Olivia')
 WHERE `style_id` = 'british-imperial-stout'
   AND `history` LIKE '%*Olivia*%';

UPDATE `style_content`
   SET `history` = REPLACE(`history`, '*Brettanomyces*', 'Brettanomyces')
 WHERE `style_id` = 'old-ale'
   AND `history` LIKE '%*Brettanomyces*%';

UPDATE `style_content`
   SET `notes` = REPLACE(`notes`, '*Brettanomyces*', 'Brettanomyces')
 WHERE `style_id` = 'old-ale'
   AND `notes` LIKE '%*Brettanomyces*%';

-- No-op on a database still at vocabulary 2.6.0, which has no shandy row.
UPDATE `style_content`
   SET `history` = REPLACE(`history`, '*maß*', 'maß')
 WHERE `style_id` = 'shandy'
   AND `history` LIKE '%*maß*%';

-- --- Rule 3: backticked slugs become canonical display names -----------------

UPDATE `style_content`
   SET `notes` = REPLACE(`notes`, '`munich-dunkel`', 'Munich-Style Dunkel')
 WHERE `style_id` = 'american-dark-lager'
   AND `notes` LIKE '%`munich-dunkel`%';

UPDATE `style_content`
   SET `notes` = REPLACE(`notes`, '`schwarzbier`', 'German-Style Schwarzbier')
 WHERE `style_id` = 'american-dark-lager'
   AND `notes` LIKE '%`schwarzbier`%';

-- "the German `german-style maerzen`" -> "the German-Style Maerzen": the
-- replacement swallows the preceding "German " so the sentence does not stutter.
UPDATE `style_content`
   SET `notes` = REPLACE(`notes`, 'the German `german-style maerzen`', 'the German-Style Maerzen')
 WHERE `style_id` = 'american-marzen-oktoberfest'
   AND `notes` LIKE '%the German `german-style maerzen`%';

UPDATE `style_content`
   SET `notes` = REPLACE(`notes`, '`german-festbier`', 'Festbier')
 WHERE `style_id` = 'american-marzen-oktoberfest'
   AND `notes` LIKE '%`german-festbier`%';

-- ----------------------------------------------------------------------------
-- Verification — both queries must return zero rows.
--
--   SELECT style_id, 'description' AS col FROM style_content WHERE description REGEXP '[*`_]'
--   UNION ALL SELECT style_id, 'appearance' FROM style_content WHERE appearance  REGEXP '[*`_]'
--   UNION ALL SELECT style_id, 'aroma'      FROM style_content WHERE aroma       REGEXP '[*`_]'
--   UNION ALL SELECT style_id, 'flavor'     FROM style_content WHERE flavor      REGEXP '[*`_]'
--   UNION ALL SELECT style_id, 'mouthfeel'  FROM style_content WHERE mouthfeel   REGEXP '[*`_]'
--   UNION ALL SELECT style_id, 'history'    FROM style_content WHERE history     REGEXP '[*`_]'
--   UNION ALL SELECT style_id, 'notes'      FROM style_content WHERE notes       REGEXP '[*`_]';
--
-- A row surfacing here after this migration is new prose, not a leftover: this
-- file names every span that existed on 2026-08-05. All seven columns are in
-- the census on purpose — the original E9-era census only ever checked
-- description, and appearance/aroma/flavor/mouthfeel had never been looked at
-- at all (they were clean, 188 non-empty rows each, checked 2026-08-07).
--
-- Underscore is in the character class deliberately: _emphasis_ is the other
-- half of Markdown's italic syntax and none of it exists today. It will match
-- a legitimate underscore in prose too, which is the right kind of false
-- positive for a census to have.
-- ----------------------------------------------------------------------------
